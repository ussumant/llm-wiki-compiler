---
name: wiki-compiler
description: Core compilation algorithm for the LLM Wiki Compiler. Reads source files from configured directories and compiles them into topic-based wiki articles. Supports both knowledge mode (markdown files) and codebase mode (code repositories). Called by /wiki-compile command.
---

# Wiki Compiler — Compilation Algorithm

This skill contains the 5-phase algorithm for compiling source files into a topic-based wiki.

**Safety rule:** NEVER modify any file outside the configured output directory. Source files are read-only.

## Prerequisites

Before running, read `.wiki-compiler.json` from the project root to get:
- `mode` — "knowledge" (default, markdown files) or "codebase" (code repository)
- `sources[]` — directories to scan (with optional `exclude` patterns)
- `output` — where to write wiki articles
- `name` — project/domain name for the wiki
- `topic_hints[]` — optional seed topics from the user
- `link_style` — "obsidian" (default) or "markdown"

**Note:** Sources don't have to live alongside the project. `/fetch-bookmarks <source>` can pull content from external services (X bookmarks today; Readwise, Pocket, GitHub stars planned) into a local directory that appears in `sources[]` alongside everything else.

**Codebase mode additional config:**
- `service_discovery` — "auto" (detect monorepo vs single project) or "manual"
- `knowledge_files[]` — glob patterns for priority documentation files (README.md, CLAUDE.md, etc.)
- `deep_scan` — `false` (default) or `true` (also read key source files for richer articles)
- `code_extensions[]` — file extensions to consider as source code (e.g., `.ts`, `.py`, `.go`)

## Phase 1: Scan Sources

### Knowledge mode (default)

1. For each entry in `sources[]`, list all `.md` files using Glob
2. Exclude any paths matching `exclude` patterns (e.g., the `wiki/` output directory itself)
3. Read `.compile-state.json` from the output directory
4. Compare file list against previous state to identify new or changed files
5. On first run (no prior state), treat ALL files as new

### Codebase mode

1. For each entry in `sources[]`, scan for **knowledge files** matching `knowledge_files[]` patterns:
   - Documentation: `README.md`, `CLAUDE.md`, `AGENTS.md`, `ARCHITECTURE.md`, `CONTRIBUTING.md`
   - API contracts: `*.proto`, `*.graphql`, `openapi.yaml`, `openapi.json`
   - Decision records: `ADR-*.md`, `docs/adr/*.md`
   - Infrastructure: `docker-compose.yml`, `Dockerfile`, `k8s/*.yaml`
   - Operations: `docs/runbooks/*.md`, `CHANGELOG.md`, `.env.example`
2. If `deep_scan` is `true`, also scan for key source files per topic area:
   - Entry points: `index.ts`, `main.py`, `main.go`, `lib.rs`, `App.swift`, etc.
   - Type definitions: `types.ts`, `models.py`, `schema.prisma`, `*.proto`
   - Config files: `package.json`, `tsconfig.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`
   - Limit to ~20 source files per topic area to control token cost
3. Exclude: `node_modules/`, `dist/`, `.git/`, `vendor/`, `__pycache__/`, `.build/`, `target/`, and configured `exclude` patterns
4. Read `.compile-state.json` and compare to identify new or changed files
5. On first run, treat ALL discovered files as new

## Phase 2: Classify and Discover Topics

### Knowledge mode (default)

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

### Codebase mode

Topic discovery uses a 3-pass approach: structure → knowledge → optional deep scan.

**Pass 1 — Structure scan (automatic topic discovery):**

1. Detect project type by looking for manifest files in the root:
   - `package.json` → Node.js/JavaScript/TypeScript
   - `go.mod` → Go
   - `Cargo.toml` → Rust
   - `pyproject.toml` / `requirements.txt` / `setup.py` → Python
   - `Gemfile` → Ruby
   - `*.sln` / `*.csproj` → .NET
   - `Package.swift` → Swift
   - `pom.xml` / `build.gradle` → Java/Kotlin

2. Detect monorepo vs single project:
   - **Monorepo/microservices:** Multiple directories each containing their own manifest file (e.g., `services/auth/package.json`, `services/billing/package.json`). Each service directory = a topic.
   - **Single project:** One manifest at root. Use top-level directory structure as topic boundaries (e.g., `src/auth/`, `src/api/`, `src/models/` each become topics).

3. Auto-create cross-cutting topics when relevant files exist:
   - `infrastructure` — if `docker-compose.yml`, `Dockerfile`, `k8s/`, `.github/workflows/` exist
   - `testing` — if `tests/`, `__tests__/`, `spec/`, `test/` directories exist
   - `deployment` — if CI/CD configs, Dockerfile, deployment scripts exist

**Pass 2 — Knowledge file scan (primary sources):**

For each topic area discovered in Pass 1:
1. Find all knowledge files (from `knowledge_files[]` config) within that topic's directory
2. Read each knowledge file's content — these are the primary sources for compilation
3. A knowledge file CAN belong to multiple topics (e.g., root `README.md` touches all topics)
4. Root-level knowledge files (`./README.md`, `./CLAUDE.md`, `./ARCHITECTURE.md`) contribute to ALL topics or get their own `project-overview` topic

**Pass 3 — Deep scan (optional, when `deep_scan: true`):**

For each topic area, also read key source files to enrich understanding:
1. **Entry points:** `index.ts`, `main.py`, `main.go`, `lib.rs`, `App.swift`, `app.py`
2. **Type definitions:** `types.ts`, `models.py`, `schema.prisma`, `*.proto`, `types.go`
3. **Route/API definitions:** `routes.ts`, `api.py`, `handlers.go`, `controller.ts`
4. **Config:** `package.json` (dependencies), `tsconfig.json`, language-specific config
5. Limit to ~20 files per topic to control token cost
6. These supplement knowledge files — they add implementation detail to the article's Architecture, API Surface, and Data sections

