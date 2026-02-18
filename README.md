# Books Database Service — RF Test Generation Baseline

> **Purpose**: This repository is specifically for QA test generation using AI tools. The application code is stable and must not be modified. Focus is on generating Robot Framework tests using MCP-powered AI assistants.

This repository provides a stable application and test infrastructure used by different AI agents to generate Robot Framework test suites. All agents use the same base environment; the application remains unchanged while tests evolve.

… [Getting Started](docs/getting-started.md) … [Development Workflow](docs/development-workflow.md) … [Architecture](docs/architecture.md) … [Testing](docs/testing.md) … [Troubleshooting](docs/troubleshooting.md) …

## Clone This Repository

Use SSH to clone from GitHub:

```bash
git clone git@github.com:your-org/ai-tools-eval.git
cd ai-tools-eval
```

## Create Your Branch (Naming Convention)

All branches are for test case generation. Create a branch identifying the round, AI tool, and model.

**Pattern:** `<round>/<tool>/<model>`

Examples:

```bash
git checkout -b r1/claudecode/sonnet4
git checkout -b r2/copilot/sonnet45
```

Commit and push as usual (don't merge to main):

```bash
git add -A
git commit -m "Round 1 Claude Code test generation files"
git push -u origin round1/claudecode/sonnet4
```

## Start the Environment

This environment is started with the one-step helper only. No other run modes are needed.

```bash
./quick-start.sh
```

After running the script, reload VS Code to activate MCP servers in the IDE:
- Open Command Palette → "Developer: Reload Window" (or restart VS Code)

What this starts and why:
- Books API and UI (`books-service`) on http://localhost:8000 — baseline application under test (do not modify)
- Database initialization (`initialization`) — creates tables, migrates, and seeds sample data
- Robot Framework MCP (`robotframework-mcp`) — executes Robot tests on demand via MCP
- RF Docs MCP (`rf-docs-mcp`) — answers Robot Framework keyword/library documentation queries via MCP

Useful endpoints after startup:
- Web UI: http://localhost:8000
- API docs (OpenAPI): http://localhost:8000/docs

To stop everything later:

```bash
docker-compose down
```

## General Information

- Tests go under `robot_tests/`; results appear in `robot_results/`.
- Do not change application code in `fastapi_demo/`; focus on tests and documentation.
- Robot Framework MCP details live in RobotFramework-MCP-server.
… [Getting Started](docs/getting-started.md) … [Development Workflow](docs/development-workflow.md) … [Architecture](docs/architecture.md) … [Testing](docs/testing.md) … [Troubleshooting](docs/troubleshooting.md) …

Next: [Getting Started](docs/getting-started.md)
