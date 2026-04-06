# Compile Knowledge Base Wiki

Compile all configured markdown source files into a topic-based wiki.

## Instructions

1. **Read configuration** from `.wiki-compiler.json` in the project root (or nearest parent directory). If not found, tell the user to run `/wiki-init` first.

2. **Validate configuration:**
   - `sources[]` must have at least one entry
   - `output` must be set
   - Source paths must exist

3. **Read schema** from `{output}/schema.md` if it exists. Use it to guide topic/concept classification and naming. If it doesn't exist (first run), it will be generated in Phase 3.7.

4. **Invoke the `wiki-compiler` skill** to run the compilation:
   - Phase 1: Scan sources
   - Phase 2: Classify and discover topics (respecting schema if present)
   - Phase 3: Compile topic articles (use parallel agents when possible)
   - Phase 3.5: Discover and compile concept articles (cross-cutting patterns)
   - Phase 3.7: Generate or update schema.md
   - Phase 4: Update INDEX.md (now includes concepts section)
   - Phase 5: Update state and log

5. **Show completion summary** with topics created/updated, concepts discovered, source count, and schema changes.

## Arguments

- No arguments: incremental compilation (recompile changed topics)
- `--full`: force recompile all topics regardless of changes
- `--topic {slug}`: recompile only the specified topic
- `--dry-run`: show what would be compiled without writing files
