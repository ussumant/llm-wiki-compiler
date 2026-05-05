# Adapter: Capture Web Link

Capture a normal web URL into markdown for `/wiki-capture`.

## Step 1: Fetch readable content

- Try to read the URL with the best available browser/web extraction tool.
- Capture:
  - final URL after redirects
  - page title
  - author/publication if visible
  - published or updated date if visible
  - main article/body text
  - key headings
- If the page is blocked, paywalled, script-only, or extraction fails, ask the user to paste the relevant text or provide a screenshot/PDF. Do not fabricate content from the title alone.

## Step 2: Normalize for wiki use

Write a captured source file under:

```text
wiki-sources/captures/web/YYYY-MM-DD-{slug}.md
```

Slug from the page title or domain + path. Keep it lowercase-kebab-case and under 80 characters.

Use `templates/captured-source-template.md` and fill:

- `source_type: web`
- `url`
- `captured_at`
- `title`
- `user_context`
- `source_date` if discovered
- `extracted_content`
- `relevance_notes`
- `candidate_connections`

## Step 3: Relevance extraction

Do not write a generic article summary. Write:

- 3-7 facts or claims that matter under the user's context
- any concrete examples, terms, metrics, names, or workflows
- what this source changes, supports, or contradicts in the existing wiki
- uncertainty notes when extraction quality is low

## Step 4: Return

Return the created markdown path to `/wiki-capture`.
