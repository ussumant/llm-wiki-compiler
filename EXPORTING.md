# Exporting the Wiki Compile Protocol to Any Project

The standard way to compile a wiki is the Claude Code plugin (`/wiki-compile`). But that requires the plugin installed and the local `plugin/skills` + `plugin/templates` files. This document covers the **portable** path: a single self-contained artifact that lets **any** LLM agent (Claude, Codex/GPT, Cursor, Gemini, a fresh Claude without the plugin) compile a wiki in any repo — with **no plugin dependency**.

## TL;DR

```powershell
# From the llm-wiki-compiler repo, deploy the protocol into a target project:
.\deploy-protocol.ps1 -TargetRepo C:\path\to\project

# Then tell any agent:
#   "Read wiki/COMPILE_PROTOCOL.md and execute it against this repository to compile the wiki."
```

That's it. The protocol reads everything project-specific from the target's `.wiki-compiler.json` at runtime, so the deployed file is **identical across all projects** — never edit it per project.

## The two artifacts

| File | Location | Role |
|------|----------|------|
| `COMPILE_PROTOCOL.md` | `llm-wiki-compiler/` (**master**) | Canonical, project-agnostic protocol. The source of truth. Edit here. |
| `deploy-protocol.ps1` | `llm-wiki-compiler/` | Copies the master into a target repo's wiki output dir. |
| `COMPILE_PROTOCOL.md` | `<project>/wiki/` (deployed copy) | What the agent actually reads inside each project. Byte-identical to the master. |

The protocol itself inlines the full 5-phase compile algorithm, the article/concept/schema/index templates, coverage tags, and time-decay rules. There are **no** external template references — that's what makes it portable.

## The export model

```
Project = COMPILE_PROTOCOL.md (identical, never edited)  +  .wiki-compiler.json (per-project)
```

All project-specific values — `mode`, `name`, `output`, `sources`/`exclude`, `topic_hints`, `article_sections`, `link_style` — live in `.wiki-compiler.json`. The protocol is a pure interpreter of that config. Drop the same protocol file into 20 repos; each behaves differently purely because its config differs.

## Step-by-step

### 1. Deploy the protocol

```powershell
.\deploy-protocol.ps1 -TargetRepo C:\Users\you\Documents\my_project
```

The script:
1. Takes the master `COMPILE_PROTOCOL.md` sitting next to it (`$PSScriptRoot`).
2. Resolves the destination directory in this order:
   - `-OutputDir` parameter, if given
   - the `output` field of the target's `.wiki-compiler.json`, if present
   - `wiki` (default)
3. Creates the directory if needed and copies the protocol in.
4. **Warns** if the target has no `.wiki-compiler.json` (the protocol can't run without one).

**Flags:**

| Flag | Effect |
|------|--------|
| `-OutputDir docs\wiki` | Force the destination dir, ignoring config. |
| `-InlineConfig` | Append a project-specific "Resolved configuration" appendix generated from the target's `.wiki-compiler.json` (see below). |
| `-Force` | Overwrite an existing `COMPILE_PROTOCOL.md`. **Required to redeploy** — without it the script skips an existing file rather than clobbering it. |
| `-WhatIf` | Dry run: show what would happen, write nothing. |
| `-Confirm` | Prompt before each action. |

### 2. Ensure the target has a config

If the deploy step warned about a missing `.wiki-compiler.json`, create one:
- Run `/wiki-init` in that repo (if the plugin is available), **or**
- Copy the minimal config from **Appendix A** of `COMPILE_PROTOCOL.md` and adjust `name`, `mode`, `sources`, and `topic_hints`.

### 3. Run the compile with any agent

Open any agent with filesystem access to the repo and say:

> *"Read `wiki/COMPILE_PROTOCOL.md` and execute it against this repository to compile the wiki."*

Supported arguments (the agent honors them per the protocol):

| Argument | Behavior |
|----------|----------|
| *(none)* | Incremental — recompile only topics whose sources changed. |
| `--full` | Recompile every topic. |
| `--topic {slug}` | Recompile a single topic. |
| `--dry-run` | Report what would change; write nothing. |

## Project-specialized copies (`-InlineConfig`)

By default the deployed copy is identical to the master — it reads everything from `.wiki-compiler.json` at runtime. That keeps it portable, but the agent has to parse the JSON.

With `-InlineConfig`, the script reads the target's `.wiki-compiler.json` at deploy time and appends an auto-generated **Appendix C — Resolved configuration** to the copy: the concrete `mode`, `name`, `output`, `link_style`, `deep_scan`, excludes, `knowledge_files`, `topic_hints`, and the ordered `article_sections`. The agent then has the exact values without re-parsing anything.

```powershell
.\deploy-protocol.ps1 -TargetRepo C:\path\to\project -InlineConfig -Force
```

Key properties:

- **The master stays generic.** Only the deployed copy gets the appendix.
- **No manual drift.** The appendix is *generated* from the config, not hand-written. Edit `.wiki-compiler.json`, redeploy with `-InlineConfig -Force`, and the appendix regenerates fresh (the copy is reset from the master first, then re-appended — no duplication).
- **The live config still wins.** The appendix is a deploy-time snapshot; the protocol notes that the current `.wiki-compiler.json` takes precedence if it has since changed.
- **No-op without config.** If the target has no `.wiki-compiler.json`, the flag is ignored (with a warning) and the generic protocol is deployed.

Use it for a project's "home" copy where convenience matters (e.g. the repo where you compile most often). Skip it when you want a strictly portable, config-driven copy.

## Keeping copies in sync

Deploying makes a **copy**, so the master and deployed protocols can drift. The discipline:

> **Always edit the master in `llm-wiki-compiler/`, then redeploy with `-Force`.**

Alternatives if you want to avoid copies entirely:
- **Reference the master by absolute path** — tell the agent to read `C:\Users\...\llm-wiki-compiler\COMPILE_PROTOCOL.md` directly. One source of truth, but the protocol no longer lives inside the project repo.
- **Symlink** the deployed copy to the master (Windows needs Developer Mode / admin).

For repos that other people or agents touch, the deployed copy is the most robust choice — the protocol travels with the repo.

## Redeploying after an update

When you change the master, push it to every project that already has it:

```powershell
.\deploy-protocol.ps1 -TargetRepo C:\path\to\project -Force
```

(The `-Force` is required because the file already exists.)

For copies you specialized with `-InlineConfig`, **include it on redeploy too** — otherwise the redeploy resets the copy to the generic master and the project appendix is lost:

```powershell
.\deploy-protocol.ps1 -TargetRepo C:\path\to\project -InlineConfig -Force
```

## Files reference

- `COMPILE_PROTOCOL.md` — the portable protocol (master). See its Appendix A for a minimal config and Appendix B for the default article sections.
- `deploy-protocol.ps1` — the deploy script (Windows/PowerShell). `Get-Help .\deploy-protocol.ps1 -Full` for full parameter docs.
- `deploy-protocol.sh` — POSIX/bash equivalent (macOS/Linux/Git Bash). Same behavior with long-form flags: `--output-dir`, `--inline-config`, `--force`, `--dry-run`. `--inline-config` requires [`jq`](https://jqlang.github.io/jq/) for parsing the config; without it the script still deploys the generic protocol (and resolves the output dir to `wiki`). Run `./deploy-protocol.sh --help`.
