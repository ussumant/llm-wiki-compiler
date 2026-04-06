#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${REPO_ROOT}/plugin"
DEST_DIR="${SCRIPT_DIR}/llm-wiki-complior-plugin"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/copilot-port-upgrade.XXXXXX")"
trap 'rm -rf "${TMP_ROOT}"' EXIT

REPO_ROOT="${REPO_ROOT}" SOURCE_DIR="${SOURCE_DIR}" DEST_DIR="${DEST_DIR}" TMP_ROOT="${TMP_ROOT}" python <<'PY'
import json
import os
import re
import shutil
import stat
import textwrap
from pathlib import Path

repo_root = Path(os.environ["REPO_ROOT"])
source_dir = Path(os.environ["SOURCE_DIR"])
dest_dir = Path(os.environ["DEST_DIR"])
tmp_root = Path(os.environ["TMP_ROOT"])
staging_dir = tmp_root / dest_dir.name

required_paths = [
    source_dir / ".claude-plugin" / "plugin.json",
    source_dir / "commands",
    source_dir / "hooks" / "hooks.json",
    source_dir / "hooks" / "session-start",
    source_dir / "skills" / "wiki-compiler" / "SKILL.md",
    source_dir / "templates" / "article-template.md",
    source_dir / "templates" / "schema-template.md",
]
for path in required_paths:
    if not path.exists():
        raise SystemExit(f"Missing required source path: {path}")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, content: str, mode: int | None = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    if mode is not None:
        path.chmod(stat.S_IMODE(mode))


def copy_tree(src: Path, dst: Path) -> None:
    shutil.copytree(src, dst, copy_function=shutil.copy2)


def replace_string_values(value, old: str, new: str):
    if isinstance(value, str):
        return value.replace(old, new)
    if isinstance(value, list):
        return [replace_string_values(item, old, new) for item in value]
    if isinstance(value, dict):
        return {key: replace_string_values(item, old, new) for key, item in value.items()}
    return value


def indent_code_block(template: str, spaces: int) -> str:
    prefix = " " * spaces
    return "\n".join(f"{prefix}{line}" if line else prefix.rstrip() for line in template.rstrip("\n").splitlines())


def transform_session_start(source_text: str) -> str:
    replacement = textwrap.dedent(
        """\
        project_root="$(dirname "$config_file")"

        if ! command -v node >/dev/null 2>&1; then
          echo "[Wiki Compiler] node is required for the Copilot port session-start hook." >&2
          exit 0
        fi

        read_config_value() {
          local key="$1"
          local fallback="$2"

          CONFIG_FILE="$config_file" CONFIG_KEY="$key" CONFIG_FALLBACK="$fallback" node <<'NODE'
        const fs = require('fs');

        try {
          const raw = fs.readFileSync(process.env.CONFIG_FILE, 'utf8');
          const config = JSON.parse(raw);
          const value = config[process.env.CONFIG_KEY];
          console.log(value === undefined || value === null || value === '' ? process.env.CONFIG_FALLBACK : value);
        } catch (error) {
          console.error(`[Wiki Compiler] Failed to parse ${process.env.CONFIG_FILE}: ${error.message}`);
          process.exit(1);
        }
        NODE
        }

        # Read config values using node
        if ! output_path="$(read_config_value output '')"; then
          exit 0
        fi
        if ! mode="$(read_config_value mode 'staging')"; then
          exit 0
        fi
        if ! name="$(read_config_value name 'Project')"; then
          exit 0
        fi
        """
    )

    pattern = re.compile(
        r'project_root="\$\(dirname "\$config_file"\)"\n\n# Read config values using node\n'
        r'output_path=\$\(node -e "const c=require\(\'\$config_file\'\); console\.log\(c\.output \|\| \'\'\)"\)\n'
        r'mode=\$\(node -e "const c=require\(\'\$config_file\'\); console\.log\(c\.mode \|\| \'staging\'\)"\)\n'
        r'name=\$\(node -e "const c=require\(\'\$config_file\'\); console\.log\(c\.name \|\| \'Project\'\)"\)\n'
    )
    updated_text, count = pattern.subn(replacement, source_text, count=1)
    if count != 1:
        raise SystemExit("Unable to transform session-start config block")

    output_path_block = textwrap.dedent(
        """\
        if [ -z "$output_path" ]; then
          exit 0
        fi

        output_prefix="$output_path"
        case "$output_prefix" in
          */) ;;
          *) output_prefix="${output_prefix}/" ;;
        esac

        index_file="$project_root/$output_path/INDEX.md"
        state_file="$project_root/$output_path/.compile-state.json"
        """
    )
    updated_text, count = re.subn(
        r'if \[ -z "\$output_path" \]; then\n  exit 0\nfi\n\nindex_file="\$project_root/\$output_path/INDEX\.md"\nstate_file="\$project_root/\$output_path/\.compile-state\.json"\n',
        output_path_block,
        updated_text,
        count=1,
    )
    if count != 1:
        raise SystemExit("Unable to transform session-start output path block")

    updated_text = updated_text.replace('Location: $output_path', 'Location: $output_prefix')
    updated_text = updated_text.replace('${output_path}INDEX.md', '${output_prefix}INDEX.md')
    updated_text = updated_text.replace('at $output_path ($topic_count topics, last compiled: $last_compiled)', 'at $output_prefix ($topic_count topics, last compiled: $last_compiled)')
    updated_text = updated_text.replace('Never modify wiki/ files directly', 'Never modify ${output_prefix} files directly')

    copilot_output = (
        '# Output in Copilot-compatible hook format\n'
        'printf \'{\\n  "hookSpecificOutput": {\\n    "hookEventName": "SessionStart",\\n'
        '    "additionalContext": "%s"\\n  }\\n}\\n\' "$escaped_context"\n'
    )
    updated_text, count = re.subn(
        r'# Output in correct format per platform\nif \[ -n "\$\{CURSOR_PLUGIN_ROOT:-\}" \]; then\n  printf .*?\nfi\n',
        lambda _: copilot_output,
        updated_text,
        count=1,
        flags=re.S,
    )
    if count != 1:
        raise SystemExit("Unable to transform session-start output block")

    return updated_text


