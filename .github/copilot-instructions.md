# AI Tools Evaluation - Robot Framework Test Generation

## Project Purpose

This codebase is specifically designed for **AI tools evaluation** focused on Robot Framework test generation. The Books API application serves as a stable baseline - **DO NOT modify any application code in `fastapi_demo/`**. Your role is generating comprehensive Robot Framework test suites.

## Critical Constraints

- **Application code is immutable**: Never modify files in `fastapi_demo/`, `server.py`, or Docker configuration
- **Focus area**: Generate Robot Framework tests in `robot_tests/` and related documentation
- **Test execution**: Use MCP tools only - never run `robot` commands directly in terminal

## Development Workflow

### Environment Setup
```bash
# Always start with this one command
./quick-start.sh

# Reload VS Code after setup to activate MCP servers
# Command Palette → "Developer: Reload Window"
```

### Branching Convention
Follow the strict pattern: `r<Round>_<Tool>_<Model>`
```bash
git checkout -b r1_Copilot_Sonnet-4.5
git checkout -b r2_AmazonQ_Sonnet-4.5
```

## Architecture Overview

- **Books API**: FastAPI service on `localhost:8000` with SQLite backend
- **MCP Integration**: Robot Framework execution and documentation via Model Context Protocol
- **Test Structure**: Tests in `robot_tests/`, results in `robot_results/`
- **Containers**: Docker Compose setup with shared volumes for test data

### Key Endpoints (Application Under Test)
- Web UI: `http://localhost:8000`
- API Documentation: `http://localhost:8000/docs`
- Books API: `http://localhost:8000/books/` (GET, POST, PUT, DELETE operations)

## Robot Framework Testing Patterns

### Directory Structure
```
robot_tests/           # Your test suites go here
robot_results/         # Test execution results (auto-generated)
RobotFramework-MCP-server/  # MCP server for test execution
```

### Test Execution via MCP
- Use IDE's MCP integration (not direct robot commands)
- Available MCP tools: `run_suite`, `run_test_by_name`, `list_tests`, `run_robocop_audit`
- Default variables: `BROWSER=chromium`, `HEADLESS=true`

### Application Data Model
Books have fields: `id`, `title`, `author`, `year`, `favorite` (boolean)
- SQLite database at `/app/data/books.db` (container path)
- Sample data populated on startup via initialization service

## Testing Guidelines

### Browser Testing
- Use Browser Library (Playwright) for UI tests
- Tests run in headless Chromium by default
- Target: `http://localhost:8000` for web interface

### API Testing  
- Use RequestsLibrary for API tests
- Target: `http://localhost:8000/books/` endpoints
- OpenAPI docs available for reference

### Code Quality
- Run `run_robocop_audit` via MCP for Robot Framework code quality checks
- Follow Robot Framework naming conventions and best practices

## Common Patterns from Codebase

### FastAPI Router Structure
```python
# Books router pattern (for API test reference)
@router.get("/", response_model=List[BookInfo])    # List all books
@router.post("/", response_model=BookInfo)         # Create book
@router.get("/{book_id}", response_model=BookInfo) # Get book by ID
@router.put("/{book_id}", response_model=BookInfo) # Update book
@router.delete("/{book_id}")                       # Delete book
```

### Database Schema Reference
```python
# Book model (for test data validation)
class Book(Base):
    id: int (primary key)
    title: str
    author: str  
    year: int
    favorite: bool = False
```

## Documentation Structure

Update docs in `docs/` if creating test-related documentation. Key files:
- `docs/testing.md` - Testing procedures and patterns
- `docs/architecture.md` - System architecture overview
- `docs/troubleshooting.md` - Common issues and solutions

## Key Files to Reference

- [`fastapi_demo/routers/books.py`](fastapi_demo/routers/books.py) - API endpoints and request/response patterns
- [`fastapi_demo/models.py`](fastapi_demo/models.py) - Database schema
- [`fastapi_demo/static/index.html`](fastapi_demo/static/index.html) - UI structure for web tests  
- [`RobotFramework-MCP-server/server.py`](RobotFramework-MCP-server/server.py) - MCP tools and Robot execution patterns
- [`docs/testing.md`](docs/testing.md) - Testing procedures and MCP usage

Remember: Generate comprehensive Robot Framework test suites that thoroughly exercise both the API and UI components of the Books application.