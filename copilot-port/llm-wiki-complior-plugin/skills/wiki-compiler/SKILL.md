---
name: wiki-compiler
description: Core compilation algorithm for the LLM Wiki Compiler. Reads markdown source files from configured directories and compiles them into topic-based wiki articles. Called by /wiki-compile command.
---

# Wiki Compiler — Compilation Algorithm

This skill contains the 5-phase algorithm for compiling markdown source files into a topic-based wiki.

**Safety rule:** NEVER modify any file outside the configured output directory. Source files are read-only.

## Prerequisites

Before running, read `.wiki-compiler.json` from the project root to get:
- `sources[]` — directories to scan (with optional `exclude` patterns)
- `output` — where to write wiki articles
- `name` — project/domain name for the wiki
- `topic_hints[]` — optional seed topics from the user
- `link_style` — "obsidian" (default) or "markdown"

## Phase 1: Scan Sources

1. For each entry in `sources[]`, list all `.md` files using Glob
2. Exclude any paths matching `exclude` patterns (e.g., the `wiki/` output directory itself)
3. Read `.compile-state.json` from the output directory
4. Compare file list against previous state to identify new or changed files
5. On first run (no prior state), treat ALL files as new

## Phase 2: Classify and Discover Topics

1. For each source file, read its:
   - File path (directory structure is a strong signal)
   - Title (first `#` heading)
   - First 500 characters of content
2. Classify each file into one or more topics based on content signals
3. **Use `topic_hints` from config** as seed topics when available
4. **Prefer existing topic slugs** from `.compile-state.json` — avoid creating near-duplicates
5. A single file CAN belong to multiple topics
6. Files that don't match any topic: group them — if 3+ unclassified files share a theme, create a new topic
7. Topic slugs should be lowercase-kebab-case (e.g., `d1-retention`, `push-notifications`)

**Topic detection guidance:**
- Use directory names as strong signals (files in `retention/` likely belong to a retention topic)
- Use headings and key terms in content as secondary signals
- Meeting notes and session histories often belong to multiple topics
- Team memory files (gotchas, decisions, dead-ends) contain entries for many topics — classify by scanning content

## Phase 3: Compile Topic Articles

For EACH topic that has new or changed source files:

1. Read ALL source files classified under that topic (need full context, not just changed files)
2. Write the topic article to `{output}/topics/{topic-slug}.md`
3. Use the article template from `${CLAUDE_PLUGIN_ROOT}/templates/article-template.md`
4. Fill every section with specific, factual content -- no placeholders
5. **Summary** should be a standalone briefing: someone reading just this section should understand the current state
6. **Timeline** entries must have real dates
7. **Current State** should be immediately actionable -- what's true right now
8. **Sources** must list every source file that contributed, using the configured link style
9. **Coverage indicators** -- each section heading must include a coverage tag:
   - `[coverage: high -- N sources]` -- 5+ sources contributed to this section, detailed synthesis. Reader can trust this section without checking raw files.
   - `[coverage: medium -- N sources]` -- 2-4 sources, decent but may miss detail. Reader should check raw sources for granular or recent questions.
   - `[coverage: low -- N sources]` -- 0-1 sources or sparse data. Reader should read the raw sources directly.
   
   Calculate coverage per section, not per article. An article might have high coverage on Summary but low coverage on Experiments. This tells the reader (human or AI agent) exactly when to trust the wiki vs when to fall back to raw files.

**Link style:**
- `obsidian`: Use `[[relative/path/to/file]]` (without .md extension)
- `markdown`: Use `[filename](relative/path/to/file.md)`

Relative paths should be from the `topics/` directory to the source file.

**Parallel compilation:** When possible, compile multiple topic articles in parallel using subagents. Each subagent gets one topic + its source files. This significantly speeds up first-run compilation.

## Phase 3.5: Discover and Compile Concept Articles

After topic articles are written, look for cross-cutting patterns that span multiple topics. These become **concept articles** -- stored in `{output}/concepts/`.

**How to discover concepts:**