def transform_skill(skill_text: str, article_template: str, schema_template: str) -> str:
    article_block = "3. Use this article template:\n   ```markdown\n" + indent_code_block(article_template, 3) + "\n   ```"
    schema_block = "1. Generate it from this schema template:\n   ```markdown\n" + indent_code_block(schema_template, 3) + "\n   ```"

    if '3. Use the article template from `${CLAUDE_PLUGIN_ROOT}/templates/article-template.md`' not in skill_text:
        raise SystemExit("Unable to find article template marker in SKILL.md")
    if '1. Generate it from `${CLAUDE_PLUGIN_ROOT}/templates/schema-template.md`' not in skill_text:
        raise SystemExit("Unable to find schema template marker in SKILL.md")

    skill_text = skill_text.replace(
        '3. Use the article template from `${CLAUDE_PLUGIN_ROOT}/templates/article-template.md`',
        article_block,
        1,
    )
    skill_text = skill_text.replace(
        '1. Generate it from `${CLAUDE_PLUGIN_ROOT}/templates/schema-template.md`',
        schema_block,
        1,
    )
    return skill_text


def transform_wiki_upgrade() -> str:
    return textwrap.dedent(
        """\
        # Upgrade Wiki Compiler Plugin

        Update the Copilot port of the plugin to the latest version.

        ## Instructions

        1. **Try a normal Copilot plugin update first** by running:
           ```bash
           copilot plugin update llm-wiki-compiler
           ```

        2. **If the update command succeeds**, tell the user to restart their Copilot session and reload Copilot Chat so the updated commands and hooks load.

        3. **If the update command fails or the plugin was installed from this local port**, tell the user to rerun the installer from the cloned repository:
           > Reinstall the staged Copilot port by rerunning `copilot-port/install.sh` from the cloned repository.
           > 
           > Re-run `copilot-port/install.sh` from the cloned `llm-wiki-compiler` repository, then restart the Copilot CLI session and reload the editor window for Copilot Chat.

        4. **If the user asks what changed**, summarize the latest commits from the repository checkout they are using.

        ## Notes

        - Prefer `copilot plugin update llm-wiki-compiler` for repository or marketplace installs.
        - Prefer rerunning `copilot-port/install.sh` for local staged installs of this port.
        - After either path, remind the user to restart the Copilot CLI session and reload Copilot Chat.
        """
    )


copy_tree(source_dir / "commands", staging_dir / "commands")
copy_tree(source_dir / "templates", staging_dir / "templates")
copy_tree(source_dir / "skills", staging_dir / "skills")
(staging_dir / "hooks").mkdir(parents=True, exist_ok=True)

source_manifest = json.loads(read_text(source_dir / ".claude-plugin" / "plugin.json"))
manifest = {}
metadata_fields = {
    "license": "MIT",
    "repository": "https://github.com/mlesk/llm-wiki-compiler",
    "homepage": "https://github.com/mlesk/llm-wiki-compiler",
}
metadata_inserted = False
for key, value in source_manifest.items():
    if key == "keywords" and not metadata_inserted:
        manifest.update(metadata_fields)
        metadata_inserted = True
    manifest[key] = value

if not metadata_inserted:
    manifest.update(metadata_fields)

manifest.update(
    {
        "commands": "commands/",
        "skills": "skills/",
        "hooks": "hooks.json",
    }
)
write_text(staging_dir / "plugin.json", json.dumps(manifest, indent=2) + "\n")

hook_template = json.loads(read_text(source_dir / "hooks" / "hooks.json"))
hook_template = replace_string_values(hook_template, "${CLAUDE_PLUGIN_ROOT}", "__PLUGIN_ROOT__")
write_text(staging_dir / "hooks.template.json", json.dumps(hook_template, indent=2) + "\n")

source_hook = source_dir / "hooks" / "session-start"
write_text(
    staging_dir / "hooks" / "session-start",
    transform_session_start(read_text(source_hook)),
    mode=source_hook.stat().st_mode,
)

source_skill = source_dir / "skills" / "wiki-compiler" / "SKILL.md"
write_text(
    staging_dir / "skills" / "wiki-compiler" / "SKILL.md",
    transform_skill(
        read_text(source_skill),
        read_text(source_dir / "templates" / "article-template.md"),
        read_text(source_dir / "templates" / "schema-template.md"),
    ),
    mode=source_skill.stat().st_mode,
)

write_text(staging_dir / "commands" / "wiki-upgrade.md", transform_wiki_upgrade())

if "__PLUGIN_ROOT__" not in read_text(staging_dir / "hooks.template.json"):
    raise SystemExit("Generated hooks.template.json is missing __PLUGIN_ROOT__ placeholder")

if dest_dir.exists():
    shutil.rmtree(dest_dir)
shutil.move(str(staging_dir), str(dest_dir))

print(f"Regenerated {dest_dir.relative_to(repo_root)} from {source_dir.relative_to(repo_root)}")
PY
