# Query Knowledge Base Wiki

Search the compiled wiki to answer a question. Faster and cheaper than reading raw source files.

## Arguments

The user's question is passed as `$ARGUMENTS`. Example: `/wiki-query what do we know about retention?`

## Instructions

1. **Read configuration** from `.wiki-compiler.json`. If not found, tell user to run `/wiki-init`.

2. **Read INDEX.md** from the configured output directory to see all available topics.

3. **Identify relevant topics** — based on the user's question, select 1-3 topic articles most likely to contain the answer.

4. **Read the selected topic articles** from `{output}/topics/`.

5. **Answer the question** with:
   - Specific facts, dates, and decisions from the wiki articles
   - Citations in the format: `(from: {topic name} > {section})`
   - If the wiki doesn't have enough detail, point the user to specific raw source files from the article's Sources section

6. **Keep it concise** — the user wants an answer, not a summary of every article you read.

## If no wiki exists

If INDEX.md doesn't exist or the wiki hasn't been compiled yet:
```
Wiki not compiled yet. Run /wiki-compile first, then try your query again.
```
