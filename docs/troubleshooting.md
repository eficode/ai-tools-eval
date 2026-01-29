# Troubleshooting

… [Getting Started](getting-started.md) … [Development Workflow](development-workflow.md) … [Architecture](architecture.md) … [Testing](testing.md) …

## MCP tools not visible in IDE

```bash
# Verify containers are running
docker ps | grep mcp

# Check MCP config exists
ls -la .claude.json .vscode/mcp.json .gitlab/duo/mcp.json .amazonq/default.json

# Test server directly
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | \
  docker exec -i robotframework-mcp python /app/server.py
```

## App unreachable from tests

```bash
# Check health and endpoint
curl http://localhost:8000/books/
docker ps | grep books-database-service

# Inspect network
docker network inspect books-service-network
```

## Browser test failures (Chromium)

```bash
# Rebuild Playwright image and restart
docker-compose build robotframework-mcp
docker-compose up -d robotframework-mcp
```

## Database looks empty

```bash
# Check init logs
docker logs initialization

# Rerun init
docker-compose up initialization

# Seed sample data (inside app container)
docker exec books-database-service python scripts/generate_books.py
```

… [Testing](testing.md) … [Architecture](architecture.md) …


