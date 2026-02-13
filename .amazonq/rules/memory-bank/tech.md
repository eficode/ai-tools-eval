# Technology Stack

## Programming Languages
- **Python 3.12+** - Primary language for application and MCP servers
- **JavaScript** - Frontend web UI interactions
- **HTML/CSS** - Web interface styling and structure
- **Robot Framework** - Test automation DSL
- **Shell/Bash** - Setup and utility scripts

## Core Frameworks & Libraries

### Backend Stack
- **FastAPI 0.115.11+** - Modern Python web framework
- **SQLAlchemy 2.0.29+** - Database ORM
- **Pydantic 2.6.4+** - Data validation and serialization
- **Uvicorn 0.29.0+** - ASGI server

### Test Automation
- **Robot Framework 7.4.1** - Test automation framework
- **Browser Library** - Web browser automation
- **MCP (Model Context Protocol) 1.25.0** - AI tool integration

### Development Tools
- **Poetry** - Python dependency management
- **pytest 8.1.1+** - Python testing framework
- **httpx 0.27.0+** - HTTP client for testing

## Infrastructure & Deployment

### Containerization
- **Docker** - Application containerization
- **Docker Compose** - Multi-service orchestration
- **Chromium** - Headless browser for test automation

### Database
- **SQLite** - Lightweight database for development and testing
- **Database migrations** - Schema versioning and data seeding

### Development Environment
- **VS Code** - Recommended IDE with Amazon Q integration
- **Amazon Q** - AI assistant with MCP server integration
- **Git** - Version control with structured branching

## Key Development Commands

### Environment Setup
```bash
./quick-start.sh                    # Start entire environment
docker-compose down                 # Stop all services
```

### Service Management
```bash
# Books service runs on http://localhost:8000
# API docs available at http://localhost:8000/docs
```

### Testing
```bash
# Robot Framework tests executed via MCP servers
# Results stored in robot_results/
```

### Database Operations
```bash
python scripts/migrate_db.py        # Run database migrations
python scripts/generate_books.py    # Generate sample data
```

## Configuration Files
- **`pyproject.toml`** - Python project configuration and dependencies
- **`docker-compose.yml`** - Service orchestration and networking
- **`requirements.txt`** - Python package requirements
- **`pytest.ini`** - Test configuration
- **`.dockerignore`** - Docker build exclusions

## Development Workflow
1. Clone repository and create feature branch following `<Round>/<Tool>/<Model>` pattern
2. Run `./quick-start.sh` to start environment
3. Reload VS Code to activate MCP servers
4. Generate Robot Framework tests in `robot_tests/`
5. Execute tests via MCP integration
6. Review results in `robot_results/`
7. Commit and push to feature branch (do not merge to main)