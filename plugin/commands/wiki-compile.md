# Compile Knowledge Base Wiki

Compile all configured source files (.md and .py) into a topic-based wiki.

## Instructions

1. **Read configuration** from `.wiki-compiler.json` in the project root (or nearest parent directory). If not found, tell the user to run `/wiki-init` first.

2. **Validate configuration:**
   - `sources[]` must have at least one entry
   - `output` must be set
   - Source paths must exist (support both relative and absolute paths)
   - Expand `~` to home directory in paths

3. **Read schema** from `{output}/schema.md` if it exists. Use it to guide topic classification and naming. If it doesn't exist (first run), it will be generated in Phase 3.5.

4. **Invoke the `wiki-compiler` skill** to run the compilation:
   - Phase 1: Scan sources (both .md and .py files based on `file_types` config)
   - Phase 2: Classify and discover topics (code-aware for .py files)
   - Phase 3: Compile topic articles (use parallel agents when possible)
     - Use `article-template.md` for knowledge topics
     - Use `code-article-template.md` for code topics
   - Phase 3.5: Generate or update schema.md
   - Phase 4: Update INDEX.md (include file type counts)
   - Phase 5: Update state and log

5. **Show completion summary** with topics created/updated, source count by type, and any schema changes.

## Arguments

- No arguments: incremental compilation (recompile changed topics only)
- `--full`: force recompile all topics regardless of changes
- `--topic {slug}`: recompile only the specified topic
- `--dry-run`: show what would be compiled without writing files
- `--code-only`: only recompile code-type topics (skip knowledge topics)
- `--knowledge-only`: only recompile knowledge-type topics (skip code topics)
