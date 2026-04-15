# Adapter: X (Twitter) Bookmarks

> Credits **Field Theory CLI** (https://github.com/afar1/fieldtheory-cli, MIT) — an open-source tool that self-custodies X bookmarks locally. This adapter installs and drives `ft` under the hood so the user never has to set it up manually.

Called by `/fetch-bookmarks x`. Walks the user through: checking prerequisites, installing Field Theory CLI (with consent), syncing bookmarks, exporting them to markdown, and wiring the output directory into `.wiki-compiler.json`.

## Step 1: Preflight — Node 20+

- Run `node --version` via Bash.
- If the command fails or the reported major version is less than 20, stop and print:
  ```
  Field Theory CLI needs Node.js 20 or newer. Install it from https://nodejs.org (or via nvm/fnm), then rerun /fetch-bookmarks x.
  ```
  Do NOT attempt to install Node automatically.

## Step 2: Preflight — Field Theory CLI

- Check for `ft` on PATH: `command -v ft`.
- If present, skip to Step 3.
- If missing, ask the user:
  > "This will install **Field Theory CLI** (https://github.com/afar1/fieldtheory-cli — MIT-licensed, free, ~30 seconds) globally via npm. It's the open-source tool that fetches X bookmarks. Proceed?"
- On **yes**: run `npm install -g fieldtheory`. Surface the output. If install fails (e.g., permission error on global install), suggest the user retry with `sudo` or configure npm's global prefix, and stop.
- On **no**: print "No problem — rerun /fetch-bookmarks x anytime you change your mind." and stop.

## Step 3: Sync bookmarks

- Run `ft sync`. Surface `ft`'s output verbatim — it's chatty for a reason.
- `ft` reads cookies from a supported browser's local profile. **Prerequisites:** the browser must be installed, must be logged into x.com, and (for Chrome) the user may need to be active in the right profile.
- **Supported browsers (as of ft 1.3.x):** chrome, chromium, brave, helium, comet, firefox. Arc, Edge, Vivaldi, Opera, Zen are NOT supported — see escape hatch below.
- If `ft sync` exits with "Couldn't connect to your browser session", try this ladder:
  1. **Multiple Chrome profiles:** auto-detect defaults to "Profile 1". If the user has profiles named `Default`, `Profile 2`, `Profile 3`, etc., the user-logged-in profile may not be Profile 1. Ask the user which profile they're logged in on, then retry: `ft sync --chrome-profile-directory "Profile 3"` (substitute the right name).
  2. **Different browser family:** retry with `ft sync --browser brave` / `--browser firefox` etc.
  3. **Unsupported browser (Arc, Edge, Vivaldi, Opera, Zen):** ask the user to either (a) log into x.com on a supported browser temporarily, or (b) use the manual cookie escape hatch — open x.com in their unsupported browser → DevTools → Application → Cookies → copy the `ct0` and `auth_token` values → run `ft sync --cookies <ct0> <auth_token>`.
- If sync still fails after one ladder attempt, stop and surface the error. Do not retry blindly.

## Step 4: Ensure markdown export

- Field Theory writes markdown into nested subdirectories under `~/.ft-bookmarks/md/`. Each bookmark becomes its own `.md` file under `~/.ft-bookmarks/md/bookmarks/`. (Future `ft classify` runs may add `~/.ft-bookmarks/md/categories/` and similar.)
- `ft sync` does NOT export markdown. After sync, always run `ft md` to write/refresh the markdown export.
- Run `ft md`. Surface its output verbatim — it prints a per-bookmark progress count.
- Verify the export by checking `~/.ft-bookmarks/md/bookmarks/` exists and is non-empty.
- If still empty after `ft md`, stop with an error pointing to the Field Theory CLI repo for troubleshooting.

## Step 5: Wire into `.wiki-compiler.json`

- Read `.wiki-compiler.json` from the current project root (or nearest parent). If not found, tell the user to run `/wiki-init` first, then stop.
- Target source path: `~/.ft-bookmarks/md/bookmarks/` (the nested directory containing the actual tweet markdown files — narrower than `~/.ft-bookmarks/md/` so we don't accidentally ingest category index pages later).
- If any entry in `sources[]` already points at that directory (tilde or expanded form), skip this step.
- Otherwise, show the user:
  ```
  Add ~/.ft-bookmarks/md/bookmarks/ to your wiki sources in .wiki-compiler.json? (y/n)
  ```
- On **yes**: append a new entry to `sources[]`:
  ```json
  {
    "path": "~/.ft-bookmarks/md/bookmarks/",
    "description": "X bookmarks (synced via Field Theory CLI)"
  }
  ```
  Preserve every other field in the config — do not reformat the whole file. Use a targeted edit.
- On **no**: remind the user they can add it manually later, then continue.

## Step 6: Suggest compile

Count the markdown files in `~/.ft-bookmarks/md/` and print:

```
Fetched N bookmark file(s) into ~/.ft-bookmarks/md/.
Run /wiki-compile to synthesize them into topic articles.
```

Do NOT invoke `/wiki-compile` automatically.

## Troubleshooting

- **`ft sync` fails with "Couldn't connect to your browser session":** see the ladder in Step 3. Most common cause is non-default Chrome profile — try `--chrome-profile-directory "Profile 3"` etc.
- **User is on Arc / Edge / Vivaldi / Opera / Zen:** these Chromium variants are NOT in `ft`'s supported list (cookies live at non-standard paths). Use the manual `--cookies` escape hatch from Step 3, or have the user log into x.com on Chrome temporarily.
- **Global npm install blocked on macOS:** usually an EACCES on `/usr/local/lib/node_modules`. Suggest `npm config set prefix ~/.npm-global` and adding `~/.npm-global/bin` to PATH.
- **OAuth fallback:** Field Theory has `ft auth` for API-based sync, but it requires an X developer app. Out of scope for `/fetch-bookmarks` (we promised "free and easy") — direct power users to the Field Theory README if they want that path.
