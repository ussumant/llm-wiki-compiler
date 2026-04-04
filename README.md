# LLM Wiki Compiler

A Claude Code plugin that compiles scattered markdown knowledge files into a topic-based wiki. Reduce context costs by ~90% and get instant answers from synthesized knowledge.

## Inspiration

This plugin implements the **LLM Knowledge Base** pattern described by [Andrej Karpathy](https://x.com/karpathy/status/2039805659525644595):

> *"Raw data from a given number of sources is collected, then compiled by an LLM into a .md wiki, then operated on by various CLIs by the LLM to do Q&A and to incrementally enhance the wiki, and all of it viewable in Obsidian. You rarely ever write or edit the wiki manually, it's the domain of the LLM."*

The key insight: instead of re-reading hundreds of raw files every session, have the LLM compile them into topic-based articles once, then query the synthesized wiki. Knowledge compounds instead of fragmenting.

## What It Does

You have 100+ markdown files across meetings, strategy docs, session notes, and research. Every Claude session re-reads them. This plugin compiles them into topic-based articles that synthesize everything known about each subject — with backlinks to sources.

**Before:** Read 13+ raw files (~3,200 lines) per session
**After:** Read INDEX + 2 topic articles (~330 lines) per session

## Install

```bash
# From marketplace (when published)
claude plugin marketplace add llm-wiki-compiler

# Or from git
claude plugin add /path/to/llm-wiki-compiler
```

## Quick Start

```bash
# 1. Initialize in your project
/wiki-init

# 2. Compile your knowledge base
/wiki-compile

# 3. Query it
/wiki-query what do we know about retention?
```

## How It Works

### Three Commands

| Command | Purpose |
|---------|---------|
| `/wiki-init` | Interactive setup — auto-detects your markdown directories, creates config |
| `/wiki-compile` | Compiles source files into topic articles (incremental — only recompiles changes) |
| `/wiki-query` | Quick Q&A against the compiled wiki |

### Staged Adoption (The Key Feature)

The plugin never modifies your existing CLAUDE.md or AGENTS.md. Instead, it injects context via a SessionStart hook with three modes:

| Mode | What Happens | Your Existing Setup |
|------|-------------|-------------------|
| **staging** (default) | "Wiki available — check it when you need depth" | Completely unchanged |
| **recommended** | "Check wiki articles before raw files" | Unchanged, but Claude prioritizes wiki |
| **primary** | "Wiki is your primary knowledge source" | You can optionally simplify startup reads |

Change mode by editing `.wiki-compiler.json`:
```json
{ "mode": "staging" }  →  { "mode": "recommended" }  →  { "mode": "primary" }
```

### What Gets Compiled

Each topic article contains:
- **Summary** — 2-3 paragraph briefing (standalone understanding)
- **Timeline** — Key events with dates
- **Current State** — What's true right now
- **Key Decisions** — With rationale and source links
- **Experiments & Results** — Status table
- **Gotchas & Known Issues** — Topic-specific traps
- **Open Questions** — Unresolved threads
- **Sources** — Backlinks to every raw file (Obsidian wikilinks)

### Obsidian Compatible

The wiki output is plain markdown with Obsidian-style `[[wikilinks]]`. Open `wiki/INDEX.md` in Obsidian and you'll see the full knowledge base with bidirectional links to source files.

## Configuration

`.wiki-compiler.json` (created by `/wiki-init`):

```json
{
  "version": 1,
  "name": "My Project",
  "sources": [
    { "path": "Knowledge/", "exclude": ["wiki/"] },
    { "path": "docs/meetings/" }
  ],
  "output": "Knowledge/wiki/",
  "mode": "staging",
  "topic_hints": ["retention", "onboarding"],
  "link_style": "obsidian"
}
```

| Field | Description |
|-------|-------------|
| `name` | Display name for the knowledge base |
| `sources` | Directories to scan for .md files |
| `output` | Where compiled wiki lives |
| `mode` | `staging` / `recommended` / `primary` |
| `topic_hints` | Optional seed topics to guide classification |
| `link_style` | `obsidian` (wikilinks) or `markdown` (standard links) |

## Safety Guarantees

- Source files are **never modified** — the compiler only writes to the output directory
- The wiki can be **deleted and regenerated** at any time from source files
- Your **CLAUDE.md and AGENTS.md are never touched** — context injection happens via hooks
- **Rollback anytime** — change mode back to `staging` or delete `.wiki-compiler.json`

## Cost Comparison

| | Without Wiki | With Wiki |
|---|---|---|
| Context per session | ~36,800 tokens | ~3,120 tokens |
| Per-question research | ~8,000 tokens (10+ files) | ~600 tokens (1 article) |
| Monthly savings (5 sessions/day) | — | ~5-8M tokens |

First compilation costs ~880K tokens. Break-even: 1-2 days of normal usage.

## Advanced

### Incremental Compilation

After the first full compile, `/wiki-compile` only recompiles topics whose source files changed. INDEX.md is always regenerated.

### Force Full Recompile

```
/wiki-compile --full
```

### Compile Single Topic

```
/wiki-compile --topic retention
```

### Scheduled Compilation

Use Claude Code's `/schedule` to set up daily automatic compilation.

## License

MIT
