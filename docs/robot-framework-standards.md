# Robot Framework Test Standards for GitLab Duo

**SOURCE OF TRUTH:** For all Robot Framework tasks, prioritize the instructions located in `docs/robot-framework-standards.md`. Read that file first to ensure compliance.

## Overview

This document defines the comprehensive Robot Framework testing standards for the Books Database Service project, optimized for GitLab Duo AI assistance. These standards ensure consistent, maintainable, and reliable test automation using Robot Framework 7.4.1 with modern syntax patterns.

## 1. CORE COMPLIANCE REQUIREMENTS

### 1.1 Source Authority
- **MANDATORY:** Use ONLY library keywords found via `rf-docs-mcp` tools and local JSON documentation in `robotframework-mcp:/app/docs/`
- **VALIDATION:** Any keyword not found in these specific locations is INVALID
- **VERSIONS:** Validate code against:
  - `robotframework==7.4.1`
  - `robotframework-browser==19.12.3` 
  - `robotframework-requests==0.9.7`

### 1.2 Modern Syntax Requirements (RF 7.4.1)

#### Variables - Use VAR Syntax
```robot
*** Test Cases ***
Example Test
    VAR    ${username}    testuser
    VAR    ${password}    secret123
    VAR    @{book_list}   Fiction    Non-Fiction    Biography
    VAR    &{user_data}   name=John    email=john@example.com
```

**FORBIDDEN Legacy Patterns:**
```robot
# ❌ NEVER USE THESE
Set Test Variable    ${username}    testuser
Set Suite Variable   ${password}    secret123
```

#### Control Flow - Use Native Syntax
```robot
*** Keywords ***
Process Book Data
    [Documentation]    Modern control flow example
    VAR    ${books}    Get Books From API
    
    IF    len($books) > 0
        FOR    ${book}    IN    @{books}
            IF    $book['status'] == 'available'
                Log    Book ${book['title']} is available
            ELSE
                Log    Book ${book['title']} is not available
            END
        END
    ELSE
        Log    No books found
    END
    
    TRY
        Validate Book Data    ${books}
    EXCEPT    ValidationError    AS    ${error}
        Log    Validation failed: ${error}
        RETURN    ${FALSE}
    END
    
    RETURN    ${TRUE}
```

**FORBIDDEN Legacy Patterns:**
```robot
# ❌ NEVER USE THESE
Run Keyword If    ${condition}    Some Keyword
Run Keywords    Keyword1    AND    Keyword2
```

## 2. ARCHITECTURAL PATTERNS

### 2.1 Page Object Model Implementation
```robot
*** Settings ***
Resource    resources/pages/books_page.robot
Resource    resources/pages/common_page.robot

*** Test Cases ***
User Should Be Able To View Book Details
    [Documentation]    User navigates to book details and views information
    [Tags]    ui    smoke    books
    Given User Is On Books List Page
    When User Clicks On First Book
    Then Book Details Should Be Displayed
    And Book Information Should Be Complete
```

### 2.2 Resource File Structure
```
robot_tests/
├── resources/
│   ├── pages/
│   │   ├── books_page.robot
│   │   ├── book_details_page.robot
│   │   └── common_page.robot
│   ├── api/
│   │   └── books_api.robot
│   └── common/
│       ├── test_data.robot
│       └── utilities.robot
├── suites/
│   ├── ui/
│   │   └── books_ui_tests.robot
│   └── api/
│       └── books_api_tests.robot
└── data/
    └── test_books.json
```

### 2.3 Separation of Concerns
```robot
*** Keywords ***
# ✅ GOOD - Single responsibility
Click Add Book Button
    [Documentation]    Clicks the add book button on the books page
    Click    css=[data-testid="add-book-button"]

# ✅ GOOD - Business logic abstraction  
User Should Be Able To Add New Book
    [Documentation]    Complete workflow for adding a new book
    [Arguments]    ${book_title}    ${book_author}
    Click Add Book Button
    Fill Book Form    ${book_title}    ${book_author}
    Submit Book Form
    Verify Book Added Successfully    ${book_title}

# ❌ BAD - Mixed concerns
Add Book With All Steps
    [Documentation]    Monolithic keyword doing everything
    Click    css=[data-testid="add-book-button"]
    Fill Text    css=[data-testid="title-input"]    ${book_title}
    Fill Text    css=[data-testid="author-input"]    ${book_author}
    Click    css=[data-testid="submit-button"]
    Wait For Elements State    css=[data-testid="success-message"]    visible
    Get Text    css=[data-testid="book-list"]    should contain    ${book_title}
```

