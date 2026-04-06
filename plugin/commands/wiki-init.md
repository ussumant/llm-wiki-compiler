# Initialize Knowledge Base Wiki

Interactive setup for a new knowledge base wiki in this project.

## Instructions

### Step 1: Check for existing configuration

Look for `.wiki-compiler.json` in the current project root. If it exists, show the current config and ask: "Wiki already configured. Want to reconfigure, or abort?"

### Step 2: Auto-detect source directories

Scan the project for relevant files. Look for:
- Directories named `Knowledge/`, `docs/`, `notes/`, `content/`, `memory/`
- Any directory containing 10+ `.md` files
- Any directory containing 5+ `.py` files (for code projects)
- Exclude: `node_modules/`, `.git/`, `wiki/`, `build/`, `dist/`, `__pycache__/`, `tests/`, `venv/`, `.venv/`

Present findings: "I found X files across Y directories:"
- List each directory with file count by type (.md / .py)
- Suggest which ones to include as sources

### Step 3: Ask user to confirm

Ask the user:
1. "What's the name for this knowledge base?" (e.g., "Trading Bot", "My Research")
2. "Which directories should I compile from?" (show auto-detected with checkmarks, let them add/remove)
   - **Support absolute paths**: user can add paths outside the project (e.g., `~/.claude/memory/`)
3. "Where should the wiki output live?" (suggest `wiki/` in project root as default)
4. "Which file types to scan?" (default `.md`, suggest `.py` if Python files detected)
5. "Any seed topics to start with?" (optional, helps classification)

### Step 4: Create configuration

Write `.wiki-compiler.json` to the project root:

```json
{
  "version": 2,
  "name": "{user's name}",
  "sources": [
    { "path": "{path1}/", "exclude": ["wiki/", "__pycache__/", "tests/"] },
    { "path": "/absolute/path/to/other/", "exclude": [] }
  ],
  "output": "{output_path}/",
  "mode": "staging",
  "file_types": [".md", ".py"],
  "topic_hints": [],
  "link_style": "obsidian"
}
```

**Notes on sources:**
- Paths starting with `/` or `~` are treated as absolute
- Paths starting with `~` should be expanded to the full home directory
- Relative paths are relative to the project root (where `.wiki-compiler.json` lives)

### Step 5: Create output directory

Create the output directory structure:
- `{output}/` directory
- `{output}/topics/` directory
- `{output}/.compile-state.json` with initial empty state: `{"last_compiled":"","topics":[],"source_locations":[],"total_sources_scanned":0}`
- `{output}/log.md` with initial empty log

### Step 6: Summary

Print:
```
Wiki initialized for "{name}"
- Sources: {count} directories, ~{md_count} markdown + ~{py_count} Python files
- Output: {output_path}
- Mode: staging (wiki supplements existing context)

Next steps:
1. Run /wiki-compile to build your first compilation
2. Open {output_path}/INDEX.md in Obsidian to browse
3. Change mode in .wiki-compiler.json when ready:
   staging → recommended → primary
```
