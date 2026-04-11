# Ingest a Single Source

Interactive workflow for adding one source file to the wiki. The LLM reads the file, discusses key takeaways with the user, then updates relevant topic articles.

## Instructions

### Step 1: Validate

- Read `.wiki-compiler.json` from the project root (or nearest parent directory). If not found, tell the user to run `/wiki-init` first.
- Accept one argument: the file path to ingest (e.g., `/wiki-ingest Knowledge/meetings/2026-04-07-standup.md`)
3. Store converted to markdown files as original page name but with `.md` extension.
- Verify the file exists and is a `.md` file
- Check that the file is within one of the configured `sources[]` directories (warn if not, but allow it)

### Step 2: Read and discuss

- Read the full source file
- Present a brief summary of key takeaways (3-5 bullet points)
- Ask the user: **"Anything you want me to emphasize or de-emphasize when updating the wiki?"**
- Wait for the user's response before proceeding — this is the interactive part where the user guides what matters

### Step 3: Classify

- Read `{output}/schema.md` to understand existing topics and naming conventions
- Determine which existing topics this source belongs to (can be multiple)
- If the source introduces a genuinely new topic not in the schema, propose creating it
- Show the user: **"This file touches these topics: [list]. I'll update each one. Sound right?"**
- Wait for confirmation before proceeding

### Step 4: Update topic articles

For each affected topic:

1. Read the current topic article from `{output}/topics/{slug}.md`
2. Read `article_sections` from `.wiki-compiler.json` (or use default template from `${CLAUDE_PLUGIN_ROOT}/templates/article-template.md` if absent)
3. Integrate the new source's information into the relevant sections
4. Respect the user's emphasis guidance from Step 2
5. Update coverage indicators — the source count may change the coverage level for some sections
6. Add the new source to the Sources section (using configured `link_style`)
7. Update the `source_count` in the article frontmatter
8. Write the updated article

If a new topic was proposed and approved in Step 3:
- Create a new topic article using the configured `article_sections`
- Populate it with content from this source

### Step 5: Update schema, index, and state

1. **Schema** — If a new topic was created, add it to `{output}/schema.md` with an evolution log entry: "{date}: Added {slug} — discovered during ingest of {filename}"
2. **INDEX.md** — Regenerate with updated source counts and dates
3. **Log** — Append to `{output}/compile-log.md`:
   ```
   ## {date} — ingest
   **Source:** {filename}
   **Topics updated:** {list}
   **New topics:** {list or "none"}
   ```
4. **State** — Update `.compile-state.json` with new source in the file list

### Step 6: Summary

Show what changed:
```
Ingested: {filename}

Topics updated:
- {topic1}: {brief description of what was added/changed}
- {topic2}: {brief description of what was added/changed}

New topics created: {list or "none"}

Tip: Run /wiki-lint to check for new cross-references or contradictions.
```

## Arguments

- Single argument: file path to ingest
- No arguments: prompts user to specify a file
- `--quiet`: Skip the interactive discussion (Steps 2-3 user prompts) and auto-classify. Useful for batch scripting.
