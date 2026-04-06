# Wiki Schema

This file defines the structure and conventions for this knowledge base wiki. It is generated on first compile and co-evolved between human and LLM on subsequent runs.

**Human:** You can edit this file to rename topics, merge them, add conventions, or change the article structure. The compiler will respect your changes on the next run.

**Compiler:** Read this file before classifying sources. Follow its conventions. Add new topics here when discovered. Never remove topics without human approval.

## Topics

{For each topic, list slug and one-line description}
- {topic-slug}: {what this topic covers}

## Topic Types

Each topic is classified as one of:
- **knowledge** — decisions, experiments, operational records (uses article-template)
- **code** — source code modules, architecture, APIs (uses code-article-template)
- **mixed** — both code and knowledge content (uses article-template with code sections)

## Article Structure

### Knowledge articles:
- **Summary** [coverage] — standalone briefing, 2-3 paragraphs
- **Timeline** [coverage] — chronological events with YYYY-MM-DD dates
- **Current State** [coverage] — what's true right now
- **Key Decisions** [coverage] — with rationale and source links
- **Parameters** [coverage] — env vars, config values, valid ranges
- **Experiments & Results** [coverage] — status table
- **Deployment** [coverage] — services, how to start/stop/rollback
- **Gotchas & Known Issues** [coverage] — topic-specific traps
- **Open Questions** [coverage] — unresolved threads
- **Sources** — backlinks to every contributing raw file

### Code articles:
- **Summary** [coverage] — what the module does and why
- **Architecture** [coverage] — components, data flow, state machines
- **Key Files** [coverage] — file table with LOC and purpose
- **Environment Variables** [coverage] — all env vars with defaults
- **State Management** [coverage] — persistence, crash recovery
- **External Dependencies** [coverage] — APIs, databases, services
- **Key Functions** [coverage] — signatures and purpose (not implementations)
- **Current Deployment** [coverage] — service name, server, logs
- **Modification Guide** [coverage] — how to change common things
- **Gotchas & Known Issues** [coverage]
- **Sources**

Coverage tags: `[coverage: high -- N sources]`, `[coverage: medium -- N sources]`, `[coverage: low -- N sources]`

## Naming Conventions

- Topic slugs: lowercase-kebab-case (e.g., `rl-trading`, `order-execution`)
- Files: `{topic-slug}.md` in `topics/`
- Dates: YYYY-MM-DD format everywhere
- Links: Obsidian `[[wikilinks]]` with relative paths from `topics/`

## Cross-Reference Rules

- Topics that share 3+ sources should reference each other in their Summary or Key Decisions sections
- Decisions that affect multiple topics get noted in each relevant topic's Key Decisions section
- When a gotcha applies to multiple topics, include it in each with a note like "(also in [[other-topic]])"
- Code topics should link to the knowledge topics that explain WHY they work that way
- Knowledge topics should link to the code topics that IMPLEMENT the decisions

## Evolution Log

{Chronological record of schema changes}
- {YYYY-MM-DD}: {what changed and why}
