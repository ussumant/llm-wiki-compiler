# Upgrade Wiki Compiler Plugin

Update the Copilot port of the plugin to the latest version.

## Instructions

1. **Try a normal Copilot plugin update first** by running:
   ```bash
   copilot plugin update llm-wiki-compiler
   ```

2. **If the update command succeeds**, tell the user to restart their Copilot session and reload Copilot Chat so the updated commands and hooks load.

3. **If the update command fails or the plugin was installed from this local port**, tell the user to rerun the installer from the cloned repository:
   > Reinstall the staged Copilot port by rerunning `copilot-port/install.sh` from the cloned repository.
   > 
   > Re-run `copilot-port/install.sh` from the cloned `llm-wiki-compiler` repository, then restart the Copilot CLI session and reload the editor window for Copilot Chat.

4. **If the user asks what changed**, summarize the latest commits from the repository checkout they are using.

## Notes

- Prefer `copilot plugin update llm-wiki-compiler` for repository or marketplace installs.
- Prefer rerunning `copilot-port/install.sh` for local staged installs of this port.
- After either path, remind the user to restart the Copilot CLI session and reload Copilot Chat.
