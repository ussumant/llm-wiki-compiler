# Visualize Wiki Knowledge Graph

Launch an interactive canvas-based knowledge graph of your compiled wiki. Topics appear as nodes, concepts as connecting edges. Click any node to read the article.

## Instructions

1. Check that `.wiki-compiler.json` exists in the project root
2. Check that the wiki has been compiled (output directory has `INDEX.md`)
3. If not compiled, suggest running `/wiki-compile` first

4. Start the visualization server:
   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/visualize/server.js" --wiki-dir "{output_path}"
   ```

5. Open the browser:
   ```bash
   open "http://localhost:3848"
   ```

6. Tell the user:
   ```
   📊 Wiki Knowledge Graph running at http://localhost:3848
   
   - Click nodes to read topic articles
   - Hover edges to see concept connections
   - Search to filter topics
   - The server reads your wiki files live — changes from /wiki-compile appear immediately
   
   Stop with Ctrl+C when done.
   ```

## Arguments

- (none) — launch visualization for current project's wiki
- `--port {number}` — use a custom port (default: 3848)
