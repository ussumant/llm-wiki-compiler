# Wiki Schema

This file defines the structure and conventions for this knowledge base wiki. It is generated on first compile and co-evolved between human and LLM on subsequent runs.

**Human:** You can edit this file to rename topics, merge them, add conventions, or change the article structure. The compiler will respect your changes on the next run.

**Compiler:** Read this file before classifying sources. Follow its conventions. Add new topics here when discovered. Never remove topics without human approval.

## Topics

{For each topic, list slug and one-line description}
- {topic-slug}: {what this topic covers}

## Concepts

{Cross-cutting patterns that span 3+ topics. Interpretive, not just factual.}
- {concept-slug}: {what pattern this captures} — connects [{topic1}, {topic2}, {topic3}]

## Article Structure

Each topic article follows this format:
- **Summary** [coverage] -- standalone briefing, 2-3 paragraphs
- **Timeline** [coverage] -- chronological events with YYYY-MM-DD dates
- **Current State** [coverage] -- what's true right now, immediately actionable
- **Key Decisions** [coverage] -- with rationale and source links
- **Experiments & Results** [coverage] -- status table
- **Gotchas & Known Issues** [coverage] -- topic-specific traps and workarounds
- **Open Questions** [coverage] -- unresolved threads, gaps
- **Sources** -- backlinks to every contributing raw file

Coverage tags: `[coverage: high -- N sources]`, `[coverage: medium -- N sources]`, `[coverage: low -- N sources]`

## Naming Conventions

- Topic slugs: lowercase-kebab-case (e.g., `d1-retention`, `push-notifications`)
- Files: `{topic-slug}.md` in `topics/`
- Dates: YYYY-MM-DD format everywhere
- Links: Obsidian `[[wikilinks]]` with relative paths from `topics/`

## Cross-Reference Rules

- Topics that share 3+ sources should reference each other in their Summary or Key Decisions sections
- Decisions that affect multiple topics get noted in each relevant topic's Key Decisions section
- When a gotcha applies to multiple topics, include it in each with a note like "(also in [[other-topic]])"

## Evolution Log

{Chronological record of schema changes}
- {YYYY-MM-DD}: {what changed and why}
