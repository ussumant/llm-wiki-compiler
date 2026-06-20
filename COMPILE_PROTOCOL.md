# Wiki Compile Protocol — Portable & Agent-Agnostic

**Purpose:** A fully self-contained, **project-agnostic** protocol for compiling a knowledge wiki from a repo's source files. **Any** LLM agent (Claude, Codex/GPT, Cursor, Gemini, a fresh Claude without the wiki-compiler plugin, etc.) can execute it. It depends on **no** installed plugin, skill, or external template — everything is inlined.

> **Exportable by design.** This file is generic. All project-specific values live in `.wiki-compiler.json`, never here. To use it in another repo: **copy this file unchanged** and make sure that repo has a `.wiki-compiler.json` (see Appendix A). Nothing in this file needs editing per project.

> **How to run it:** Open an agent with filesystem access to the repo and say:
> *"Read `wiki/COMPILE_PROTOCOL.md` and execute it against this repository to (re)compile the wiki."*
> (`wiki/` is just the conventional location — the actual output dir is whatever `output` says in the config.)

---

## 0. Safety rules (read first)

1. **Source files are READ-ONLY.** Only ever write inside the `output` directory from the config. Never modify, delete, or move anything outside it.
2. **No deletions.** Stale content is flagged / re-ordered / annotated, never removed. The wiki is a time-series artifact.
3. **No placeholders.** Every section must contain specific, factual content from real sources. If unsupported, mark it `[coverage: low]` and say so.
4. **Determinism over flourish.** Prefer numbers, dates, file paths, and concrete decisions over vague prose.
5. If `.wiki-compiler.json` is missing or `output`/`sources` are empty/invalid, **stop and report** instead of guessing.

---

## 1. Load configuration

Read `.wiki-compiler.json` from the repo root (or nearest parent). **The config is the single source of project-specific truth.** Fields you must honor:

| Field | Meaning |
|-------|---------|
| `mode` | `"knowledge"` (markdown notes) or `"codebase"` (source repo). Drives Phase 2 discovery. |
| `name` | Wiki/project display name (used in INDEX.md). |
| `output` | Directory to write articles into. **Everything you write goes here.** |
| `sources[]` | Each `{ path, exclude[] }` — dirs to scan and glob patterns to skip. |
| `knowledge_files[]` | Glob patterns for priority docs treated as **primary** sources (READMEs, ADRs, `docs/**`, API contracts, infra files…). |
| `topic_hints[]` | Optional seed topic slugs from the human. Use as starting topics. |
| `article_sections[]` | The article structure: ordered `{ name, description, required? }`. **Use these exact sections.** If absent, fall back to the default template in Appendix B. |
| `deep_scan` | Codebase mode only. `false` = rely on knowledge files + structure. `true` = also read ~20 key source files per topic. |
| `link_style` | `"markdown"` → `[label](relative/path.md)`. `"obsidian"` → `[[relative/path]]` (no `.md`). |
| `service_discovery` | Codebase mode: `"auto"` (detect monorepo vs single project) or `"manual"`. |

**Arguments the human may pass:**
- *(none)* → **incremental**: recompile only topics whose sources changed.
- `--full` → recompile every topic.
- `--topic {slug}` → recompile only that topic.
- `--dry-run` → report what *would* change; **write nothing**.

---

## 2. Phase 1 — Scan sources

1. Read `{output}/.compile-state.json` (if present): previous file list, topic slugs, `last_compiled`. **First run (no state) → treat all files as new.**
2. Read `{output}/schema.md` (if present) **before classifying** — it's the source of truth for topic/concept names and conventions. Respect human edits there.
3. Walk every `sources[].path`, applying its `exclude[]` globs. **Always exclude the `output` dir itself** so the wiki never ingests itself.
   - **Knowledge mode:** list all `.md` files.
   - **Codebase mode:** collect knowledge files matching `knowledge_files[]` (primary sources) + structure signals (manifest files, top-level dir layout). If `deep_scan: true`, also up to ~20 key source files per topic area (entry points, type/model defs, route/handler files).
4. Diff against `.compile-state.json` → mark each source **new / changed / unchanged**.
5. Record each source's **date** (frontmatter `date`/`last_updated`/`posted_at` > filename date pattern > file mtime), parsed to `YYYY-MM-DD`, else `undated`.

---

## 3. Phase 2 — Classify & discover topics