**Classification output** is identical to knowledge mode: topic slug → list of source files. The rest of the pipeline (Phases 3-5) runs unchanged.

**Topic slug conventions for codebases:**
- Service names: `auth-service`, `billing-service`, `notification-service`
- Module names: `auth`, `api-routes`, `data-layer`, `ui-components`
- Cross-cutting: `infrastructure`, `testing`, `deployment`, `shared-utils`

**Article template:** When `mode` is `codebase`, use `${CLAUDE_PLUGIN_ROOT}/templates/codebase-article-template.md` as the fallback template (instead of the default knowledge template). If `article_sections` is set in config, use those sections (same as knowledge mode).

## Phase 3: Compile Topic Articles

For EACH topic that has new or changed source files:

1. Read ALL source files classified under that topic (need full context, not just changed files)
2. Write the topic article to `{output}/topics/{topic-slug}.md`
3. **Determine article structure:**
   - If `.wiki-compiler.json` has an `article_sections` array: use those sections in order. Each section's `description` field tells you what content belongs there.
   - If `article_sections` is absent (legacy configs without this field): fall back to the default template at `${CLAUDE_PLUGIN_ROOT}/templates/article-template.md`
4. Fill every section with specific, factual content -- no placeholders
5. **Summary** should be a standalone briefing: someone reading just this section should understand the current state
6. **Sources** must list every source file that contributed, using the configured link style
7. **Coverage indicators** -- each section heading must include a coverage tag:
   - `[coverage: high -- N sources]` -- 5+ sources contributed to this section, detailed synthesis. Reader can trust this section without checking raw files.
   - `[coverage: medium -- N sources]` -- 2-4 sources, decent but may miss detail. Reader should check raw sources for granular or recent questions.
   - `[coverage: low -- N sources]` -- 0-1 sources or sparse data. Reader should read the raw sources directly.
   
   Calculate coverage per section, not per article. An article might have high coverage on Summary but low coverage on Experiments. This tells the reader (human or AI agent) exactly when to trust the wiki vs when to fall back to raw files.

**Link style:**
- `obsidian`: Use `[[relative/path/to/file]]` (without .md extension)
- `markdown`: Use `[filename](relative/path/to/file.md)`

Relative paths should be from the `topics/` directory to the source file.

**Parallel compilation:** When possible, compile multiple topic articles in parallel using subagents. Each subagent gets one topic + its source files. This significantly speeds up first-run compilation.

**IMPORTANT — Sequencing:** Parallel dispatch is ONLY for Phase 3 (topic article compilation). After ALL parallel agents have returned and all topic articles are written, the PARENT process MUST continue to Phase 3.5 (concept discovery). Do NOT end the compilation after Phase 3. The remaining phases (3.5, 3.7, 4, 5) run sequentially in the parent process after parallel compilation completes.

## Phase 3.5: Discover and Compile Concept Articles

**This phase MUST run after Phase 3 completes.** Read the topic articles that were just compiled and look for cross-cutting patterns. These become **concept articles** -- stored in `{output}/concepts/`.

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

| Topic | Also Known As | Sources | Last Updated | Status |
|-------|--------------|---------|-------------|--------|
| [[topics/{slug}]] | {keyword aliases} | {count} | {date} | active |

## Concepts

| Concept | Connects | Last Updated |
|---------|----------|-------------|
| [[concepts/{slug}]] | {topic1}, {topic2}, {topic3} | {date} |

## Recent Changes
- {date}: {what changed in this compilation run}
```

**Keyword aliases:** For each topic, include alternate names, abbreviations, and related terms that someone might search for. For example, a topic called `side-quest-ideas` might have aliases "FitOS, Growth OS, Paperclip, ClawShip". These help `/wiki-search` and Claude find the right topic even when the user uses different terminology.

**Concepts section:** List all concept articles with the topics they connect. If no concepts exist yet, omit this section.

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

## Phase 6: Generate CONTEXT.md (codebase mode only, first run)

On the **first compile** (no prior `.compile-state.json`), generate `{output}/CONTEXT.md`:

```markdown
# Codebase Wiki — Navigation Guide

This project has a compiled knowledge wiki. Use it instead of scanning raw files.

## How to use this wiki

1. Start at INDEX.md — scan the topic table to find relevant modules
2. Read 1-3 topic articles relevant to your current task
3. Check coverage tags:
   - [coverage: high] — trust this section, skip raw files
   - [coverage: medium] — good overview, check raw sources for implementation details
   - [coverage: low] — read the raw source files listed in Sources
4. Check concepts/ for cross-cutting patterns (auth strategy, error handling, etc.)
5. Only read raw source files when you need code-level detail

## When NOT to use the wiki
- Writing new code (read the actual source files for exact syntax/types)
- Debugging a specific function (go to the file directly)
- The wiki article says [coverage: low] for what you need

## Stats
Compiled: {date} | Topics: {N} | Sources: {M} | Auto-updates on session start
```

On subsequent compiles, update the Stats line in CONTEXT.md.

After generating CONTEXT.md, **ask the user** (don't auto-modify): "Want me to add a reference to `wiki/CONTEXT.md` in your CLAUDE.md? This helps the agent discover the wiki automatically."

## Output

After compilation, show a summary to the user:
- Topics created/updated (with article line counts)
- Total sources scanned
- Any files that couldn't be classified
- Any suggested new topics for next run
- Time taken
