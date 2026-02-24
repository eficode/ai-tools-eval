SOURCE OF TRUTH: For all Robot Framework tasks, prioritize the instructions located in `.amazonq/robot-framework-standards.md`. Read that file first to ensure compliance.

# Robot Framework Test Standards for Amazon Q
**Version:** 7.4.1 | **Browser Library:** 19.12.3 | **RequestsLibrary:** 0.9.7

## 1. MANDATORY COMPLIANCE

### Source Authority
**CRITICAL:** Use ONLY keywords from these validated sources:
- **Standard Libraries (RF 7.4.1):** BuiltIn, Collections, String, DateTime, OperatingSystem, Process, Screenshot, Telnet, XML
- **Browser Library (19.12.3):** 147 keywords for Playwright-based web automation
- **RequestsLibrary (0.9.7):** 33 keywords for HTTP/REST API testing
- **Local Documentation:** `/app/docs/` in robotframework-mcp container

Query documentation via MCP tools before using any keyword. Invalid keywords will cause test failures.

### Modern Syntax Requirements (RF 7.4.1)

**✅ REQUIRED SYNTAX:**
```robot
# Variables - Use VAR
VAR    ${username}    testuser
VAR    @{items}    apple    banana    orange
VAR    &{config}    host=localhost    port=8000

# Conditionals - Use IF/ELSE/ELSE IF
IF    ${status_code} == 200
    Log    Success
ELSE IF    ${status_code} == 404
    Log    Not Found
ELSE
    Fail    Unexpected status: ${status_code}
END

# Loops - Use FOR
FOR    ${book}    IN    @{books}
    Log    ${book}[title]
END

FOR    ${i}    IN RANGE    10
    Click    id=button-${i}
END

# Error Handling - Use TRY/EXCEPT
TRY
    Click    id=submit-button
EXCEPT    ElementNotFound
    Log    Button not found, using alternative
    Click    xpath=//button[@type='submit']
END

# While Loops - Use WHILE
VAR    ${count}    0
WHILE    ${count} < 10
    ${count}=    Evaluate    ${count} + 1
    Log    Count: ${count}
END
```

**❌ FORBIDDEN LEGACY SYNTAX:**
```robot
# DO NOT USE THESE:
Set Test Variable    ${var}    value          # Use VAR instead
Set Suite Variable    ${var}    value         # Use VAR instead
Run Keyword If    condition    keyword        # Use IF/ELSE instead
Run Keyword Unless    condition    keyword     # Use IF/ELSE instead
:FOR    ${item}    IN    @{list}              # Use FOR instead
```

## 2. ARCHITECTURAL PATTERNS

### Test Structure Hierarchy
```
*** Test Cases ***
User Should Be Able To Add New Book
    [Documentation]    Verify book creation through UI
    [Tags]    ui    smoke    crud
    Given User Is On Books Page
    When User Adds Book With Valid Data
    Then Book Should Appear In List

*** Keywords ***
User Is On Books Page
    [Documentation]    Navigate to books page and verify loaded
    New Page    ${BASE_URL}
    Wait For Load State    networkidle
    Get Title    ==    Books Database

User Adds Book With Valid Data
    [Documentation]    Fill and submit book creation form
    VAR    ${title}    Test Book ${TIMESTAMP}
    Click    id=add-book-btn
    Fill Text    id=title-input    ${title}
    Fill Text    id=author-input    Test Author
    Select Options By    id=category-select    value    Fiction
    Click    id=save-btn
    Wait For Response    matcher=**/books    timeout=5s

Book Should Appear In List
    [Documentation]    Verify book appears in UI list
    Wait Until Network Is Idle    timeout=3s
    ${books}=    Get Elements    css=.book-card
    Should Not Be Empty    ${books}
```

