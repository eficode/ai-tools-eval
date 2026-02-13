# Project Structure

## Directory Organization

### Core Application (`fastapi_demo/`)
- **Purpose**: Stable books database service (DO NOT MODIFY)
- **Components**:
  - `main.py` - FastAPI application entry point
  - `models.py` - SQLAlchemy database models
  - `database.py` - Database configuration and connection
  - `dtos.py` - Pydantic data transfer objects
  - `routers/books.py` - Books API endpoints
  - `static/` - Web UI files (HTML, CSS, JavaScript)

### Test Infrastructure
- **`robot_tests/`** - Robot Framework test suites (AI-generated content goes here)
- **`robot_results/`** - Test execution results and artifacts
- **`tests/`** - Python unit tests for the application

### MCP Servers (`RobotFramework-MCP-server/`)
- **`server.py`** - Robot Framework execution MCP server
- **`rf_docs_server.py`** - Robot Framework documentation MCP server
- **Docker configurations** - Containerized MCP server setup

### Supporting Infrastructure
- **`scripts/`** - Database utilities (migration, data generation)
- **`data/`** - SQLite database storage
- **`docs/`** - Project documentation
- **`template/`** - Test generation templates and standards
- **`chat/`** - AI conversation logs and artifacts

### Configuration Files
- **`docker-compose.yml`** - Multi-service container orchestration
- **`pyproject.toml`** - Python project dependencies and metadata
- **`quick-start.sh`** - One-command environment setup
- **`.amazonq/rules/`** - Amazon Q IDE integration rules

## Architectural Patterns

### Service Architecture
- **Books Service**: FastAPI REST API with SQLite database
- **MCP Servers**: Containerized Robot Framework execution and documentation services
- **Web UI**: Static frontend consuming the REST API

### Test Architecture
- **Robot Framework**: Primary test automation framework
- **MCP Integration**: Model Context Protocol for AI-driven test execution
- **Containerization**: Isolated test execution environment with browser automation

### Data Flow
1. AI tools generate Robot Framework tests in `robot_tests/`
2. MCP servers execute tests against the books service
3. Results stored in `robot_results/` with screenshots and traces
4. Different AI tools/models use separate git branches for comparison

## Component Relationships
- Books Service provides the stable application under test
- MCP servers bridge AI tools with Robot Framework execution
- Test infrastructure captures and organizes results for comparison
- Git branching isolates different AI tool approaches