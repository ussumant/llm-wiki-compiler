# Initialize Knowledge Base Wiki

Interactive, conversational setup for a new knowledge base wiki. One question at a time, multiple choice when possible.

## Instructions

**Important:** Ask ONE question per message. Wait for the user's response before moving to the next question. Never batch multiple questions. Keep the tone conversational — like a knowledgeable colleague setting things up for you.

### Step 1: Check for existing config

Look for `.wiki-compiler.json` in the current project root. If it exists:

```
You already have a wiki configured for "{name}" ({topic_count} topics, last compiled {date}).

A) Reconfigure from scratch
B) Keep current setup (abort)
```

If B, exit. If A, continue.

### Step 2: Welcome + auto-detect

Scan the project for markdown-heavy directories. Look for:
- Directories named `Knowledge/`, `docs/`, `notes/`, `content/`, `meetings/`, `research/`
- Any directory containing 10+ `.md` files
- Exclude: `node_modules/`, `.git/`, `wiki/`, `build/`, `dist/`

Present findings conversationally:

```
Welcome to LLM Wiki Compiler. I'll get you set up in about 5 questions.

I found {count} markdown files across your project:

  {dir1}/  — {count} files
  {dir2}/  — {count} files
  {dir3}/  — {count} files

Which directories should I compile into your wiki?

A) All of the above (recommended)
B) Let me pick — show me the list
C) I'll type the paths myself
```

Wait for response. If B, show checkboxes. If C, ask for paths.

### Step 3: Name

```
Got it, {count} directories selected. What should I call this knowledge base?

A) "{auto_detected_name}" (based on your project name)
B) Let me type a name
```

Wait for response.

### Step 4: Output location

```
Where should the compiled wiki live?

A) {first_source}/wiki/ (recommended — keeps it near your sources)
B) docs/wiki/
C) Let me pick a different path
```

Wait for response.

### Step 5: Sample files and propose article structure

Now read 10-15 representative `.md` files from the confirmed source directories:
- Pick files from different subdirectories for breadth
- Read the first ~500 characters + the title (first `#` heading) of each
- Note what kinds of content you're seeing

Based on what you found, generate 5-8 article sections that fit the domain. Then present:

```
I sampled {N} of your files. Looks like you have {description of content types}.

Here's the article structure I'd suggest for your wiki:

  1. Summary — standalone briefing of the topic
  2. {section} — {description}
  3. {section} — {description}
  4. {section} — {description}
  5. {section} — {description}
  6. Sources — backlinks to all contributing files

A) Looks good, use this (recommended)
B) I want to add or remove sections
C) Regenerate — try a different structure
```

If B, ask which sections to add/remove/rename. If C, regenerate with different emphasis.

Rules for section generation:
- **Always include `Summary` first and `Sources` last** — these are universal
- Middle sections are domain-specific — match the actual content patterns observed
- Examples of what the LLM might propose by domain:
  - **Product/growth:** Timeline, Current State, Key Decisions, Experiments & Results, Gotchas, Open Questions
  - **Research:** Key Findings, Methodology, Evidence, Gaps & Contradictions, Open Questions
  - **Personal journal:** Themes & Patterns, Progress, Reflections, Action Items
  - **Book notes:** Characters, Themes, Plot Threads, Connections, Quotes
  - **Technical docs:** Architecture, API Surface, Dependencies, Known Issues, Migration Notes
  - **Business/team:** Stakeholders, Decisions, Action Items, Meeting History, Open Threads

### Step 6: Wiki mode

```
Almost done. How should the wiki integrate with your workflow?

A) Staging — wiki supplements your existing setup, no changes needed (recommended for first-time)
B) Recommended — Claude reads wiki before raw files
C) Primary — wiki is the main knowledge source, raw files only for detail

You can change this anytime in .wiki-compiler.json.
```

Wait for response.

### Step 7: Stale detection

```
Last question. Want me to warn you when your wiki is out of date?

If source files change after a compile, the plugin can flag it at session start:
"Wiki may be stale — 12 files changed. Run /wiki-compile to update."

A) Yes, warn me (recommended)
B) No thanks, I'll compile manually
```

If A, set `auto_update` to `"prompt"`. If B, set to `"off"`.

### Step 8: Create configuration

Write `.wiki-compiler.json` to the project root:

```json
{
  "version": 1,
  "name": "{name}",
  "sources": [
    { "path": "{path1}/", "exclude": ["wiki/"] },
    { "path": "{path2}/" }
  ],
  "output": "{output_path}/",
  "mode": "{selected_mode}",
  "auto_update": "{selected_auto_update}",
  "article_sections": [
    { "name": "Summary", "description": "{description}", "required": true },
    { "name": "{section2}", "description": "{description}" },
    { "name": "{section3}", "description": "{description}" },
    { "name": "{section4}", "description": "{description}" },
    { "name": "{section5}", "description": "{description}" },
    { "name": "Sources", "description": "backlinks to all contributing source files", "required": true }
  ],
  "topic_hints": [],
  "link_style": "obsidian"
}
```

### Step 9: Create output directory

Create:
- `{output}/` directory
- `{output}/topics/` directory
- `{output}/.compile-state.json` with initial empty state
- `{output}/compile-log.md` with initial empty log

### Step 10: Done

```
Wiki initialized for "{name}"

  Sources:    {count} directories, ~{file_count} markdown files
  Output:     {output_path}
  Structure:  {section_count} sections ({section names})
  Mode:       {mode}
  Stale warnings: {on/off}

Next steps:
  1. Run /wiki-compile to build your first compilation (5-10 min)
  2. Open {output_path}/INDEX.md in Obsidian to browse
  3. After compiling, run /wiki-migrate to switch your AGENTS.md to wiki-first

Edit .wiki-compiler.json anytime to adjust settings.
```