### Page Object Pattern
```robot
*** Settings ***
Resource    pages/books_page.resource

*** Keywords ***
# pages/books_page.resource
Navigate To Books Page
    [Documentation]    Open books page
    New Page    ${BASE_URL}
    Wait For Load State    domcontentloaded

Add New Book
    [Arguments]    ${title}    ${author}    ${category}
    [Documentation]    Create book via UI
    Click    ${BTN_ADD_BOOK}
    Fill Text    ${INPUT_TITLE}    ${title}
    Fill Text    ${INPUT_AUTHOR}    ${author}
    Select Options By    ${SELECT_CATEGORY}    value    ${category}
    Click    ${BTN_SAVE}

*** Variables ***
${BTN_ADD_BOOK}       id=add-book-btn
${INPUT_TITLE}        id=title-input
${INPUT_AUTHOR}       id=author-input
${SELECT_CATEGORY}    id=category-select
${BTN_SAVE}           id=save-btn
```

### Data-Driven Testing
```robot
*** Test Cases ***
Verify Book Creation With Multiple Categories
    [Template]    Create Book And Verify Category
    Fiction        The Great Novel
    Non-Fiction    History Book
    Science        Physics Guide
    Biography      Life Story

*** Keywords ***
Create Book And Verify Category
    [Arguments]    ${category}    ${title}
    Given User Is On Books Page
    When User Creates Book    ${title}    Test Author    ${category}
    Then Book Category Should Be    ${category}
```

## 3. WAIT STRATEGIES & STABILITY

### Explicit Waits (Browser Library)
```robot
# ✅ CORRECT - Explicit waits
Wait For Elements State    id=book-list    visible    timeout=5s
Wait Until Network Is Idle    timeout=3s
Wait For Response    matcher=**/books    timeout=5s
Wait For Load State    networkidle

# Element state waits
Wait For Elements State    css=.loading-spinner    hidden    timeout=10s
Wait For Elements State    id=submit-btn    enabled    timeout=3s

# Custom conditions
Wait For Condition    return document.readyState === 'complete'    timeout=5s

# ❌ FORBIDDEN - Fixed sleeps
Sleep    2s    # NEVER USE THIS
```

### API Wait Patterns (RequestsLibrary)
```robot
# Polling with retry
VAR    ${max_retries}    5
VAR    ${retry_count}    0
WHILE    ${retry_count} < ${max_retries}
    ${response}=    GET On Session    api    /books/${book_id}
    IF    ${response.status_code} == 200
        BREAK
    END
    ${retry_count}=    Evaluate    ${retry_count} + 1
    Sleep    1s    # Acceptable for API polling
END
Status Should Be    200    ${response}
```

## 4. BROWSER LIBRARY ESSENTIALS (19.12.3)

### Browser Context Management
```robot
*** Settings ***
Library    Browser    timeout=10s    retry_assertions_for=3s

*** Test Cases ***
Test With Browser Context
    New Browser    chromium    headless=true
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    ${BASE_URL}
    # Test steps
    [Teardown]    Close Browser

*** Keywords ***
Setup Browser For Testing
    [Documentation]    Initialize browser with standard config
    New Browser    chromium    headless=${HEADLESS}
    New Context    
    ...    viewport={'width': 1920, 'height': 1080}
    ...    acceptDownloads=true
    ...    ignoreHTTPSErrors=true
```

### Common Browser Keywords
```robot
# Navigation
New Page    http://localhost:8000
Go To    http://localhost:8000/books
Reload

# Interactions
Click    id=submit-button
Fill Text    id=username    testuser
Type Text    id=search    Robot Framework    delay=50ms
Select Options By    id=category    value    Fiction
Check Checkbox    id=agree-terms
Upload File By Selector    id=file-input    ${CURDIR}/test.pdf

# Assertions
Get Title    ==    Books Database
Get Text    css=.book-title    ==    Test Book
Get Element Count    css=.book-card    ==    5
Get Attribute    id=submit-btn    disabled    ==    ${None}

# Waits
Wait For Elements State    id=loading    hidden    timeout=5s
Wait Until Network Is Idle    timeout=3s
Wait For Response    matcher=**/api/books    timeout=5s

# Screenshots
Take Screenshot    fullPage=true
Take Screenshot    selector=id=book-card-1

# JavaScript Execution
${result}=    Evaluate JavaScript    document.querySelector('#count').textContent
Execute JavaScript    window.scrollTo(0, document.body.scrollHeight)
```

