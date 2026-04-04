# Compile Knowledge Base Wiki

Compile all configured markdown source files into a topic-based wiki.

## Instructions

1. **Read configuration** from `.wiki-compiler.json` in the project root (or nearest parent directory). If not found, tell the user to run `/wiki-init` first.

2. **Validate configuration:**
   - `sources[]` must have at least one entry
   - `output` must be set
   - Source paths must exist

3. **Invoke the `wiki-compiler` skill** to run the 5-phase compilation:
   - Phase 1: Scan sources
   - Phase 2: Classify and discover topics
   - Phase 3: Compile topic articles (use parallel agents when possible)
   - Phase 4: Update INDEX.md
   - Phase 5: Update state and log

4. **Show completion summary** with topics created/updated and source count.

## Arguments

- No arguments: full compilation (recompile changed topics)
- `--full`: force recompile all topics regardless of changes
- `--topic {slug}`: recompile only the specified topic
- `--dry-run`: show what would be compiled without writing files
