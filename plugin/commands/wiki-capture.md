# Capture a Link Into the Wiki

Capture a URL plus user context, normalize it into a durable markdown source, then connect it to the global wiki, local project wiki, or both.

## Arguments

- `/wiki-capture <url>` — capture a link and ask for context
- `/wiki-capture <url> --context "why this matters"` — capture with explicit context
- `/wiki-capture <url> --no-update` — only write the source markdown; do not update wiki articles

Codex prompt equivalents:

```text
https://example.com/article

capture this in my wiki
```

or:

```text
Capture this in my wiki:
{url}

Context: {why it matters to the work I am doing}
```

## Instructions

### Step 1: Resolve target wiki

Default global wiki:

```text
~/Knowledge
```

Override:

```text
LLM_WIKI_GLOBAL_DIR=/path/to/wiki-root
```

Routing rules:

- If the user says "my wiki", "global wiki", "personal wiki", or just "capture this in my wiki", use the global wiki by default.
- If the user says "this repo", "this project", "local wiki", or "project wiki", use the nearest local `.wiki-compiler.json`.
- If the user says "both", capture into both global and local wiki targets.
- If no local `.wiki-compiler.json` exists and the user asks for local capture, offer to initialize one.
- If no global `.wiki-compiler.json` exists, initialize the global wiki automatically from `templates/global-wiki-config.json` before capture.
- If a local wiki exists and the capture defaults to global, mention that a local wiki is available and offer to also connect the source there when it clearly relates to the current project.

### Step 2: Validate wiki config

- For each target wiki, read `.wiki-compiler.json`.
- Confirm `output` is set.
- If the target wiki has not been compiled yet, still allow capture, but explain that connections will be stronger after the first compile.

### Step 3: Collect user context

- If `--context` is absent, ask:
  > "What should I pay attention to? For example: how this link relates to the product, codebase, strategy, customer, or workflow."
- Treat this context as part of the source, not as a transient instruction.
- Do not summarize the link generically. Read it through the user's context.

### Step 4: Route to a capture adapter

Choose exactly one adapter:

| URL pattern | Adapter |
| --- | --- |
| `youtube.com`, `youtu.be` | `skills/wiki-compiler/adapters/capture-youtube.md` |
| `x.com`, `twitter.com` | `skills/wiki-compiler/adapters/capture-x.md` |
| Any other `http` or `https` URL | `skills/wiki-compiler/adapters/capture-web.md` |

Read the adapter and follow it. The adapter must return a normalized markdown file path under the configured capture source directory.

### Step 5: Ensure capture source is configured

- Default capture source directory: `wiki-sources/captures/`
- If `.wiki-compiler.json` already includes that path in `sources[]`, leave it alone.
- Otherwise ask:
  ```
  Add wiki-sources/captures/ to this wiki's sources so future compiles include captured links? (y/n)
  ```
- On yes, append:
  ```json
  {
    "path": "wiki-sources/captures/",
    "description": "Captured links with user context"
  }
  ```
- Preserve every other config field. Do not reformat unrelated config.

### Step 6: Connect it to the wiki

If `--no-update` is set:
- Stop after writing the source file and wiring the source directory.
- Print the source path and suggest running `/wiki-ingest {source_path}` or `/wiki-compile`.

Otherwise:

1. Read `{output}/INDEX.md` and `{output}/schema.md` if they exist.
2. Read the normalized source file.
3. Identify 1-3 likely existing topics or concepts this source connects to.
4. Present a short connection plan:
   ```
   Captured: {title}

   Likely connections:
   - {topic}: {why it fits}
   - {concept}: {why it fits}

   Proposed update:
   - Update existing topic(s): {list}
   - Create new topic/concept only if needed: {slug or "none"}
   ```
5. Ask for confirmation before writing wiki article changes.
6. On confirmation, follow the `/wiki-ingest` flow using the captured markdown file as the source. Integrate the user's context and extracted insights into topic/concept articles, with provenance back to the captured source and original URL.

### Step 7: Output summary

Print:

```
Captured: {title}
Source: {path}
Original URL: {url}

Connected to:
- {topic/concept}: {what changed}

Target wiki:
- {global|local|both}: {wiki root}

Next:
- Run /wiki-lint to check cross-links and coverage
- Run /wiki-visualize to see the new graph connections
```

## Source format

Use `templates/captured-source-template.md` as the source shape. Every captured source must include:

- `source_type`
- `url`
- `captured_at`
- `title`
- `user_context`
- extracted content or transcript
- relevance notes
- candidate wiki connections

## Safety

- Never overwrite an existing captured source. If the slug exists, append `-2`, `-3`, etc.
- Never update raw source files outside `wiki-sources/captures/`.
- Never auto-install tools without explicit user consent.
- Do not auto-create a new topic when an existing topic is a reasonable fit.
