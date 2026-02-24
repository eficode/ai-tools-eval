# Project Structure

## Directory Organization

### Application Code (DO NOT MODIFY)
```
fastapi_demo/
├── routers/          # API route handlers
│   └── books.py      # Books CRUD endpoints
├── static/           # Frontend assets
│   ├── index.html    # Web UI
│   ├── script.js     # Client-side logic
│   └── styles.css    # UI styling
├── tests/            # Application unit tests
├── database.py       # SQLAlchemy database setup
├── dtos.py           # Pydantic data transfer objects
├── main.py           # FastAPI application entry point
└── models.py         # SQLAlchemy ORM models
```

### Test Generation Area (FOCUS HERE)
```
robot_tests/          # Generated Robot Framework test suites
robot_results/        # Test execution results and reports
```

### MCP Servers
```
RobotFramework-MCP-server/
├── server.py         # Robot Framework test execution MCP server
├── rf_docs_server.py # Robot Framework documentation MCP server
├── Dockerfile        # Container for test execution
└── Dockerfile.docs   # Container for documentation server
```

### Infrastructure
```
scripts/
├── generate_books.py # Database seeding script
└── migrate_db.py     # Database migration script

data/
└── books.db          # SQLite database file

docs/
├── getting-started.md
├── development-workflow.md
├── architecture.md
├── testing.md
└── troubleshooting.md

template/
├── Instruction Template.txt
└── Test Standards.txt
```

### Configuration Files
```
docker-compose.yml    # Multi-service orchestration
Dockerfile            # Books service container
pyproject.toml        # Poetry dependency management
requirements.txt      # Pip dependencies
pytest.ini            # Pytest configuration
quick-start.sh        # One-step environment startup
```

## Core Components and Relationships

### 1. Books Service (books-service)
- FastAPI application serving REST API and web UI
- Port 8000 exposed to host
- Depends on SQLite database in `data/books.db`
- Health check endpoint for container orchestration

### 2. Initialization Service
- Runs once on startup
- Creates database tables via SQLAlchemy
- Executes migrations
- Seeds sample data if database is empty
- Exits after completion

### 3. Robot Framework MCP (robotframework-mcp)
- Executes Robot Framework tests on demand
- Mounts `robot_tests/` as read-only
- Writes results to `robot_results/`
- Includes Browser library with Chromium
- Runs headless for CI/CD compatibility

### 4. RF Docs MCP (rf-docs-mcp)
- Provides Robot Framework 7.4.1 documentation
- Answers keyword and library queries
- Uses cached documentation for performance
- Supports AI agents during test generation

## Architectural Patterns

### Service Architecture
- **Microservices**: Four independent Docker containers
- **Service Discovery**: Docker network `books-service-network`
- **Health Checks**: Ensures books-service is ready before initialization
- **Volume Mounts**: Shared data and test directories

### Application Architecture
- **MVC Pattern**: Routers (controllers), Models (ORM), Static (views)
- **Dependency Injection**: FastAPI's built-in DI for database sessions
- **DTO Pattern**: Pydantic models for request/response validation
- **Repository Pattern**: Database operations abstracted in routers

### Testing Architecture
- **Test Isolation**: Robot tests run in separate container
- **Results Persistence**: Mounted volume preserves test reports
- **MCP Integration**: AI agents interact via Model Context Protocol
- **Browser Automation**: Playwright-based Browser library for UI testing

## Branch Strategy
- **main**: Stable baseline (no merges from test branches)
- **Test branches**: `<round>/<tool>/<model>` (e.g., `r1/claudecode/sonnet4`)
- Each branch represents one AI tool's test generation attempt
- Branches remain separate for comparison purposes
