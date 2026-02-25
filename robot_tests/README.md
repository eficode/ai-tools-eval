# Robot Framework Test Suite - Books Database Service

## Overview

This test suite provides comprehensive UI and API testing for the Books Database Service using Robot Framework 7.4.1 with modern syntax and Gherkin-style test cases.

## Generated Files

### Test Suites

1. **`books_ui.robot`** - UI Test Suite (9 test cases)
   - View all books
   - Search functionality
   - Clear search
   - Negative scenarios
   - Page title verification
   - Performance testing

2. **`books_api.robot`** - API Test Suite (9 test cases)
   - Create books (POST)
   - Retrieve books (GET)
   - Update books (PUT)
   - Delete books (DELETE)
   - Error handling (404, 422)
   - Multiple book creation
   - Concurrent requests

### Resource Files

1. **`resources/common.resource`** - Shared utilities
   - Common variables (URLs, timeouts, browser settings)
   - Test data generation keywords
   - Utility keywords (Wait For Element And Click, etc.)
   - Screenshot and logging utilities

2. **`resources/BooksPageUI.resource`** - UI Page Object
   - Page navigation keywords
   - Element selectors
   - UI interaction keywords
   - Verification keywords

3. **`resources/BooksAPI.resource`** - API interactions
   - Session management
   - CRUD operation keywords
   - Response validation keywords
   - Data extraction utilities

## Architecture

### Modern RF 7.4.1 Syntax

All tests use modern Robot Framework 7.4.1 syntax:
- ✅ `VAR` for variable declaration
- ✅ `IF/ELSE` for conditionals
- ✅ `FOR` loops (not `:FOR`)
- ✅ `TRY/EXCEPT` for error handling
- ✅ Native Python expressions
- ❌ No legacy keywords (Set Variable, Run Keyword If, etc.)

### Gherkin Pattern

All test cases follow Gherkin syntax:
```robotframework
Given User Opens The Books Application
When User Navigates To Books Page
Then All Books Should Be Displayed
And Book Count Should Be Greater Than Zero
```

### Page Object Model

UI tests follow the Page Object Model pattern:
- Test cases contain business logic (Gherkin steps)
- Page objects contain implementation details
- Clear separation of concerns

## Running Tests

### Run All Tests
```bash
robot robot_tests/
```

### Run UI Tests Only
```bash
robot robot_tests/books_ui.robot
```

### Run API Tests Only
```bash
robot robot_tests/books_api.robot
```

### Run by Tags
```bash
# Smoke tests only
robot --include smoke robot_tests/

# High priority tests
robot --include priority-high robot_tests/

# API tests excluding negative scenarios
robot --include api --exclude negative robot_tests/
```

## Test Tags

### Test Level
- `smoke` - Critical path tests
- `regression` - Full regression suite

### Feature
- `ui` - UI tests
- `api` - API tests

### Priority
- `priority-high` - Must run on every commit
- `priority-medium` - Run daily
- `priority-low` - Run weekly

### Type
- `create` - Create operations
- `read` - Read operations
- `update` - Update operations
- `delete` - Delete operations
- `search` - Search functionality
- `validation` - Validation tests
- `error-handling` - Error handling tests
- `negative` - Negative test scenarios
- `performance` - Performance tests

## Test Data Management

### Data Isolation
All tests generate unique test data using timestamps:
```robotframework
VAR    &{book_data}    Generate Unique Book Data
```

### Cleanup
- **Suite Teardown**: Closes sessions, logs duration
- **Test Teardown**: Deletes test books, takes screenshots on failure

### Read-Only Database
Tests do not modify existing records. All test data is:
- Created with unique identifiers
- Cleaned up after test execution
- Isolated from other tests

## Configuration

### Variables (resources/common.resource)
```robotframework
${BASE_URL}               http://books-service:8000
${BROWSER}                chromium
${HEADLESS}               ${True}
${DEFAULT_TIMEOUT}        10s
```

### Browser Settings
- Browser: Chromium
- Headless: True
- Viewport: 1920x1080

### API Settings
- Base URL: http://books-service:8000
- Timeout: 30s
- SSL Verification: True

## Test Results

Results are saved to `../robot_results/`:
- `log.html` - Detailed test execution log
- `report.html` - Test execution report
- `output.xml` - Machine-readable results

## Dependencies

- Robot Framework 7.4.1
- Browser Library 19.12.3
- RequestsLibrary 0.9.7
- Collections (standard library)
- DateTime (standard library)
- String (standard library)

## Standards Compliance

All tests comply with `ROBOT_FRAMEWORK_STANDARDS.md`:
- Modern RF 7.4.1 syntax
- Gherkin-style test cases
- Page Object Model for UI
- Explicit waits (no Sleep)
- Comprehensive documentation
- Proper error handling
- Test independence

## Test Coverage

### UI Tests (9 test cases)
1. ✅ View all books
2. ✅ Search for books by title
3. ✅ Clear search and see all books
4. ✅ Search for nonexistent book (negative)
5. ✅ Verify page title
6. ✅ Performance - books load quickly

### API Tests (9 test cases)
1. ✅ Create new book (POST)
2. ✅ Retrieve all books (GET)
3. ✅ Retrieve book details (GET by ID)
4. ✅ Update book information (PUT)
5. ✅ Delete book (DELETE)
6. ✅ 404 for nonexistent book (negative)
7. ✅ 422 validation error (negative)
8. ✅ Create multiple books
9. ✅ Handle concurrent requests

## Example Test Execution

```bash
# Run smoke tests
robot --include smoke robot_tests/

# Output:
# ==============================================================================
# Books UI Test Suite                                                          
# ==============================================================================
# User Should Be Able To View All Books                                | PASS |
# ------------------------------------------------------------------------------
# Books API Test Suite                                                         
# ==============================================================================
# User Should Be Able To Create A New Book Via API                     | PASS |
# ==============================================================================
# 2 tests, 2 passed, 0 failed
# ==============================================================================
```

## Troubleshooting

### Browser Tests Fail
- Ensure Browser library is initialized: `rfbrowser init`
- Check headless mode setting
- Verify viewport size is appropriate

### API Tests Fail
- Verify Books service is running: `curl http://localhost:8000/health`
- Check API session is created in suite setup
- Verify network connectivity

### Cleanup Issues
- Check test teardown logs
- Verify DELETE permissions
- Ensure book IDs are tracked correctly

## Contributing

When adding new tests:
1. Follow Gherkin syntax for test cases
2. Use modern RF 7.4.1 syntax only
3. Add appropriate tags
4. Document all keywords
5. Ensure test independence
6. Generate unique test data
7. Clean up in teardown

## License

This test suite is part of the Books Database Service project.
