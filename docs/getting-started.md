# Getting Started

… [Development Workflow](development-workflow.md) … [Architecture](architecture.md) … [Testing](testing.md) … [Troubleshooting](troubleshooting.md) …

## Prerequisites

- Docker Desktop (includes Docker Compose)
- Git
- Repository cloned locally (see main [README](../README.md) for clone instructions)

## Start Environment (one command)

```bash
./quick-start.sh
```

What starts and why:
- Books API and UI (`books-service`) at http://localhost:8000 — baseline app under test (do not modify)
- Database initialization (`initialization`) for tables, migrations, and sample data
- Robot Framework MCP (`robotframework-mcp`) for test execution via MCP
- RF Docs MCP (`rf-docs-mcp`) for keyword/library docs via MCP

## Verify

```bash
docker ps
curl http://localhost:8000/books/
```

Open:
- Web UI: http://localhost:8000
- API docs: http://localhost:8000/docs

## Generate Tool-Specific and Robot Framework Information Files

The `template/` folder contains two key files for AI-assisted test generation:

- **Instruction Template.txt**: Robot Framework test structure template with placeholders for Settings, Variables, Test Cases, Keywords, and Comments sections
- **Test Standards.txt**: AI generation rules including Page Object pattern, explicit wait strategies, behavioral naming, and library version constraints

Steps to generate tests:

1. Use your IDE's feature to generate a tool-specific instructions file (e.g., Copilot's "Generate Chat Instructions" button to generate copilot-instructions.md)
2. Ask your AI assistant to generate Robot Framework tests following the templates in the `template/` folder
3. Ensure tests comply with the standards defined in Test Standards.txt (RF 7.4.1, Browser Library 19.12.3, RequestsLibrary 0.9.7) 

## Generate and Run Tests

Place Robot Framework suites under `robot_tests/`. Use your IDE’s MCP integration (configured by `./quick-start.sh`) to list and run tests, or run manually via Docker exec.

Next: [Development Workflow](development-workflow.md)

## Stop Services

```bash
docker-compose down
```

… [Development Workflow](development-workflow.md) … [Architecture](architecture.md) …
