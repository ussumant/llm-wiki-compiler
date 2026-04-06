---
name: wiki-compiler
description: Core compilation algorithm for the LLM Wiki Compiler. Reads source files (.md and .py) from configured directories and compiles them into topic-based wiki articles. Supports code-aware compilation for trading systems.
---

# Wiki Compiler — Compilation Algorithm

This skill contains the 5-phase algorithm for compiling source files into a topic-based wiki.

**Safety rule:** NEVER modify any file outside the configured output directory. Source files are read-only.

## Prerequisites

Before running, read `.wiki-compiler.json` from the project root to get:
- `sources[]` — directories to scan (supports absolute paths for cross-directory sources)
- `output` — where to write wiki articles (supports absolute paths)
- `name` — project/domain name for the wiki
- `topic_hints[]` — optional seed topics from the user
- `link_style` — "obsidian" (default) or "markdown"
- `file_types` — list of extensions to scan, default `[".md"]`. Set `[".md", ".py"]` for code projects

## Phase 1: Scan Sources

1. For each entry in `sources[]`, list all files matching `file_types` using Glob
   - Source paths can be **absolute** (e.g., `"/Users/foo/memory/"`) or relative to project root
   - For `.py` files, use pattern `**/*.py`
   - For `.md` files, use pattern `**/*.md`
2. Exclude any paths matching `exclude` patterns (e.g., the `wiki/` output directory, `__pycache__/`, `.git/`, `tests/`)
3. Read `.compile-state.json` from the output directory
4. Compare file list against previous state to identify new or changed files
5. On first run (no prior state), treat ALL files as new

## Phase 2: Classify and Discover Topics

### For `.md` files:
1. Read file path, title (first `#` heading), and first 500 characters
2. Classify into topics based on content signals

### For `.py` files (code-aware classification):
1. Read file path and extract:
   - Module docstring (first triple-quoted string)
   - Class names and their docstrings
   - Top-level function names
   - Environment variable references (`os.environ.get(...)`, `os.getenv(...)`)
   - Key constants (ALL_CAPS variables at module level)
2. Classify based on:
   - File name and directory (strongest signal: `rl_live_xiaoming_v20.py` → rl-trading topic)
   - Imported modules (e.g., imports `tigeropen` → broker-integration topic)
   - Class/function names (e.g., `OrderExecutor` → order-execution topic)

### General classification rules:
3. **Use `topic_hints` from config** as seed topics when available
4. **Prefer existing topic slugs** from `.compile-state.json` — avoid creating near-duplicates
5. A single file CAN belong to multiple topics
6. Files that don't match any topic: group them — if 3+ unclassified files share a theme, create a new topic
7. Topic slugs should be lowercase-kebab-case (e.g., `rl-trading`, `order-execution`)

## Phase 3: Compile Topic Articles

For EACH topic that has new or changed source files:

1. Read ALL source files classified under that topic
2. Write the topic article to `{output}/topics/{topic-slug}.md`
3. Use the appropriate template from `${CLAUDE_PLUGIN_ROOT}/templates/`:
   - `article-template.md` for topics dominated by `.md` sources (knowledge/decisions/experiments)
   - `code-article-template.md` for topics dominated by `.py` sources (architecture/modules/params)
   - If mixed, use `article-template.md` but include the Code sections (Parameters, Architecture)
4. Fill every section with specific, factual content — no placeholders
5. **Summary** should be a standalone briefing
6. **Timeline** entries must have real dates
7. **Current State** should be immediately actionable
8. **Sources** must list every source file that contributed

### Coverage indicators:
Each section heading must include a coverage tag:
- `[coverage: high -- N sources]` — 5+ sources, detailed synthesis. Trust this section.
- `[coverage: medium -- N sources]` — 2-4 sources, decent but may miss detail.
- `[coverage: low -- N sources]` — 0-1 sources. Read raw sources directly.

Calculate coverage per section, not per article.

### For `.py` source files specifically:
- Extract and list **all environment variables** with their defaults and descriptions
- Extract **key class/function signatures** (not full implementations)
- Document **state machine transitions** if the module has state management
- Note **external dependencies** (APIs, databases, services)
- Cross-reference related modules (e.g., "uses `breakout_fut_module.py` when `BO_ENABLE=1`")

### Link style:
- `obsidian`: Use `[[relative/path/to/file]]` (without .md extension)
- `markdown`: Use `[filename](relative/path/to/file.md)`

For absolute source paths, use the full path as the link target.

**Parallel compilation:** When possible, compile multiple topic articles in parallel using subagents.

## Phase 3.5: Generate or Update Schema

If `{output}/schema.md` does not exist (first run):
1. Generate it from `${CLAUDE_PLUGIN_ROOT}/templates/schema-template.md`
2. Fill in the Topics section with all discovered topic slugs and descriptions
3. Add an Evolution Log entry: "{today's date}: Initial schema generated from {N} topics"

If `{output}/schema.md` already exists:
1. Read it BEFORE Phase 2 (classification) — use its topic list and naming conventions
2. After Phase 3 (compilation), check for new topics not in the schema
3. Add any new topics to the schema's Topics section
4. Add an Evolution Log entry if topics were added
5. Never remove topics from schema without human approval — flag them as candidates

## Phase 4: Update INDEX.md

Write to `{output}/INDEX.md`:

```markdown
# {name} Knowledge Base

Last compiled: {today's date}
Total topics: {count} | Total sources: {unique file count} ({md_count} .md + {py_count} .py)

## Topics

| Topic | Type | Sources | Last Updated | Status |
|-------|------|---------|-------------|--------|
| [[topics/{slug}]] | code/knowledge/mixed | {count} | {date} | active |

## Quick Reference
{For code-heavy wikis: list key env vars, service names, and entry points}

## Recent Changes
- {date}: {what changed in this compilation run}
```

Always regenerate INDEX.md, even if no topics changed.

## Phase 5: Update State and Log

1. **Log** — Append to `{output}/log.md`:
```markdown
## {today's date}

**Topics updated:** {list}
**New topics:** {list or "none"}
**Sources scanned:** {count} ({md_count} .md + {py_count} .py)
**Sources changed:** {count}
```

2. **Compile state** — Update `{output}/.compile-state.json`:
```json
{
  "last_compiled": "{today's date}",
  "topics": ["{slug1}", "{slug2}"],
  "source_locations": ["{path1}", "{path2}"],
  "source_hashes": {"{path}": "{md5_first_1000_chars}"},
  "total_sources_scanned": 0,
  "file_type_counts": {".md": 0, ".py": 0}
}
```

## Output

After compilation, show a summary:
- Topics created/updated (with article line counts)
- Total sources scanned (by file type)
- Any files that couldn't be classified
- Any suggested new topics for next run
- Stale topics that may need attention
- Time taken
