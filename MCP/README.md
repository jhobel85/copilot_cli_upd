# MCP — Model Context Protocol Servers

MCP servers extend the AI agent with additional tools. Each server runs as a local process.

## Current Servers

| Server | Package | Purpose |
|--------|---------|---------|
| `memory` | `@modelcontextprotocol/server-memory` | Persistent knowledge graph across sessions |

## Activate

**Per-session:** `/mcp add --config MCP/mcp-config.json`

**User-level (all sessions):** Merge server entries into `~/.copilot/mcp.json`

## Memory Server

- **Read** (`search_nodes`, `open_nodes`): any agent
- **Write** (`create_entities`, `add_observations`, `delete_*`): orchestrator only — never sub-agents

## Add a New Server

Add an entry to `mcp-config.json`, then reload with `/mcp`:

```json
{
  "mcpServers": {
    "my-server": { "command": "node", "args": ["path/to/server.js"] }
  }
}
```