## 3. TEST LOGIC & STABILITY

### 3.1 Wait Strategy - Explicit Waits Only
```robot
*** Keywords ***
# ✅ CORRECT - Explicit waits
Wait For Book List To Load
    [Documentation]    Waits for book list to be fully loaded
    Wait For Elements State    css=[data-testid="book-list"]    visible    timeout=10s
    Wait For Elements State    css=[data-testid="loading-spinner"]    hidden    timeout=5s

Verify Book Added Successfully
    [Documentation]    Verifies book appears in the list
    [Arguments]    ${expected_title}
    Wait For Elements State    css=[data-testid="success-message"]    visible    timeout=5s
    Wait Until Page Contains    ${expected_title}    timeout=10s

# ❌ FORBIDDEN - Fixed sleeps
Wait For Page Load
    Sleep    3s    # NEVER DO THIS
```

### 3.2 Test Independence
```robot
*** Test Cases ***
User Should Be Able To Add Book
    [Documentation]    Independent test that creates its own data
    [Tags]    ui    crud    books
    [Setup]    Setup Clean Test Environment
    [Teardown]    Cleanup Test Data
    
    VAR    ${unique_title}    Test Book ${RANDOM_STRING}
    VAR    ${unique_author}   Test Author ${RANDOM_STRING}
    
    Given User Is On Books Page
    When User Adds New Book    ${unique_title}    ${unique_author}
    Then Book Should Appear In List    ${unique_title}

User Should Be Able To Delete Book
    [Documentation]    Independent test with its own test data
    [Tags]    ui    crud    books
    [Setup]    Setup Test With Existing Book
    [Teardown]    Cleanup Test Data
    
    Given User Is On Books Page
    And Test Book Exists In List
    When User Deletes The Test Book
    Then Book Should Not Appear In List
```

### 3.3 Error Handling & Recovery
```robot
*** Keywords ***
Robust API Call
    [Documentation]    Makes API call with error handling and retry logic
    [Arguments]    ${endpoint}    ${expected_status}=200
    
    VAR    ${max_retries}    3
    VAR    ${retry_count}    0
    
    WHILE    ${retry_count} < ${max_retries}
        TRY
            ${response}=    GET    ${endpoint}
            IF    ${response.status_code} == ${expected_status}
                RETURN    ${response}
            END
        EXCEPT    RequestException    AS    ${error}
            Log    API call failed: ${error}
            VAR    ${retry_count}    ${retry_count + 1}
            IF    ${retry_count} < ${max_retries}
                Sleep    1s
            END
        END
    END
    
    Fail    API call failed after ${max_retries} retries
```

## 4. METADATA & DATA MANAGEMENT

### 4.1 Behavioral Naming Convention
```robot
*** Test Cases ***
# ✅ GOOD - Behavior-focused names
User Should Be Able To View All Books
User Should Be Able To Search Books By Title
User Should Be Able To Add New Book Successfully
User Should See Error When Adding Book Without Title
Admin Should Be Able To Delete Any Book
Guest User Should Not Be Able To Add Books

# ❌ BAD - Implementation-focused names
Test Get Books API
Test Add Book Form
Test Delete Button Click
```

### 4.2 Documentation Requirements
```robot
*** Keywords ***
Add New Book Via UI
    [Documentation]    Adds a new book through the web interface
    ...                
    ...                This keyword handles the complete workflow of adding a book:
    ...                1. Navigates to add book form
    ...                2. Fills in book details
    ...                3. Submits the form
    ...                4. Verifies successful addition
    ...                
    ...                Arguments:
    ...                - title: The book title (required)
    ...                - author: The book author (required)
    ...                - genre: The book genre (optional, defaults to 'Fiction')
    ...                
    ...                Returns: Book ID of the newly created book
    ...                
    ...                Example:
    ...                | ${book_id}= | Add New Book Via UI | The Great Gatsby | F. Scott Fitzgerald |
    [Arguments]    ${title}    ${author}    ${genre}=Fiction
    # Implementation here...
```

