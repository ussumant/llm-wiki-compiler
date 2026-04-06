---
topic: {Topic Name}
type: knowledge
last_compiled: {YYYY-MM-DD}
source_count: {number}
status: active
---

# {Topic Name}

## Summary [coverage: {high|medium|low} -- {N} sources]
{2-3 paragraph synthesis of everything known about this topic.
Written as a briefing -- someone reading just this section should
understand the current state without reading any source file.
Be specific with numbers, dates, and decisions -- not vague summaries.}

## Timeline [coverage: {high|medium|low} -- {N} sources]
{Key events in chronological order}
- **YYYY-MM-DD:** {What happened}

## Current State [coverage: {high|medium|low} -- {N} sources]
{What's true RIGHT NOW: active metrics, live experiments, deployed versions.
This section should be immediately actionable.}

## Key Decisions [coverage: {high|medium|low} -- {N} sources]
{Decisions that shaped current approach, with rationale}
- **YYYY-MM-DD:** {Decision} -- {Why}

## Parameters [coverage: {high|medium|low} -- {N} sources]
{Key configuration parameters, environment variables, and their current values.
Include valid ranges and what happens when changed.}

| Parameter | Current Value | Default | Description |
|-----------|--------------|---------|-------------|

## Experiments & Results [coverage: {high|medium|low} -- {N} sources]
| Experiment | Date | Status | Finding | Source |
|------------|------|--------|---------|--------|

## Deployment [coverage: {high|medium|low} -- {N} sources]
{Service names, systemd units, deployment history, rollback procedures.
What's running where, how to restart, how to roll back.}

## Gotchas & Known Issues [coverage: {high|medium|low} -- {N} sources]
{Relevant known issues, traps, and workarounds.
Only include entries relevant to THIS topic.}

## Open Questions [coverage: {high|medium|low} -- {N} sources]
{Unresolved threads, gaps in knowledge, suggested next investigations.}

## Sources
{List ALL source files that contributed to this article}
- [[relative/path/to/source]]

---

## Coverage Guide

- **high** -- 5+ sources, detailed synthesis. Trust this section.
- **medium** -- 2-4 sources, decent coverage. Check raw sources for granular questions.
- **low** -- 1 source or sparse data. Read the raw sources directly.
