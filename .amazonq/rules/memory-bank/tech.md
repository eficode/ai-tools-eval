# Technology Stack

## Programming Languages
- **Python 3.12**: Primary language for application and scripts
- **JavaScript (ES6+)**: Frontend client-side logic
- **HTML5/CSS3**: Web UI markup and styling
- **Robot Framework**: Test automation DSL
- **Shell Script**: Environment setup and utilities

## Core Frameworks and Libraries

### Backend
- **FastAPI 0.115.11**: Modern async web framework
- **Uvicorn 0.29.0**: ASGI server
- **SQLAlchemy 2.0.29**: ORM and database toolkit
- **Pydantic 2.6.4**: Data validation and settings management

### Testing
- **pytest 8.1.1**: Python unit testing framework
- **httpx 0.27.0**: Async HTTP client for API testing
- **Robot Framework 7.4.1**: Keyword-driven test automation
- **Browser Library**: Playwright-based browser automation for Robot Framework

### Infrastructure
- **Docker**: Container runtime
- **Docker Compose**: Multi-container orchestration
- **SQLite**: Embedded relational database
- **MCP (Model Context Protocol) 1.25.0**: AI agent integration protocol

## Build Systems and Dependency Management

### Poetry (Primary)
```bash
# Defined in pyproject.toml
poetry install          # Install dependencies
poetry run dev-server   # Run development server
```

### Pip (Alternative)
```bash
# Defined in requirements.txt
pip install -r requirements.txt
```

### Docker Build
```bash
# Multi-stage builds for optimized images
docker-compose build
```

## Development Commands

### Environment Management
```bash
# Start entire environment (RECOMMENDED)
./quick-start.sh

# Stop all services
docker-compose down

# View logs
docker-compose logs -f books-service
docker-compose logs -f robotframework-mcp
```

### Application Development
```bash
# Run locally (without Docker)
poetry run dev-server
# or
python server.py

# Access application
# Web UI: http://localhost:8000
# API docs: http://localhost:8000/docs
```

### Database Operations
```bash
# Generate sample books
python scripts/generate_books.py

# Run migrations
python scripts/migrate_db.py

# Database location
data/books.db
```

### Testing
```bash
# Run Python unit tests
pytest

# Run specific test file
pytest tests/test_books.py

# Robot Framework tests (via MCP)
# Executed through AI agent MCP integration
# Results appear in robot_results/
```

### Code Quality
```bash
# Robot Framework linting
./run_robocop_audit.sh
```

## Environment Variables

### Books Service
- `DATABASE_URL`: SQLite connection string (default: `sqlite:///data/books.db`)

### Robot Framework MCP
- `ROBOT_OUTPUT_DIR`: Test results directory (default: `/results`)
- `RF_TESTS_DIR`: Test suites directory (default: `/tests`)
- `BROWSER`: Browser engine (default: `chromium`)
- `HEADLESS`: Headless mode flag (default: `true`)

### RF Docs MCP
- `RF_DOCS_CACHE`: Documentation cache directory (default: `/cache`)

## Port Mappings
- **8000**: Books service (API + Web UI)
- All MCP servers communicate via Docker network (no host ports)

## IDE Integration
- **VS Code**: Reload window after `quick-start.sh` to activate MCP servers
- **Command Palette**: "Developer: Reload Window"
- MCP servers appear in IDE for AI agent interaction

## Version Constraints
- Python: `^3.12` (Poetry) or `>=3.12`
- FastAPI: `>=0.110.1,<0.111.0`
- SQLAlchemy: `>=2.0.29,<2.1.0`
- Pydantic: `>=2.6.4,<2.7.0`
- Robot Framework: `7.4.1` (in MCP container)