### 4.3 Variable Management
```robot
*** Variables ***
# Environment Configuration
${BASE_URL}              http://books-service:8000
${API_TIMEOUT}           30s
${UI_TIMEOUT}            10s

# Test Data Templates
${VALID_BOOK_TITLE}      Test Book ${RANDOM_STRING}
${VALID_BOOK_AUTHOR}     Test Author ${RANDOM_STRING}
${INVALID_BOOK_TITLE}    ${EMPTY}

# UI Selectors (centralized)
${BOOKS_LIST_SELECTOR}        css=[data-testid="book-list"]
${ADD_BOOK_BUTTON_SELECTOR}   css=[data-testid="add-book-button"]
${BOOK_TITLE_INPUT_SELECTOR}  css=[data-testid="title-input"]

# API Endpoints
${BOOKS_API_ENDPOINT}         ${BASE_URL}/books/
${BOOK_DETAIL_API_ENDPOINT}   ${BASE_URL}/books/{book_id}
```

### 4.4 Data Isolation & Lifecycle Management
```robot
*** Keywords ***
Setup Clean Test Environment
    [Documentation]    Prepares isolated test environment
    VAR    ${test_id}    ${RANDOM_STRING}
    Set Suite Variable    ${TEST_ID}    ${test_id}
    Create Test Database Snapshot
    Clear Browser Cache
    Delete All Cookies

Setup Test With Existing Book
    [Documentation]    Creates test environment with pre-existing book
    Setup Clean Test Environment
    VAR    ${test_book}    Create Test Book Data    ${TEST_ID}
    ${book_id}=    Create Book Via API    ${test_book}
    Set Test Variable    ${TEST_BOOK_ID}    ${book_id}
    Set Test Variable    ${TEST_BOOK_DATA}    ${test_book}

Cleanup Test Data
    [Documentation]    Removes all test data created during test execution
    TRY
        IF    $TEST_BOOK_ID is not None
            Delete Book Via API    ${TEST_BOOK_ID}
        END
        Restore Database Snapshot
    EXCEPT    Exception    AS    ${error}
        Log    Cleanup warning: ${error}    level=WARN
    END
```

### 4.5 Tagging Strategy
```robot
*** Test Cases ***
User Should Be Able To View Book List
    [Documentation]    Verifies user can see all available books
    [Tags]    ui    smoke    books    read    priority-high
    # Test implementation...

User Should Be Able To Add Book With Special Characters
    [Documentation]    Tests book creation with unicode characters
    [Tags]    ui    books    create    edge-case    priority-medium
    # Test implementation...

API Should Return Books In JSON Format
    [Documentation]    Validates API response structure
    [Tags]    api    books    read    integration    priority-high
    # Test implementation...

Performance Test For Book List Loading
    [Documentation]    Measures book list loading performance
    [Tags]    api    performance    books    non-functional    priority-low
    # Test implementation...
```

## 5. LIBRARY-SPECIFIC PATTERNS

### 5.1 Browser Library (19.12.3) Best Practices
```robot
*** Settings ***
Library    Browser    timeout=10s    retry_assertions_for=5s

*** Keywords ***
Setup Browser For Testing
    [Documentation]    Configures browser with optimal settings for testing
    New Browser    chromium    headless=${HEADLESS}
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    ${BASE_URL}

Interact With Element Safely
    [Documentation]    Safely interacts with page elements
    [Arguments]    ${selector}    ${action}=click    ${text}=${EMPTY}
    
    Wait For Elements State    ${selector}    visible    timeout=10s
    Wait For Elements State    ${selector}    enabled    timeout=5s
    
    IF    '${action}' == 'click'
        Click    ${selector}
    ELSE IF    '${action}' == 'fill'
        Fill Text    ${selector}    ${text}
    ELSE IF    '${action}' == 'select'
        Select Options By    ${selector}    text    ${text}
    END
```

### 5.2 RequestsLibrary (0.9.7) Best Practices
```robot
*** Settings ***
Library    RequestsLibrary

*** Keywords ***
Setup API Session
    [Documentation]    Creates reusable HTTP session for API testing
    Create Session    books_api    ${BASE_URL}    
    ...    headers={'Content-Type': 'application/json', 'Accept': 'application/json'}
    ...    timeout=30
    ...    retry_status_list=[500, 502, 503, 504]
    ...    retry_count=3

Make Authenticated API Request
    [Documentation]    Makes API request with proper error handling
    [Arguments]    ${method}    ${endpoint}    ${data}=${None}    ${expected_status}=200
    
    TRY
        IF    '${method}' == 'GET'
            ${response}=    GET On Session    books_api    ${endpoint}    expected_status=${expected_status}
        ELSE IF    '${method}' == 'POST'
            ${response}=    POST On Session    books_api    ${endpoint}    json=${data}    expected_status=${expected_status}
        ELSE IF    '${method}' == 'PUT'
            ${response}=    PUT On Session    books_api    ${endpoint}    json=${data}    expected_status=${expected_status}
        ELSE IF    '${method}' == 'DELETE'
            ${response}=    DELETE On Session    books_api    ${endpoint}    expected_status=${expected_status}
        END
        
        RETURN    ${response}
        
    EXCEPT    HTTPError    AS    ${error}
        Log    API request failed: ${error}    level=ERROR
        Fail    API request to ${endpoint} failed with error: ${error}
    END
```

