# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Books Database Service** designed for QA test generation using AI tools. The application code is stable and must NOT be modified - focus is on generating Robot Framework tests using MCP-powered AI assistants.

**Key Architecture:**
- **FastAPI Books API**: RESTful service for managing books catalog (SQLite backend)
- **Docker Compose**: Multi-container orchestration with MCP integration
- **Robot Framework MCP Server**: On-demand test execution via Model Context Protocol
- **RF Documentation MCP**: Real-time keyword documentation access
- **Web UI**: Static frontend consuming the REST API

## Branch Naming Convention

All branches are for test case generation. Use pattern: `<round>/<tool>/<model>`

Examples:
```bash
git checkout -b r1/claudecode/sonnet4
git checkout -b r2/copilot/sonnet45
```

Don't merge to main - push branch directly:
```bash
git push -u origin r1/claudecode/sonnet4
```

## Essential Commands

### Environment Setup
```bash
# One-command environment start
./quick-start.sh

# After startup, reload VS Code to activate MCP servers
# Services available at:
# - Web UI: http://localhost:8000
# - API docs: http://localhost:8000/docs

# Stop everything
docker-compose down
```

### Testing

**Robot Framework (via MCP - primary focus):**
- Add `.robot` test suites to `robot_tests/` directory
- Use IDE's MCP integration to run tests (configured by quick-start.sh)
- Results saved to `robot_results/` with HTML reports
- Available MCP tools: run_suite(), run_test_by_name(), list_tests(), run_robocop_audit()

**Python Unit Tests:**
```bash
# Run all unit tests
docker exec -it books-database-service pytest -q

# Run specific test
docker exec -it books-database-service pytest tests/test_books.py::test_create_book -q -vv
```

### Development Tools
```bash
# Poetry-based dependency management (if needed)
poetry install
poetry run dev-server  # Alternative to Docker for development

# Database inspection (SQLite)
docker exec -it books-database-service sqlite3 /app/data/books.db ".tables"
```

## Architecture Overview

**Container Structure:**
- `books-service`: FastAPI app on port 8000, healthchecked, uses SQLite
- `initialization`: One-time DB setup, creates tables and sample data (100 books)
- `robotframework-mcp`: Persistent test execution environment (2GB shared memory)
- `rf-docs-mcp`: Documentation query service with 321 keywords from RF 7.4.1

**MCP Integration Pattern:**
- On-demand execution via `docker exec -i <container> python /app/server.py`
- No persistent MCP servers - spawns on request, processes, then exits
- Communication over stdin/stdout using JSON-RPC 2.0 message format
- Configured for Claude Code, VS Code Copilot, GitLab Duo, Amazon Q

**Volume Mappings:**
- `./data/` → SQLite database storage
- `./robot_tests/` → Test suites (read-only in container)
- `./robot_results/` → Test reports and artifacts (read-write)

## Application Structure

**FastAPI Demo (`fastapi_demo/`):**
```
├── main.py          # FastAPI app with books router
├── models.py        # SQLAlchemy Book model
├── database.py      # DB engine and session setup
├── dtos.py          # Pydantic request/response models
├── routers/books.py # Books CRUD endpoints
└── static/          # Frontend HTML/CSS/JS
```

**Test Framework:**
- Robot Framework 7.4.1 with Browser Library (Playwright)
- RequestsLibrary for API testing
- Robocop for static code analysis
- Pytest for Python unit tests

## Key Constraints

- **DO NOT modify application code in `fastapi_demo/`** - it's intentionally stable
- Focus on test generation in `robot_tests/` directory
- Application provides: Books CRUD API, search functionality, web UI
- Database pre-seeded with 100 sample books (auto-generated if empty)
- Tests run against containerized application via `http://books-service:8000`

## Useful File Paths

- Tests: `robot_tests/` (your work goes here)
- Results: `robot_results/` (generated reports)
- Scripts: `scripts/generate_books.py`, `scripts/migrate_db.py`
- Docs: `docs/architecture.md` (detailed technical architecture)
- Config: `pyproject.toml` (Poetry), `pytest.ini`, `docker-compose.yml`

## MCP Tools Available

**Robot Framework MCP (`robotframework-mcp`):**
- `run_suite()` - Execute test suite/folder
- `run_test_by_name()` - Run specific test
- `list_tests()` - List test cases in suite
- `run_robocop_audit()` - Static code analysis

**RF Documentation MCP (`rf-docs-mcp`):**
- `robot-get_keyword_documentation()` - Get keyword details
- `robot-get_library_documentation()` - Get library docs
- `robot-get_environment_details()` - RF environment info

All MCP communication handled automatically by IDE integration after running `./quick-start.sh`.