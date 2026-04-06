#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="${SCRIPT_DIR}/llm-wiki-complior-plugin"
PLUGIN_NAME="llm-wiki-compiler"

if ! command -v copilot >/dev/null 2>&1; then
  echo "Error: GitHub Copilot CLI ('copilot') is not installed or not on PATH." >&2
  exit 1
fi

if [ ! -f "${PLUGIN_DIR}/plugin.json" ]; then
  echo "Error: staged plugin manifest not found at ${PLUGIN_DIR}/plugin.json" >&2
  exit 1
fi

if [ ! -f "${PLUGIN_DIR}/hooks.template.json" ]; then
  echo "Error: staged Copilot hook template not found at ${PLUGIN_DIR}/hooks.template.json" >&2
  exit 1
fi

generate_hooks_config() {
  PLUGIN_DIR="${PLUGIN_DIR}" python - <<'PY'
import json
import os
from pathlib import Path

plugin_dir = Path(os.environ["PLUGIN_DIR"])
template_path = plugin_dir / "hooks.template.json"
output_path = plugin_dir / "hooks.json"

data = json.loads(template_path.read_text())
command = data["hooks"]["SessionStart"][0]["hooks"][0]["command"]
data["hooks"]["SessionStart"][0]["hooks"][0]["command"] = command.replace("__PLUGIN_ROOT__", str(plugin_dir))
output_path.write_text(json.dumps(data, indent=2) + "\n")
PY
}

resolve_settings_path() {
  if [ -n "${COPILOT_CHAT_SETTINGS_FILE:-}" ]; then
    printf '%s\n' "${COPILOT_CHAT_SETTINGS_FILE}"
    return 0
  fi

  case "$(uname -s)" in
    Darwin)
      if [ -f "${HOME}/Library/Application Support/Code/User/settings.json" ]; then
        printf '%s\n' "${HOME}/Library/Application Support/Code/User/settings.json"
      elif [ -f "${HOME}/Library/Application Support/Code - Insiders/User/settings.json" ]; then
        printf '%s\n' "${HOME}/Library/Application Support/Code - Insiders/User/settings.json"
      else
        printf '%s\n' "${HOME}/Library/Application Support/Code/User/settings.json"
      fi
      ;;
    Linux)
      if [ -f "${HOME}/.config/Code/User/settings.json" ]; then
        printf '%s\n' "${HOME}/.config/Code/User/settings.json"
      elif [ -f "${HOME}/.config/Code - Insiders/User/settings.json" ]; then
        printf '%s\n' "${HOME}/.config/Code - Insiders/User/settings.json"
      else
        printf '%s\n' "${HOME}/.config/Code/User/settings.json"
      fi
      ;;
    *)
      if [ -n "${APPDATA:-}" ]; then
        if [ -f "${APPDATA}/Code/User/settings.json" ]; then
          printf '%s\n' "${APPDATA}/Code/User/settings.json"
        elif [ -f "${APPDATA}/Code - Insiders/User/settings.json" ]; then
          printf '%s\n' "${APPDATA}/Code - Insiders/User/settings.json"
        else
          printf '%s\n' "${APPDATA}/Code/User/settings.json"
        fi
      else
        printf '%s\n' "${HOME}/.config/Code/User/settings.json"
      fi
      ;;
  esac
}

configure_chat_plugin() {
  local settings_file
  settings_file="$(resolve_settings_path)"

  mkdir -p "$(dirname "${settings_file}")"

  SETTINGS_FILE="${settings_file}" PLUGIN_DIR="${PLUGIN_DIR}" python - <<'PY'
import json
import os
from pathlib import Path

settings_path = Path(os.environ["SETTINGS_FILE"])
plugin_dir = os.environ["PLUGIN_DIR"]

def strip_jsonc(text: str) -> str:
    result = []
    in_string = False
    string_char = ""
    escape = False
    i = 0

    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ""

        if in_string:
            result.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == string_char:
                in_string = False
            i += 1
            continue

        if ch in ('"', "'"):
            in_string = True
            string_char = ch
            result.append(ch)
            i += 1
            continue

        if ch == "/" and nxt == "/":
            i += 2
            while i < len(text) and text[i] not in "\r\n":
                i += 1
            continue

        if ch == "/" and nxt == "*":
            i += 2
            while i + 1 < len(text) and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
            continue

        result.append(ch)
        i += 1

    stripped = "".join(result)
    cleaned = []
    in_string = False
    string_char = ""
    escape = False
    i = 0

    while i < len(stripped):
        ch = stripped[i]

        if in_string:
            cleaned.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == string_char:
                in_string = False
            i += 1
            continue

        if ch in ('"', "'"):
            in_string = True
            string_char = ch
            cleaned.append(ch)
            i += 1
            continue

        if ch == ",":
            j = i + 1
            while j < len(stripped) and stripped[j] in " \t\r\n":
                j += 1
            if j < len(stripped) and stripped[j] in "}]":
                i += 1
                continue

        cleaned.append(ch)
        i += 1

    return "".join(cleaned)

if settings_path.exists() and settings_path.stat().st_size > 0:
    data = json.loads(strip_jsonc(settings_path.read_text()))
    if not isinstance(data, dict):
        raise SystemExit(f"Expected JSON object in {settings_path}")
else:
    data = {}

data["chat.plugins.enabled"] = True

plugin_locations = data.get("chat.pluginLocations")
if plugin_locations is None:
    plugin_locations = {}
elif not isinstance(plugin_locations, dict):
    raise SystemExit(f"Expected 'chat.pluginLocations' to be an object in {settings_path}")

plugin_locations[plugin_dir] = True
data["chat.pluginLocations"] = plugin_locations

settings_path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
PY

  printf 'Updated Copilot Chat settings: %s\n' "${settings_file}"
}

echo "Installing ${PLUGIN_NAME} from ${PLUGIN_DIR}"
generate_hooks_config
copilot plugin install "${PLUGIN_DIR}"

configure_chat_plugin

cat <<EOF
Installed ${PLUGIN_NAME}.

Next steps:
1. Start a new Copilot CLI session to load the plugin.
2. Reload your editor window so Copilot Chat picks up the plugin location.

If you use a non-default VS Code settings file, rerun with:
  COPILOT_CHAT_SETTINGS_FILE=/absolute/path/to/settings.json ${SCRIPT_DIR}/install.sh
EOF