1. Seed from `schema.md` topics (if any) + `topic_hints[]`. **Prefer existing slugs; avoid near-duplicates.**
2. Discover topics:
   - **Knowledge mode:** directory names are strong signals; headings/key terms secondary. A file can belong to multiple topics. If 3+ unclassified files share a theme, create a topic.
   - **Codebase mode:** detect project type from manifest files; detect **monorepo** (each service dir = a topic) vs **single project** (top-level dirs = topics). Auto-create cross-cutting topics when the files exist: `infrastructure`/`deployment` (Docker/CI), `testing` (`tests/`), etc. Root docs (`README`, `CLAUDE.md`, `ARCHITECTURE.md`) inform **all** topics or a `project-overview` topic.
3. Slugs: `lowercase-kebab-case` (or match the existing convention already in `{output}/topics/`).
4. Classify each topic **time-sensitive** (default) vs **stable** — used for date annotations in Phase 3. Err toward time-sensitive.
5. Output: `topic-slug → [list of source files]`.

---

## 4. Phase 3 — Compile topic articles

For each topic with new/changed sources (or all, if `--full` / first run):

1. Read **all** sources for that topic (full context, not just changed ones).
2. Write `{output}/topics/{slug}.md` using the **`article_sections` from config, in order**, with frontmatter:

```markdown
---
topic: {Name}
last_compiled: {YYYY-MM-DD}
source_count: {N}
status: active
---

# {Name}

## {Section name from article_sections[0]} [coverage: {high|medium|low} -- {N} sources]
{Content matching that section's `description`. The first section should read as a
standalone briefing — someone reading only it understands the current state.}

## {Section name from article_sections[1]} [coverage: ...]
...

## Sources
- {link per link_style to every contributing file}
```

> If `article_sections` is absent in the config, use the default section set in **Appendix B**.

3. **Coverage tag on every section heading** (computed per section, not per article):
   - `high -- N` → 5+ sources, trust without raw files.
   - `medium -- N` → 2–4 sources, check raw for granular detail.
   - `low -- N` → 0–1 sources, read raw files.
4. **Time-decay annotations** (use the recorded source dates):
   - Time-sensitive: >6mo = aging, >18mo = stale. Stable: >24mo = aging, >48mo = stale.
   - Lead the briefing/summary section with the source date range when time-sensitive.
   - Order any Timeline / Key Decisions newest-first, date-prefixed; prefix stale bullets with `⚠️ [YYYY-MM, may be stale]`.
   - A section resting mostly on aging sources gets `[as of YYYY-MM]` (median date) beside its coverage tag.
   - On conflict, prefer the materially newer source and note the shift: `"YYYY-MM: {old} → {new}"`.
5. **Sources** must list **every** contributing file, using `link_style`. Relative paths are **from `{output}/topics/`** to the source (e.g. `../../app/core/factor_models.py`).
6. **Parallelism (optional):** topic articles are independent — fan out subagents if your runtime supports it. **But Phases 3.5 → 5 run sequentially in the parent after ALL topic articles are written. Do not stop after Phase 3.**

---

## 5. Phase 3.5 — Discover & compile concept articles

After **all** topic articles are written, read them back and find cross-cutting patterns appearing in **3+ topics**. Write each to `{output}/concepts/{slug}.md`. Check `schema.md` first and **prefer updating** an existing concept over creating a near-duplicate. Only create one if it connects 3+ topics with a **non-obvious** insight — don't force them.

```markdown
---
concept: {Concept Name}
last_compiled: {YYYY-MM-DD}
topics_connected: [{topic1}, {topic2}, {topic3}]
status: active
---

# {Concept Name}

## Pattern
{What recurs across topics, and why.}

## Instances
- **{date}** in {link to topic}: {what happened}

## What This Means
{The "so what" — what the pattern reveals about the work, decisions, or blind spots.}

## Sources
- {links to the connected topics}
```

Concept articles are **interpretive**, not just factual.

---

## 6. Phase 3.7 — Generate or update schema

`{output}/schema.md` is the structural source of truth.

- **First run (absent):** create it — list every topic slug + one-line description, every concept + the topics it connects, the article-section structure (from `article_sections`), naming conventions, cross-reference rules, and an Evolution Log entry: `"{today}: Initial schema generated from {N} topics, {M} concepts"`.
- **Subsequent runs:** read it first (Phase 1), then after Phase 3.5 add any **new** topics/concepts and log them. **Never remove** a topic/concept without human approval — flag it as a candidate instead.