### Selector Strategies
```robot
# ID (fastest, most reliable)
Click    id=submit-button

# CSS Selectors
Click    css=.book-card:first-child button.delete
Get Text    css=[data-testid="book-title"]

# XPath (use sparingly)
Click    xpath=//button[contains(text(), 'Submit')]

# Text-based (fragile, avoid for critical elements)
Click    text=Add Book

# Playwright selectors (recommended)
Click    data-testid=submit-btn
Click    role=button[name="Submit"]
```

## 5. REQUESTSLIBRARY ESSENTIALS (0.9.7)

### Session Management
```robot
*** Settings ***
Library    RequestsLibrary

*** Test Cases ***
API Test With Session
    Create Session    api    ${API_URL}    verify=true
    ${response}=    GET On Session    api    /books
    Status Should Be    200    ${response}
    [Teardown]    Delete All Sessions

*** Keywords ***
Setup API Session
    [Documentation]    Create authenticated API session
    VAR    &{headers}    Content-Type=application/json    Accept=application/json
    Create Session    api    ${API_URL}    headers=${headers}    verify=true
```

### HTTP Methods
```robot
# GET Request
${response}=    GET On Session    api    /books
Status Should Be    200    ${response}
${books}=    Set Variable    ${response.json()}

# GET with parameters
VAR    &{params}    category=Fiction    limit=10
${response}=    GET On Session    api    /books    params=${params}

# POST Request
VAR    &{book_data}    title=New Book    author=Test Author    category=Fiction
${response}=    POST On Session    api    /books    json=${book_data}
Status Should Be    201    ${response}
${book_id}=    Set Variable    ${response.json()}[id]

# PUT Request
VAR    &{update_data}    title=Updated Title    author=Updated Author
${response}=    PUT On Session    api    /books/${book_id}    json=${update_data}
Status Should Be    200    ${response}

# DELETE Request
${response}=    DELETE On Session    api    /books/${book_id}
Status Should Be    200    ${response}

# Custom headers
VAR    &{headers}    Authorization=Bearer ${token}
${response}=    GET On Session    api    /books    headers=${headers}
```

### Response Validation
```robot
# Status validation
Status Should Be    200    ${response}
Request Should Be Successful    ${response}

# JSON response validation
${json}=    Set Variable    ${response.json()}
Should Be Equal    ${json}[title]    Expected Title
Should Contain    ${json}[author]    Test
Length Should Be    ${json}[books]    5

# Response headers
${content_type}=    Get From Dictionary    ${response.headers}    Content-Type
Should Contain    ${content_type}    application/json
```

## 6. STANDARD LIBRARY KEYWORDS (RF 7.4.1)

### BuiltIn Library (Most Common)
```robot
# Logging
Log    Message    level=INFO
Log To Console    Visible message
Log Many    ${var1}    ${var2}    ${var3}

# Assertions
Should Be Equal    ${actual}    ${expected}
Should Not Be Equal    ${actual}    ${unexpected}
Should Contain    ${list}    ${item}
Should Be True    ${condition}
Should Be Empty    ${list}
Length Should Be    ${list}    5

# Control Flow (use modern syntax instead)
Pass Execution    Skipping test
Fail    Test failed: ${reason}
Fatal Error    Critical failure

# Variables
Set Test Variable    ${var}    value    # DEPRECATED - use VAR
Set Suite Variable    ${var}    value   # DEPRECATED - use VAR
```

