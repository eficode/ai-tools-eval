# Development Guidelines

## Code Quality Standards

### Documentation Patterns
- **Module-level docstrings**: All Python modules start with triple-quoted docstrings describing purpose, tools, and functionality
- **Function docstrings**: MCP tools use structured docstrings with Parameters and Returns sections
- **Inline comments**: Used sparingly for complex logic; code should be self-documenting
- **API documentation**: FastAPI endpoints include `summary`, `description`, and `response_description` parameters

Example from rf_docs_server.py:
```python
@mcp.tool()
def fetch_rf_documentation(force_refresh: bool = False) -> Dict:
    """
    Download Robot Framework 7.4.1 documentation for all standard libraries.
    
    Parameters:
      - force_refresh: If True, re-download even if cached (default: False)
    
    Returns:
      - success: Boolean indicating if download succeeded
      - version: RF version (always 7.4.1)
      - files_downloaded: List of downloaded files
    """
```

### Naming Conventions
- **Functions**: snake_case for all functions and methods (`fetch_rf_documentation`, `generate_books`)
- **Variables**: snake_case for local variables (`db_book`, `file_stat`, `keyword_name_lower`)
- **Constants**: UPPER_SNAKE_CASE for module-level constants (`DEFAULT_TESTS`, `RF_VERSION`, `API_URL`)
- **Classes**: PascalCase for class names (`DocumentationParser`, `BookCreate`, `BookInfo`)
- **Private functions**: Prefix with underscore (`_download_file`, `_parse_documentation`, `_robot_cmd`)

### Code Structure
- **Imports organization**: Standard library → Third-party → Local imports, separated by blank lines
- **Path handling**: Use `pathlib.Path` for file operations, not string concatenation
- **Environment variables**: Access via `os.getenv()` with sensible defaults
- **Error handling**: Try-except blocks return structured error dictionaries with `success`, `error`, and `hint` keys

Example from server.py:
```python
try:
    from robot.api import TestSuiteBuilder
    suite = TestSuiteBuilder().build(suite_path)
    # ... processing logic
    return {"count": len(names), "tests": names}
except Exception as e:
    return {"error": str(e), "hint": "Check suite_path and Robot syntax."}
```

## Semantic Patterns

### API Response Structure
All MCP tools and API endpoints return consistent dictionary structures:
- **Success responses**: Include `success: True`, relevant data fields, and metadata
- **Error responses**: Include `success: False`, `error` message, and optional `hint` for resolution
- **Metadata**: Version info, timestamps, file paths, and counts where applicable

Example from rf_docs_server.py:
```python
return {
    "success": True,
    "version": RF_VERSION,
    "library": library_name,
    "total_keywords": len(keyword_list),
    "keywords": keyword_list
}
```

### Database Operations Pattern
FastAPI routers follow consistent CRUD patterns:
1. Query database using SQLAlchemy ORM
2. Check for None and raise HTTPException(404) if not found
3. Convert ORM models to Pydantic DTOs using `**model.__dict__`
4. Commit changes and refresh before returning

Example from books.py:
```python
@router.put("/{book_id}", response_model=BookInfo)
def update_book(book_id: int, book: BookCreate, db: Session = Depends(get_db)):
    db_book = db.query(Book).filter(Book.id == book_id).first()
    if db_book is None:
        raise HTTPException(status_code=404, detail="Book not found")
    for key, value in book.model_dump().items():
        setattr(db_book, key, value)
    db.commit()
    db.refresh(db_book)
    return BookInfo(**db_book.__dict__)
```

### Subprocess Execution Pattern
When running external commands (robot, robocop, rebot):
1. Build command as list of strings
2. Use `subprocess.run()` with `capture_output=True`, `text=True`
3. Set timeout to prevent hanging
4. Return structured dict with `returncode`, `command`, `stdout`, `stderr`, `artifacts`
5. Truncate output to prevent overwhelming responses (e.g., `[-10000:]`)

Example from server.py:
```python
def _run(cmd: List[str]) -> Dict:
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return {
        "returncode": p.returncode,
        "command": " ".join(shlex.quote(c) for c in cmd),
        "stdout": p.stdout[-10000:],
        "stderr": p.stderr[-10000:],
        "artifacts": {
            "output_xml": str(Path(DEFAULT_RESULTS) / "output.xml"),
            "log_html": str(Path(DEFAULT_RESULTS) / "log.html"),
            "report_html": str(Path(DEFAULT_RESULTS) / "report.html"),
        },
    }
```

### File Caching Pattern
Documentation and data files use caching with version-specific filenames:
- Check if file exists before downloading/processing
- Use version numbers in filenames (`RobotFrameworkUserGuide_7.4.1.html`)
- Store metadata alongside cached data (timestamps, counts)
- Provide `force_refresh` parameter to bypass cache

Example from rf_docs_server.py:
```python
DOCS_FILE = CACHE_DIR / f"RobotFrameworkUserGuide_{RF_VERSION}.html"

if force_refresh or not DOCS_FILE.exists():
    result = _download_file(RF_DOCS_URL, DOCS_FILE)
else:
    result = {"success": True, "cached": True, "path": str(DOCS_FILE)}
```

