# Initialize the Global Wiki

Create or repair the user's default cross-project wiki.

## Arguments

- `/wiki-global-init` — initialize the default global wiki
- `/wiki-global-init --path ~/Somewhere` — initialize a custom global wiki directory

Codex prompt equivalents:

```text
Set up my global wiki
```

or:

```text
Use ~/Knowledge as my global wiki
```

## Global wiki location

Default:

```text
~/Knowledge
```

Override:

```text
LLM_WIKI_GLOBAL_DIR=/path/to/wiki-root
```

Prefer `~/Knowledge` over hidden app storage because users can browse it, back it up, sync it, edit sources, and understand where their knowledge lives.

## Instructions

1. Resolve the target directory:
   - `--path` wins if provided.
   - Else `LLM_WIKI_GLOBAL_DIR` if set.
   - Else `~/Knowledge`.
2. Create the directory if it does not exist.
3. Create these subdirectories if missing:
   ```text
   wiki-sources/captures/
   wiki/
   ```
4. If `.wiki-compiler.json` does not exist, create it from `templates/global-wiki-config.json`.
5. If `.wiki-compiler.json` exists, verify it includes `wiki-sources/captures/` in `sources[]`; ask before adding it if missing.
6. Do not overwrite an existing config.
7. Print:
   ```text
   Global wiki ready at {path}

   Try:
   https://example.com
   capture this in my wiki
   ```

## Default config

Use `templates/global-wiki-config.json` as the default config shape. The default wiki is a knowledge-mode wiki with capture sources enabled and output at `wiki/`.
