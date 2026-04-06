---
topic: {Topic Name}
type: code
last_compiled: {YYYY-MM-DD}
source_count: {number}
status: active
---

# {Topic Name}

## Summary [coverage: {high|medium|low} -- {N} sources]
{What this module/subsystem does, why it exists, and how it fits into the larger system.
Written as a briefing for someone who needs to modify or debug this code.}

## Architecture [coverage: {high|medium|low} -- {N} sources]
{Key classes, their relationships, data flow between components.
Include state machine diagrams if applicable (as text).}

```
{Component A} → {Component B} → {Component C}
     ↓                              ↑
{Component D} ──────────────────────┘
```

## Key Files [coverage: {high|medium|low} -- {N} sources]
| File | LOC | Purpose | Entry Point |
|------|-----|---------|-------------|

## Environment Variables [coverage: {high|medium|low} -- {N} sources]
{All env vars this module reads, with defaults and effects.}

| Variable | Default | Description | Impact |
|----------|---------|-------------|--------|

## State Management [coverage: {high|medium|low} -- {N} sources]
{State files, persistence format, recovery procedures.
What happens on crash? What state survives restart?}

## External Dependencies [coverage: {high|medium|low} -- {N} sources]
{APIs, databases, services this module connects to.
Include connection patterns, retry logic, fallbacks.}

| Dependency | Type | Purpose | Fallback |
|------------|------|---------|----------|

## Key Functions [coverage: {high|medium|low} -- {N} sources]
{Most important functions/methods with their signatures and purpose.
NOT full implementations — just what they do and when they're called.}

## Current Deployment [coverage: {high|medium|low} -- {N} sources]
{Service name, server, how to start/stop/restart, log location.}

## Modification Guide [coverage: {high|medium|low} -- {N} sources]
{Common modification scenarios and which files to touch.
"If you want to change X, modify Y and Z, then test with W."}

## Gotchas & Known Issues [coverage: {high|medium|low} -- {N} sources]
{Code-specific traps: race conditions, ordering dependencies,
things that look wrong but are intentional.}

## Sources
{List ALL source files that contributed to this article}
- [[relative/path/to/source.py]]

---

## Coverage Guide

- **high** -- 5+ sources, detailed synthesis. Trust this section.
- **medium** -- 2-4 sources, decent coverage. Check raw sources for granular questions.
- **low** -- 1 source or sparse data. Read the raw sources directly.
