# Upgrade Wiki Compiler Plugin

Update the plugin to the latest version from the forked repository.

## Instructions

1. **Find the plugin source directory** by running:
   ```bash
   find ~/.claude/plugins -name "llm-wiki-compiler" -type d 2>/dev/null | head -1
   ```

2. **Pull the latest changes:**
   ```bash
   cd {plugin_directory} && git pull origin main
   ```

3. **Optionally sync with upstream:**
   ```bash
   cd {plugin_directory} && git fetch upstream && git log upstream/main --oneline -5
   ```
   Show the user what's new upstream and ask if they want to merge.

4. **Show what changed** by reading the git log:
   ```bash
   git log --oneline -5
   ```

5. **Tell the user to restart Claude Code** for the changes to take effect:

   > Updated to latest version. Restart Claude Code to load the new commands and hooks.
   >
   > What's new:
   > {list the new commits since their previous version}
