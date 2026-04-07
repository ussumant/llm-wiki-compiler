# Migrate to Wiki-First Startup

One-time migration command. Analyzes your AGENTS.md or CLAUDE.md session startup sequence and shows which raw file reads can be replaced by wiki articles.

## Instructions

### Step 1: Validate

- Read `.wiki-compiler.json` — if not found, tell the user to run `/wiki-init` first
- Check that the wiki has been compiled at least once (INDEX.md and topic articles exist)
- If not compiled, tell the user to run `/wiki-compile` first

### Step 2: Find startup instructions

Look for session startup instructions in this order:
1. `AGENTS.md` in the project root
2. `CLAUDE.md` in the project root
3. Any file referenced by `CLAUDE.md` that contains startup/context loading instructions

Identify the section that lists files to read at session start. Look for patterns like:
- "Read these files", "Session Startup", "Before doing any work, read..."
- Numbered lists of file paths with descriptions
- References to context files, knowledge bases, or startup sequences

### Step 3: Map raw files to wiki topics

For each file listed in the startup sequence:
1. Read the wiki INDEX.md to get the list of topics
2. For each raw file, check if its content is covered by a wiki topic:
   - Match by filename appearing in a topic's Sources section
   - Match by content overlap (the raw file's key terms appearing in a topic article)
3. Check the coverage level of the relevant topic sections

### Step 4: Present the coverage report

```
Wiki Migration Report for {project name}

Current startup: {N} file reads

✅ {filename} → covered by {topic} [coverage: high]
✅ {filename} → covered by {topic} [coverage: high]
⚠️ {filename} → partially covered by {topic} [coverage: medium]
   → Check raw source for: {what's missing}
⚠️ {filename} → partially covered by {topic} [coverage: low]
   → Read raw source directly for granular detail
❌ {filename} → not covered by any wiki topic
   → Keep this in startup, or /wiki-ingest to add it

Summary: {covered}/{total} reads can be replaced by wiki
Estimated token savings: ~{old_tokens} → ~{new_tokens} ({reduction}% reduction)
```

### Step 5: Generate replacement startup block

Based on the report, generate a replacement startup section that:
1. Reads wiki INDEX.md first
2. Lists relevant topic articles by work area
3. Keeps any ❌ items as direct file reads (operational rules, checklists)
4. Includes coverage-based fallback instructions

Present the replacement block to the user:

```
Here's a suggested replacement for your startup section:

---
{generated startup block}
---

Want me to apply this? (I'll only edit the startup section — everything else stays the same.)
```

### Step 6: Apply (with confirmation)

**Only if the user confirms:**
- Replace the startup section in AGENTS.md or CLAUDE.md
- Keep everything outside the startup section unchanged
- Show a diff of what changed

**Never auto-apply.** The user must explicitly confirm before any file is modified.

## Arguments

- No arguments: analyzes and reports
- `--apply`: skip the confirmation prompt and apply immediately (for scripting)
- `--dry-run`: just show the report, don't offer to apply
