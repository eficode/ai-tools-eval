# Books Database Service - Architecture Documentation

… [Getting Started](getting-started.md) … [Development Workflow](development-workflow.md) … [Testing](testing.md) … [Troubleshooting](troubleshooting.md) …

**Version:** 1.3  
**Last Updated:** January 2026  
**Target Audience:** Developers, DevOps Engineers, System Architects

## Table of Contents

1. [Introduction](#introduction)
2. [System Overview](#system-overview)
3. [Prerequisites](#prerequisites)
4. [Container Details](#container-details)
5. [MCP Architecture Pattern](#mcp-architecture-pattern)
6. [MCP Tools Available](#mcp-tools-available)
7. [Network & Volume Architecture](#network--volume-architecture)
8. [Data Flow](#data-flow)
9. [Configuration](#configuration)
10. [Troubleshooting](#troubleshooting)
11. [Development Workflow](#development-workflow)
12. [Backup and Recovery](#backup-and-recovery)
13. [Related Documentation](#related-documentation)

## Introduction

This document describes the baseline environment architecture used for Robot Framework test generation by multiple AI agents. It includes a containerized FastAPI application and MCP-powered testing/documentation services. The application is intentionally stable and not modified during test generation.

### Purpose

- **Books Database Service**: RESTful API and web UI for managing a books catalog
- **Automated Testing**: Robot Framework test execution via MCP protocol
- **Documentation Access**: Real-time keyword documentation through MCP tools
- **Development Environment**: Fully containerized setup with automatic initialization

### Key Technologies

- **FastAPI** - Modern Python web framework
- **SQLite** - Lightweight database for book storage
- **Docker Compose** - Container orchestration
- **Robot Framework 7.4.1** - Test automation framework
- **MCP (Model Context Protocol)** - AI-tool integration protocol for test execution
- **Playwright/Browser Library** - Web automation for UI testing

## System Overview

```
┌───────────────────────────────────────────────────────────────────────┐
│                        HOST MACHINE (macOS/Linux/Windows)             │
│                                                                       │
│  ┌──────────────┐   ┌──────────────┐  ┌───────────────────┐           │
│  │  ./data      │   │ ./robot_tests│  │  ./robot_results  │           │
│  │  (SQLite DB) │   │ (Test Suites)│  │  (Test Reports)   │           │
│  └──────┬───────┘   └──────┬───────┘  └─────┬─────────────┘           │
│         │                  │ (ro)           │ (rw)                    │
│  ┌──────┼──────────────────┼────────────────┼──────────────┐          │
│  │      │   books-service-network (bridge)  │              │          │
│  │  ┌───▼────────┐  ┌──────▼─────────┐  ┌───▼───────────┐  │          │
│  │  │ books-     │  │ initialization │  │ robotframework│  │          │
│  │  │ service    │  │ (Init Script)  │  │ -mcp          │  │          │
│  │  │ (FastAPI)  │  │ Run once       │  │ (Test Env)    │  │          │
│  │  │ Port: 8000 │  │ restart:       │  │ shm_size: 2gb │  │          │
│  │  │ Healthcheck│  │ on-failure     │  │               │  │          │
│  │  └────────────┘  └────────────────┘  └───────────────┘  │          │
│  │       │                    │                            │          │
│  │       │          ┌─────────▼────────┐                   │          │
│  │       │          │   rf-docs-mcp    │                   │          │
│  │       │          │ (Documentation)  │                   │          │
│  │       │          │ RF 7.4.1 Docs    │                   │          │
│  │       │          │ 321 Keywords     │                   │          │
│  │       │          └──────────────────┘                   │          │
│  └───────┼─────────────────────────────────────────────────┘          │
│          │                                                            │
│    ┌─────▼────────┐                                                   │
│    │localhost:8000│  ← Browser Access                                 │
│    └──────────────┘                                                   │
└───────────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Software Requirements

| Software       | Minimum Version | Purpose                          |
|----------------|-----------------|----------------------------------|
| Docker         | 20.10+          | Container runtime                |
| Docker Compose | 2.0+            | Multi-container orchestration    |
| Git            | 2.0+            | Source code management           |

### System Requirements

| Component   | Minimum   | Recommended          |
|-------------|-----------|----------------------|
| CPU         | 2 cores   | 4+ cores             |
| RAM         | 4 GB      | 8+ GB                |
| Disk Space  | 5 GB      | 10+ GB               |
| OS          | macOS 10.15+, Linux (kernel 3.10+), Windows 10+ with WSL2 | Latest stable |

### Network & Permissions

- Port 8000 available on host machine
- Internet access for initial Docker image pulls
- Docker command permissions (Linux: add user to `docker` group)
- Write access to project directory for volume mounts

## Container Details

### 1. books-service (books-database-service)

- **Image**: Built from `./Dockerfile`
- **Purpose**: FastAPI REST API serving books database
- **Port**: `8000:8000` (exposed to host)
- **Healthcheck**: HTTP GET to `/books/` every 30s
- **Restart Policy**: unless-stopped
- **Access**:
  - From host: `http://localhost:8000`
  - From containers: `http://books-service:8000`

### 2. initialization

- **Image**: Same as books-service
- **Purpose**: One-time database initialization
- **Lifecycle**: Runs once, restarts on-failure until successful, then stops
- **Tasks**:
  1. Create database directory
  2. Create SQLAlchemy tables
  3. Run migrations (`scripts/migrate_db.py`)
  4. Generate 100 sample books if database is empty

### 3. robotframework-mcp (Test Execution Environment)

- **Image**: Built from `./RobotFramework-MCP-server/Dockerfile`
- **Purpose**: On-demand Robot Framework test execution environment
- **Shared Memory**: 2GB (for Chromium/Playwright)
- **Lifecycle**: Persistent container (uses `tail -f /dev/null` to stay alive)
  - MCP server invoked on-demand via `docker exec -i robotframework-mcp python /app/server.py`
  - Each request spawns server, processes request, then exits
- **Tools Installed**:
  - Robot Framework 7.4.1
  - Browser Library 19.12.3 (Playwright)
  - RequestsLibrary 0.9.7
  - Robocop 7.2.0 (static analyzer)
  - MCP Python SDK (FastMCP)
- **User**: Non-root (`appuser`, UID 10001)

### 4. rf-docs-mcp (Documentation Query Environment)

- **Image**: Built from `./RobotFramework-MCP-server/Dockerfile.docs`
- **Purpose**: On-demand Robot Framework documentation query environment
- **Lifecycle**: Persistent container invoked via `docker exec -i rf-docs-mcp python /app/rf_docs_server.py`
- **Data**: 321 keywords from 9 libraries (RF 7.4.1), pre-generated JSON documentation

## MCP Architecture Pattern

### On-Demand Execution Model

This system uses an **on-demand MCP execution pattern**:

**Protocol Stack:**
```
Application Protocol: MCP (Model Context Protocol)
Message Format:       JSON-RPC 2.0
Transport:            stdin/stdout (via docker exec)
```

**How It Works:**
- Containers stay alive as ready-to-use execution environments
- No persistent MCP server processes running inside containers
- MCP clients invoke servers on-demand: `docker exec -i <container> python /app/<server>.py`
- Server spawns, processes one MCP request, then exits
- Communication uses MCP protocol with JSON-RPC 2.0 message encoding over stdin/stdout
- Resources are minimal when idle (just the `tail` process)

**Benefits:**
- No port management or network complexity
- No resource consumption when idle
- Clean isolation via Docker
- Easy debugging (containers stay alive for inspection)
- Stateless execution

**Communication Flow:**
```
IDE (MCP Client)
  → docker exec -i robotframework-mcp python /app/server.py
    → MCP server spawns
      → Reads MCP request from stdin (JSON-RPC 2.0 format)
      → Executes tests
      → Returns MCP response to stdout (JSON-RPC 2.0 format)
    → MCP server exits
  → IDE displays results
```

## MCP Tools Available

### robotframework-mcp Tools (Test Execution)

| Tool                  | Description                          | Parameters                                            | Returns                        |
|-----------------------|--------------------------------------|-------------------------------------------------------|--------------------------------|
| `run_suite()`         | Execute entire test suite or folder  | `suite_path`, `include_tags`, `exclude_tags`, `variables` | Test results, artifact paths   |
| `run_test_by_name()`  | Execute specific test by name        | `test_name`, `suite_path`, `variables`                | Test results, artifact paths   |
| `list_tests()`        | List all test cases in suite         | `suite_path`                                          | Array of test names            |
| `run_robocop_audit()` | Static code analysis with Robocop    | `target_path`, `report_format`                        | Audit results, report path     |

**Usage Example:**
```json
{
  "method": "run_suite",
  "params": {
    "suite_path": "/tests/books_api.robot",
    "include_tags": "smoke"
  }
}
```

### rf-docs-mcp Tools (Documentation Query)

| Tool                                 | Description                    | Parameters                   | Returns                              |
|--------------------------------------|--------------------------------|------------------------------|--------------------------------------|
| `robot-get_keyword_documentation`    | Get detailed keyword docs      | `keyword_name`, `library_name` | Signature, args, description, examples |
| `robot-get_library_documentation`    | Get full library docs          | `library_name`               | All keywords, initialization params  |
| `robot-get_file_imports`             | Analyze test file imports      | `file_path`                  | List of imported libraries/resources |
| `robot-get_environment_details`      | Get RF environment info        | -                            | Versions, Python path, tools         |
| ...and 6 more tools                  | -                              | -                            | -                                    |

## Network & Volume Architecture

### Network

```
┌─────────────────────────────────────────────────┐
│     books-service-network (bridge)              │
│                                                 │
│  books-service:8000  ←─── robotframework-mcp    │
│         ▲                         │             │
│         │                         ▼             │
│    initialization            rf-docs-mcp        │
└─────────────────────┬───────────────────────────┘
                      │ Port 8000
                      ▼
              localhost:8000 (Host)
```

### Volume Mapping

```
HOST FILESYSTEM              CONTAINER PATHS
─────────────────            ───────────────

./data/                ──→   /app/data (books-service, initialization)
                             └── books.db (SQLite)

./robot_tests/         ──→   /tests (robotframework-mcp, read-only)

./robot_results/       ──→   /results (robotframework-mcp, read-write)
                             ├── log.html
                             ├── report.html
                             └── output.xml

Docker Named Volumes:
  rf_docs_cache        ──→   /cache (rf-docs-mcp)
  rf_library_docs      ──→   /app/docs (robotframework-mcp)
```

### Service Dependencies

```
initialization      →  depends_on: books-service
robotframework-mcp  →  depends_on: books-service
rf-docs-mcp         →  (no dependencies, standalone)
```

### Port Exposure & Resource Requirements

| Service            | Internal Port | External Port | Access Method                         | CPU    | Memory  | SHM     |
|--------------------|---------------|---------------|---------------------------------------|--------|---------|---------|
| books-service      | 8000          | 8000          | localhost:8000 (host browser)         | Low    | ~100MB  | Default |
| robotframework-mcp | -             | -             | `docker exec -i` + stdin/stdout       | Medium | ~500MB  | 2GB     |
| rf-docs-mcp        | -             | -             | `docker exec -i` + stdin/stdout       | Low    | ~50MB   | Default |
| initialization     | -             | -             | Ephemeral (auto-stops after init)     | Low    | ~100MB  | Default |

### Security Boundaries

```
┌──────────────────────────────────────┐
│  HOST NETWORK (Public)               │
│  Port 8000 → books-service           │
│  (Only exposed port)                 │
└───────────────┬──────────────────────┘
                │
┌───────────────▼──────────────────────┐
│  books-service-network (Isolated)    │
│  - books-service → container IP      │
│  - robotframework-mcp → container IP │
│  - rf-docs-mcp → container IP        │
│  No external access to test services │
└──────────────────────────────────────┘
```

**MCP Security:**
- MCP servers run inside isolated Docker containers
- Communication requires Docker socket access (`docker exec`)
- No network exposure for MCP services
- Volume mounts use read-only where appropriate
- Test execution runs as non-root user

## Data Flow

### 1. Application Startup

```
docker-compose up
  → Create network: books-service-network
  → Create volumes: rf_docs_cache, rf_library_docs
  → Start books-service (FastAPI on port 8000, healthcheck begins)
  → Start initialization (creates DB, runs migrations, generates sample data)
  → Start robotframework-mcp (waits for MCP commands)
  → Start rf-docs-mcp (loads cached documentation)
```

### 2. Test Execution (On-Demand MCP)

```
IDE (MCP Client)
  → Prepares MCP request: {"method": "tools/call", "params": {"name": "run_suite", ...}}
  → Executes: docker exec -i robotframework-mcp python /app/server.py
  → Container spawns /app/server.py
    → Reads MCP request from stdin (JSON-RPC 2.0 format)
    → Executes robot command
      → Loads tests from /tests
      → Runs tests against http://books-service:8000
      → Generates reports in /results
    → Returns MCP response to stdout (JSON-RPC 2.0 format)
    → Process exits
  → IDE receives results, reports available in ./robot_results/
```

### 3. API Request Flow (UI Test)

```
Robot Test (Browser Library)
  → GET http://books-service:8000/
  → FastAPI serves static/index.html
  → JavaScript fetches: GET http://books-service:8000/books/
  → books-service queries SQLite (/app/data/books.db)
  → Returns JSON response
  → JavaScript renders book cards
```

## Configuration

### Environment Variables

**books-service:**
```bash
DATABASE_URL=sqlite:///data/books.db
```

**robotframework-mcp:**
```bash
ROBOT_OUTPUT_DIR=/results
RF_TESTS_DIR=/tests
BROWSER=chromium
HEADLESS=true
PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
```

**rf-docs-mcp:**
```bash
RF_DOCS_CACHE=/cache
```

### MCP Client Configuration

Generated by `./quick-start.sh` or `./RobotFramework-MCP-server/create-mcp-config.sh`:

| IDE               | Configuration File      | Generator Command                  |
|-------------------|-------------------------|------------------------------------|
| Claude Code       | `.claude.json`          | `create-mcp-config.sh claude-code` |
| VS Code (Copilot) | `.vscode/mcp.json`      | `create-mcp-config.sh vscode`      |
| GitLab Duo        | `.gitlab/duo/mcp.json`  | `create-mcp-config.sh gitlab`      |
| Amazon Q          | `.amazonq/default.json` | `create-mcp-config.sh amazonq`     |

**Example `.claude.json`:**
```json
{
  "mcpServers": {
    "RobotFramework": {
      "command": "/usr/bin/docker",
      "args": ["exec", "-i", "robotframework-mcp", "python", "/app/server.py"],
      "timeout": 60000
    },
    "rf-docs": {
      "command": "/usr/bin/docker",
      "args": ["exec", "-i", "rf-docs-mcp", "python", "/app/rf_docs_server.py"],
      "timeout": 60000
    }
  }
}
```

## Related Documentation

### Project Documentation

- [Root README](../README.md) - Project overview and quick start
- [Getting Started](getting-started.md) - Environment setup

### External Documentation

**MCP:**
- [MCP Specification](https://spec.modelcontextprotocol.io/)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
- [Claude Code MCP Guide](https://docs.anthropic.com/claude-code/mcp)

**Robot Framework:**
- [Robot Framework User Guide](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html)
- [Browser Library](https://marketsquare.github.io/robotframework-browser/Browser.html)
- [Robocop](https://robocop.readthedocs.io/)

**Docker & FastAPI:**
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Playwright Documentation](https://playwright.dev/)

---

**Glossary:**

| Term            | Definition |
|-----------------|------------|
| MCP             | Model Context Protocol - Application protocol for connecting AI assistants to external tools and data sources |
| JSON-RPC 2.0    | Message format used by MCP for encoding requests/responses (not the protocol itself) |
| FastMCP         | Python SDK for implementing MCP servers using FastAPI-like patterns |
| Robot Framework | Open-source test automation framework |
| Playwright      | Modern web automation library supporting Chromium, Firefox, and WebKit |
| Robocop         | Static code analysis tool for Robot Framework |
| stdin/stdout    | Standard input/output streams for process communication (MCP transport layer) |
| Headless Browser| Browser running without graphical interface, required in Docker environments |
| Named Volume    | Docker-managed storage persisting independently of containers |
| Bind Mount      | Direct mapping from host directory to container directory |

---

**Document Revision History:**

| Version | Date       | Changes |
|---------|------------|---------|
| 1.0     | Initial    | Initial architecture documentation |
| 1.1     | 2026-01-22 | Added prerequisites, corrected MCP execution model, added configuration, logging, troubleshooting |
| 1.2     | 2026-01-22 | Consolidated duplicate content, improved table formatting, reduced length by ~30% |
| 1.3     | 2026-01-22 | Clarified MCP vs JSON-RPC terminology: MCP is the protocol, JSON-RPC 2.0 is the message format |

… [Getting Started](getting-started.md) … [Development Workflow](development-workflow.md) … [Testing](testing.md) … [Troubleshooting](troubleshooting.md) …

Next: [Testing](testing.md)