### Collections Library
```robot
*** Settings ***
Library    Collections

*** Keywords ***
Process Book List
    [Arguments]    @{books}
    
    # List operations
    ${count}=    Get Length    ${books}
    ${first}=    Get From List    ${books}    0
    Append To List    ${books}    New Book
    Remove From List    ${books}    0
    ${contains}=    List Should Contain Value    ${books}    Test Book
    
    # Dictionary operations
    VAR    &{book}    title=Test    author=Author    category=Fiction
    ${title}=    Get From Dictionary    ${book}    title
    Set To Dictionary    ${book}    year=2024
    Dictionary Should Contain Key    ${book}    title
    ${keys}=    Get Dictionary Keys    ${book}
    ${values}=    Get Dictionary Values    ${book}
```

### String Library
```robot
*** Settings ***
Library    String

*** Keywords ***
Validate Book Title
    [Arguments]    ${title}
    
    ${lower}=    Convert To Lower Case    ${title}
    ${upper}=    Convert To Upper Case    ${title}
    ${length}=    Get Length    ${title}
    Should Match Regexp    ${title}    ^[A-Za-z0-9\\s]+$
    ${contains}=    Should Contain    ${title}    Book
    ${stripped}=    Strip String    ${title}
    ${replaced}=    Replace String    ${title}    old    new
    ${split}=    Split String    ${title}    separator=${SPACE}
```

### DateTime Library
```robot
*** Settings ***
Library    DateTime

*** Keywords ***
Generate Timestamp
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    RETURN    ${timestamp}

Validate Date Range
    [Arguments]    ${start_date}    ${end_date}
    ${diff}=    Subtract Date From Date    ${end_date}    ${start_date}
    Should Be True    ${diff} > 0
    ${formatted}=    Convert Date    ${start_date}    result_format=%Y-%m-%d
```

## 7. TEST ORGANIZATION & METADATA

### Test Case Naming
```robot
# ✅ GOOD - Behavior-focused, descriptive
User Should Be Able To Create New Book
System Should Reject Invalid Book Data
Admin Can Delete Multiple Books At Once
API Should Return 404 For Non-Existent Book

# ❌ BAD - Implementation-focused, vague
Test 1
Create Book
Click Button
API Test
```

### Documentation & Tags
```robot
*** Settings ***
Documentation    Books Management Test Suite
...              
...              This suite validates CRUD operations for books
...              through both UI and API interfaces.
...              
...              Prerequisites:
...              - Books service running on ${BASE_URL}
...              - Database initialized with sample data
...              
...              Test Data:
...              - Uses unique timestamps for book titles
...              - Cleans up created books in teardown

Force Tags       books    regression
Default Tags     ui

*** Test Cases ***
User Should Be Able To Create Book Via UI
    [Documentation]    Validates complete book creation workflow
    ...                
    ...                Steps:
    ...                1. Navigate to books page
    ...                2. Click add book button
    ...                3. Fill form with valid data
    ...                4. Submit and verify success
    ...                
    ...                Expected: Book appears in list with correct data
    [Tags]    smoke    crud    create
    [Setup]    Setup Browser For Testing
    # Test implementation
    [Teardown]    Cleanup Test Data
```

### Variables Organization
```robot
*** Variables ***
# Environment Configuration
${BASE_URL}           http://localhost:8000
${API_URL}            http://books-service:8000
${BROWSER}            chromium
${HEADLESS}           true

# Test Data
${TEST_TITLE}         Robot Framework Test Book
${TEST_AUTHOR}        Test Automation Author
${TEST_CATEGORY}      Fiction

# Timeouts
${DEFAULT_TIMEOUT}    10s
${API_TIMEOUT}        5s
${LOAD_TIMEOUT}       30s

# Selectors (use Page Object pattern instead)
${BTN_ADD_BOOK}       id=add-book-btn
${INPUT_TITLE}        id=title-input

# Dynamic Variables (generate in keywords)
${TIMESTAMP}          # Set in Suite Setup
${UNIQUE_ID}          # Set per test
```

