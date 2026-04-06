# Lint Knowledge Base Wiki

Run health checks on the compiled wiki to find issues.

## Instructions

1. **Read configuration** from `.wiki-compiler.json`. If not found, tell the user to run `/wiki-init` first.

2. **Read the wiki state:**
   - Read `{output}/INDEX.md` for current topics
   - Read `{output}/schema.md` for expected structure (if exists)
   - Read `{output}/.compile-state.json` for last compilation state

3. **Run these checks:**

### Check 1: Stale Articles
Compare source file modification dates against `.compile-state.json`. Flag topics whose sources have changed since last compile.

### Check 2: Orphan Pages
Check each wiki article's Sources section. Flag articles where:
- Source files no longer exist (were deleted or moved)
- Article has 0 sources listed

### Check 3: Missing Cross-References
For each pair of topics, count shared sources. If two topics share 3+ sources but neither references the other, suggest a cross-reference.

### Check 4: Low Coverage Sections
Scan all articles for `[coverage: low]` tags. List them as improvement candidates.

### Check 5: Contradictions
Compare key facts across articles. Look for:
- Different dates for the same event in different articles
- Conflicting metrics or parameter values
- Decisions described differently across topics

### Check 6: Schema Drift
If `schema.md` exists:
- Topics in `topics/` directory not listed in schema.md
- Topics listed in schema.md that don't have a corresponding article
- Article sections that don't match the schema's Article Structure

### Check 7: Code Drift (for code topics)
For topics of type `code`:
- Compare env vars listed in wiki article vs actual env vars in source .py files
- Check if key functions listed in the article still exist in the source
- Flag articles where source .py files have been significantly modified (>20% line change)

### Check 8: Parameter Consistency
For topics with Parameters or Environment Variables sections:
- Cross-check parameter values against other topics mentioning the same parameter
- Flag any parameter with different documented values across topics

4. **Output a summary:**

```
Wiki Lint: "{name}"
──────────────────────────
Stale:            {N} topics (sources changed since last compile)
Orphans:          {N} articles with missing sources
Cross-refs:       {N} missing links suggested
Low coverage:     {N} sections across {N} topics
Contradictions:   {N} found
Schema drift:     {N} mismatches
Code drift:       {N} code topics with outdated info
Param conflicts:  {N} parameter inconsistencies

{Details for each finding, grouped by check}
```

5. **Suggest fixes:**
   - Stale topics: "Run `/wiki-compile` to refresh"
   - Orphans: "Source was deleted — recompile to remove stale references"
   - Cross-refs: "Consider adding a reference to [[topic-b]] in topic-a's Summary"
   - Contradictions: "Check {source1} vs {source2} for the correct value"
   - Code drift: "Run `/wiki-compile --topic {slug}` to refresh code documentation"
   - Param conflicts: "Parameter X has value A in topic-1 but value B in topic-2"

6. **Log the lint run** by appending to `{output}/log.md`:
```markdown
### {date} — Lint
- Stale: {N}, Orphans: {N}, Cross-refs: {N}, Low: {N}, Contradictions: {N}, Drift: {N}, Code: {N}, Params: {N}
```
