# Robot Framework Test Standards for Claude Code

**SOURCE OF TRUTH**: For all Robot Framework tasks, prioritize the instructions located in `.claude/ROBOT_FRAMEWORK_STANDARDS.md`. Read this file first to ensure compliance.

---

## Document Information

**Target Tool**: Claude Code
**Version**: Robot Framework 7.4.1
**Library Versions**:
- `robotframework==7.4.1`
- `robotframework-browser==19.12.3`
- `robotframework-requests==0.9.7`

**Last Updated**: 2026-02-26
**Purpose**: Comprehensive standards for generating Robot Framework tests using Claude Code

---

## Table of Contents

1. [Knowledge Sources](#knowledge-sources)
2. [Syntax Rules (MANDATORY)](#syntax-rules-mandatory)
3. [Architectural Standards](#architectural-standards)
4. [Test Design Principles](#test-design-principles)
5. [Modern RF 7.x Syntax Reference](#modern-rf-7x-syntax-reference)
6. [Standard Library Keywords](#standard-library-keywords)
7. [External Library Guidelines](#external-library-guidelines)
8. [Anti-Patterns (FORBIDDEN)](#anti-patterns-forbidden)
9. [File Structure Template](#file-structure-template)
10. [Best Practices Checklist](#best-practices-checklist)

---

## Knowledge Sources

### Primary Sources (MANDATORY)

1. **MCP Server: rf-docs-mcp**
   - Access via MCP tools: `robot-get_keyword_documentation`, `robot-get_library_documentation`
   - Contains 321 keywords from 9 standard libraries (RF 7.4.1)
   - Source for: BuiltIn, String, Collections, DateTime, OperatingSystem, Process, XML, Screenshot, Telnet

2. **Local Documentation: `/app/docs/` in robotframework-mcp container**
   - `Browser.json` - Browser Library 19.12.3 (Playwright-based)
   - `RequestsLibrary.json` - RequestsLibrary 0.9.7

3. **User Guide Syntax**
   - Query rf-docs-mcp for modern syntax documentation
   - Covers: VAR, IF/ELSE, FOR, WHILE, TRY/EXCEPT, RETURN, BREAK/CONTINUE

### CRITICAL RULE
**ANY KEYWORD NOT FOUND IN THESE SOURCES IS INVALID AND MUST NOT BE USED.**

---

## Syntax Rules (MANDATORY)

### ✅ MODERN SYNTAX (RF 7.x) - USE THESE

#### 1. Variable Assignment - VAR Syntax (RF 7.0+)

**Scalar Variables:**
```robot
VAR    ${variable}       value
VAR    ${number}         ${42}
VAR    ${path}           ${CURDIR}/data
VAR    ${multiline}      This is a longer value
...                      split across multiple lines.
...                      Parts are joined with spaces.
```

**Lists:**
```robot
VAR    @{items}          first    second    third
VAR    @{numbers}        ${1}     ${2}      ${3}
VAR    @{empty}
```

**Dictionaries:**
```robot
VAR    &{user}           name=John    age=30    role=admin
VAR    &{config}         host=localhost    port=8000
VAR    &{empty}
```

**Variable Scopes:**
```robot
VAR    ${local}          value                    # LOCAL (default)
VAR    ${TEST}           value    scope=TEST      # Test level
VAR    ${SUITE}          value    scope=SUITE     # Suite level
VAR    ${SUITES}         value    scope=SUITES    # Suite + children (RF 7.1+)
VAR    ${GLOBAL}         value    scope=GLOBAL    # Global level
```

#### 2. Conditional Execution - IF/ELSE (RF 4.0+)

**Basic IF:**
```robot
IF    ${condition}
    Some Keyword
    Another Keyword
END
```

**IF/ELSE:**
```robot
IF    ${age} >= 18
    Log    Adult
ELSE
    Log    Minor
END
```

**IF/ELSE IF/ELSE:**
```robot
IF    ${status} == 'success'
    Handle Success
ELSE IF    ${status} == 'error'
    Handle Error
ELSE IF    ${status} == 'pending'
    Handle Pending
ELSE
    Fail    Unknown status: ${status}
END
```

**Inline IF (RF 5.0+):**
```robot
IF    ${condition}    Log    Condition is true

IF    ${x} > 0    RETURN    positive    ELSE    RETURN    non-positive

${value} =    IF    ${use_default}    Get Default Value    ELSE    Get Custom Value
```

**Condition Expressions:**
```robot
# String comparison
IF    "${env}" == "production"

# Numeric comparison
IF    ${count} > 10

# Boolean
IF    ${enabled}

# Python expressions
IF    len($items) > 0
IF    platform.system() == 'Linux'
IF    math.ceil(${value}) == 5

# NOT conditions
IF    not ${disabled}
IF    ${x} != ${y}
```

#### 3. Loops - FOR (RF 3.1+)

**Basic FOR:**
```robot
FOR    ${item}    IN    apple    banana    cherry
    Log    ${item}
END
```

**FOR with List Variable:**
```robot
FOR    ${user}    IN    @{USERS}
    Create User    ${user}
END
```

**FOR with Range:**
```robot
FOR    ${index}    IN RANGE    10
    Log    Index: ${index}
END

FOR    ${i}    IN RANGE    1    10    2
    Log    ${i}    # 1, 3, 5, 7, 9
END
```

**FOR with ENUMERATE:**
```robot
FOR    ${index}    ${item}    IN ENUMERATE    @{ITEMS}
    Log    Item ${index}: ${item}
END
```

**Nested FOR:**
```robot
FOR    ${row}    IN    @{TABLE}
    FOR    ${cell}    IN    @{row}
        Process Cell    ${cell}
    END
END
```

**FOR with IF:**
```robot
FOR    ${file}    IN    @{FILES}
    IF    '${file}'.endswith('.txt')
        Process Text File    ${file}
    END
END
```

#### 4. WHILE Loops (RF 5.0+)

```robot
WHILE    ${condition}
    ${value} =    Get Value
    IF    ${value} == ${target}    BREAK
    Wait    1s
END
```

#### 5. Loop Control - BREAK/CONTINUE (RF 5.0+)

```robot
FOR    ${item}    IN    @{ITEMS}
    IF    '${item}' == 'skip'    CONTINUE
    IF    '${item}' == 'stop'    BREAK
    Process Item    ${item}
END
```

#### 6. Error Handling - TRY/EXCEPT/FINALLY (RF 5.0+)

**Basic TRY/EXCEPT:**
```robot
TRY
    Risky Keyword
EXCEPT    Expected error message
    Handle Error
END
```

**Multiple EXCEPT:**
```robot
TRY
    Some Operation
EXCEPT    Connection refused
    Log    Could not connect
EXCEPT    Timeout
    Log    Operation timed out
EXCEPT    AS    ${err}
    Log    Unexpected error: ${err}
END
```

**With FINALLY:**
```robot
TRY
    Open Browser    ${URL}
    Perform Test Actions
EXCEPT
    Log    Test failed
FINALLY
    Close Browser
END
```

#### 7. Return Values - RETURN (RF 5.0+)

**Simple Return:**
```robot
*** Keywords ***
Get Username
    VAR    ${name}    john_doe
    RETURN    ${name}
```

**Multiple Values:**
```robot
*** Keywords ***
Get Credentials
    RETURN    username    password
```

**Conditional Return:**
```robot
*** Keywords ***
Find Item
    [Arguments]    ${target}    @{items}
    FOR    ${item}    IN    @{items}
        IF    '${item}' == '${target}'    RETURN    ${item}
    END
    RETURN    ${None}
```

**Inline IF Return:**
```robot
*** Keywords ***
Check Status
    [Arguments]    ${status}
    IF    ${status}    RETURN    success    ELSE    RETURN    failure
```

---

### ❌ LEGACY SYNTAX (FORBIDDEN) - DO NOT USE

These keywords are DEPRECATED and MUST be replaced with modern syntax:

| **Legacy Keyword** | **Modern Replacement** | **Example** |
|-------------------|----------------------|------------|
| `Run Keyword If` | `IF/ELSE` | `IF ${condition} Keyword arg END` |
| `Run Keyword Unless` | `IF not` | `IF not ${condition} Keyword END` |
| `Run Keyword And Return If` | `IF + RETURN` | `IF ${cond} ${x}= Keyword RETURN ${x} END` |
| `Set Test Variable` | `VAR scope=TEST` | `VAR ${var} value scope=TEST` |
| `Set Suite Variable` | `VAR scope=SUITE` | `VAR ${var} value scope=SUITE` |
| `Set Global Variable` | `VAR scope=GLOBAL` | `VAR ${var} value scope=GLOBAL` |
| `Set Local Variable` | `VAR` | `VAR ${var} value` |
| `Exit For Loop` | `BREAK` | `BREAK` |
| `Exit For Loop If` | `IF + BREAK` | `IF ${cond} BREAK` |
| `Continue For Loop` | `CONTINUE` | `CONTINUE` |
| `Continue For Loop If` | `IF + CONTINUE` | `IF ${cond} CONTINUE` |
| `Return From Keyword` | `RETURN` | `RETURN ${value}` |
| `Return From Keyword If` | `IF + RETURN` | `IF ${cond} RETURN ${value}` |

**NEVER use these legacy keywords in new code. If you encounter them in existing code during updates, migrate them to modern syntax.**

---

## Architectural Standards

### 1. Page Object Model (UI Tests)

**Structure:**
```
robot_tests/
├── tests/
│   └── ui/
│       └── test_login.robot
├── resources/
│   └── pages/
│       ├── LoginPage.robot
│       ├── DashboardPage.robot
│       └── BasePage.robot
└── libraries/
    └── custom/
```

**Example Page Object:**
```robot
*** Settings ***
Documentation     Login page object with reusable keywords
Library           Browser

*** Variables ***
${LOGIN_URL}              http://books-service:8000/login
${USERNAME_INPUT}         id=username
${PASSWORD_INPUT}         id=password
${LOGIN_BUTTON}           id=login-btn
${ERROR_MESSAGE}          css=.error-message

*** Keywords ***
Open Login Page
    [Documentation]    Navigate to login page and verify it loaded
    New Page    ${LOGIN_URL}
    Wait For Elements State    ${USERNAME_INPUT}    visible    timeout=5s

Enter Credentials
    [Documentation]    Fill in username and password fields
    [Arguments]    ${username}    ${password}
    Fill Text    ${USERNAME_INPUT}    ${username}
    Fill Text    ${PASSWORD_INPUT}    ${password}

Click Login Button
    [Documentation]    Submit login form
    Click    ${LOGIN_BUTTON}

Verify Login Success
    [Documentation]    Confirm successful login by checking dashboard
    Wait For Elements State    css=.dashboard    visible    timeout=5s

Verify Login Error
    [Documentation]    Confirm error message is displayed
    [Arguments]    ${expected_error}
    VAR    ${actual}    Get Text    ${ERROR_MESSAGE}
    Should Contain    ${actual}    ${expected_error}
```

**Using Page Object in Tests:**
```robot
*** Settings ***
Documentation     Login functionality tests
Resource          ../resources/pages/LoginPage.robot

*** Test Cases ***
User Should Be Able To Login With Valid Credentials
    [Documentation]    Verify successful login with correct username/password
    [Tags]    login    smoke    positive
    Open Login Page
    Enter Credentials    testuser    testpass123
    Click Login Button
    Verify Login Success

User Should See Error With Invalid Credentials
    [Documentation]    Verify error message with incorrect credentials
    [Tags]    login    negative
    Open Login Page
    Enter Credentials    invalid    wrongpass
    Click Login Button
    Verify Login Error    Invalid credentials
```

### 2. Resource File Organization

**Structure:**
```robot
*** Settings ***
Documentation     Shared keywords and variables for Books API tests
Library           RequestsLibrary
Library           Collections

*** Variables ***
${API_BASE}       http://books-service:8000
${API_TIMEOUT}    10

*** Keywords ***
Create API Session
    [Documentation]    Initialize RequestsLibrary session
    Create Session    books    ${API_BASE}    timeout=${API_TIMEOUT}

Get All Books
    [Documentation]    Retrieve all books from API
    ${response}=    GET On Session    books    /books/
    RETURN    ${response}

Get Book By ID
    [Documentation]    Retrieve specific book by ID
    [Arguments]    ${book_id}
    ${response}=    GET On Session    books    /books/${book_id}
    RETURN    ${response}

Create Book
    [Documentation]    Create new book via API
    [Arguments]    ${title}    ${author}    ${isbn}
    VAR    &{data}    title=${title}    author=${author}    isbn=${isbn}
    ${response}=    POST On Session    books    /books/    json=${data}
    RETURN    ${response}
```

### 3. Separation of Concerns

**Layers:**
```
Tests (*** Test Cases ***)
    ↓
Business Keywords (High-level actions)
    ↓
Technical Keywords (Implementation details)
    ↓
Library Keywords (Browser, RequestsLibrary, etc.)
```

**Example:**
```robot
*** Test Cases ***
User Should Be Able To Add Book To Cart
    [Documentation]    Verify adding book to shopping cart
    Given User Is On Books Catalog Page
    When User Adds Book "Robot Framework Handbook" To Cart
    Then Cart Should Contain 1 Item
    And Book "Robot Framework Handbook" Should Be In Cart

*** Keywords ***
# BUSINESS KEYWORDS (Gherkin-style)
Given User Is On Books Catalog Page
    Open Books Catalog
    Verify Catalog Page Loaded

When User Adds Book "${title}" To Cart
    Search For Book    ${title}
    Click Add To Cart Button For Book    ${title}

Then Cart Should Contain ${count} Item
    ${actual}=    Get Cart Item Count
    Should Be Equal As Integers    ${actual}    ${count}

And Book "${title}" Should Be In Cart
    ${items}=    Get Cart Items
    List Should Contain Value    ${items}    ${title}

# TECHNICAL KEYWORDS (Implementation)
Open Books Catalog
    New Page    http://books-service:8000/catalog

Verify Catalog Page Loaded
    Wait For Elements State    css=.catalog-container    visible    timeout=5s

Search For Book
    [Arguments]    ${title}
    Fill Text    id=search-input    ${title}
    Click    id=search-button
    Wait For Elements State    css=.search-results    visible

Click Add To Cart Button For Book
    [Arguments]    ${title}
    VAR    ${selector}    xpath=//div[contains(text(),'${title}')]/following::button[text()='Add to Cart']
    Click    ${selector}

Get Cart Item Count
    ${text}=    Get Text    id=cart-count
    RETURN    ${text}

Get Cart Items
    VAR    @{items}    Get Elements    css=.cart-item .title
    RETURN    @{items}
```

### 4. Test Templates (Data-Driven Testing)

**Template Definition:**
```robot
*** Settings ***
Documentation     Data-driven search tests using Test Template
Test Template     Search Should Return Expected Results

*** Test Cases ***                SEARCH_TERM         EXPECTED_COUNT
Search For Python Books           Python              ${15}
Search For Robot Framework        Robot Framework     ${8}
Search For Java Books             Java                ${12}
Search With No Results            XYZ123              ${0}

*** Keywords ***
Search Should Return Expected Results
    [Arguments]    ${search_term}    ${expected_count}
    Open Books Page
    Enter Search Term    ${search_term}
    Submit Search
    ${actual}=    Get Search Result Count
    Should Be Equal As Integers    ${actual}    ${expected_count}
```

---

## Test Design Principles

### 1. Wait Strategy (CRITICAL)

#### ✅ CORRECT - Explicit Waits

**Browser Library:**
```robot
# Wait for element state
Wait For Elements State    ${SELECTOR}    visible    timeout=10s
Wait For Elements State    ${SELECTOR}    enabled    timeout=5s
Wait For Elements State    ${SELECTOR}    hidden    timeout=3s

# Wait for condition
Wait Until Keyword Succeeds    10s    1s    Element Should Contain    ${SELECTOR}    text

# Wait for network idle (page load)
Wait For Load State    networkidle    timeout=10s
```

**BuiltIn Library:**
```robot
# Wait for keyword to succeed
Wait Until Keyword Succeeds    30s    2s    Page Should Contain    Success

# Wait for condition
Wait Until Keyword Succeeds    10s    1s    Check Database State
```

#### ❌ FORBIDDEN - Fixed Sleep

```robot
# NEVER DO THIS
Sleep    5s
Sleep    10 seconds
```

**Exception:** Sleep is ONLY allowed in development/debugging. Remove before committing code.

### 2. Test Independence

**Requirements:**
- Tests MUST run in any order
- Tests MUST NOT depend on data created by other tests
- Tests MUST clean up after themselves

**Example:**
```robot
*** Test Cases ***
User Should Be Able To Create Book
    [Setup]    Initialize Test With Clean Database
    [Teardown]    Cleanup Test Data

    ${book_id}=    Create Unique Book
    ${book}=    Get Book By ID    ${book_id}
    Should Be Equal    ${book}[title]    ${EXPECTED_TITLE}

*** Keywords ***
Initialize Test With Clean Database
    Connect To Database
    Delete All Test Data

Create Unique Book
    [Documentation]    Generate unique book data for this test
    VAR    ${timestamp}    Evaluate    str(time.time())
    VAR    ${title}       Test Book ${timestamp}
    VAR    ${isbn}        ISBN-${timestamp}
    ${id}=    Create Book    ${title}    Test Author    ${isbn}
    RETURN    ${id}

Cleanup Test Data
    Delete All Test Data
    Close Database Connection
```

### 3. Error Resilience

**Always handle expected errors:**
```robot
*** Test Cases ***
API Should Handle Invalid Book ID Gracefully
    [Documentation]    Verify 404 response for non-existent book
    TRY
        ${response}=    GET On Session    books    /books/999999    expected_status=404
        Should Be Equal As Integers    ${response.status_code}    404
    EXCEPT    AS    ${error}
        Fail    Unexpected error: ${error}
    END
```

**Use FINALLY for cleanup:**
```robot
*** Test Cases ***
Browser Test With Guaranteed Cleanup
    TRY
        Open Browser To Application
        Perform Test Steps
        Verify Results
    EXCEPT    AS    ${error}
        Log    Test failed: ${error}
        Take Screenshot
    FINALLY
        Close Browser
    END
```

### 4. Behavioral Naming

**Format:** `[Actor] Should [Expected Behavior] [Context]`

**Examples:**
```robot
*** Test Cases ***
User Should Be Able To Login With Valid Credentials
User Should See Error Message When Submitting Empty Form
Admin Should Be Able To Delete Books From Catalog
API Should Return 400 For Invalid Book Data
System Should Send Email After Successful Order
Guest User Should Be Redirected To Login Page
```

### 5. Documentation Requirements

**Every keyword MUST have:**
- `[Documentation]` block explaining purpose
- Clear description of what it does
- NOT implementation details

**Example:**
```robot
*** Keywords ***
Verify Book Appears In Search Results
    [Documentation]    Confirm that book is visible in search result list
    ...                Fails if book is not found within timeout period
    [Arguments]    ${book_title}

    VAR    ${selector}    xpath=//div[@class='book-card']//h3[text()='${book_title}']
    Wait For Elements State    ${selector}    visible    timeout=10s
```

### 6. Variable Scope and Data Isolation

**NO HARDCODED VALUES:**
```robot
# ❌ BAD
Fill Text    id=username    john_doe
Should Contain    ${response}    Welcome back!

# ✅ GOOD
Fill Text    id=username    ${USERNAME}
Should Contain    ${response}    ${WELCOME_MESSAGE}
```

**Variable Organization:**
```robot
*** Variables ***
# URLs
${BASE_URL}           http://books-service:8000
${LOGIN_URL}          ${BASE_URL}/login
${CATALOG_URL}        ${BASE_URL}/catalog

# Timeouts
${SHORT_TIMEOUT}      3s
${MEDIUM_TIMEOUT}     10s
${LONG_TIMEOUT}       30s

# Test Data (Generated Dynamically)
${TEST_USERNAME}      # Set in Suite Setup
${TEST_USER_ID}       # Set in Suite Setup

# Selectors
${SEARCH_INPUT}       id=search
${SEARCH_BUTTON}      id=search-btn
${RESULTS_CONTAINER}  css=.search-results
```

### 7. Lifecycle Hooks

**Suite Level:**
```robot
*** Settings ***
Suite Setup       Initialize Test Environment
Suite Teardown    Cleanup Test Environment

*** Keywords ***
Initialize Test Environment
    [Documentation]    Prepare environment for entire test suite
    Start Application Services
    Initialize Database With Test Data
    Create API Session
    VAR    ${SUITE_START_TIME}    Get Time    epoch    scope=SUITE

Cleanup Test Environment
    [Documentation]    Clean up after entire test suite
    Delete All Test Data
    Close All Connections
    Generate Test Report
```

**Test Level:**
```robot
*** Settings ***
Test Setup        Prepare Individual Test
Test Teardown     Cleanup Individual Test

*** Keywords ***
Prepare Individual Test
    [Documentation]    Setup for each individual test
    VAR    ${TEST_ID}    Generate UUID    scope=TEST
    Log    Starting test ${TEST_ID}
    Reset Application State

Cleanup Individual Test
    [Documentation]    Cleanup after each test
    Log    Completing test ${TEST_ID}
    IF    '${TEST_STATUS}' == 'FAIL'
        Take Screenshot
        Capture Browser Logs
    END
```

### 8. Organization and Tagging

**Tag Categories:**
```robot
*** Test Cases ***
User Should Be Able To Login
    [Tags]    login    ui    smoke    positive    priority-high
    # Test implementation

Admin Should Not Access With User Credentials
    [Tags]    login    security    negative    priority-high
    # Test implementation

Books Should Load Within Performance Threshold
    [Tags]    performance    catalog    non-functional
    # Test implementation

API Should Return Valid JSON Response
    [Tags]    api    integration    smoke    priority-medium
    # Test implementation
```

**Tag Usage:**
```bash
# Run smoke tests only
robot --include smoke tests/

# Run high priority tests
robot --include priority-high tests/

# Run UI tests but exclude performance tests
robot --include ui --exclude performance tests/

# Run positive login tests
robot --include loginANDpositive tests/
```

**Suite Organization:**
```
robot_tests/
├── tests/
│   ├── ui/
│   │   ├── login/
│   │   │   ├── test_login_positive.robot
│   │   │   └── test_login_negative.robot
│   │   ├── catalog/
│   │   │   ├── test_search.robot
│   │   │   └── test_filter.robot
│   │   └── cart/
│   │       └── test_shopping_cart.robot
│   ├── api/
│   │   ├── books/
│   │   │   ├── test_books_crud.robot
│   │   │   └── test_books_validation.robot
│   │   └── users/
│   │       └── test_user_management.robot
│   └── integration/
│       └── test_end_to_end_purchase.robot
```

---

## Modern RF 7.x Syntax Reference

### VAR Syntax (RF 7.0+)

**Scalar Variables:**
```robot
VAR    ${name}        John Doe
VAR    ${age}         ${30}
VAR    ${active}      ${True}
```

**List Variables:**
```robot
VAR    @{colors}      red    green    blue
VAR    @{numbers}     ${1}   ${2}    ${3}
VAR    @{empty}
```

**Dictionary Variables:**
```robot
VAR    &{person}      name=John    age=30    city=Helsinki
VAR    &{config}      host=localhost    port=8000
VAR    &{empty}
```

**Multiline Values:**
```robot
VAR    ${description}
...    This is a longer description
...    that spans multiple lines.
...    Lines are joined with spaces by default.

VAR    ${sql_query}
...    SELECT * FROM books
...    WHERE author = 'Asimov'
...    AND year > 1950
...    separator=\n
```

**Scopes:**
```robot
VAR    ${local}       value                      # LOCAL (default)
VAR    ${test_var}    value    scope=TEST        # Current test
VAR    ${suite_var}   value    scope=SUITE       # Current suite
VAR    ${suites_var}  value    scope=SUITES      # Suite + children (RF 7.1+)
VAR    ${global_var}  value    scope=GLOBAL      # Global across all suites
```

**Conditional VAR:**
```robot
IF    "${ENV}" == "production"
    VAR    ${db_host}    prod-db.example.com
    VAR    ${db_port}    5432
ELSE
    VAR    ${db_host}    localhost
    VAR    ${db_port}    5433
END
```

### IF/ELSE Syntax (RF 4.0+)

**Basic Forms:**
```robot
# Simple IF
IF    ${condition}
    Log    Condition is true
END

# IF/ELSE
IF    ${value} > 0
    Log    Positive
ELSE
    Log    Non-positive
END

# IF/ELSE IF/ELSE
IF    ${status} == 'success'
    Handle Success
ELSE IF    ${status} == 'warning'
    Handle Warning
ELSE IF    ${status} == 'error'
    Handle Error
ELSE
    Fail    Unknown status: ${status}
END
```

**Inline IF (RF 5.0+):**
```robot
# Single statement
IF    ${enabled}    Log    Feature is enabled

# With ELSE
IF    ${count} > 0    Log    Has items    ELSE    Log    Empty

# With RETURN
IF    ${condition}    RETURN    ${value}

# With assignment
${result} =    IF    ${use_cache}    Get From Cache    ELSE    Fetch From API

# Multiple return values
${host}    ${port} =    IF    ${prod}    Get Prod Config    ELSE    Get Dev Config
```

**Condition Types:**
```robot
# String comparison (quotes required)
IF    "${env}" == "production"

# Numeric comparison (no quotes)
IF    ${count} > 10
IF    ${price} >= 100.50
IF    ${stock} <= 0

# Boolean
IF    ${enabled}
IF    not ${disabled}

# Python expressions
IF    len($items) == 0
IF    platform.system() == 'Darwin'
IF    math.ceil(${value}) > 5
IF    '${text}'.startswith('Hello')

# Complex expressions
IF    ${x} > 0 and ${y} < 100
IF    ${status} in ['active', 'pending']
```

### FOR Loop Syntax

**Basic Iteration:**
```robot
FOR    ${item}    IN    apple    banana    cherry
    Log    ${item}
END
```

**List Variable:**
```robot
FOR    ${book}    IN    @{BOOKS}
    Validate Book    ${book}
END
```

**Range:**
```robot
# 0 to 9
FOR    ${i}    IN RANGE    10
    Log    ${i}
END

# 1 to 10
FOR    ${i}    IN RANGE    1    11
    Log    ${i}
END

# 0 to 10 by 2 (0, 2, 4, 6, 8, 10)
FOR    ${i}    IN RANGE    0    11    2
    Log    ${i}
END
```

**ENUMERATE:**
```robot
FOR    ${index}    ${value}    IN ENUMERATE    @{ITEMS}
    Log    Item ${index}: ${value}
END

# Start from different index
FOR    ${index}    ${value}    IN ENUMERATE    @{ITEMS}    start=1
    Log    Item ${index}: ${value}
END
```

**ZIP (multiple lists):**
```robot
FOR    ${name}    ${age}    IN ZIP    ${NAMES}    ${AGES}
    Log    ${name} is ${age} years old
END
```

**Nested FOR:**
```robot
FOR    ${suite}    IN    @{TEST_SUITES}
    FOR    ${test}    IN    @{suite}[tests]
        Run Test    ${test}
    END
END
```

**FOR with BREAK/CONTINUE:**
```robot
FOR    ${num}    IN RANGE    100
    IF    ${num} % 2 == 0    CONTINUE    # Skip even numbers
    IF    ${num} > 50    BREAK           # Stop at 50
    Process Number    ${num}
END
```

### WHILE Loop Syntax (RF 5.0+)

**Basic WHILE:**
```robot
VAR    ${counter}    ${0}
WHILE    ${counter} < 10
    Log    Counter: ${counter}
    VAR    ${counter}    ${counter + 1}
END
```

**With BREAK:**
```robot
WHILE    True
    ${value} =    Get Next Value
    IF    '${value}' == 'DONE'    BREAK
    Process Value    ${value}
END
```

**With TRY/EXCEPT:**
```robot
WHILE    ${attempts} < ${MAX_ATTEMPTS}
    TRY
        ${result} =    Perform Operation
        IF    ${result}    BREAK
    EXCEPT    Timeout
        Log    Retry after timeout
        VAR    ${attempts}    ${attempts + 1}
    END
END
```

### TRY/EXCEPT/FINALLY Syntax (RF 5.0+)

**Basic TRY/EXCEPT:**
```robot
TRY
    ${response} =    GET    ${URL}
EXCEPT    Timeout
    Log    Request timed out
END
```

**Multiple EXCEPT blocks:**
```robot
TRY
    Perform Database Operation
EXCEPT    ConnectionError
    Log    Database connection failed
EXCEPT    QueryError
    Log    Query execution failed
EXCEPT    AS    ${error}
    Log    Unexpected error: ${error}
END
```

**With ELSE (executes if no exception):**
```robot
TRY
    ${data} =    Fetch Data
EXCEPT
    Log    Failed to fetch
ELSE
    Process Data    ${data}
END
```

**With FINALLY (always executes):**
```robot
TRY
    Open Connection
    Transfer Data
EXCEPT
    Log    Transfer failed
FINALLY
    Close Connection    # Always executed
END
```

**Nested TRY:**
```robot
TRY
    TRY
        Risky Operation
    EXCEPT
        Fallback Operation
    END
EXCEPT
    Log    Both failed
END
```

### RETURN Statement (RF 5.0+)

**Simple Return:**
```robot
*** Keywords ***
Get Status Message
    RETURN    All systems operational
```

**Return Variable:**
```robot
*** Keywords ***
Calculate Sum
    [Arguments]    ${a}    ${b}
    VAR    ${result}    Evaluate    ${a} + ${b}
    RETURN    ${result}
```

**Return Multiple Values:**
```robot
*** Keywords ***
Get Database Config
    RETURN    localhost    5432    mydb    username
```

**Conditional Return:**
```robot
*** Keywords ***
Find User By Email
    [Arguments]    ${email}
    FOR    ${user}    IN    @{USERS}
        IF    '${user}[email]' == '${email}'    RETURN    ${user}
    END
    RETURN    ${None}
```

**Early Return:**
```robot
*** Keywords ***
Validate Input
    [Arguments]    ${value}
    IF    not ${value}    RETURN    # Exit early
    Perform Validation    ${value}
```

### BREAK and CONTINUE (RF 5.0+)

**BREAK (exit loop):**
```robot
FOR    ${item}    IN    @{ITEMS}
    IF    '${item}' == 'STOP'    BREAK
    Process Item    ${item}
END
```

**CONTINUE (skip to next iteration):**
```robot
FOR    ${file}    IN    @{FILES}
    IF    '${file}'.endswith('.tmp')    CONTINUE
    Process File    ${file}
END
```

**Conditional Forms:**
```robot
FOR    ${x}    IN RANGE    100
    IF    ${x} % 2 == 0    CONTINUE    # Skip even
    IF    ${x} > 50    BREAK           # Stop at 50
    Log    ${x}
END
```

---

## Standard Library Keywords

### BuiltIn Library (Automatically Available)

**Most Important Keywords:**

#### Logging
```robot
Log    ${message}    level=INFO
Log    ${message}    level=WARN
Log    ${message}    level=ERROR
Log To Console    ${message}
Log Variables    # Log all current variables
```

#### Assertions
```robot
Should Be Equal    ${actual}    ${expected}    msg=Values don't match
Should Be Equal As Strings    ${actual}    ${expected}
Should Be Equal As Integers    ${actual}    ${expected}
Should Be Equal As Numbers    ${actual}    ${expected}    precision=2

Should Not Be Equal    ${actual}    ${unexpected}

Should Contain    ${container}    ${item}
Should Not Contain    ${container}    ${item}

Should Be True    ${condition}    msg=Condition is false
Should Be True    ${value} > 10

Should Start With    ${string}    ${prefix}
Should End With    ${string}    ${suffix}
Should Match Regexp    ${string}    ${pattern}
```

#### Variables
```robot
Set Variable    ${value}
Set Variable If    ${condition}    ${value_if_true}    ${value_if_false}

Get Variable Value    ${var_name}    default=default_value
Get Variables    # Returns dictionary of all variables

Create List    item1    item2    item3
Create Dictionary    key1=value1    key2=value2
```

#### Length and Counting
```robot
Get Length    ${item}    # Works with strings, lists, dicts
Get Count    ${container}    ${item}    # Count occurrences
```

#### Flow Control (Use with Modern Syntax)
```robot
Fail    ${message}
Skip    ${message}
Skip If    ${condition}    ${message}

Wait Until Keyword Succeeds    ${timeout}    ${retry_interval}    Keyword    args
```

#### Evaluation
```robot
Evaluate    ${expression}    # Python expression
# Examples:
${result}=    Evaluate    5 + 3
${random}=    Evaluate    random.randint(1, 100)
${platform}=    Evaluate    platform.system()
```

#### String Operations
```robot
Catenate    ${str1}    ${str2}    ${str3}
Catenate    SEPARATOR=,    ${str1}    ${str2}

Convert To String    ${value}
Convert To Integer    ${value}
Convert To Number    ${value}
Convert To Boolean    ${value}
```

#### Utilities
```robot
Sleep    ${duration}    # Use ONLY for debugging
Get Time    # Returns current time
Get Time    epoch    # Returns Unix timestamp

Import Library    LibraryName
Import Resource    resource.robot
Import Variables    variables.py
```

### Collections Library

**Import:**
```robot
Library    Collections
```

**List Operations:**
```robot
Append To List    ${list}    ${value}
Insert Into List    ${list}    ${index}    ${value}
Remove From List    ${list}    ${index}
Remove Values From List    ${list}    ${value}

Get From List    ${list}    ${index}
Get Index From List    ${list}    ${value}
Get Slice From List    ${list}    ${start}    ${end}

Lists Should Be Equal    ${list1}    ${list2}
List Should Contain Value    ${list}    ${value}
List Should Not Contain Value    ${list}    ${value}

Sort List    ${list}
Reverse List    ${list}
Copy List    ${list}

Count Values In List    ${list}    ${value}
Get Match Count    ${list}    ${pattern}
```

**Dictionary Operations:**
```robot
Get From Dictionary    ${dict}    ${key}
Get Dictionary Keys    ${dict}
Get Dictionary Values    ${dict}
Get Dictionary Items    ${dict}

Set To Dictionary    ${dict}    ${key}    ${value}
Set To Dictionary    ${dict}    key1=value1    key2=value2

Remove From Dictionary    ${dict}    ${key}

Dictionaries Should Be Equal    ${dict1}    ${dict2}
Dictionary Should Contain Key    ${dict}    ${key}
Dictionary Should Contain Value    ${dict}    ${value}
Dictionary Should Not Contain Key    ${dict}    ${key}

Copy Dictionary    ${dict}
```

### String Library

**Import:**
```robot
Library    String
```

**Case Conversion:**
```robot
Convert To Lower Case    ${string}
Convert To Upper Case    ${string}
Convert To Title Case    ${string}
```

**String Operations:**
```robot
Fetch From Left    ${string}    ${marker}
Fetch From Right    ${string}    ${marker}

Split String    ${string}    ${separator}
Split String From Right    ${string}    ${separator}    max_split=${1}

Strip String    ${string}    # Remove leading/trailing whitespace
Strip String    ${string}    characters=${chars}

Replace String    ${string}    ${search}    ${replace}
Replace String Using Regexp    ${string}    ${pattern}    ${replace}
```

**Generation:**
```robot
Generate Random String    ${length}
Generate Random String    ${length}    [LETTERS]
Generate Random String    ${length}    [NUMBERS]
Generate Random String    ${length}    [LOWER]
```

**Line Operations:**
```robot
Get Line    ${string}    ${line_number}
Get Line Count    ${string}
Get Lines Containing String    ${string}    ${pattern}
Get Lines Matching Pattern    ${string}    ${pattern}
Get Lines Matching Regexp    ${string}    ${pattern}
```

**Pattern Matching:**
```robot
Get Regexp Matches    ${string}    ${pattern}
Should Match Regexp    ${string}    ${pattern}
Should Not Match Regexp    ${string}    ${pattern}
```

**Formatting:**
```robot
Format String    ${template}    @{args}    &{kwargs}
# Example: Format String    Hello {0} {name}    World    name=Robot
```

### DateTime Library

**Import:**
```robot
Library    DateTime
```

**Keywords:**
```robot
Get Current Date
Get Current Date    result_format=%Y-%m-%d
Get Current Date    result_format=epoch

Add Time To Date    ${date}    ${time}
Subtract Date From Date    ${date1}    ${date2}
Subtract Time From Date    ${date}    ${time}

Convert Date    ${date}    result_format=%Y-%m-%d
Convert Time    ${time}    result_format=number
```

### OperatingSystem Library

**Import:**
```robot
Library    OperatingSystem
```

**File Operations:**
```robot
Create File    ${path}    ${content}
Append To File    ${path}    ${content}
Remove File    ${path}

File Should Exist    ${path}
File Should Not Exist    ${path}

Get File    ${path}
Get Binary File    ${path}

Copy File    ${source}    ${destination}
Move File    ${source}    ${destination}
```

**Directory Operations:**
```robot
Create Directory    ${path}
Remove Directory    ${path}    recursive=True

Directory Should Exist    ${path}
Directory Should Not Exist    ${path}

List Directory    ${path}
List Files In Directory    ${path}    pattern=*.txt    absolute=True
Count Items In Directory    ${path}

Copy Directory    ${source}    ${destination}
```

**Environment Variables:**
```robot
Get Environment Variable    ${name}
Get Environment Variable    ${name}    default=default_value
Set Environment Variable    ${name}    ${value}
```

**Path Operations:**
```robot
Join Path    ${base}    ${part1}    ${part2}
Normalize Path    ${path}
Split Path    ${path}
Split Extension    ${path}
```

### Process Library

**Import:**
```robot
Library    Process
```

**Keywords:**
```robot
Start Process    ${command}    ${arg1}    ${arg2}    alias=my_process
Run Process    ${command}    ${arg1}    ${arg2}    shell=True    timeout=10s

Wait For Process    ${handle}    timeout=30s
Terminate Process    ${handle}
Kill Process    ${handle}

Process Should Be Running    ${handle}
Process Should Be Stopped    ${handle}

Get Process Result    ${handle}
Get Process Id    ${handle}
```

### XML Library

**Import:**
```robot
Library    XML
```

**Keywords:**
```robot
Parse XML    ${source}
Save XML    ${tree}    ${path}

Get Element    ${tree}    ${xpath}
Get Elements    ${tree}    ${xpath}
Get Element Text    ${element}    ${xpath}
Get Element Attribute    ${element}    ${name}

Element Should Exist    ${tree}    ${xpath}
Element Text Should Be    ${element}    ${expected}
Element Attribute Should Be    ${element}    ${name}    ${expected}

Add Element    ${parent}    ${child}
Set Element Text    ${element}    ${text}
Set Element Attribute    ${element}    ${name}    ${value}
Remove Element    ${tree}    ${xpath}
```

---

## External Library Guidelines

### Browser Library (19.12.3)

**Import:**
```robot
Library    Browser    timeout=10s    retry_assertions_for=1s
```

**Browser/Context/Page Management:**
```robot
# Browser lifecycle
New Browser    browser=chromium    headless=True
Close Browser

# Context (isolated session)
New Context    viewport={'width': 1920, 'height': 1080}
Close Context

# Page (tab)
New Page    ${URL}
Go To    ${URL}
Close Page
```

**Navigation:**
```robot
Go To    ${URL}
Go Back
Go Forward
Reload
```

**Waiting:**
```robot
Wait For Elements State    ${selector}    visible    timeout=10s
Wait For Elements State    ${selector}    enabled    timeout=5s
Wait For Elements State    ${selector}    hidden    timeout=3s
Wait For Elements State    ${selector}    stable    timeout=5s

Wait For Load State    load    timeout=30s
Wait For Load State    domcontentloaded    timeout=10s
Wait For Load State    networkidle    timeout=30s

Wait For Navigation    timeout=10s
Wait For Request    ${url_pattern}    timeout=10s
Wait For Response    ${url_pattern}    timeout=10s

Wait Until Network Is Idle    timeout=10s
```

**Selectors:**
```robot
# CSS
css=.classname
css=#id
css=button[type='submit']

# XPath
xpath=//button[@type='submit']
xpath=//div[contains(text(), 'Welcome')]

# Text
text="Click me"
text="Login" >> visible=true

# ID (shorthand)
id=login-button

# Data attributes
css=[data-test-id="submit-btn"]

# Chaining
css=.container >> text="Submit"
```

**Interactions:**
```robot
Click    ${selector}
Click    ${selector}    clickCount=2    # Double click
Click    ${selector}    button=right    # Right click

Fill Text    ${selector}    ${text}
Type Text    ${selector}    ${text}    delay=100ms

Check Checkbox    ${selector}
Uncheck Checkbox    ${selector}

Select Options By    ${selector}    value    ${value}
Select Options By    ${selector}    text    ${text}
Select Options By    ${selector}    index    ${index}

Upload File By Selector    ${selector}    ${file_path}

Hover    ${selector}
Focus    ${selector}
```

**Assertions:**
```robot
Get Text    ${selector}
Get Property    ${selector}    ${property}
Get Attribute    ${selector}    ${attribute}

Get Element Count    ${selector}
Get Element States    ${selector}

Get Url
Get Title
Get Page Source
```

**Screenshots:**
```robot
Take Screenshot    filename=screenshot.png
Take Screenshot    ${selector}    filename=element.png
```

**Browser Context Options:**
```robot
New Context
...    viewport={'width': 1920, 'height': 1080}
...    userAgent=Custom User Agent
...    acceptDownloads=True
...    recordVideo={'dir': 'videos/'}
...    locale=fi-FI
...    timezoneId=Europe/Helsinki
```

**Example:**
```robot
*** Settings ***
Library    Browser

*** Test Cases ***
Complete Browser Test Example
    New Browser    chromium    headless=True
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    http://books-service:8000

    # Wait for page load
    Wait For Load State    networkidle
    Wait For Elements State    css=.book-card    visible    timeout=10s

    # Interact
    Fill Text    id=search    Robot Framework
    Click    id=search-btn

    # Wait for results
    Wait For Elements State    css=.search-results    visible

    # Assert
    ${count}=    Get Element Count    css=.book-card
    Should Be True    ${count} > 0

    # Cleanup
    Close Browser
```

### RequestsLibrary (0.9.7)

**Import:**
```robot
Library    RequestsLibrary
```

**Session Management:**
```robot
# Create session (reusable connection)
Create Session    alias_name    ${BASE_URL}    timeout=10    verify=True

# Session with auth
Create Session    api    ${BASE_URL}    auth=('user', 'pass')

# Session with headers
VAR    &{headers}    Content-Type=application/json    Authorization=Bearer ${TOKEN}
Create Session    api    ${BASE_URL}    headers=${headers}
```

**HTTP Methods (Session-based):**
```robot
# GET
${response}=    GET On Session    alias_name    /endpoint
${response}=    GET On Session    alias_name    /endpoint    params=key=value&foo=bar

# POST
VAR    &{data}    title=Book    author=Author    isbn=123456
${response}=    POST On Session    alias_name    /books    json=${data}

# PUT
${response}=    PUT On Session    alias_name    /books/${id}    json=${data}

# PATCH
${response}=    PATCH On Session    alias_name    /books/${id}    json=${data}

# DELETE
${response}=    DELETE On Session    alias_name    /books/${id}

# OPTIONS
${response}=    OPTIONS On Session    alias_name    /books

# HEAD
${response}=    HEAD On Session    alias_name    /books
```

**HTTP Methods (Direct URL):**
```robot
${response}=    GET    ${URL}
${response}=    POST    ${URL}    json=${data}
${response}=    PUT    ${URL}    json=${data}
${response}=    DELETE    ${URL}
```

**Expected Status:**
```robot
# Expect specific status
${response}=    GET On Session    api    /endpoint    expected_status=200

# Expect multiple statuses
${response}=    GET On Session    api    /endpoint    expected_status=200,201,204

# Expect any status (don't fail on 4xx/5xx)
${response}=    GET On Session    api    /endpoint    expected_status=any
```

**Response Object:**
```robot
# Status
${status}=    Set Variable    ${response.status_code}
Should Be Equal As Integers    ${status}    200

# Headers
${content_type}=    Set Variable    ${response.headers['Content-Type']}
Should Contain    ${content_type}    application/json

# Body (text)
${body}=    Set Variable    ${response.text}
Should Contain    ${body}    success

# Body (JSON)
${json}=    Set Variable    ${response.json()}
Should Be Equal    ${json}[id]    ${123}
Should Be Equal As Strings    ${json}[name]    Test Book

# Cookies
${cookies}=    Set Variable    ${response.cookies}
```

**Headers and Parameters:**
```robot
# Query parameters
VAR    &{params}    page=1    limit=10    sort=title
${response}=    GET On Session    api    /books    params=${params}

# Custom headers
VAR    &{headers}    X-Custom-Header=value    Accept=application/json
${response}=    GET On Session    api    /books    headers=${headers}

# Both
${response}=    GET On Session    api    /books    params=${params}    headers=${headers}
```

**Request Body:**
```robot
# JSON body
VAR    &{book}    title=RF Guide    author=Robot    isbn=RF-2024
${response}=    POST On Session    api    /books    json=${book}

# Form data
VAR    &{form}    username=user    password=pass
${response}=    POST On Session    api    /login    data=${form}

# File upload
VAR    &{files}    file=${file_path}
${response}=    POST On Session    api    /upload    files=${files}
```

**Complete Example:**
```robot
*** Settings ***
Library    RequestsLibrary
Library    Collections

*** Variables ***
${API_BASE}    http://books-service:8000
${TIMEOUT}     10

*** Test Cases ***
API CRUD Operations Should Work
    [Documentation]    Test full CRUD cycle for Books API

    # Setup
    Create Session    books    ${API_BASE}    timeout=${TIMEOUT}

    # CREATE
    VAR    &{new_book}    title=Test Book    author=Test Author    isbn=TEST-123
    ${create_response}=    POST On Session    books    /books/    json=${new_book}    expected_status=201
    VAR    ${book_id}    ${create_response.json()}[id]

    # READ
    ${get_response}=    GET On Session    books    /books/${book_id}    expected_status=200
    Should Be Equal    ${get_response.json()}[title]    Test Book

    # UPDATE
    VAR    &{updated_book}    title=Updated Book    author=Test Author    isbn=TEST-123
    ${update_response}=    PUT On Session    books    /books/${book_id}    json=${updated_book}    expected_status=200
    Should Be Equal    ${update_response.json()}[title]    Updated Book

    # DELETE
    ${delete_response}=    DELETE On Session    books    /books/${book_id}    expected_status=204

    # Verify deletion
    ${verify_response}=    GET On Session    books    /books/${book_id}    expected_status=404
```

---

## Anti-Patterns (FORBIDDEN)

### 1. Linear Scripting in Test Cases

#### ❌ WRONG - Implementation in Test Case
```robot
*** Test Cases ***
Test Login
    New Page    http://localhost:8000/login
    Fill Text    id=username    testuser
    Fill Text    id=password    testpass123
    Click    id=login-button
    Wait For Elements State    css=.dashboard    visible
```

#### ✅ CORRECT - Business Keywords
```robot
*** Test Cases ***
User Should Be Able To Login With Valid Credentials
    [Documentation]    Verify successful login with correct credentials
    [Tags]    login    smoke    positive
    Given User Is On Login Page
    When User Logs In With Valid Credentials
    Then Dashboard Should Be Displayed

*** Keywords ***
Given User Is On Login Page
    Open Login Page
    Verify Login Page Loaded

When User Logs In With Valid Credentials
    Enter Username    ${VALID_USERNAME}
    Enter Password    ${VALID_PASSWORD}
    Submit Login Form

Then Dashboard Should Be Displayed
    Wait For Dashboard
    Verify User Is Logged In
```

### 2. Using Sleep for Waiting

#### ❌ WRONG
```robot
Click    ${BUTTON}
Sleep    5s
Get Text    ${RESULT}
```

#### ✅ CORRECT
```robot
Click    ${BUTTON}
Wait For Elements State    ${RESULT}    visible    timeout=10s
${text}=    Get Text    ${RESULT}
```

### 3. Hardcoded Values

#### ❌ WRONG
```robot
Fill Text    id=username    john_doe
POST On Session    api    /books    json={"title":"Book","author":"Author"}
```

#### ✅ CORRECT
```robot
Fill Text    id=username    ${TEST_USERNAME}
VAR    &{book_data}    title=${BOOK_TITLE}    author=${BOOK_AUTHOR}
POST On Session    api    /books    json=${book_data}
```

### 4. Test Dependencies

#### ❌ WRONG
```robot
*** Test Cases ***
Test 1 Create User
    ${USER_ID}=    Create User    john_doe
    Set Suite Variable    ${USER_ID}

Test 2 Update User
    Update User    ${USER_ID}    new_email@test.com

Test 3 Delete User
    Delete User    ${USER_ID}
```

#### ✅ CORRECT
```robot
*** Test Cases ***
User Should Be Created Successfully
    [Setup]    Initialize Clean Test Environment
    [Teardown]    Cleanup Test Data

    ${user_id}=    Create Unique User
    User Should Exist    ${user_id}

User Should Be Updated Successfully
    [Setup]    Initialize Clean Test Environment With User
    [Teardown]    Cleanup Test Data

    ${user_id}=    Get Test User ID
    Update User    ${user_id}    new_email@test.com
    User Email Should Be    ${user_id}    new_email@test.com
```

### 5. Missing Documentation

#### ❌ WRONG
```robot
*** Keywords ***
Do Login
    [Arguments]    ${u}    ${p}
    Fill Text    id=username    ${u}
    Fill Text    id=password    ${p}
    Click    id=login-button
```

#### ✅ CORRECT
```robot
*** Keywords ***
Perform Login
    [Documentation]    Submit login form with provided credentials
    ...                Waits for page navigation after submission
    [Arguments]    ${username}    ${password}

    Fill Text    id=username    ${username}
    Fill Text    id=password    ${password}
    Click    id=login-button
    Wait For Load State    networkidle
```

### 6. Missing Error Handling

#### ❌ WRONG
```robot
*** Test Cases ***
Test API
    ${response}=    GET On Session    api    /books/999999
    Log    ${response.json()}
```

#### ✅ CORRECT
```robot
*** Test Cases ***
API Should Handle Invalid ID Gracefully
    [Documentation]    Verify 404 response for non-existent book
    ${response}=    GET On Session    api    /books/999999    expected_status=404
    Should Be Equal As Integers    ${response.status_code}    404
    Should Contain    ${response.text}    not found
```

### 7. God Keywords (Too Much Logic)

#### ❌ WRONG
```robot
*** Keywords ***
Complete Purchase Flow
    [Arguments]    ${product}    ${quantity}    ${payment_method}
    Open Product Page    ${product}
    Click Add To Cart
    Enter Quantity    ${quantity}
    Click Checkout
    Select Payment Method    ${payment_method}
    IF    "${payment_method}" == "card"
        Enter Card Details    ${CARD_NUMBER}    ${CARD_CVV}    ${CARD_EXPIRY}
    ELSE IF    "${payment_method}" == "paypal"
        Login To PayPal    ${PAYPAL_EMAIL}    ${PAYPAL_PASSWORD}
    ELSE
        Fail    Invalid payment method
    END
    Click Submit Order
    Wait For Confirmation
    ${order_id}=    Get Order ID
    RETURN    ${order_id}
```

#### ✅ CORRECT
```robot
*** Keywords ***
Complete Purchase Flow
    [Documentation]    Execute full purchase process from product to confirmation
    [Arguments]    ${product}    ${quantity}    ${payment_method}

    Add Product To Cart    ${product}    ${quantity}
    Proceed To Checkout
    Complete Payment    ${payment_method}
    ${order_id}=    Confirm Order
    RETURN    ${order_id}

Add Product To Cart
    [Documentation]    Add specified product and quantity to shopping cart
    [Arguments]    ${product}    ${quantity}
    Open Product Page    ${product}
    Click Add To Cart
    Enter Quantity    ${quantity}

Proceed To Checkout
    [Documentation]    Navigate from cart to checkout page
    Click Checkout
    Verify Checkout Page Loaded

Complete Payment
    [Documentation]    Process payment using specified method
    [Arguments]    ${payment_method}
    Select Payment Method    ${payment_method}
    IF    "${payment_method}" == "card"
        Process Card Payment
    ELSE IF    "${payment_method}" == "paypal"
        Process PayPal Payment
    ELSE
        Fail    Invalid payment method: ${payment_method}
    END

Confirm Order
    [Documentation]    Submit order and return order ID
    Click Submit Order
    Wait For Confirmation Page
    ${order_id}=    Get Order ID From Confirmation
    RETURN    ${order_id}
```

---

## File Structure Template

```robot
*** Settings ***
Documentation     [HIGH-LEVEL DESCRIPTION OF THIS FILE]
...
...               Purpose: [What functionality does this file test/implement?]
...               Scope: [What is covered?]
...               Dependencies: [What external systems/services are required?]
...
...               This file is automatically generated or maintained by Claude Code
...               following Robot Framework 7.4.1 standards.

Resource          resources/common.robot
Resource          resources/pages/LoginPage.robot
Library           Browser    timeout=10s    retry_assertions_for=1s
Library           RequestsLibrary
Library           Collections
Library           String

Suite Setup       Initialize Test Suite
Suite Teardown    Cleanup Test Suite
Test Setup        Initialize Individual Test
Test Teardown     Cleanup Individual Test

Force Tags        [FEATURE_TAG]    [PRIORITY_TAG]
Default Tags      [DEFAULT_TAG]


*** Variables ***
# Application URLs
${BASE_URL}              http://books-service:8000
${LOGIN_URL}             ${BASE_URL}/login
${API_BASE}              ${BASE_URL}

# Timeouts
${SHORT_TIMEOUT}         3s
${MEDIUM_TIMEOUT}        10s
${LONG_TIMEOUT}          30s

# Test Data (Set dynamically in Suite Setup)
${TEST_USERNAME}         # Generated unique username
${TEST_USER_ID}          # Generated user ID

# Selectors
${USERNAME_INPUT}        id=username
${PASSWORD_INPUT}        id=password
${LOGIN_BUTTON}          id=login-btn


*** Test Cases ***
[TEST_CASE_NAME]
    [Documentation]    [DESCRIPTION OF USER BEHAVIOR BEING VALIDATED]
    ...
    ...                Steps:
    ...                1. [Step description]
    ...                2. [Step description]
    ...                3. [Step description]
    ...
    ...                Expected: [Expected outcome]
    [Tags]    [category]    [priority]    [type]
    [Setup]    [OPTIONAL_TEST_SPECIFIC_SETUP]
    [Teardown]    [OPTIONAL_TEST_SPECIFIC_TEARDOWN]

    # Use Gherkin-style or Business Keywords
    Given [Precondition]
    When [Action]
    Then [Verification]
    And [Additional Verification]


*** Keywords ***
[KEYWORD_NAME]
    [Documentation]    [CLEAR DESCRIPTION OF WHAT THIS KEYWORD DOES]
    ...                [Additional details if needed]
    ...                [Arguments description if complex]
    [Arguments]    ${arg1}    ${arg2}=${default}

    # Implementation steps
    [STEP_OR_KEYWORD]    ${arg1}
    [STEP_OR_KEYWORD]    ${arg2}

    # Return value if applicable
    RETURN    ${result}


*** Comments ***
# Maintenance Notes:
# - [Important information about this file]
# - [Known limitations or dependencies]
# - [Future improvements]

# Change Log:
# - YYYY-MM-DD: [Description of changes]
```

---

## Best Practices Checklist

### Before Generating Tests

- [ ] Query rf-docs-mcp for relevant standard library keywords
- [ ] Read Browser.json and RequestsLibrary.json for external library keywords
- [ ] Verify all keywords exist in approved documentation sources
- [ ] Understand existing test structure and patterns in the project

### During Test Generation

- [ ] Use ONLY modern RF 7.x syntax (VAR, IF/ELSE, FOR, RETURN, etc.)
- [ ] NEVER use legacy keywords (Run Keyword If, Set Test Variable, etc.)
- [ ] Apply Page Object Model for UI tests
- [ ] Separate test cases (Gherkin) from implementation (keywords)
- [ ] Use explicit waits (Wait For...) - NO Sleep
- [ ] All variables in Variables section - NO hardcoded values
- [ ] Every test is independent - NO dependencies on other tests
- [ ] Every keyword has [Documentation]
- [ ] Behavioral test case names ([Actor] Should [Behavior] [Context])
- [ ] Appropriate tags for categorization and filtering
- [ ] Proper Setup/Teardown at suite and test levels

### After Test Generation

- [ ] Verify no legacy syntax used
- [ ] Confirm all keywords exist in documentation sources
- [ ] Check for hardcoded values
- [ ] Validate proper error handling (TRY/EXCEPT where appropriate)
- [ ] Ensure test independence (can run in any order)
- [ ] Review wait strategies (no Sleep)
- [ ] Confirm proper documentation on all keywords
- [ ] Validate file saved outside template/ directory
- [ ] Add SOURCE OF TRUTH header at top of file

### Code Review Points

- [ ] Modern syntax compliance (RF 7.4.1)
- [ ] Keyword source validation (MCP tools + local docs)
- [ ] Page Object pattern applied correctly
- [ ] Clear separation: Tests → Business Keywords → Technical Keywords → Library Keywords
- [ ] No business logic in Test Cases section
- [ ] Explicit waits used correctly
- [ ] Proper variable scope and naming
- [ ] Comprehensive documentation
- [ ] Error handling and resilience
- [ ] Test data isolation and uniqueness

---

## Environment Integration

### MCP Server Access

**rf-docs-mcp (Documentation):**
```
Access via: Claude Code MCP integration (.claude.json)
Container: rf-docs-mcp
Server: /app/rf_docs_server.py
Tools: robot-get_keyword_documentation, robot-get_library_documentation, etc.
```

**RobotFramework-mcp (Execution):**
```
Access via: Claude Code MCP integration (.claude.json)
Container: robotframework-mcp
Server: /app/server.py
Tools: run_suite, run_test_by_name, list_tests, run_robocop_audit
```

### Local Documentation

**Browser Library:**
```
Container: robotframework-mcp
Path: /app/docs/Browser.json
Access: docker exec robotframework-mcp cat /app/docs/Browser.json
```

**RequestsLibrary:**
```
Container: robotframework-mcp
Path: /app/docs/RequestsLibrary.json
Access: docker exec robotframework-mcp cat /app/docs/RequestsLibrary.json
```

### Test Execution

**Run Tests:**
```bash
# Via MCP tool
run_suite(suite_path="/tests/books_api.robot", include_tags="smoke")

# Direct execution
docker exec -it robotframework-mcp robot /tests/books_api.robot
```

**Results Location:**
```
Host: ./robot_results/
Container: /results/
Files: log.html, report.html, output.xml
```

---

## Quick Reference Card

### DO Use (RF 7.x Modern Syntax)

```robot
# Variables
VAR    ${var}    value
VAR    ${var}    value    scope=TEST

# Conditionals
IF    ${condition}
    Keyword
END

# Inline IF
IF    ${cond}    Keyword    ELSE    Other Keyword

# Loops
FOR    ${item}    IN    @{ITEMS}
    Process    ${item}
END

# Loop Control
BREAK
CONTINUE

# Error Handling
TRY
    Risky Keyword
EXCEPT    Error Message
    Handle Error
END

# Return
RETURN    ${value}
```

### DON'T Use (Legacy/Deprecated)

```robot
# ❌ Set Test Variable    ${var}    value
# ❌ Run Keyword If    ${condition}    Keyword
# ❌ Exit For Loop
# ❌ Return From Keyword    ${value}
# ❌ Sleep    5s
```

### Test Structure

```
*** Test Cases ***
[Actor] Should [Behavior] [Context]    ← Behavioral name
    [Documentation]                     ← Always document
    [Tags]                              ← Categorize
    Given [Precondition]                ← Gherkin style
    When [Action]                       ← Business keywords only
    Then [Verification]                 ← NO implementation details
```

### Waiting Strategy

```robot
# ✅ DO
Wait For Elements State    ${sel}    visible    timeout=10s
Wait Until Keyword Succeeds    30s    2s    Check Condition

# ❌ DON'T
Sleep    5s
```

---

## Document Metadata

**File**: `.claude/ROBOT_FRAMEWORK_STANDARDS.md`
**Purpose**: Authoritative reference for Claude Code RF test generation
**Maintenance**: Update when RF version changes or new patterns emerge
**Version**: 1.0
**Created**: 2026-02-26
**Target**: Claude Code CLI tool
**RF Version**: 7.4.1
**Browser Library**: 19.12.3
**RequestsLibrary**: 0.9.7

---

**For questions or clarifications about these standards, refer to:**
- Architecture documentation: `docs/architecture.md`
- MCP documentation: Query rf-docs-mcp server
- Project README: `README.md`

---

*This document is the SOURCE OF TRUTH for all Robot Framework test generation with Claude Code. All tests must comply with these standards.*
