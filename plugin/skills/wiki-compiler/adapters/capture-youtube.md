# Adapter: Capture YouTube Link

Capture a YouTube video into markdown for `/wiki-capture`.

This adapter should use the local `youtube-workflow-documenter` skill when available. The goal is not a full published tutorial by default; it is a wiki source that preserves transcript evidence and extracts the pieces relevant to the user's context.

## Step 1: Preflight

- Check for `yt-dlp` on PATH.
- If video download or clips are needed, also check `ffmpeg` and `ffprobe`.
- Prefer captions/transcripts first. Only use transcription fallback when captions are missing or too weak.
- If required tooling is missing, ask the user whether to continue with available transcript/page metadata or stop for setup. Do not install tools automatically.

## Step 2: Build transcript evidence

Use this fallback order:

1. Manual subtitles
2. Auto subtitles
3. OpenAI/audio transcription if the user has configured it and approves
4. User-provided transcript or notes

Preserve timestamp spans. Normalize tiny subtitle fragments into readable paragraphs without losing evidence.

## Step 3: Normalize for wiki use

Write a captured source file under:

```text
wiki-sources/captures/youtube/YYYY-MM-DD-{slug}.md
```

Use `templates/captured-source-template.md` and fill:

- `source_type: youtube`
- `url`
- `captured_at`
- `title`
- `user_context`
- channel/creator if available
- duration if available
- transcript excerpts with timestamps
- extracted notes relevant to the user's context
- workflow steps only when the video is actually a tutorial or walkthrough
- candidate wiki connections

## Step 4: Relevance extraction

Read the video through the user's context. Extract:

- what this teaches about the user's current work
- specific tactics, workflow steps, or product/design/engineering patterns
- timestamped evidence for key claims
- what belongs in existing topics vs a new topic/concept

Do not dump the full transcript into topic articles. The full transcript can live in the captured source file; wiki topics should receive synthesis.

## Step 5: Return

Return the created markdown path to `/wiki-capture`.