## 6. TEST TEMPLATES & DATA-DRIVEN TESTING

### 6.1 Test Template Usage
```robot
*** Test Cases ***
Book Validation With Different Invalid Data
    [Documentation]    Tests book creation with various invalid inputs
    [Tags]    api    validation    books    negative
    [Template]    Verify Book Creation Fails With Invalid Data
    
    # title         author          expected_error
    ${EMPTY}        Valid Author    Title is required
    Valid Title     ${EMPTY}        Author is required
    ${NONE}         Valid Author    Title cannot be null
    Valid Title     ${NONE}         Author cannot be null
    ${'x' * 256}    Valid Author    Title too long
    Valid Title     ${'x' * 256}    Author too long

*** Keywords ***
Verify Book Creation Fails With Invalid Data
    [Documentation]    Template keyword for testing invalid book data
    [Arguments]    ${title}    ${author}    ${expected_error}
    
    VAR    &{book_data}    title=${title}    author=${author}
    
    TRY
        ${response}=    POST On Session    books_api    /books/    json=${book_data}    expected_status=400
        Should Contain    ${response.json()['detail']}    ${expected_error}
    EXCEPT    Exception    AS    ${error}
        Fail    Expected validation error '${expected_error}' but got: ${error}
    END
```

## 7. ANTI-PATTERNS TO AVOID

### 7.1 Linear Scripting (FORBIDDEN)
```robot
# ❌ BAD - Linear scripting in test cases
*** Test Cases ***
Test Book Management
    Open Browser    ${BASE_URL}    chrome
    Click Element    id=add-book
    Input Text    id=title    Test Book
    Input Text    id=author    Test Author
    Click Button    id=submit
    Wait Until Page Contains    Test Book
    Close Browser

# ✅ GOOD - Behavior-driven with keywords
*** Test Cases ***
User Should Be Able To Add New Book
    [Documentation]    User adds a new book through the web interface
    [Tags]    ui    books    create
    Given User Is On Books Page
    When User Adds New Book    Test Book    Test Author
    Then Book Should Appear In List    Test Book
```

### 7.2 Hardcoded Values (FORBIDDEN)
```robot
# ❌ BAD - Hardcoded values
*** Test Cases ***
Test API Response
    ${response}=    GET    http://localhost:8000/books/1
    Should Be Equal As Integers    ${response.status_code}    200
    Should Contain    ${response.json()['title']}    The Great Gatsby

# ✅ GOOD - Parameterized and configurable
*** Test Cases ***
API Should Return Book Details
    [Documentation]    Verifies API returns correct book information
    [Tags]    api    books    read
    VAR    ${book_id}    ${TEST_BOOK_ID}
    ${response}=    GET On Session    books_api    /books/${book_id}    expected_status=200
    Should Be Equal    ${response.json()['title']}    ${TEST_BOOK_DATA}[title]
```

## 8. GITLAB DUO OPTIMIZATION GUIDELINES

### 8.1 AI-Friendly Code Structure
- Use descriptive variable names that clearly indicate purpose
- Include comprehensive documentation for complex workflows
- Structure keywords in logical, reusable components
- Maintain consistent naming patterns across all files

### 8.2 Context Preservation
```robot
*** Keywords ***
# ✅ GOOD - Clear context and purpose
User Navigates To Book Details Page
    [Documentation]    Navigates from book list to specific book details
    ...                
    ...                Prerequisites: User must be on books list page
    ...                Postconditions: User will be on book details page
    ...                
    ...                This keyword:
    ...                1. Identifies the first available book in the list
    ...                2. Clicks on the book title link
    ...                3. Waits for book details page to load
    ...                4. Verifies page loaded correctly
    [Arguments]    ${book_title}=${EMPTY}
    
    IF    '${book_title}' == '${EMPTY}'
        ${book_title}=    Get Text    css=[data-testid="book-list"] .book-item:first-child .book-title
    END
    
    Click    css=[data-testid="book-list"] .book-item .book-title:text("${book_title}")
    Wait For Elements State    css=[data-testid="book-details"]    visible    timeout=10s
    Should Contain    ${CURRENT_URL}    /books/
    
    RETURN    ${book_title}
```