## 8. SETUP & TEARDOWN PATTERNS

### Suite-Level Lifecycle
```robot
*** Settings ***
Suite Setup       Suite Initialization
Suite Teardown    Suite Cleanup

*** Keywords ***
Suite Initialization
    [Documentation]    One-time setup for entire suite
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    Set Suite Variable    ${TIMESTAMP}    ${timestamp}
    Setup API Session
    Setup Browser For Testing
    Log To Console    Suite started: ${SUITE_NAME}

Suite Cleanup
    [Documentation]    Cleanup after all tests
    Delete All Sessions
    Close Browser
    Log To Console    Suite completed: ${SUITE_NAME}
```

### Test-Level Lifecycle
```robot
*** Settings ***
Test Setup        Test Initialization
Test Teardown     Test Cleanup

*** Keywords ***
Test Initialization
    [Documentation]    Setup before each test
    ${unique_id}=    Generate Random String    8    [LETTERS][NUMBERS]
    Set Test Variable    ${UNIQUE_ID}    ${unique_id}
    Log    Starting test: ${TEST_NAME}

Test Cleanup
    [Documentation]    Cleanup after each test
    Run Keyword If Test Failed    Take Screenshot    ${TEST_NAME}_failure
    Cleanup Test Data
    Log    Completed test: ${TEST_NAME}
```

### Conditional Teardown
```robot
*** Keywords ***
Cleanup Test Data
    [Documentation]    Remove test data if created
    TRY
        IF    '${BOOK_ID}' != '${EMPTY}'
            ${response}=    DELETE On Session    api    /books/${BOOK_ID}
            Log    Deleted test book: ${BOOK_ID}
        END
    EXCEPT
        Log    Cleanup failed, continuing    level=WARN
    END
```

## 9. ERROR HANDLING & RESILIENCE

### Try-Except Patterns
```robot
*** Keywords ***
Robust Element Click
    [Arguments]    ${selector}
    [Documentation]    Click with fallback strategies
    
    TRY
        Click    ${selector}    timeout=3s
    EXCEPT    TimeoutError
        Log    Primary selector failed, trying alternative    level=WARN
        TRY
            Click    ${selector}    force=true
        EXCEPT
            Take Screenshot
            Fail    Unable to click element: ${selector}
        END
    END

Safe API Call
    [Arguments]    ${endpoint}
    [Documentation]    API call with retry logic
    
    VAR    ${max_retries}    3
    VAR    ${retry_count}    0
    
    WHILE    ${retry_count} < ${max_retries}
        TRY
            ${response}=    GET On Session    api    ${endpoint}    timeout=5
            Request Should Be Successful    ${response}
            RETURN    ${response}
        EXCEPT
            ${retry_count}=    Evaluate    ${retry_count} + 1
            IF    ${retry_count} < ${max_retries}
                Log    Retry ${retry_count}/${max_retries}    level=WARN
                Sleep    2s
            ELSE
                Fail    API call failed after ${max_retries} retries
            END
        END
    END
```

## 10. BEST PRACTICES CHECKLIST

### Test Independence
- ✅ Each test can run in any order
- ✅ Tests create their own test data
- ✅ Tests clean up after themselves
- ✅ No shared state between tests
- ❌ Never depend on execution order

### Maintainability
- ✅ Use Page Object pattern for UI tests
- ✅ Extract reusable keywords to Resource files
- ✅ Use meaningful variable names
- ✅ Document complex logic
- ✅ Keep test cases readable (Gherkin style)
- ❌ No hardcoded values in test cases
- ❌ No duplicate code

### Stability
- ✅ Use explicit waits (Wait For Elements State)
- ✅ Wait for network idle before assertions
- ✅ Use unique test data (timestamps, UUIDs)
- ✅ Implement retry logic for flaky operations
- ❌ Never use Sleep for synchronization
- ❌ Avoid text-based selectors

