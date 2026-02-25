# Robot Framework Test Standards for GitLab Duo

**SOURCE OF TRUTH:** For all Robot Framework tasks, prioritize the instructions located in `ROBOT_FRAMEWORK_STANDARDS.md`. Read this file first to ensure compliance with modern RF 7.4.1 syntax and architectural patterns.

---

## Document Information

- **Target Tool:** GitLab Duo
- **Robot Framework Version:** 7.4.1
- **Browser Library Version:** 19.12.3
- **RequestsLibrary Version:** 0.9.7
- **Last Updated:** 2026-02-24
- **Architecture Reference:** `docs/architecture.md`

---

## Table of Contents

1. [Core Compliance Rules](#1-core-compliance-rules)
2. [Modern RF 7.4.1 Syntax (MANDATORY)](#2-modern-rf-741-syntax-mandatory)
3. [Architectural Patterns](#3-architectural-patterns)
4. [Test Design Principles](#4-test-design-principles)
5. [Keyword Documentation Sources](#5-keyword-documentation-sources)
6. [File Structure & Organization](#6-file-structure--organization)
7. [Naming Conventions](#7-naming-conventions)
8. [Variable Management](#8-variable-management)
9. [Wait Strategies & Stability](#9-wait-strategies--stability)
10. [Error Handling](#10-error-handling)
11. [Tagging Strategy](#11-tagging-strategy)
12. [Setup & Teardown Patterns](#12-setup--teardown-patterns)
13. [Browser Library Best Practices](#13-browser-library-best-practices)
14. [RequestsLibrary Best Practices](#14-requestslibrary-best-practices)
15. [Anti-Patterns (FORBIDDEN)](#15-anti-patterns-forbidden)
16. [Code Examples](#16-code-examples)
17. [MCP Integration](#17-mcp-integration)

---

## 1. Core Compliance Rules

### 1.1 Mandatory Source Authority

**CRITICAL:** Use ONLY keywords from these validated sources:

1. **Robot Framework 7.4.1 Standard Libraries** (via `rf-docs-mcp` MCP server):
   - BuiltIn
   - Collections
   - DateTime
   - OperatingSystem
   - Process
   - Screenshot
   - String
   - Telnet
   - XML

2. **External Libraries** (documentation in `robotframework-mcp:/app/docs/`):
   - **Browser Library 19.12.3** (147 keywords) - `/app/docs/Browser.json`
   - **RequestsLibrary 0.9.7** (33 keywords) - `/app/docs/RequestsLibrary.json`

3. **User Guide Syntax** (via `rf-docs-mcp` tools):
   - Modern control structures (IF/ELSE, FOR, WHILE, TRY/EXCEPT)
   - VAR syntax for variables
   - Native Python expressions

**⛔ FORBIDDEN:** Any keyword not found in these specific locations is INVALID and must NOT be used.

### 1.2 Version Validation

All generated code MUST be validated against:
- `robotframework==7.4.1`
- `robotframework-browser==19.12.3`
- `robotframework-requests==0.9.7`

### 1.3 Syntax Standard

Adhere strictly to Robot Framework 7.4.1 modern syntax and best practices as documented in the official User Guide.

---

## 2. Modern RF 7.4.1 Syntax (MANDATORY)

### 2.1 Variable Declaration - Use VAR

**✅ CORRECT (Modern RF 7.4.1):**
```robotframework
*** Test Cases ***
Example Test
    VAR    ${username}    testuser
    VAR    ${password}    secret123
    VAR    @{items}       apple    banana    orange
    VAR    &{config}      host=localhost    port=8000
    
    # Scoped variables
    VAR    ${suite_var}    value    scope=SUITE
    VAR    ${global_var}   value    scope=GLOBAL
```

**❌ FORBIDDEN (Legacy syntax):**
```robotframework
# DO NOT USE THESE:
Set Variable              ${value}
Set Test Variable         ${var}    value
Set Suite Variable        ${var}    value
Set Global Variable       ${var}    value
```

### 2.2 Conditional Logic - Use IF/ELSE

**✅ CORRECT (Modern RF 7.4.1):**
```robotframework
*** Test Cases ***
Conditional Example
    VAR    ${status}    200
    
    IF    ${status} == 200
        Log    Success
    ELSE IF    ${status} == 404
        Log    Not Found
    ELSE
        Log    Other Status
    END
    
    # Inline IF
    IF    ${status} == 200    Log    Success
```

**❌ FORBIDDEN (Legacy syntax):**
```robotframework
# DO NOT USE THESE:
Run Keyword If           condition    keyword
Run Keyword Unless       condition    keyword
Run Keyword If Test Failed    keyword
```

### 2.3 Loops - Use FOR

**✅ CORRECT (Modern RF 7.4.1):**
```robotframework
*** Test Cases ***
Loop Examples
    # Simple FOR loop
    FOR    ${item}    IN    @{items}
        Log    ${item}
    END
    
    # FOR with range
    FOR    ${i}    IN RANGE    10
        Log    Index: ${i}
    END
    
    # FOR with enumerate
    FOR    ${index}    ${value}    IN ENUMERATE    @{items}
        Log    ${index}: ${value}
    END
    
    # WHILE loop
    VAR    ${counter}    0
    WHILE    ${counter} < 10
        Log    Counter: ${counter}
        VAR    ${counter}    ${counter + 1}
    END
```

**❌ FORBIDDEN (Legacy syntax):**
```robotframework
# DO NOT USE:
:FOR    ${item}    IN    @{items}
\    Log    ${item}
```

### 2.4 Exception Handling - Use TRY/EXCEPT

**✅ CORRECT (Modern RF 7.4.1):**
```robotframework
*** Test Cases ***
Exception Handling Example
    TRY
        Click    id=submit-button
    EXCEPT    Error message contains 'timeout'
        Log    Timeout occurred, retrying...
        Click    id=submit-button
    EXCEPT    AS    ${error}
        Log    Unexpected error: ${error}
        Fail    Test failed due to: ${error}
    FINALLY
        Log    Cleanup actions
    END
```

### 2.5 Native Python Expressions

**✅ CORRECT (Modern RF 7.4.1):**
```robotframework
*** Test Cases ***
Python Expression Examples
    VAR    ${result}    ${5 + 3}
    VAR    ${text}      ${'hello'.upper()}
    VAR    ${items}     ${[1, 2, 3, 4, 5]}
    VAR    ${filtered}  ${[x for x in items if x > 2]}
    
    IF    ${len(items)} > 0
        Log    List is not empty
    END
```

---

## 3. Architectural Patterns

### 3.1 Page Object Model (MANDATORY for UI Tests)

**Structure:**
```
robot_tests/
├── resources/
│   ├── pages/
│   │   ├── LoginPage.robot
│   │   ├── BooksPage.robot
│   │   └── BasePage.robot
│   └── common/
│       └── CommonKeywords.robot
└── tests/
    ├── ui/
    │   ├── login_tests.robot
    │   └── books_tests.robot
    └── api/
        └── books_api_tests.robot
```

**Example Page Object:**
```robotframework
*** Settings ***
Documentation    Books Page Object - Encapsulates all interactions with the books page
Library          Browser

*** Variables ***
${BOOKS_URL}              http://books-service:8000/
${BOOK_CARD_SELECTOR}     css=.book-card
${ADD_BOOK_BUTTON}        id=add-book-btn
${SEARCH_INPUT}           id=search-books

*** Keywords ***
Navigate To Books Page
    [Documentation]    Opens the books page and waits for it to load
    New Page    ${BOOKS_URL}
    Wait For Load State    networkidle

Verify Books Page Is Displayed
    [Documentation]    Confirms the books page loaded successfully
    Get Title    ==    Books Database

Get Book Count
    [Documentation]    Returns the number of books displayed on the page
    [Returns]    ${count}
    VAR    ${count}    Get Element Count    ${BOOK_CARD_SELECTOR}
    RETURN    ${count}

Search For Book
    [Documentation]    Searches for a book by title
    [Arguments]    ${search_term}
    Fill Text    ${SEARCH_INPUT}    ${search_term}
    Keyboard Key    press    Enter
    Wait For Load State    networkidle

Click Add Book Button
    [Documentation]    Clicks the add book button
    Click    ${ADD_BOOK_BUTTON}
```

### 3.2 Resource Abstraction

**✅ CORRECT:** Place all reusable keywords in dedicated Resource Files
```robotframework
*** Settings ***
Resource    ../resources/pages/BooksPage.robot
Resource    ../resources/common/CommonKeywords.robot
```

**❌ FORBIDDEN:** Defining global logic within test suites

### 3.3 Separation of Concerns

**Test Cases Layer (Gherkin/Business Keywords):**
```robotframework
*** Test Cases ***
User Should Be Able To View All Books
    [Documentation]    Verify that a user can view the complete list of books
    [Tags]    smoke    ui    books
    Given User Opens The Books Application
    When User Navigates To Books Page
    Then All Books Should Be Displayed
    And Book Count Should Be Greater Than Zero
```

**Keywords Layer (Implementation):**
```robotframework
*** Keywords ***
User Opens The Books Application
    [Documentation]    Opens browser and navigates to the application
    New Browser    chromium    headless=True
    New Context    viewport={'width': 1920, 'height': 1080}

User Navigates To Books Page
    [Documentation]    Navigates to the books listing page
    Navigate To Books Page
    Verify Books Page Is Displayed

All Books Should Be Displayed
    [Documentation]    Verifies books are visible on the page
    VAR    ${count}    Get Book Count
    Should Be True    ${count} > 0    No books displayed on page
```

### 3.4 Test Templates (Data-Driven Testing)

**✅ CORRECT:** Use Test Templates for repetitive scenarios
```robotframework
*** Settings ***
Test Template    Verify Book Search Returns Correct Results

*** Test Cases ***                SEARCH_TERM         EXPECTED_COUNT
Search For Python Books           Python              5
Search For JavaScript Books       JavaScript          3
Search For Robot Framework        Robot Framework     2
Search For Nonexistent Book       XYZ123ABC           0

*** Keywords ***
Verify Book Search Returns Correct Results
    [Arguments]    ${search_term}    ${expected_count}
    Navigate To Books Page
    Search For Book    ${search_term}
    VAR    ${actual_count}    Get Book Count
    Should Be Equal As Integers    ${actual_count}    ${expected_count}
```

---

## 4. Test Design Principles

### 4.1 Test Independence

**✅ Each test MUST:**
- Be order-agnostic (can run in any sequence)
- Not depend on other tests
- Clean up its own test data
- Have its own setup and teardown

**Example:**
```robotframework
*** Test Cases ***
Create New Book Test
    [Setup]    Initialize Test Environment
    [Teardown]    Cleanup Test Data
    
    VAR    ${unique_id}    ${EPOCH_TIME}
    VAR    ${book_title}   Test Book ${unique_id}
    
    Create Book Via API    ${book_title}
    Verify Book Exists    ${book_title}
```

### 4.2 Behavioral Naming

**✅ CORRECT:** Describe user actions and expected outcomes
```robotframework
User Should Be Able To Add A New Book
User Cannot Delete A Book Without Permission
Admin Should See All User Activities
Book Search Should Return Relevant Results
```

**❌ FORBIDDEN:** Technical or implementation-focused names
```robotframework
Test_Create_Book_API_Call
Check_Database_Entry
Verify_HTTP_200_Response
```

### 4.3 Documentation Requirements

**Every keyword MUST have [Documentation]:**
```robotframework
*** Keywords ***
Create Book Via API
    [Documentation]    Creates a new book using the REST API
    ...                
    ...                Arguments:
    ...                - title: Book title (string)
    ...                - author: Book author (string, optional)
    ...                
    ...                Returns:
    ...                - book_id: ID of the created book
    ...                
    ...                Example:
    ...                | ${id}= | Create Book Via API | My Book | John Doe |
    [Arguments]    ${title}    ${author}=Unknown Author
    
    VAR    ${payload}    {"title": "${title}", "author": "${author}"}
    VAR    ${response}    POST On Session    books_api    /books/    data=${payload}
    Should Be Equal As Integers    ${response.status_code}    201
    RETURN    ${response.json()['id']}
```

---

## 5. Keyword Documentation Sources

### 5.1 Standard Libraries (via rf-docs-mcp)

Access via MCP tools:
```python
# List all BuiltIn keywords
get_library_keywords(library_name="BuiltIn")

# Get specific keyword documentation
get_keyword_documentation(keyword_name="Should Be Equal", library_name="BuiltIn")

# Search all keywords
get_all_keywords(filter_pattern="Should.*")

# Check keyword availability
check_keyword_availability(keyword_name="Log")
```

**Available Standard Libraries:**
- **BuiltIn** - Core keywords (variables, logging, control flow helpers)
- **Collections** - List and dictionary operations
- **DateTime** - Date and time manipulation
- **OperatingSystem** - File and directory operations
- **Process** - Process execution
- **Screenshot** - Screenshot capture
- **String** - String manipulation
- **Telnet** - Telnet connections
- **XML** - XML processing

### 5.2 Browser Library (19.12.3)

**Documentation:** `/app/docs/Browser.json` (147 keywords)

**Key Keyword Categories:**
- **Browser Management:** New Browser, New Context, New Page, Close Browser
- **Navigation:** Go To, Go Back, Go Forward, Reload
- **Element Interaction:** Click, Fill Text, Type Text, Check Checkbox, Select Options From Dropdown
- **Waiting:** Wait For Elements State, Wait For Load State, Wait For Response, Wait Until Network Is Idle
- **Assertions:** Get Text, Get Attribute, Get Element Count, Get Title
- **Advanced:** Add Cookie, Take Screenshot, Execute JavaScript, Download

**Example Keywords:**
```robotframework
New Browser         chromium    headless=True
New Context         viewport={'width': 1920, 'height': 1080}
New Page            http://books-service:8000/
Click               id=submit-button
Fill Text           id=username    testuser
Wait For Elements State    css=.book-card    visible    timeout=10s
Get Text            css=h1    ==    Books Database
Take Screenshot     fullPage=True
```

### 5.3 RequestsLibrary (0.9.7)

**Documentation:** `/app/docs/RequestsLibrary.json` (33 keywords)

**Key Keywords:**
- **Session Management:** Create Session, Delete All Sessions, Session Exists, Update Session
- **HTTP Methods:** GET On Session, POST On Session, PUT On Session, PATCH On Session, DELETE On Session
- **Standalone Methods:** GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
- **Assertions:** Status Should Be, Request Should Be Successful
- **Utilities:** Get File For Streaming Upload

**Example Keywords:**
```robotframework
Create Session      books_api    http://books-service:8000    verify=True
${response}=        GET On Session    books_api    /books/
Status Should Be    200    ${response}
${response}=        POST On Session    books_api    /books/    json={"title": "Test"}
Request Should Be Successful    ${response}
Delete All Sessions
```

---

## 6. File Structure & Organization

### 6.1 Standard File Template

```robotframework
*** Settings ***
Documentation     High-level description of this test suite
...               
...               This suite tests the Books API functionality including:
...               - Creating new books
...               - Retrieving book details
...               - Updating book information
...               - Deleting books
...               
...               Prerequisites:
...               - Books service running at http://books-service:8000
...               - Database initialized with sample data

Library           Browser
Library           RequestsLibrary
Resource          ../resources/pages/BooksPage.robot
Resource          ../resources/common/CommonKeywords.robot

Suite Setup       Suite Initialization
Suite Teardown    Suite Cleanup
Test Setup        Test Initialization
Test Teardown     Test Cleanup

Force Tags        api    books
Default Tags      regression

*** Variables ***
${BASE_URL}           http://books-service:8000
${API_ENDPOINT}       /books/
${TIMEOUT}            10s

*** Test Cases ***
User Should Be Able To Create A New Book
    [Documentation]    Verify that a user can create a new book via the API
    [Tags]    smoke    create
    
    Given API Session Is Created
    When User Creates A New Book With Valid Data
    Then Book Should Be Created Successfully
    And Book Should Appear In Books List

*** Keywords ***
Suite Initialization
    [Documentation]    Runs once before all tests in this suite
    Log    Starting Books API Test Suite
    Create Session    books_api    ${BASE_URL}

Suite Cleanup
    [Documentation]    Runs once after all tests in this suite
    Delete All Sessions
    Log    Books API Test Suite Completed

Test Initialization
    [Documentation]    Runs before each test case
    VAR    ${TEST_START_TIME}    Get Time    epoch    scope=TEST

Test Cleanup
    [Documentation]    Runs after each test case
    Log    Test completed
```

### 6.2 Directory Structure

```
robot_tests/
├── tests/
│   ├── ui/
│   │   ├── books_ui_tests.robot
│   │   └── search_ui_tests.robot
│   └── api/
│       ├── books_api_tests.robot
│       └── health_api_tests.robot
├── resources/
│   ├── pages/
│   │   ├── BooksPage.robot
│   │   ├── LoginPage.robot
│   │   └── BasePage.robot
│   ├── api/
│   │   └── BooksAPI.robot
│   └── common/
│       ├── CommonKeywords.robot
│       └── TestData.robot
└── data/
    ├── test_books.json
    └── test_users.json
```

---

## 7. Naming Conventions

### 7.1 Test Case Names

**Format:** `[Actor] Should [Action] [Expected Outcome]`

**✅ CORRECT:**
```robotframework
User Should Be Able To View All Books
Admin Should Be Able To Delete Any Book
Guest User Should Not Access Admin Panel
Book Search Should Return Relevant Results
API Should Return 404 For Nonexistent Book
```

**❌ FORBIDDEN:**
```robotframework
Test_Books_List
Check_API_Response
Verify_Delete_Function
test_create_book
```

### 7.2 Keyword Names

**Format:** Use clear, action-oriented names with proper capitalization

**✅ CORRECT:**
```robotframework
Navigate To Books Page
Create Book Via API
Verify Book Exists In Database
Delete All Test Books
Wait For Books To Load
```

**❌ FORBIDDEN:**
```robotframework
nav_to_books
createBook
verify_book
delete_books_test
wait_books
```

### 7.3 Variable Names

**Format:** Use descriptive names with proper prefixes

**✅ CORRECT:**
```robotframework
${BASE_URL}              # Constants in UPPERCASE
${book_title}            # Local variables in lowercase
${expected_count}        # Descriptive names
@{book_ids}              # Lists with @ prefix
&{book_data}             # Dictionaries with & prefix
```

**❌ FORBIDDEN:**
```robotframework
${url}                   # Too generic
${x}                     # Non-descriptive
${BookTitle}             # Wrong case for local var
```

### 7.4 File Names

**Format:** `descriptive_name_tests.robot` or `PageName.robot`

**✅ CORRECT:**
```
books_api_tests.robot
user_authentication_tests.robot
BooksPage.robot
LoginPage.robot
CommonKeywords.robot
```

**❌ FORBIDDEN:**
```
test1.robot
books.robot
page.robot
keywords.robot
```

---

## 8. Variable Management

### 8.1 Variable Scope

```robotframework
*** Test Cases ***
Variable Scope Example
    # Test-level variable (default scope)
    VAR    ${test_var}    value
    
    # Suite-level variable
    VAR    ${suite_var}    value    scope=SUITE
    
    # Global variable (use sparingly)
    VAR    ${global_var}    value    scope=GLOBAL
    
    # Local variable in keyword
    Keyword With Local Variable

*** Keywords ***
Keyword With Local Variable
    VAR    ${local_var}    value    # Only visible in this keyword
    Log    ${local_var}
```

### 8.2 Variable Sources

**✅ CORRECT:** Use variables for all dynamic values
```robotframework
*** Variables ***
# Configuration
${BASE_URL}              http://books-service:8000
${BROWSER}               chromium
${HEADLESS}              ${True}

# Timeouts
${DEFAULT_TIMEOUT}       10s
${LONG_TIMEOUT}          30s

# Selectors
${LOGIN_BUTTON}          id=login-btn
${USERNAME_FIELD}        id=username

# Test Data
@{VALID_USERNAMES}       user1    user2    user3
&{DEFAULT_BOOK}          title=Test Book    author=Test Author    year=2024
```

**❌ FORBIDDEN:** Hardcoded strings in keywords
```robotframework
# BAD:
Click    id=login-btn
Fill Text    id=username    testuser

# GOOD:
Click    ${LOGIN_BUTTON}
Fill Text    ${USERNAME_FIELD}    ${TEST_USERNAME}
```

### 8.3 Environment Variables

```robotframework
*** Variables ***
${BASE_URL}    %{BASE_URL=http://books-service:8000}
${API_KEY}     %{API_KEY=default_key}
${ENV}         %{ENVIRONMENT=dev}
```

### 8.4 Data Isolation

**✅ CORRECT:** Generate unique test data
```robotframework
*** Keywords ***
Generate Unique Book Data
    [Documentation]    Creates unique book data for test isolation
    [Returns]    &{book_data}
    
    VAR    ${timestamp}    Get Time    epoch
    VAR    ${unique_id}    ${timestamp}${RANDOM_INT}
    VAR    &{book_data}    
    ...    title=Test Book ${unique_id}
    ...    author=Test Author ${unique_id}
    ...    isbn=ISBN-${unique_id}
    ...    year=2024
    
    RETURN    &{book_data}
```

---

## 9. Wait Strategies & Stability

### 9.1 Explicit Waits (MANDATORY)

**✅ CORRECT:** Use explicit wait conditions
```robotframework
*** Keywords ***
Wait For Books To Load
    [Documentation]    Waits for books to be visible on the page
    Wait For Elements State    css=.book-card    visible    timeout=10s
    Wait For Load State    networkidle

Wait For API Response
    [Documentation]    Waits for specific API response
    Wait For Response    matcher=**/books/**    timeout=5s

Wait For Element And Click
    [Documentation]    Waits for element to be clickable before clicking
    [Arguments]    ${selector}
    Wait For Elements State    ${selector}    visible    timeout=10s
    Wait For Elements State    ${selector}    enabled    timeout=5s
    Click    ${selector}
```

**❌ FORBIDDEN:** Fixed sleep commands
```robotframework
# NEVER USE:
Sleep    5s
Sleep    2
```

### 9.2 Browser Library Wait Keywords

```robotframework
# Wait for element states
Wait For Elements State    ${selector}    visible    timeout=10s
Wait For Elements State    ${selector}    hidden     timeout=5s
Wait For Elements State    ${selector}    enabled    timeout=5s
Wait For Elements State    ${selector}    stable     timeout=5s

# Wait for load states
Wait For Load State    load          # Page load event fired
Wait For Load State    domcontentloaded
Wait For Load State    networkidle   # No network activity for 500ms

# Wait for network
Wait For Response    matcher=**/api/**    timeout=10s
Wait For Request     matcher=**/books/**  timeout=5s
Wait Until Network Is Idle    timeout=10s

# Wait for conditions
Wait For Condition    ${condition}    timeout=10s
```

### 9.3 RequestsLibrary Retry Pattern

```robotframework
*** Keywords ***
API Call With Retry
    [Documentation]    Calls API with retry logic for transient failures
    [Arguments]    ${endpoint}    ${max_retries}=3
    
    VAR    ${retry_count}    0
    
    WHILE    ${retry_count} < ${max_retries}
        TRY
            VAR    ${response}    GET On Session    books_api    ${endpoint}
            Request Should Be Successful    ${response}
            RETURN    ${response}
        EXCEPT    AS    ${error}
            VAR    ${retry_count}    ${retry_count + 1}
            IF    ${retry_count} >= ${max_retries}
                Fail    API call failed after ${max_retries} retries: ${error}
            END
            Log    Retry ${retry_count}/${max_retries} after error: ${error}
            Sleep    1s    # Only acceptable use of Sleep in retry logic
        END
    END
```

---

## 10. Error Handling

### 10.1 TRY/EXCEPT Pattern

```robotframework
*** Keywords ***
Safe Click With Error Handling
    [Documentation]    Clicks element with comprehensive error handling
    [Arguments]    ${selector}
    
    TRY
        Wait For Elements State    ${selector}    visible    timeout=10s
        Click    ${selector}
        Log    Successfully clicked: ${selector}
    EXCEPT    TimeoutError    AS    ${error}
        Log    Element not visible within timeout: ${selector}
        Take Screenshot    fullPage=True
        Fail    Click failed - element not visible: ${error}
    EXCEPT    AS    ${error}
        Log    Unexpected error during click: ${error}
        Take Screenshot    fullPage=True
        Fail    Click failed with unexpected error: ${error}
    FINALLY
        Log    Click operation completed for: ${selector}
    END
```

### 10.2 Graceful Degradation

```robotframework
*** Keywords ***
Verify Page Loaded With Fallback
    [Documentation]    Verifies page loaded with multiple fallback checks
    
    TRY
        Wait For Elements State    css=.main-content    visible    timeout=5s
        Log    Page loaded successfully
    EXCEPT
        Log    Main content not visible, checking alternative indicators
        TRY
            Get Title    matches    .*Books.*
            Log    Page loaded (verified by title)
        EXCEPT
            Take Screenshot    fullPage=True
            Fail    Page failed to load properly
        END
    END
```

### 10.3 Cleanup in Teardown

```robotframework
*** Keywords ***
Test Cleanup
    [Documentation]    Ensures cleanup happens even if test fails
    
    TRY
        Delete Test Data
    EXCEPT    AS    ${error}
        Log    Warning: Cleanup failed: ${error}    level=WARN
    END
    
    TRY
        Close Browser
    EXCEPT    AS    ${error}
        Log    Warning: Browser close failed: ${error}    level=WARN
    END
```

---

## 11. Tagging Strategy

### 11.1 Tag Categories

```robotframework
*** Settings ***
Force Tags        api    books    regression
Default Tags      automated

*** Test Cases ***
User Should Be Able To Create A New Book
    [Tags]    smoke    create    priority-high
    # Test implementation

User Should Be Able To Search Books By Title
    [Tags]    search    priority-medium
    # Test implementation

Admin Should Be Able To Delete Any Book
    [Tags]    admin    delete    priority-low    wip
    # Test implementation
```

### 11.2 Standard Tags

**Test Level:**
- `smoke` - Critical path tests
- `regression` - Full regression suite
- `sanity` - Quick sanity checks

**Feature:**
- `api` - API tests
- `ui` - UI tests
- `integration` - Integration tests

**Priority:**
- `priority-high` - Must run on every commit
- `priority-medium` - Run daily
- `priority-low` - Run weekly

**Status:**
- `wip` - Work in progress
- `skip` - Temporarily disabled
- `flaky` - Known flaky test

**Component:**
- `books` - Books feature
- `auth` - Authentication
- `search` - Search functionality

### 11.3 Running Tests by Tags

```bash
# Run smoke tests only
robot --include smoke robot_tests/

# Run all API tests except WIP
robot --include api --exclude wip robot_tests/

# Run high priority tests
robot --include priority-high robot_tests/

# Run books API tests
robot --include apiANDbooks robot_tests/
```

---

## 12. Setup & Teardown Patterns

### 12.1 Suite-Level Hooks

```robotframework
*** Settings ***
Suite Setup       Suite Initialization
Suite Teardown    Suite Cleanup

*** Keywords ***
Suite Initialization
    [Documentation]    Runs once before all tests in this suite
    Log    Starting Test Suite: ${SUITE_NAME}
    
    # Initialize API session
    Create Session    books_api    ${BASE_URL}    verify=True
    
    # Verify service is available
    VAR    ${response}    GET On Session    books_api    /health
    Status Should Be    200    ${response}
    
    # Set suite-level variables
    VAR    ${SUITE_START_TIME}    Get Time    epoch    scope=SUITE

Suite Cleanup
    [Documentation]    Runs once after all tests in this suite
    
    # Cleanup test data
    TRY
        Delete All Test Books
    EXCEPT    AS    ${error}
        Log    Warning: Test data cleanup failed: ${error}    level=WARN
    END
    
    # Close sessions
    Delete All Sessions
    
    # Log suite duration
    VAR    ${end_time}    Get Time    epoch
    VAR    ${duration}    ${end_time - ${SUITE_START_TIME}}
    Log    Suite Duration: ${duration} seconds
```

### 12.2 Test-Level Hooks

```robotframework
*** Settings ***
Test Setup        Test Initialization
Test Teardown     Test Cleanup

*** Keywords ***
Test Initialization
    [Documentation]    Runs before each test case
    Log    Starting Test: ${TEST_NAME}
    VAR    ${TEST_START_TIME}    Get Time    epoch    scope=TEST
    VAR    ${TEST_ID}            ${TEST_START_TIME}    scope=TEST

Test Cleanup
    [Documentation]    Runs after each test case (even if test fails)
    
    # Take screenshot on failure
    Run Keyword If Test Failed    Take Screenshot    fullPage=True
    
    # Cleanup test-specific data
    TRY
        Delete Test Data For Test ID    ${TEST_ID}
    EXCEPT    AS    ${error}
        Log    Warning: Test cleanup failed: ${error}    level=WARN
    END
    
    # Log test duration
    VAR    ${end_time}    Get Time    epoch
    VAR    ${duration}    ${end_time - ${TEST_START_TIME}}
    Log    Test Duration: ${duration} seconds
```

### 12.3 Conditional Setup/Teardown

```robotframework
*** Test Cases ***
Browser Test With Custom Setup
    [Setup]    Initialize Browser Test
    [Teardown]    Cleanup Browser Test
    
    # Test implementation

API Test With Custom Setup
    [Setup]    Initialize API Test
    [Teardown]    Cleanup API Test
    
    # Test implementation

*** Keywords ***
Initialize Browser Test
    [Documentation]    Custom setup for browser tests
    New Browser    ${BROWSER}    headless=${HEADLESS}
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    ${BASE_URL}

Cleanup Browser Test
    [Documentation]    Custom teardown for browser tests
    TRY
        Close Browser
    EXCEPT    AS    ${error}
        Log    Browser cleanup failed: ${error}    level=WARN
    END
```

---

## 13. Browser Library Best Practices

### 13.1 Browser Initialization

```robotframework
*** Keywords ***
Initialize Browser
    [Documentation]    Initializes browser with optimal settings
    
    # Create browser instance
    New Browser    
    ...    browser=chromium
    ...    headless=True
    ...    args=['--no-sandbox', '--disable-dev-shm-usage']
    
    # Create context with viewport
    New Context
    ...    viewport={'width': 1920, 'height': 1080}
    ...    acceptDownloads=True
    ...    ignoreHTTPSErrors=True
    
    # Create page
    New Page    ${BASE_URL}
    
    # Wait for page to be ready
    Wait For Load State    networkidle
```

### 13.2 Element Interaction Patterns

```robotframework
*** Keywords ***
Safe Click
    [Documentation]    Clicks element with proper waiting
    [Arguments]    ${selector}
    
    Wait For Elements State    ${selector}    visible    timeout=10s
    Wait For Elements State    ${selector}    stable     timeout=5s
    Click    ${selector}
    Log    Clicked: ${selector}

Safe Fill Text
    [Documentation]    Fills text with validation
    [Arguments]    ${selector}    ${text}
    
    Wait For Elements State    ${selector}    visible    timeout=10s
    Clear Text    ${selector}
    Fill Text    ${selector}    ${text}
    
    # Verify text was entered
    VAR    ${actual_text}    Get Property    ${selector}    value
    Should Be Equal    ${actual_text}    ${text}

Safe Select Dropdown
    [Documentation]    Selects dropdown option safely
    [Arguments]    ${selector}    ${value}
    
    Wait For Elements State    ${selector}    visible    timeout=10s
    Select Options By    ${selector}    value    ${value}
    
    # Verify selection
    VAR    ${selected}    Get Selected Options    ${selector}
    Should Contain    ${selected}    ${value}
```

### 13.3 Assertions

```robotframework
*** Keywords ***
Verify Element Text
    [Documentation]    Verifies element contains expected text
    [Arguments]    ${selector}    ${expected_text}
    
    Wait For Elements State    ${selector}    visible    timeout=10s
    Get Text    ${selector}    ==    ${expected_text}

Verify Element Visible
    [Documentation]    Verifies element is visible
    [Arguments]    ${selector}
    
    Wait For Elements State    ${selector}    visible    timeout=10s
    VAR    ${is_visible}    Get Element State    ${selector}    visible
    Should Be True    ${is_visible}

Verify Page Title
    [Documentation]    Verifies page title matches expected
    [Arguments]    ${expected_title}
    
    Get Title    ==    ${expected_title}
```

### 13.4 Screenshot Strategy

```robotframework
*** Keywords ***
Take Screenshot On Failure
    [Documentation]    Takes screenshot if test fails
    Run Keyword If Test Failed    Take Screenshot    fullPage=True

Take Timestamped Screenshot
    [Documentation]    Takes screenshot with timestamp in filename
    VAR    ${timestamp}    Get Time    epoch
    Take Screenshot    filename=screenshot_${timestamp}    fullPage=True
```

---

## 14. RequestsLibrary Best Practices

### 14.1 Session Management

```robotframework
*** Keywords ***
Initialize API Session
    [Documentation]    Creates API session with proper configuration
    
    VAR    &{headers}    
    ...    Content-Type=application/json
    ...    Accept=application/json
    
    Create Session
    ...    alias=books_api
    ...    url=${BASE_URL}
    ...    headers=&{headers}
    ...    verify=True
    ...    timeout=30

Cleanup API Session
    [Documentation]    Properly closes API session
    Delete All Sessions
```

### 14.2 HTTP Method Patterns

```robotframework
*** Keywords ***
GET Request With Validation
    [Documentation]    Performs GET request with response validation
    [Arguments]    ${endpoint}    ${expected_status}=200
    [Returns]    ${response}
    
    VAR    ${response}    GET On Session    books_api    ${endpoint}
    Status Should Be    ${expected_status}    ${response}
    RETURN    ${response}

POST Request With JSON
    [Documentation]    Performs POST request with JSON payload
    [Arguments]    ${endpoint}    ${payload}    ${expected_status}=201
    [Returns]    ${response}
    
    VAR    ${response}    POST On Session    
    ...    alias=books_api
    ...    url=${endpoint}
    ...    json=${payload}
    ...    expected_status=${expected_status}
    
    Request Should Be Successful    ${response}
    RETURN    ${response}

PUT Request With Validation
    [Documentation]    Performs PUT request with validation
    [Arguments]    ${endpoint}    ${payload}    ${expected_status}=200
    [Returns]    ${response}
    
    VAR    ${response}    PUT On Session
    ...    alias=books_api
    ...    url=${endpoint}
    ...    json=${payload}
    
    Status Should Be    ${expected_status}    ${response}
    RETURN    ${response}

DELETE Request With Validation
    [Documentation]    Performs DELETE request with validation
    [Arguments]    ${endpoint}    ${expected_status}=204
    
    VAR    ${response}    DELETE On Session    books_api    ${endpoint}
    Status Should Be    ${expected_status}    ${response}
```

### 14.3 Response Validation

```robotframework
*** Keywords ***
Validate JSON Response
    [Documentation]    Validates JSON response structure and content
    [Arguments]    ${response}    ${expected_keys}
    
    # Verify response is successful
    Request Should Be Successful    ${response}
    
    # Parse JSON
    VAR    ${json_data}    Set Variable    ${response.json()}
    
    # Verify expected keys exist
    FOR    ${key}    IN    @{expected_keys}
        Dictionary Should Contain Key    ${json_data}    ${key}
    END
    
    RETURN    ${json_data}

Validate Response Status And Content
    [Documentation]    Validates both status code and response content
    [Arguments]    ${response}    ${expected_status}    ${expected_content}
    
    Status Should Be    ${expected_status}    ${response}
    Should Contain    ${response.text}    ${expected_content}
```

### 14.4 Error Handling

```robotframework
*** Keywords ***
API Call With Error Handling
    [Documentation]    Makes API call with comprehensive error handling
    [Arguments]    ${method}    ${endpoint}    ${payload}=${None}
    
    TRY
        IF    '${method}' == 'GET'
            VAR    ${response}    GET On Session    books_api    ${endpoint}
        ELSE IF    '${method}' == 'POST'
            VAR    ${response}    POST On Session    books_api    ${endpoint}    json=${payload}
        ELSE IF    '${method}' == 'PUT'
            VAR    ${response}    PUT On Session    books_api    ${endpoint}    json=${payload}
        ELSE IF    '${method}' == 'DELETE'
            VAR    ${response}    DELETE On Session    books_api    ${endpoint}
        END
        
        RETURN    ${response}
        
    EXCEPT    HTTPError    AS    ${error}
        Log    HTTP Error occurred: ${error}    level=ERROR
        Fail    API call failed with HTTP error: ${error}
    EXCEPT    AS    ${error}
        Log    Unexpected error: ${error}    level=ERROR
        Fail    API call failed: ${error}
    END
```

---

## 15. Anti-Patterns (FORBIDDEN)

### 15.1 ⛔ Linear Scripting in Test Cases

**❌ FORBIDDEN:**
```robotframework
*** Test Cases ***
Bad Test Example
    New Browser    chromium    headless=True
    New Page    http://books-service:8000/
    Click    id=login-btn
    Fill Text    id=username    testuser
    Fill Text    id=password    secret
    Click    id=submit
    Get Text    css=.welcome    ==    Welcome testuser
```

**✅ CORRECT:**
```robotframework
*** Test Cases ***
User Should Be Able To Login Successfully
    [Documentation]    Verify user can login with valid credentials
    [Tags]    smoke    auth
    Given User Opens The Application
    When User Logs In With Valid Credentials
    Then User Should See Welcome Message

*** Keywords ***
User Opens The Application
    Initialize Browser
    Navigate To Login Page

User Logs In With Valid Credentials
    Enter Username    ${VALID_USERNAME}
    Enter Password    ${VALID_PASSWORD}
    Click Login Button

User Should See Welcome Message
    Verify Welcome Message Is Displayed    ${VALID_USERNAME}
```

### 15.2 ⛔ Legacy Syntax

**❌ FORBIDDEN:**
```robotframework
# Legacy variable setting
Set Variable              ${value}
Set Test Variable         ${var}    value
Set Suite Variable        ${var}    value

# Legacy conditionals
Run Keyword If            condition    keyword
Run Keyword Unless        condition    keyword

# Legacy loops
:FOR    ${item}    IN    @{items}
\    Log    ${item}

# Legacy error handling
Run Keyword And Ignore Error    keyword
Run Keyword And Return Status    keyword
```

**✅ CORRECT:** Use modern RF 7.4.1 syntax (see Section 2)

### 15.3 ⛔ Fixed Sleep Commands

**❌ FORBIDDEN:**
```robotframework
Click    id=submit
Sleep    5s    # NEVER DO THIS
Get Text    css=.result
```

**✅ CORRECT:**
```robotframework
Click    id=submit
Wait For Elements State    css=.result    visible    timeout=10s
Get Text    css=.result
```

### 15.4 ⛔ Hardcoded Values

**❌ FORBIDDEN:**
```robotframework
New Page    http://localhost:8000/
Fill Text    id=username    testuser
Click    id=submit-btn
```

**✅ CORRECT:**
```robotframework
New Page    ${BASE_URL}
Fill Text    ${USERNAME_FIELD}    ${TEST_USERNAME}
Click    ${SUBMIT_BUTTON}
```

### 15.5 ⛔ Missing Documentation

**❌ FORBIDDEN:**
```robotframework
*** Keywords ***
Create Book
    [Arguments]    ${title}
    POST On Session    books_api    /books/    json={"title": "${title}"}
```

**✅ CORRECT:**
```robotframework
*** Keywords ***
Create Book
    [Documentation]    Creates a new book via the API
    ...                
    ...                Arguments:
    ...                - title: Book title (string, required)
    ...                
    ...                Returns:
    ...                - response: HTTP response object
    [Arguments]    ${title}
    
    VAR    ${payload}    {"title": "${title}"}
    VAR    ${response}    POST On Session    books_api    /books/    json=${payload}
    RETURN    ${response}
```

### 15.6 ⛔ Test Dependencies

**❌ FORBIDDEN:**
```robotframework
*** Test Cases ***
Test 1 - Create Book
    # Creates book with ID 123
    Create Book    Test Book

Test 2 - Update Book
    # Depends on Test 1 creating book with ID 123
    Update Book    123    New Title
```

**✅ CORRECT:**
```robotframework
*** Test Cases ***
Test 1 - Create Book
    [Setup]    Initialize Test Environment
    [Teardown]    Cleanup Test Data
    
    VAR    ${book_id}    Create Book    Test Book
    Verify Book Exists    ${book_id}

Test 2 - Update Book
    [Setup]    Initialize Test Environment
    [Teardown]    Cleanup Test Data
    
    # Create its own test data
    VAR    ${book_id}    Create Book    Original Title
    Update Book    ${book_id}    New Title
    Verify Book Title    ${book_id}    New Title
```

---

## 16. Code Examples

### 16.1 Complete UI Test Example

```robotframework
*** Settings ***
Documentation     Books UI Test Suite
...               
...               Tests the Books web application UI functionality
...               including viewing, searching, and managing books.

Library           Browser
Resource          ../resources/pages/BooksPage.robot
Resource          ../resources/common/CommonKeywords.robot

Suite Setup       Initialize UI Test Suite
Suite Teardown    Cleanup UI Test Suite
Test Setup        Initialize Browser Test
Test Teardown     Cleanup Browser Test

Force Tags        ui    books
Default Tags      regression

*** Variables ***
${BASE_URL}           http://books-service:8000
${BROWSER}            chromium
${HEADLESS}           ${True}

*** Test Cases ***
User Should Be Able To View All Books
    [Documentation]    Verify that a user can view the complete list of books
    [Tags]    smoke    view
    
    Given User Opens The Books Application
    When User Navigates To Books Page
    Then All Books Should Be Displayed
    And Book Count Should Be Greater Than Zero

User Should Be Able To Search For Books By Title
    [Documentation]    Verify that a user can search for books using the search feature
    [Tags]    search
    
    Given User Opens The Books Application
    And User Navigates To Books Page
    When User Searches For Book    Python
    Then Search Results Should Contain    Python
    And Search Results Count Should Match Expected

User Should See Book Details When Clicking A Book Card
    [Documentation]    Verify that clicking a book card displays book details
    [Tags]    details
    
    Given User Opens The Books Application
    And User Navigates To Books Page
    When User Clicks On First Book Card
    Then Book Details Should Be Displayed
    And Book Details Should Contain Title And Author

*** Keywords ***
Initialize UI Test Suite
    [Documentation]    Runs once before all UI tests
    Log    Starting Books UI Test Suite

Cleanup UI Test Suite
    [Documentation]    Runs once after all UI tests
    Log    Books UI Test Suite Completed

Initialize Browser Test
    [Documentation]    Initializes browser for each test
    New Browser    ${BROWSER}    headless=${HEADLESS}
    New Context    viewport={'width': 1920, 'height': 1080}

Cleanup Browser Test
    [Documentation]    Closes browser after each test
    TRY
        Close Browser
    EXCEPT    AS    ${error}
        Log    Browser cleanup failed: ${error}    level=WARN
    END

User Opens The Books Application
    [Documentation]    Opens the books application in browser
    New Page    ${BASE_URL}
    Wait For Load State    networkidle

User Navigates To Books Page
    [Documentation]    Navigates to the books listing page
    Navigate To Books Page
    Verify Books Page Is Displayed

All Books Should Be Displayed
    [Documentation]    Verifies that books are visible on the page
    Wait For Elements State    css=.book-card    visible    timeout=10s

Book Count Should Be Greater Than Zero
    [Documentation]    Verifies at least one book is displayed
    VAR    ${count}    Get Book Count
    Should Be True    ${count} > 0    No books displayed on page

User Searches For Book
    [Documentation]    Performs a book search
    [Arguments]    ${search_term}
    Search For Book    ${search_term}

Search Results Should Contain
    [Documentation]    Verifies search results contain expected term
    [Arguments]    ${expected_term}
    VAR    ${results}    Get Text    css=.book-card
    Should Contain    ${results}    ${expected_term}    ignore_case=True

Search Results Count Should Match Expected
    [Documentation]    Verifies search results count is reasonable
    VAR    ${count}    Get Book Count
    Should Be True    ${count} > 0    No search results found

User Clicks On First Book Card
    [Documentation]    Clicks on the first book card
    Click    css=.book-card >> nth=0

Book Details Should Be Displayed
    [Documentation]    Verifies book details modal/page is displayed
    Wait For Elements State    css=.book-details    visible    timeout=10s

Book Details Should Contain Title And Author
    [Documentation]    Verifies book details contain required information
    VAR    ${details}    Get Text    css=.book-details
    Should Not Be Empty    ${details}
```

### 16.2 Complete API Test Example

```robotframework
*** Settings ***
Documentation     Books API Test Suite
...               
...               Tests the Books REST API functionality including
...               CRUD operations and error handling.

Library           RequestsLibrary
Library           Collections
Resource          ../resources/api/BooksAPI.robot
Resource          ../resources/common/CommonKeywords.robot

Suite Setup       Initialize API Test Suite
Suite Teardown    Cleanup API Test Suite
Test Setup        Initialize API Test
Test Teardown     Cleanup API Test

Force Tags        api    books
Default Tags      regression

*** Variables ***
${BASE_URL}           http://books-service:8000
${API_ENDPOINT}       /books/
${TIMEOUT}            30

*** Test Cases ***
User Should Be Able To Create A New Book Via API
    [Documentation]    Verify that a new book can be created via POST request
    [Tags]    smoke    create
    
    Given API Session Is Active
    When User Creates A New Book With Valid Data
    Then Book Should Be Created Successfully
    And Book Should Appear In Books List

User Should Be Able To Retrieve Book Details Via API
    [Documentation]    Verify that book details can be retrieved via GET request
    [Tags]    read
    
    Given API Session Is Active
    And A Book Exists In The System
    When User Retrieves Book Details
    Then Book Details Should Match Expected Data

User Should Be Able To Update Book Information Via API
    [Documentation]    Verify that book information can be updated via PUT request
    [Tags]    update
    
    Given API Session Is Active
    And A Book Exists In The System
    When User Updates Book Information
    Then Book Should Be Updated Successfully
    And Updated Information Should Be Persisted

User Should Be Able To Delete A Book Via API
    [Documentation]    Verify that a book can be deleted via DELETE request
    [Tags]    delete
    
    Given API Session Is Active
    And A Book Exists In The System
    When User Deletes The Book
    Then Book Should Be Deleted Successfully
    And Book Should Not Appear In Books List

API Should Return 404 For Nonexistent Book
    [Documentation]    Verify that API returns 404 for nonexistent book ID
    [Tags]    error-handling
    
    Given API Session Is Active
    When User Requests Nonexistent Book
    Then API Should Return 404 Status Code

API Should Validate Required Fields On Create
    [Documentation]    Verify that API validates required fields
    [Tags]    validation
    
    Given API Session Is Active
    When User Attempts To Create Book Without Required Fields
    Then API Should Return 422 Status Code
    And Response Should Contain Validation Errors

*** Keywords ***
Initialize API Test Suite
    [Documentation]    Runs once before all API tests
    Log    Starting Books API Test Suite
    Create Session    books_api    ${BASE_URL}    verify=True    timeout=${TIMEOUT}
    
    # Verify API is available
    VAR    ${response}    GET On Session    books_api    /health
    Status Should Be    200    ${response}

Cleanup API Test Suite
    [Documentation]    Runs once after all API tests
    Delete All Sessions
    Log    Books API Test Suite Completed

Initialize API Test
    [Documentation]    Runs before each API test
    VAR    ${TEST_START_TIME}    Get Time    epoch    scope=TEST
    VAR    ${TEST_ID}            ${TEST_START_TIME}    scope=TEST
    VAR    @{TEST_BOOK_IDS}      @{EMPTY}    scope=TEST

Cleanup API Test
    [Documentation]    Runs after each API test
    # Cleanup test books
    TRY
        FOR    ${book_id}    IN    @{TEST_BOOK_IDS}
            Delete Book Via API    ${book_id}
        END
    EXCEPT    AS    ${error}
        Log    Warning: Test cleanup failed: ${error}    level=WARN
    END

API Session Is Active
    [Documentation]    Verifies API session is active
    VAR    ${exists}    Session Exists    books_api
    Should Be True    ${exists}    API session not found

User Creates A New Book With Valid Data
    [Documentation]    Creates a new book with valid test data
    VAR    &{book_data}    Generate Unique Book Data
    VAR    ${response}    Create Book Via API    &{book_data}
    
    VAR    ${book_id}    Set Variable    ${response.json()['id']}
    Append To List    ${TEST_BOOK_IDS}    ${book_id}
    VAR    ${CREATED_BOOK_ID}    ${book_id}    scope=TEST
    VAR    ${CREATED_BOOK_DATA}    &{book_data}    scope=TEST

Book Should Be Created Successfully
    [Documentation]    Verifies book was created successfully
    Should Not Be Empty    ${CREATED_BOOK_ID}

Book Should Appear In Books List
    [Documentation]    Verifies created book appears in books list
    VAR    ${response}    GET On Session    books_api    ${API_ENDPOINT}
    Status Should Be    200    ${response}
    
    VAR    ${books}    Set Variable    ${response.json()}
    VAR    ${book_ids}    Create List
    FOR    ${book}    IN    @{books}
        Append To List    ${book_ids}    ${book['id']}
    END
    
    Should Contain    ${book_ids}    ${CREATED_BOOK_ID}

A Book Exists In The System
    [Documentation]    Creates a test book for the test
    User Creates A New Book With Valid Data

User Retrieves Book Details
    [Documentation]    Retrieves book details via API
    VAR    ${response}    GET On Session    books_api    ${API_ENDPOINT}${CREATED_BOOK_ID}
    Status Should Be    200    ${response}
    VAR    ${RETRIEVED_BOOK}    Set Variable    ${response.json()}    scope=TEST

Book Details Should Match Expected Data
    [Documentation]    Verifies retrieved book details match expected
    Should Be Equal    ${RETRIEVED_BOOK['id']}    ${CREATED_BOOK_ID}
    Should Be Equal    ${RETRIEVED_BOOK['title']}    ${CREATED_BOOK_DATA['title']}

User Updates Book Information
    [Documentation]    Updates book information via API
    VAR    &{update_data}    title=Updated Title    author=Updated Author
    VAR    ${response}    PUT On Session    
    ...    books_api    
    ...    ${API_ENDPOINT}${CREATED_BOOK_ID}
    ...    json=&{update_data}
    Status Should Be    200    ${response}
    VAR    ${UPDATED_BOOK_DATA}    &{update_data}    scope=TEST

Book Should Be Updated Successfully
    [Documentation]    Verifies book was updated successfully
    Should Not Be Empty    ${UPDATED_BOOK_DATA}

Updated Information Should Be Persisted
    [Documentation]    Verifies updated information is persisted
    VAR    ${response}    GET On Session    books_api    ${API_ENDPOINT}${CREATED_BOOK_ID}
    Status Should Be    200    ${response}
    VAR    ${book}    Set Variable    ${response.json()}
    Should Be Equal    ${book['title']}    ${UPDATED_BOOK_DATA['title']}

User Deletes The Book
    [Documentation]    Deletes book via API
    VAR    ${response}    DELETE On Session    books_api    ${API_ENDPOINT}${CREATED_BOOK_ID}
    Status Should Be    204    ${response}

Book Should Be Deleted Successfully
    [Documentation]    Verifies book was deleted
    # Remove from cleanup list since already deleted
    Remove Values From List    ${TEST_BOOK_IDS}    ${CREATED_BOOK_ID}

Book Should Not Appear In Books List
    [Documentation]    Verifies deleted book does not appear in list
    VAR    ${response}    GET On Session    books_api    ${API_ENDPOINT}${CREATED_BOOK_ID}    expected_status=404
    Status Should Be    404    ${response}

User Requests Nonexistent Book
    [Documentation]    Requests a nonexistent book
    VAR    ${response}    GET On Session    books_api    ${API_ENDPOINT}99999    expected_status=404
    VAR    ${ERROR_RESPONSE}    Set Variable    ${response}    scope=TEST

API Should Return 404 Status Code
    [Documentation]    Verifies API returned 404
    Status Should Be    404    ${ERROR_RESPONSE}

User Attempts To Create Book Without Required Fields
    [Documentation]    Attempts to create book with missing required fields
    VAR    &{invalid_data}    author=Test Author
    VAR    ${response}    POST On Session    
    ...    books_api    
    ...    ${API_ENDPOINT}
    ...    json=&{invalid_data}
    ...    expected_status=422
    VAR    ${VALIDATION_RESPONSE}    Set Variable    ${response}    scope=TEST

API Should Return 422 Status Code
    [Documentation]    Verifies API returned 422
    Status Should Be    422    ${VALIDATION_RESPONSE}

Response Should Contain Validation Errors
    [Documentation]    Verifies response contains validation error details
    VAR    ${error_data}    Set Variable    ${VALIDATION_RESPONSE.json()}
    Should Contain    ${error_data}    detail

Generate Unique Book Data
    [Documentation]    Generates unique book data for testing
    [Returns]    &{book_data}
    
    VAR    ${timestamp}    Get Time    epoch
    VAR    &{book_data}    
    ...    title=Test Book ${timestamp}
    ...    author=Test Author ${timestamp}
    ...    year=2024
    ...    isbn=ISBN-${timestamp}
    
    RETURN    &{book_data}

Create Book Via API
    [Documentation]    Creates a book via API
    [Arguments]    &{book_data}
    [Returns]    ${response}
    
    VAR    ${response}    POST On Session    
    ...    books_api    
    ...    ${API_ENDPOINT}
    ...    json=&{book_data}
    
    Status Should Be    201    ${response}
    RETURN    ${response}

Delete Book Via API
    [Documentation]    Deletes a book via API
    [Arguments]    ${book_id}
    
    TRY
        VAR    ${response}    DELETE On Session    books_api    ${API_ENDPOINT}${book_id}
        Status Should Be    204    ${response}
    EXCEPT    AS    ${error}
        Log    Failed to delete book ${book_id}: ${error}    level=WARN
    END
```

---

## 17. MCP Integration

### 17.1 Available MCP Servers

This project provides two MCP servers for Robot Framework development:

1. **robotframework-mcp** - Test execution environment
2. **rf-docs-mcp** - Documentation query environment

### 17.2 MCP Configuration

Configuration files are generated by `./quick-start.sh` or manually via:
```bash
./RobotFramework-MCP-server/create-mcp-config.sh gitlab
```

**GitLab Duo Configuration:** `.gitlab/duo/mcp.json`

### 17.3 Using MCP Tools

**Documentation Query (rf-docs-mcp):**
```python
# Get keyword documentation
get_keyword_documentation(
    keyword_name="Should Be Equal",
    library_name="BuiltIn"
)

# List library keywords
get_library_keywords(
    library_name="Collections",
    filter_pattern=".*List.*"
)

# Search documentation
search_rf_documentation(
    query="variables",
    max_results=10
)

# Get installed library docs
get_installed_library_docs(
    library_name="Browser",
    format="json"
)
```

**Test Execution (robotframework-mcp):**
```python
# Run test suite
run_suite(
    suite_path="/tests/books_api_tests.robot",
    include_tags="smoke",
    variables={"BASE_URL": "http://books-service:8000"}
)

# Run specific test
run_test_by_name(
    test_name="User Should Be Able To Create A New Book",
    suite_path="/tests/books_api_tests.robot"
)

# List tests
list_tests(suite_path="/tests/")

# Run Robocop audit
run_robocop_audit(
    target_path="/tests/",
    report_format="json"
)
```

### 17.4 Test Results Location

All test results are saved to `./robot_results/` (mapped from container `/results`):
- `log.html` - Detailed test execution log
- `report.html` - Test execution report
- `output.xml` - Machine-readable test results

---

## Document Revision History

| Version | Date       | Changes |
|---------|------------|---------|
| 1.0     | 2026-02-24 | Initial comprehensive standards document for GitLab Duo |

---

**End of Document**

For questions or clarifications, refer to:
- Architecture: `docs/architecture.md`
- Testing Guide: `docs/testing.md`
- Development Workflow: `docs/development-workflow.md`
