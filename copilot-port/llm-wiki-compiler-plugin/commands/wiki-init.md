# Initialize Knowledge Base Wiki

Interactive setup for a new knowledge base wiki in this project.

## Instructions

### Step 1: Check for existing configuration

Look for `.wiki-compiler.json` in the current project root. If it exists, show the current config and ask: "Wiki already configured. Want to reconfigure, or abort?"

### Step 2: Auto-detect knowledge directories

Scan the project for markdown-heavy directories. Look for:
- Directories named `Knowledge/`, `docs/`, `notes/`, `content/`
- Any directory containing 10+ `.md` files
- Exclude: `node_modules/`, `.git/`, `wiki/`, `build/`, `dist/`

Present findings: "I found X markdown files across Y directories:"
- List each directory with file count
- Suggest which ones to include as sources

### Step 3: Ask user to confirm

Ask the user:
1. "What's the name for this knowledge base?" (e.g., "Lingotune", "My Research", "Project Alpha")
2. "Which directories should I compile from?" (show auto-detected with checkmarks, let them add/remove)
3. "Where should the wiki output live?" (suggest `{first_source}/wiki/` as default)

### Step 4: Create configuration

Write `.wiki-compiler.json` to the project root:

```json
{
  "version": 1,
  "name": "{user's name}",
  "sources": [
    { "path": "{path1}/", "exclude": ["wiki/"] },
    { "path": "{path2}/" }
  ],
  "output": "{output_path}/",
  "mode": "staging",
  "topic_hints": [],
  "link_style": "obsidian"
}
```

### Step 5: Create output directory

Create the output directory structure:
- `{output}/` directory
- `{output}/topics/` directory
- `{output}/.compile-state.json` with initial empty state
- `{output}/compile-log.md` with initial empty log

### Step 6: Summary

Print:
```
Wiki initialized for "{name}"
- Sources: {count} directories, ~{file_count} markdown files
- Output: {output_path}
- Mode: staging (wiki supplements existing context)

Next steps:
1. Run /wiki-compile to build your first compilation
2. Open {output_path}/INDEX.md in Obsidian to browse
3. Change mode in .wiki-compiler.json when ready:
   staging → recommended → primary
```