### Frontend State Management
JavaScript uses centralized state object pattern:
- Single `state` object holds all application data
- Separate nested objects for filters, sort, pagination
- State mutations trigger UI updates via `applyFiltersAndSort()` and `displayBooks()`
- Event listeners update state, then call render functions

Example from script.js:
```javascript
const state = {
    books: [],
    filteredBooks: [],
    filters: {
        search: '',
        category: 'all',
        favorite: false
    },
    sort: {
        by: 'title',
        ascending: true
    },
    pagination: {
        page: 1,
        limit: 12,
        hasMore: false
    }
};
```

## Frequently Used Code Idioms

### Dictionary Unpacking for Model Conversion
```python
# ORM to DTO conversion
return BookInfo(**db_book.__dict__)

# DTO to ORM creation
db_book = Book(**book.model_dump())
```

### Path Safety and Validation
```python
# Ensure directory exists before file operations
Path(DEFAULT_RESULTS).mkdir(parents=True, exist_ok=True)

# Validate path is within allowed directory
safe_path = os.path.abspath(target_path)
if not safe_path.startswith(os.path.abspath(DEFAULT_TESTS)):
    return {"error": "Invalid path"}
```

### Async/Await for API Calls (Frontend)
```javascript
async function fetchBooks() {
    try {
        const response = await fetch(API_URL);
        if (!response.ok) {
            throw new Error('Failed to fetch books');
        }
        state.books = await response.json();
        displayBooks(state.filteredBooks);
    } catch (error) {
        showNotification('Error fetching books', 'error');
    }
}
```

### Debouncing User Input
```javascript
searchInput.addEventListener('input', debounce(() => {
    state.filters.search = searchInput.value.trim().toLowerCase();
    applyFiltersAndSort();
}, 300));
```

### Conditional Rendering with Ternary Operators
```javascript
// JavaScript
sortDirectionBtn.querySelector('i').className = state.sort.ascending 
    ? 'fas fa-sort-up' 
    : 'fas fa-sort-down';

// Python
display_content = content[:5000] + "\\n\\n... (truncated)" if truncated else content
```

## Testing Standards

### Test Organization
- Unit tests in `tests/` directory mirror application structure
- Robot Framework tests in `robot_tests/` directory
- Test results and reports in `robot_results/` directory
- Use pytest for Python unit tests with fixtures in `conftest.py`

### Test Execution
- Robot tests executed via MCP server tools (`run_suite`, `run_test_by_name`)
- Python tests run with `pytest` command
- Code quality audits with `robocop` tool
- All test artifacts preserved with timestamps

## Security Practices

### Path Traversal Prevention
Always validate and sanitize file paths before operations:
```python
# Validate path is within allowed directory
safe_path = os.path.abspath(target_path)
if not safe_path.startswith(os.path.abspath(DEFAULT_TESTS)):
    return {"error": f"Invalid path: {target_path}"}
```

### Input Validation
- Use Pydantic models for API request validation
- Type hints on all function parameters
- Validate required fields before processing
- Return structured errors for invalid input

### Error Information Disclosure
- Return generic error messages to users
- Log detailed errors internally
- Include helpful hints without exposing system details

## Performance Optimizations

### Output Truncation
Prevent overwhelming responses by truncating large outputs:
```python
"stdout": p.stdout[-10000:]  # Last 10000 characters
"content_preview": section.get("content", "")[:300] + "..."
```

### Pagination
Frontend implements load-more pagination:
- Initial load shows 12 items
- "Load More" button fetches next page
- Tracks `hasMore` state to hide button when exhausted

### Caching
- Cache downloaded documentation files
- Store parsed indexes as JSON
- Use version-specific cache keys
- Provide force refresh option

## Common Annotations and Decorators

### FastAPI Route Decorators
```python
@router.get("/", response_model=List[BookInfo],
         summary="Get all books",
         description="This endpoint retrieves all books from the database",
         response_description="A list of all books")
```

### MCP Tool Decorator
```python
@mcp.tool()
def run_suite(suite_path: str = DEFAULT_TESTS, ...) -> Dict:
    """Run an entire Robot Framework suite/folder."""
```

### Dependency Injection
```python
def read_books(db: Session = Depends(get_db)):
    # db session automatically injected
```

## Application-Specific Conventions

### Robot Framework Integration
- Browser library with Chromium for UI testing
- Headless mode enabled by default
- Variables passed via `-v` flag: `BROWSER:chromium`, `HEADLESS:true`
- Output directory always specified with `--outputdir`

### MCP Server Patterns
- Use FastMCP framework for tool registration
- Tools return Dict with structured data
- Run server with `mcp.run()` in `__main__`
- Container entrypoint uses `tail -f /dev/null` to keep alive

### Docker Compose Services
- Health checks for dependent services
- Volume mounts for data persistence and test execution
- Environment variables for configuration
- Restart policies: `unless-stopped` for services, `on-failure` for initialization

### Branch Naming
Follow strict convention for test generation branches:
- Pattern: `<round>/<tool>/<model>`
- Examples: `r1/claudecode/sonnet4`, `r2/copilot/sonnet45`
- Never merge test branches to main
- Each branch represents one AI tool evaluation