### Performance
- ✅ Reuse browser contexts when possible
- ✅ Use API for test data setup
- ✅ Minimize unnecessary waits
- ✅ Close resources in teardown
- ❌ Don't create new browser per test

## 11. COMPLETE EXAMPLE

```robot
*** Settings ***
Documentation     Books CRUD Operations Test Suite
Library           Browser    timeout=10s    retry_assertions_for=3s
Library           RequestsLibrary
Resource          resources/books_page.resource
Suite Setup       Suite Initialization
Suite Teardown    Suite Cleanup
Test Setup        Test Initialization
Test Teardown     Test Cleanup
Force Tags        books    regression

*** Variables ***
${BASE_URL}           http://localhost:8000
${API_URL}            http://books-service:8000
${BROWSER}            chromium
${HEADLESS}           true

*** Test Cases ***
User Should Be Able To Create Book Via UI
    [Documentation]    Verify book creation through web interface
    [Tags]    ui    smoke    create
    Given User Is On Books Page
    When User Creates Book With Valid Data
    Then Book Should Appear In Books List
    And Book Should Be Retrievable Via API

API Should Return All Books
    [Documentation]    Verify GET /books endpoint
    [Tags]    api    smoke
    Given Books Exist In Database
    When User Requests All Books Via API
    Then Response Should Contain Book List
    And Response Should Have Valid Structure

User Should Be Able To Delete Book
    [Documentation]    Verify book deletion workflow
    [Tags]    ui    delete
    Given Book Exists In System
    And User Is On Books Page
    When User Deletes The Book
    Then Book Should Not Appear In List
    And API Should Return 404 For Deleted Book

*** Keywords ***
Suite Initialization
    [Documentation]    Initialize test environment
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    Set Suite Variable    ${TIMESTAMP}    ${timestamp}
    Create Session    api    ${API_URL}    verify=true
    New Browser    ${BROWSER}    headless=${HEADLESS}
    New Context    viewport={'width': 1920, 'height': 1080}

Suite Cleanup
    [Documentation]    Cleanup test environment
    Delete All Sessions
    Close Browser

Test Initialization
    [Documentation]    Setup for each test
    ${unique_id}=    Generate Random String    8    [LETTERS][NUMBERS]
    Set Test Variable    ${UNIQUE_ID}    ${unique_id}
    Set Test Variable    ${BOOK_ID}    ${EMPTY}

Test Cleanup
    [Documentation]    Cleanup after each test
    Run Keyword If Test Failed    Take Screenshot    ${TEST_NAME}_failure
    IF    '${BOOK_ID}' != '${EMPTY}'
        TRY
            DELETE On Session    api    /books/${BOOK_ID}
        EXCEPT
            Log    Cleanup failed for book ${BOOK_ID}    level=WARN
        END
    END

# Given Keywords
User Is On Books Page
    [Documentation]    Navigate to books page
    New Page    ${BASE_URL}
    Wait For Load State    networkidle
    Get Title    ==    Books Database

Books Exist In Database
    [Documentation]    Verify books exist via API
    ${response}=    GET On Session    api    /books
    Status Should Be    200    ${response}
    ${books}=    Set Variable    ${response.json()}
    Should Not Be Empty    ${books}

Book Exists In System
    [Documentation]    Create test book via API
    VAR    &{book_data}    
    ...    title=Test Book ${TIMESTAMP}
    ...    author=Test Author
    ...    category=Fiction
    ${response}=    POST On Session    api    /books    json=${book_data}
    Status Should Be    201    ${response}
    ${book_id}=    Set Variable    ${response.json()}[id]
    Set Test Variable    ${BOOK_ID}    ${book_id}

# When Keywords
User Creates Book With Valid Data
    [Documentation]    Fill and submit book form
    VAR    ${title}    Test Book ${TIMESTAMP} ${UNIQUE_ID}
    Click    id=add-book-btn
    Wait For Elements State    id=book-form    visible
    Fill Text    id=title-input    ${title}
    Fill Text    id=author-input    Test Author
    Select Options By    id=category-select    value    Fiction
    Click    id=save-btn
    Wait For Response    matcher=**/books    timeout=5s
    Set Test Variable    ${TEST_BOOK_TITLE}    ${title}

User Requests All Books Via API
    [Documentation]    GET all books
    ${response}=    GET On Session    api    /books
    Set Test Variable    ${API_RESPONSE}    ${response}

User Deletes The Book
    [Documentation]    Delete book via UI
    ${selector}=    Set Variable    css=[data-book-id="${BOOK_ID}"] button.delete
    Click    ${selector}
    Wait For Elements State    css=.confirmation-dialog    visible
    Click    id=confirm-delete-btn
    Wait Until Network Is Idle    timeout=3s

# Then Keywords
Book Should Appear In Books List
    [Documentation]    Verify book in UI list
    Wait Until Network Is Idle    timeout=3s
    ${text}=    Get Text    css=.book-list
    Should Contain    ${text}    ${TEST_BOOK_TITLE}

Book Should Be Retrievable Via API
    [Documentation]    Verify book via API
    ${response}=    GET On Session    api    /books
    ${books}=    Set Variable    ${response.json()}
    ${found}=    Evaluate    [b for b in ${books} if b['title'] == '${TEST_BOOK_TITLE}']
    Should Not Be Empty    ${found}
    ${book_id}=    Set Variable    ${found}[0][id]
    Set Test Variable    ${BOOK_ID}    ${book_id}

Response Should Contain Book List
    [Documentation]    Validate response structure
    Status Should Be    200    ${API_RESPONSE}
    ${books}=    Set Variable    ${API_RESPONSE.json()}
    Should Not Be Empty    ${books}

Response Should Have Valid Structure
    [Documentation]    Validate book object structure
    ${books}=    Set Variable    ${API_RESPONSE.json()}
    ${first_book}=    Set Variable    ${books}[0]
    Dictionary Should Contain Key    ${first_book}    id
    Dictionary Should Contain Key    ${first_book}    title
    Dictionary Should Contain Key    ${first_book}    author
    Dictionary Should Contain Key    ${first_book}    category

Book Should Not Appear In List
    [Documentation]    Verify book removed from UI
    Wait Until Network Is Idle    timeout=3s
    TRY
        ${selector}=    Set Variable    css=[data-book-id="${BOOK_ID}"]
        Wait For Elements State    ${selector}    hidden    timeout=3s
    EXCEPT
        ${text}=    Get Text    css=.book-list
        Should Not Contain    ${text}    ${TEST_BOOK_TITLE}
    END

API Should Return 404 For Deleted Book
    [Documentation]    Verify book deleted via API
    TRY
        ${response}=    GET On Session    api    /books/${BOOK_ID}    expected_status=404
        Status Should Be    404    ${response}
    EXCEPT
        Log    Book successfully deleted    level=INFO
    END
```

## 12. QUICK REFERENCE

### MCP Tools for Documentation
```robot
# Query keyword documentation before use:
# - get_library_keywords(library_name="Browser")
# - get_keyword_documentation(keyword_name="Click")
# - check_keyword_availability(keyword_name="Fill Text")
# - get_installed_library_docs(library_name="Browser", format="json")
```

### Common Patterns
```robot
# Unique test data
${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
${uuid}=    Generate Random String    8    [LETTERS][NUMBERS]

# Conditional execution
IF    ${condition}
    Keyword
END

# Retry logic
FOR    ${i}    IN RANGE    3
    TRY
        Flaky Keyword
        BREAK
    EXCEPT
        Sleep    1s
    END
END

# Safe cleanup
TRY
    Cleanup Keyword
EXCEPT
    Log    Cleanup failed    level=WARN
END
```

---
**Document Version:** 1.0  
**Last Updated:** 2024  
**Target Tool:** Amazon Q Developer  
**Maintained By:** AI Tools Evaluation Project
