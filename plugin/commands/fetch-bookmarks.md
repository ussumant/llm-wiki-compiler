# Fetch Bookmarks from an External Source

Pull bookmarks from an external service (X/Twitter today; Readwise, Pocket, GitHub stars planned) into a local directory that `/wiki-compile` can consume. Optional — only needed when you want wiki topics synthesized from external sources, not just files already on disk.

The command itself is a thin dispatcher. Each source has its own adapter file that handles dependency checks, auth, sync, and wiring.

## Instructions

### Step 1: Parse the source argument

- Accept one argument: the source slug (e.g., `/fetch-bookmarks x`).
- If no argument is provided, list the available adapters by globbing `${CLAUDE_PLUGIN_ROOT}/skills/wiki-compiler/adapters/*.md` and show:
  ```
  Usage: /fetch-bookmarks <source>

  Available sources:
  - x — X/Twitter bookmarks (via Field Theory CLI)

  More adapters planned: readwise, pocket, github-stars.
  ```
  Then stop.

### Step 2: Locate the adapter

- Resolve the adapter file at `${CLAUDE_PLUGIN_ROOT}/skills/wiki-compiler/adapters/{source}.md`.
- If the file does not exist, print:
  ```
  No adapter for "{source}" yet. Available: {list}.
  Want to contribute one? See adapters/x.md for the contract.
  ```
  Then stop.

### Step 3: Follow the adapter

- Read the adapter file in full.
- Follow its steps in order. Each adapter is self-contained and handles its own preflight, consent prompts, sync, and config updates.
- Surface the adapter's step-by-step progress to the user as you go. Do not retry failing steps silently — if a step fails, stop and show the error.

### Step 4: Close the loop

After the adapter finishes successfully, print:

```
Bookmarks fetched. Run /wiki-compile to synthesize them into topic articles.
```

Do **not** auto-invoke `/wiki-compile`. The user may want to fetch from multiple sources or tweak `.wiki-compiler.json` before compiling.

## Arguments

- `<source>` — required. Slug matching an adapter file in `plugin/skills/wiki-compiler/adapters/`. Currently: `x`.
- No arguments: prints help listing available adapters.

## Adapter contract (for contributors)

Each adapter is a self-contained markdown file that the dispatcher follows. Adapters must:

1. Preflight runtime and CLI dependencies. Abort with a friendly install link if a prerequisite is missing — never auto-install a runtime.
2. Get explicit user consent before installing any tool (`npm install`, `pip install`, etc.). Show the project URL and license.
3. Run the third-party sync command and surface its output verbatim so the user can respond to any prompts it raises.
4. Ensure the source's output ends up as markdown at a stable path.
5. Read `.wiki-compiler.json` from the project root. If that path is not already present in `sources[]`, ask the user to confirm adding it, then write the update preserving all other fields.
6. Print a "run `/wiki-compile`" suggestion. Never auto-invoke compile.

See `plugin/skills/wiki-compiler/adapters/x.md` for the reference implementation.