1. Read all topic articles that were just compiled (or all if first run)
2. Look for patterns that appear in 3+ topic articles:
   - **Recurring decisions** -- the same tradeoff appearing in different contexts (e.g., "speed vs quality" showing up in retention decisions, push notification strategy, and experiment design)
   - **Relationship patterns** -- a person, team, or stakeholder who appears across multiple topics with consistent dynamics
   - **Methodology evolution** -- how an approach changed over time across topics (e.g., "how we measure retention" evolving from n-day to bracket)
   - **Recurring failures** -- the same type of mistake across different domains (e.g., "trusting aggregated data without checking raw events")
3. Check `schema.md` for existing concepts -- prefer updating existing concept articles over creating new ones
4. Only create a concept if it genuinely connects 3+ topics with a non-obvious insight. Don't force concepts.

**Concept article format:**

Write to `{output}/concepts/{concept-slug}.md`:

```markdown
---
concept: {Concept Name}
last_compiled: {YYYY-MM-DD}
topics_connected: [{topic1}, {topic2}, {topic3}]
status: active
---

# {Concept Name}

## Pattern
{1-2 paragraphs describing the cross-cutting pattern. What keeps recurring and why.}

## Instances
{Each time this pattern appeared, with dates and context}
- **{date}** in [[../topics/{topic}]]: {what happened}
- **{date}** in [[../topics/{topic}]]: {what happened}

## What This Means
{Synthesis -- what the pattern tells you about your work, decisions, or blind spots.
This is the "so what" that Farzapedia calls the writer's job.}

## Sources
- [[../topics/{topic1}]]
- [[../topics/{topic2}]]
```

**Important:** Concept articles are interpretive, not just factual. They answer "what does this pattern mean?" not just "what happened?" This is what makes them useful for strategic and creative thinking.

**Create the concepts/ directory** if it doesn't exist.

## Phase 3.7: Generate or Update Schema

If `{output}/schema.md` does not exist (first run):
1. Generate it from `${CLAUDE_PLUGIN_ROOT}/templates/schema-template.md`
2. Fill in the Topics section AND Concepts section with all discovered slugs and descriptions
3. Add an Evolution Log entry: "{today's date}: Initial schema generated from {N} topics, {N} concepts"

If `{output}/schema.md` already exists:
1. Read it BEFORE Phase 2 (classification) -- use its topic list, concept list, and naming conventions
2. After Phase 3.5 (concepts), check for new topics and concepts not in the schema
3. Add any new topics/concepts to the schema
4. Add an Evolution Log entry if anything was added: "{today's date}: Added {slug} -- {reason}"
5. Never remove topics or concepts from schema without human approval -- flag them as candidates instead

The schema is the source of truth for wiki structure. The human can edit it between compiles to rename topics, merge them, or change conventions. The compiler respects those changes.

## Phase 4: Update INDEX.md

Write to `{output}/INDEX.md`:

```markdown
# {name} Knowledge Base

Last compiled: {today's date}
Total topics: {count} | Total sources: {unique file count}

## Topics

| Topic | Sources | Last Updated | Status |
|-------|---------|-------------|--------|
| [[topics/{slug}]] | {count} | {date} | active |

## Recent Changes
- {date}: {what changed in this compilation run}
```

Always regenerate INDEX.md, even if no topics changed (it's cheap).

## Phase 5: Update State and Log

1. **Log** — Append to `{output}/log.md`:
```markdown
## {today's date}

**Topics updated:** {list}
**New topics:** {list or "none"}
**Sources scanned:** {count}
**Sources changed:** {count}
```

2. **Compile state** — Update `{output}/.compile-state.json`:
```json
{
  "last_compiled": "{today's date}",
  "topics": ["{slug1}", "{slug2}", ...],
  "source_locations": ["{path1}", "{path2}", ...],
  "total_sources_scanned": {count}
}
```

## Output

After compilation, show a summary to the user:
- Topics created/updated (with article line counts)
- Total sources scanned
- Any files that couldn't be classified
- Any suggested new topics for next run
- Time taken