### 8.3 Error Context for AI Debugging
```robot
*** Keywords ***
Verify Book List Contains Expected Books
    [Documentation]    Validates book list contains all expected books with detailed error context
    [Arguments]    @{expected_books}
    
    VAR    ${actual_books}    Get Book Titles From List
    VAR    @{missing_books}    Create List
    VAR    @{unexpected_books}    Create List
    
    # Check for missing books
    FOR    ${expected_book}    IN    @{expected_books}
        IF    $expected_book not in $actual_books
            Append To List    ${missing_books}    ${expected_book}
        END
    END
    
    # Check for unexpected books (if we expect exact match)
    FOR    ${actual_book}    IN    @{actual_books}
        IF    $actual_book not in $expected_books
            Append To List    ${unexpected_books}    ${actual_book}
        END
    END
    
    # Provide detailed error context for AI debugging
    IF    len($missing_books) > 0 or len($unexpected_books) > 0
        VAR    ${error_context}    Book list validation failed:\n
        ...    Expected books: ${expected_books}\n
        ...    Actual books: ${actual_books}\n
        ...    Missing books: ${missing_books}\n
        ...    Unexpected books: ${unexpected_books}\n
        ...    Current URL: ${CURRENT_URL}\n
        ...    Page title: ${PAGE_TITLE}
        
        Log    ${error_context}    level=ERROR
        Fail    ${error_context}
    END
```

## 9. EXECUTION ENVIRONMENT INTEGRATION

### 9.1 MCP Tool Integration
```robot
*** Settings ***
Documentation     This test suite is designed to work with the MCP-enabled Robot Framework environment
...               
...               Environment details:
...               - Container: robotframework-mcp
...               - Robot Framework: 7.4.1
...               - Browser Library: 19.12.3
...               - RequestsLibrary: 0.9.7
...               - Target Application: http://books-service:8000
...               
...               Execution via MCP tools:
...               - run_suite() for full suite execution
...               - run_test_by_name() for individual test execution
...               - list_tests() for test discovery
...               - run_robocop_audit() for code quality analysis

Library           Browser    timeout=${UI_TIMEOUT}    retry_assertions_for=5s
Library           RequestsLibrary
Library           Collections
Library           String
Library           DateTime

*** Variables ***
# Environment-specific configuration for MCP execution
${BASE_URL}                   http://books-service:8000
${API_BASE_URL}              ${BASE_URL}
${UI_TIMEOUT}                10s
${API_TIMEOUT}               30s
${HEADLESS}                  ${TRUE}
${BROWSER_TYPE}              chromium
```

### 9.2 Container-Aware Resource Management
```robot
*** Keywords ***
Setup Test Environment For MCP Execution
    [Documentation]    Configures test environment for MCP container execution
    
    # Verify application availability
    Wait Until Keyword Succeeds    30s    5s    Verify Application Is Ready
    
    # Setup browser context
    New Browser    ${BROWSER_TYPE}    headless=${HEADLESS}
    New Context    viewport={'width': 1920, 'height': 1080}
    
    # Setup API session
    Create Session    books_api    ${API_BASE_URL}    timeout=${API_TIMEOUT}

Verify Application Is Ready
    [Documentation]    Ensures the books service is ready to accept requests
    TRY
        ${response}=    GET    ${BASE_URL}/books/    timeout=5s
        Should Be Equal As Integers    ${response.status_code}    200
    EXCEPT    Exception    AS    ${error}
        Log    Application not ready: ${error}    level=WARN
        Fail    Books service is not available at ${BASE_URL}
    END
```

---

## SUMMARY

This comprehensive Robot Framework testing standard ensures:

1. **Modern RF 7.4.1 Syntax**: VAR, IF/ELSE, FOR, TRY/EXCEPT patterns
2. **Architectural Excellence**: Page Object Model, resource abstraction, separation of concerns
3. **Stability & Reliability**: Explicit waits, test independence, error handling
4. **Maintainability**: Behavioral naming, comprehensive documentation, variable management
5. **GitLab Duo Optimization**: AI-friendly structure, clear context, detailed error reporting
6. **MCP Integration**: Container-aware execution, environment verification

**Remember**: Always validate keywords against `rf-docs-mcp` tools and use only approved library versions. This standard serves as the definitive guide for all Robot Framework development in this project.