---

## 7. Phase 4 — Update INDEX.md

Always regenerate `{output}/INDEX.md` (cheap, even if nothing changed):

```markdown
# {name} Knowledge Base

Last compiled: {today}
Total topics: {count} | Total concepts: {count} | Total sources: {unique source count}

## Topics

| Topic | Also Known As | Sources | Last Updated | Status |
|-------|--------------|---------|-------------|--------|
| {link to topic} | {keyword aliases} | {count} | {date} | active |

## Concepts

| Concept | Connects | Last Updated |
|---------|----------|-------------|
| {link to concept} | {topic1}, {topic2}, {topic3} | {date} |

## Recent Changes
- {today}: {what changed this run}
```

**Aliases** = alternate names/abbreviations someone might search for. Use `link_style` for all links. Omit the Concepts section if there are no concepts yet.

---

## 8. Phase 5 — Update state & log

1. Append to `{output}/log.md`:

```markdown
## {today}

**Topics updated:** {list}
**New topics:** {list or "none"}
**Sources scanned:** {count}
**Sources changed:** {count}
```

2. Overwrite `{output}/.compile-state.json`:

```json
{
  "last_compiled": "{today}",
  "topics": ["{slug1}", "{slug2}"],
  "source_locations": ["{path1}", "{path2}"],
  "total_sources_scanned": 123
}
```

---

## 9. Final report (to the human)

- Topics created/updated (with article line counts).
- Concepts discovered/updated.
- Total sources scanned / changed.
- Files that couldn't be classified + suggested new topics for next run.
- Schema changes made.
- If `--dry-run`: state clearly that **no files were written**.

---

## 10. Quick checklist

- [ ] Read `.wiki-compiler.json`; aborted if missing/invalid.
- [ ] Read `{output}/schema.md` + `{output}/.compile-state.json` before classifying.
- [ ] Scanned sources, applied excludes (incl. `output` itself), dated every source, diffed vs. last state.
- [ ] Classified into topics, preferring existing slugs.
- [ ] Wrote topic articles with **all** `article_sections`, per-section coverage tags, time-decay annotations, full Sources lists.
- [ ] Ran concept discovery (3.5) **after** all topic articles.
- [ ] Updated schema (3.7), INDEX.md (4), log.md + .compile-state.json (5).
- [ ] Never wrote outside `output`. Never deleted content.
- [ ] Printed the final report.

---

## Appendix A — Minimal `.wiki-compiler.json` (for a new project)

If the target repo has no config, create one (or have the human run `/wiki-init`). Minimal codebase example:

```json
{
  "version": 2,
  "mode": "codebase",
  "name": "My Project",
  "sources": [{ "path": "./", "exclude": ["node_modules/", "dist/", ".git/", "wiki/", "vendor/", "__pycache__/"] }],
  "output": "wiki/",
  "knowledge_files": ["README.md", "CLAUDE.md", "AGENTS.md", "ARCHITECTURE.md", "docs/**/*.md", "Dockerfile", "*.proto"],
  "deep_scan": false,
  "topic_hints": [],
  "link_style": "markdown",
  "article_sections": [
    { "name": "Purpose", "description": "What this module does and who depends on it", "required": true },
    { "name": "Architecture", "description": "Key files, structure, entry points" },
    { "name": "Talks To", "description": "Dependencies and communication patterns" },
    { "name": "API Surface", "description": "Endpoints, exported functions, interfaces" },
    { "name": "Data", "description": "Tables, queues, caches, state owned" },
    { "name": "Key Decisions", "description": "Why it was built this way" },
    { "name": "Gotchas", "description": "Known issues, edge cases, failure modes" },
    { "name": "Sources", "description": "Backlinks to contributing files", "required": true }
  ]
}
```

For a **knowledge** (notes) project: set `"mode": "knowledge"`, drop `deep_scan`/`knowledge_files`, and either omit `article_sections` (uses Appendix B default) or define your own.

## Appendix B — Default article sections (used only when `article_sections` is absent)

`Summary` · `Timeline` · `Current State` · `Key Decisions` · `Experiments & Results` · `Gotchas & Known Issues` · `Open Questions` · `Sources` — each with a `[coverage: …]` tag, same rules as Phase 3.
