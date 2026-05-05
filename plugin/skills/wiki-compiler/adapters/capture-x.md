# Adapter: Capture X Link

Capture an X/Twitter URL into markdown for `/wiki-capture`.

For full bookmark-library sync, use `/fetch-bookmarks x`, which delegates to Field Theory CLI. This adapter is for one link at a time when the user adds context and wants the source connected to the current wiki.

## Step 1: Determine capture mode

- If the user provided a specific post/thread URL, capture that URL.
- If the user asks to import bookmarks or saved X items, stop and route them to `/fetch-bookmarks x`.

## Step 2: Fetch content

Try available approaches in this order:

1. Browser/web extraction of the public post/thread.
2. Field Theory CLI output if the post already exists under `~/.ft-bookmarks/md/bookmarks/`.
3. User-pasted post/thread text if the content is private, deleted, or blocked.

Preserve:

- author/handle if visible
- post URL
- post date if visible
- thread structure if visible
- quoted links or referenced artifacts

## Step 3: Normalize for wiki use

Write a captured source file under:

```text
wiki-sources/captures/x/YYYY-MM-DD-{slug}.md
```

Use `templates/captured-source-template.md` and fill:

- `source_type: x`
- `url`
- `captured_at`
- `title` as a short description of the post/thread
- `user_context`
- post/thread text
- relevance notes
- candidate wiki connections

## Step 4: Relevance extraction

Social posts are snapshots, not timeless facts. Always include `captured_at` and any visible post date. In relevance notes, separate:

- concrete claim or example
- why the user saved/captured it
- where it fits in the existing wiki
- whether it is a weak signal, anecdote, or durable reference

## Step 5: Return

Return the created markdown path to `/wiki-capture`.
