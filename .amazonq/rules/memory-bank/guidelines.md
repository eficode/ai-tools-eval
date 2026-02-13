# Development Guidelines

## Code Quality Standards

### Python Code Formatting
- **Docstrings**: Comprehensive module-level docstrings with tool descriptions and parameter lists (5/5 files)
- **Type Hints**: Consistent use of typing annotations for parameters and return values (4/5 files)
- **Import Organization**: Standard library imports first, then third-party, then local imports with clear separation
- **Line Length**: Generally follows PEP 8 guidelines with reasonable line breaks
- **String Formatting**: Consistent use of f-strings for variable interpolation

### JavaScript Code Standards
- **ES6+ Features**: Modern JavaScript with const/let, arrow functions, async/await patterns
- **Function Organization**: Clear separation between utility functions, event handlers, and API calls
- **Error Handling**: Comprehensive try-catch blocks with user-friendly error messages
- **DOM Manipulation**: Efficient DOM queries with proper event listener management

### Documentation Standards
- **API Documentation**: FastAPI endpoints include summary, description, and response_description fields
- **Parameter Documentation**: Detailed parameter descriptions with examples in API routes
- **Tool Documentation**: MCP tools have comprehensive docstrings with parameter types and usage examples
- **Inline Comments**: Strategic comments explaining complex logic and business rules

## Architectural Patterns

### MCP Server Implementation Pattern
```python
from mcp.server.fastmcp import FastMCP
mcp = FastMCP(APP_NAME)

@mcp.tool()
def tool_name(param: str, optional_param: Optional[str] = None) -> Dict:
    """Tool description with parameters and return value documentation."""
    # Implementation with comprehensive error handling
    return {"success": True, "data": result}
```

### FastAPI Route Pattern
```python
@router.method("/path", response_model=Model,
              summary="Brief description",
              description="Detailed description",
              response_description="Response description")
def endpoint_name(param: Type = Depends(dependency)):
    # Implementation with proper error handling
    return response_object
```

### Database Operations Pattern
```python
# Query pattern with error handling
db_object = db.query(Model).filter(Model.field == value).first()
if db_object is None:
    raise HTTPException(status_code=404, detail="Object not found")
```

## Error Handling Conventions

### Python Exception Handling
- **Subprocess Operations**: Always use try-catch with timeout handling for external commands
- **File Operations**: Path validation and existence checks before file operations
- **Database Operations**: Proper SQLAlchemy session management with rollback capabilities
- **HTTP Errors**: Consistent HTTPException usage with appropriate status codes and messages

### JavaScript Error Handling
- **API Calls**: Comprehensive error handling with user notifications
- **Form Validation**: Client-side validation with clear error messages
- **Async Operations**: Proper promise rejection handling with fallback behaviors

## Security Practices

### Path Security
- **Path Validation**: Absolute path resolution with security checks to prevent directory traversal
- **Input Sanitization**: Proper validation of user inputs before processing
- **Command Injection Prevention**: Use of shlex.quote() for shell command construction

### API Security
- **Input Validation**: Pydantic models for request validation
- **Error Messages**: Generic error messages that don't expose internal system details
- **Resource Access**: Proper authorization checks before resource access

## Performance Optimization

### Database Patterns
- **Efficient Queries**: Direct SQLAlchemy queries without unnecessary joins
- **Session Management**: Proper database session lifecycle management
- **Bulk Operations**: Efficient bulk insert patterns for data generation

### Frontend Performance
- **Debounced Search**: Input debouncing to prevent excessive API calls
- **Pagination**: Client-side pagination with load-more functionality
- **State Management**: Efficient state updates with minimal DOM manipulation

## Testing and Quality Assurance

### Code Quality Tools
- **Robocop Integration**: Automated Robot Framework code quality auditing
- **Subprocess Testing**: Comprehensive testing of external tool integrations
- **Error Path Testing**: Explicit testing of error conditions and edge cases

### Development Workflow
- **Branch Naming**: Structured branch naming convention: `<Round>/<Tool>/<Model>`
- **Commit Messages**: Descriptive commit messages with appropriate prefixes
- **Environment Isolation**: Docker containerization for consistent development environments

## Common Implementation Patterns

### Configuration Management
- **Environment Variables**: Consistent use of os.getenv() with sensible defaults
- **Path Constants**: Centralized path configuration with environment variable overrides
- **Version Pinning**: Explicit version specifications for external dependencies

### Data Processing
- **JSON Handling**: Robust JSON parsing with error handling and validation
- **File Processing**: Streaming file operations for large files with progress tracking
- **Data Transformation**: Clear separation between data fetching, processing, and presentation

### User Interface Patterns
- **Progressive Enhancement**: Base functionality with enhanced features
- **Responsive Design**: Mobile-first approach with flexible layouts
- **User Feedback**: Immediate feedback for user actions with loading states and notifications