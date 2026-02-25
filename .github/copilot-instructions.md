<!-- 
═══════════════════════════════════════════════════════════════════════════════
SOURCE OF TRUTH: For all Robot Framework tasks, prioritize the instructions 
located in .github/copilot-instructions.md. Read that file first to ensure 
compliance with modern RF 7.4.1 syntax, library versions, and best practices.
═══════════════════════════════════════════════════════════════════════════════
-->

# AI Assistant Instructions for Books Database Service RF Test Generation

## Project Purpose

This is a **test generation baseline project**. Your primary task is generating Robot Framework test suites for the Books Database Service. The application code (`fastapi_demo/`) is stable and **must not be modified**. Focus exclusively on test creation, execution, and refinement.

## Critical Constraints

### Application Code is Read-Only
- **NEVER modify** files in `fastapi_demo/`, `server.py`, or `Dockerfile`
- All work focuses on `robot_tests/` directory
- Python unit tests in `tests/` are optional context; do not alter application behavior

### Branching Convention
Use pattern: `r<round>/<tool>/<model>`
```bash
git checkout -b r1/copilot/sonnet45
git checkout -b r2/claudecode/sonnet4
```
Do not merge to main; each branch captures one tool's test generation session.

## Architecture Essentials

### MCP On-Demand Execution Pattern
- Services run via Docker Compose; containers stay alive but MCP servers spawn on-demand
- Communication: `docker exec -i <container> python /app/server.py` (stdin/stdout, JSON-RPC 2.0)
- No persistent MCP processes; stateless execution per request
- Access patterns in [docs/architecture.md](../docs/architecture.md) lines 150-220

### Service Stack
```
books-service (localhost:8000)     → FastAPI app + SQLite DB
initialization                     → One-time DB setup (creates 100 books)
robotframework-mcp                 → Test execution environment (RF 7.4.1, Browser 19.12.3)
rf-docs-mcp                        → Keyword documentation query service
```

Start all services: `./quick-start.sh` (generates MCP config + starts containers)

## Robot Framework Test Generation

### Mandatory Library Versions
```robot
Library    Browser    version=19.12.3
Library    RequestsLibrary    version=0.9.7
```
**Robot Framework 7.4.1** syntax only. Query keywords via `rf-docs-mcp` MCP tools before use.

### Modern RF 7.4.1 Syntax (MANDATORY)

**⛔ CRITICAL: Use ONLY modern syntax. Legacy keywords are FORBIDDEN.**

#### 1. VAR Statement (Replaces Set Variable Keywords)
```robot
# ✅ CORRECT - Modern VAR syntax
VAR    ${local_var}     value                    # Local scope (default)
VAR    ${test_var}      value    scope=TEST      # Test scope
VAR    ${suite_var}     value    scope=SUITE     # Suite scope
VAR    ${global_var}    value    scope=GLOBAL    # Global scope
VAR    @{list_var}      item1    item2    item3  # List variable
VAR    &{dict_var}      key1=value1    key2=value2  # Dictionary variable

# ❌ FORBIDDEN - Legacy syntax
Set Test Variable      ${var}    value
Set Suite Variable     ${var}    value
Set Global Variable    ${var}    value
```

#### 2. Native IF/ELSE (Replaces Run Keyword If)
```robot
# ✅ CORRECT - Native IF/ELSE
IF    ${status_code} == 200
    Log    Request successful
ELSE IF    ${status_code} == 404
    Log    Resource not found
ELSE
    Fail    Unexpected status: ${status_code}
END

# Inline IF for simple cases
IF    ${count} > 0    Log    Items found

# ❌ FORBIDDEN - Legacy conditional keywords
Run Keyword If         ${condition}    Keyword
Run Keyword Unless     ${condition}    Keyword
```

#### 3. Native FOR Loops (Replaces :FOR syntax)
```robot
# ✅ CORRECT - Modern FOR syntax
FOR    ${book}    IN    @{books}
    Log    Processing: ${book}
    Validate Book    ${book}
END

# FOR with RANGE
FOR    ${i}    IN RANGE    10
    Create Test Book    index=${i}
END

# FOR with ENUMERATE
FOR    ${index}    ${book}    IN ENUMERATE    @{books}
    Log    Book ${index}: ${book}
END

# ❌ FORBIDDEN - Legacy FOR syntax
:FOR    ${item}    IN    @{list}
```

#### 4. Native WHILE Loops
```robot
# ✅ CORRECT - WHILE with limit
VAR    ${count}    0
WHILE    ${count} < 10    limit=20
    ${count}=    Evaluate    ${count} + 1
    Log    Count: ${count}
END

# WHILE with timeout
WHILE    ${condition}    timeout=30s
    Wait Until Page Is Ready
END
```

#### 5. TRY/EXCEPT Error Handling
```robot
# ✅ CORRECT - TRY/EXCEPT syntax
TRY
    Click    //button[@id='submit']
EXCEPT    ElementNotFound    AS    ${error}
    Log    Button not available: ${error}
    Fail    Submit button missing
EXCEPT
    Log    Unexpected error occurred
FINALLY
    Capture Page Screenshot
END

# ❌ FORBIDDEN - Legacy error handling
Run Keyword And Ignore Error    Keyword
Run Keyword And Expect Error    Keyword
```

#### 6. BREAK and CONTINUE in Loops
```robot
# ✅ CORRECT - Modern loop control
FOR    ${book}    IN    @{books}
    IF    '${book}' == ''
        CONTINUE    # Skip empty entries
    END
    IF    ${book.pages} > 1000
        BREAK    # Stop at first large book
    END
    Process Book    ${book}
END

# ❌ FORBIDDEN - Legacy loop control  
Continue For Loop
Continue For Loop If
Exit For Loop
Exit For Loop If
```

### Deprecated Keywords to AVOID

**The following BuiltIn keywords are DEPRECATED in RF 7.4.1. Use modern syntax instead:**

| ❌ DEPRECATED Keyword | ✅ Use Instead |
|----------------------|----------------|
| `Set Test Variable` | `VAR    ${var}    value    scope=TEST` |
| `Set Suite Variable` | `VAR    ${var}    value    scope=SUITE` |
| `Set Global Variable` | `VAR    ${var}    value    scope=GLOBAL` |
| `Run Keyword If` | `IF` statement |
| `Run Keyword Unless` | `IF` with negation |
| `Continue For Loop` | `CONTINUE` statement |
| `Continue For Loop If` | `IF` + `CONTINUE` |
| `Exit For Loop` | `BREAK` statement |
| `Exit For Loop If` | `IF` + `BREAK` |
| `Return From Keyword` | `RETURN` statement |
| `Return From Keyword If` | `IF` + `RETURN` |

### Test Standards (from `template/Test Standards.txt`)
1. **Page Object Model**: UI tests must use Page Object pattern
2. **Explicit Waits**: Use `Wait Until...` keywords; **NEVER use Sleep**
3. **Behavioral Naming**: Test names describe user actions (e.g., "User Should Be Able To Add A Book")
4. **Test Independence**: Each test must run standalone, order-agnostic
5. **Variable-Driven**: No hardcoded strings; use `${VARIABLES}` for URLs, test data
6. **Documentation**: Every keyword needs `[Documentation]` block
7. **Resource Abstraction**: Reusable keywords go in separate `.resource` files

### ⛔ ARCHITECTURAL ENFORCEMENT: No Linear Scripting

**CRITICAL RULE: Test Cases MUST use Gherkin or Business Keywords. Implementation logic belongs ONLY in Keywords section.**

#### ✅ CORRECT Pattern: Gherkin in Test Cases
```robot
*** Test Cases ***
User Should Be Able To Create A New Book Via UI
    [Documentation]    Validates book creation workflow through web interface
    [Tags]    crud    ui    smoke
    Given User Is On Books Page
    When User Creates New Book    title=RF Guide    author=Jane Doe    pages=300
    Then Book Should Be Visible In List    RF Guide
    And Book Details Should Match    title=RF Guide    pages=300

*** Keywords ***
Given User Is On Books Page
    [Documentation]    Navigates to books listing page and verifies page load
    New Page    ${BASE_URL}/
    Wait For Elements State    //h1[contains(text(), 'Books')]    visible    timeout=10s

When User Creates New Book
    [Documentation]    Fills and submits book creation form
    [Arguments]    ${title}    ${author}    ${pages}
    Click    //button[@id='add-book']
    Fill Text    //input[@name='title']    ${title}
    Fill Text    //input[@name='author']    ${author}
    Fill Text    //input[@name='pages']    ${pages}
    Click    //button[@type='submit']

Then Book Should Be Visible In List
    [Documentation]    Verifies book appears in the listing
    [Arguments]    ${title}
    Wait For Elements State    //td[text()='${title}']    visible    timeout=5s
```

#### ❌ FORBIDDEN Pattern: Linear Scripting in Test Cases
```robot
*** Test Cases ***
Create Book Test
    # ❌ THIS IS WRONG - Raw implementation in test case
    New Page    http://localhost:8000
    Click    //button[@id='add-book']
    Fill Text    //input[@name='title']    Test Book
    Fill Text    //input[@name='author']    Test Author
    Click    //button[@type='submit']
    Wait For Elements State    //td[text()='Test Book']    visible
```

### Test Standards (from `template/Test Standards.txt`)

### Test Structure Template
See `template/Instruction Template.txt` for canonical structure:
```robot
*** Settings ***
Documentation     High-level suite description
Library           Browser
Resource          resources/page_objects.resource

Suite Setup       Open Browser To Books Page
Suite Teardown    Close Browser

*** Test Cases ***
User Should Be Able To Create A New Book
    [Documentation]    Validates book creation via UI form
    [Tags]    crud    ui    smoke
    Fill Book Form    title=Test Book    author=Test Author    pages=250
    Submit Book Form
    Book Should Appear In List    Test Book
```

### Library-Specific Guidelines

#### Browser Library (v19.12.3) - 147 Keywords

**Most Common Keyword Categories:**
- **Get Keywords (38)**: `Get Text`, `Get Attribute`, `Get Element Count`, `Get Url`, etc.
- **Wait Keywords (12)**: `Wait For Elements State`, `Wait For Condition`, `Wait Until Network Is Idle`, etc.
- **Set Keywords (11)**: `Set Browser Timeout`, `Set Viewport Size`, `Set Offline`, etc.
- **Navigation**: `New Page`, `Go To`, `Go Back`, `Go Forward`, `Reload`
- **Interaction**: `Click`, `Fill Text`, `Type Text`, `Check Checkbox`, `Select Options From Dropdown`
- **Assertions**: `Get Element Count`, `Get Text`, verify via standard assertions

**Critical Browser Patterns:**
```robot
# ✅ CORRECT - Browser initialization with proper waits
*** Keywords ***
Open Browser To Application
    [Documentation]    Initializes browser and navigates to application
    New Browser    browser=chromium    headless=True
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    ${BASE_URL}
    Wait For Load State    networkidle    timeout=30s

# ✅ CORRECT - Explicit waits (NEVER use Sleep)
Wait For Book List To Load
    [Documentation]    Waits for book listing to be fully rendered
    Wait For Elements State    //table[@id='books-table']    visible    timeout=10s
    Wait For Element Count    //table[@id='books-table']//tr    >    1

# ✅ CORRECT - Element interaction with error handling
Click Element With Retry
    [Documentation]    Clicks element with retry logic for flaky scenarios
    [Arguments]    ${locator}    ${max_retries}=3
    VAR    ${attempt}    0
    WHILE    ${attempt} < ${max_retries}    limit=10
        TRY
            Wait For Elements State    ${locator}    visible    timeout=5s
            Click    ${locator}
            BREAK
        EXCEPT    ElementNotFound    AS    ${error}
            Log    Attempt ${attempt}: ${error}
            VAR    ${attempt}    ${attempt + 1}
        END
    END
```

**Browser Library Wait Strategies:**
- `Wait For Elements State` - Wait for element visibility/enabled/etc.
- `Wait For Load State` - Wait for page load events (`load`, `networkidle`, `domcontentloaded`)
- `Wait For Condition` - Custom JavaScript condition
- `Wait Until Network Is Idle` - Wait for network activity to settle

#### RequestsLibrary (v0.9.7) - 33 Keywords

**Core HTTP Methods:**
- Session Management: `Create Session`, `Delete All Sessions`
- HTTP Verbs: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `HEAD`, `OPTIONS`
- Session Variants: `GET On Session`, `POST On Session`, etc.

**Critical RequestsLibrary Patterns:**
```robot
# ✅ CORRECT - Session-based API testing
*** Keywords ***
Setup API Session
    [Documentation]    Creates reusable HTTP session with base configuration
    Create Session    books_api    ${API_BASE_URL}    verify=True
    ...    headers={"Content-Type": "application/json"}

Create Book Via API
    [Documentation]    Creates a book using POST request
    [Arguments]    ${title}    ${author}    ${pages}
    VAR    &{book_data}    title=${title}    author=${author}    pages=${pages}
    ...    year=2024    publisher=Test Pub    isbn=1234567890
    ...    description=Test book
    ${response}=    POST On Session    books_api    /books/
    ...    json=${book_data}    expected_status=201
    RETURN    ${response.json()}

Verify Book Exists Via API
    [Documentation]    Validates book creation via GET request
    [Arguments]    ${book_id}
    ${response}=    GET On Session    books_api    /books/${book_id}
    ...    expected_status=200
    Should Be Equal    ${response.json()['id']}    ${book_id}
```

### Standard Library Quick Reference

**BuiltIn Library** (107 keywords total, 11 deprecated):
- ✅ Use: `Log`, `Should Be Equal`, `Should Contain`, `Should Not Be Empty`, `Fail`, `Pass Execution`
- ✅ Use: `Length Should Be`, `Convert To Integer`, `Convert To String`, `Evaluate`
- ❌ Avoid: `Run Keyword If`, `Set Test Variable`, `Continue For Loop`, `Exit For Loop`

**String Library** (42 keywords):
- `Should Match Regexp`, `Should Not Match Regexp`, `Replace String`, `Split String`
- `Get Substring`, `Convert To Lowercase`, `Convert To Uppercase`, `Strip String`

**Collections Library** (48 keywords):
- `Append To List`, `Get From Dictionary`, `Get From List`, `Dictionary Should Contain Key`
- `List Should Contain Value`, `Lists Should Be Equal`, `Sort List`, `Remove From List`

**DateTime Library** (22 keywords):
- `Get Current Date`, `Convert Date`, `Add Time To Date`, `Subtract Time From Date`
- Useful for timestamp validation and test data generation

### Running Tests
Use MCP tools via IDE integration (configured by `quick-start.sh`):
- `run_suite()` - Execute entire suite/folder
- `run_test_by_name()` - Run specific test
- `list_tests()` - See available tests
- Results saved to `robot_results/` (mapped from container `/results`)

### Quality Audit
Run Robocop static analysis:
```bash
./run_robocop_audit.sh
```
Generates dated report in `robot_results/robocop_YYYYMMDD.txt`

## API Under Test

**Books REST API** (http://localhost:8000/docs):
- `GET /books/` - List all books
- `POST /books/` - Create book (requires: title, author, pages, year, publisher, isbn, description)
- `GET /books/{id}` - Get book by ID
- `PUT /books/{id}` - Update book
- `DELETE /books/{id}` - Delete book
- `POST /books/{id}/favorite` - Toggle favorite status

See [fastapi_demo/routers/books.py](../fastapi_demo/routers/books.py) for request/response schemas.

## Key Files & Directories

```
robot_tests/         → Your test suites (.robot files)
robot_results/       → Test execution outputs (output.xml, log.html, report.html)
template/            → Test generation guidance (Instruction Template.txt, Test Standards.txt)
docs/                → Architecture, workflows, testing guides
RobotFramework-MCP-server/  → MCP server implementations (server.py, rf_docs_server.py)
```

## Development Workflow

1. **Start environment**: `./quick-start.sh` (select your IDE when prompted)
2. **Reload VS Code**: Command Palette → "Developer: Reload Window" (activates MCP)
3. **Generate tests**: Create `.robot` files in `robot_tests/` following template standards
4. **Execute tests**: Use MCP tools from IDE (queries `robotframework-mcp` container)
5. **Review results**: Check `robot_results/` for HTML reports and logs
6. **Audit quality**: Run `./run_robocop_audit.sh` before committing
7. **Commit**: `git add -A && git commit -m "Add book creation test suite"`
8. **Push**: `git push -u origin r1/copilot/sonnet45`

## Troubleshooting

- **Container not running**: `docker ps` to verify; restart with `docker compose up -d`
- **MCP not responding**: Reload VS Code window after `quick-start.sh`
- **Tests fail to find keywords**: Query `rf-docs-mcp` tools first; only use documented keywords
- **Database issues**: Check `docker logs books-database-service`
- **Full guides**: [docs/troubleshooting.md](../docs/troubleshooting.md)

## What Makes This Project Different

- **On-demand MCP pattern**: No network ports for MCP; uses `docker exec` stdio transport
- **Immutable baseline**: Application is frozen; only tests evolve across AI tool comparisons
- **Branch-per-tool**: Each branch preserves one AI tool's test generation artifacts
- **Template-driven**: `template/` files define exact Robot Framework conventions to follow
- **Version-locked RF ecosystem**: Strict version pins ensure reproducibility (RF 7.4.1, Browser 19.12.3)

## Common Mistakes to Avoid

- ❌ Editing `fastapi_demo/` application code
- ❌ Using `Sleep` keywords instead of explicit waits
- ❌ Hardcoding values instead of variables
- ❌ Using keywords not found in RF 7.4.1 documentation
- ❌ Creating tests with execution order dependencies
- ❌ Skipping Robocop audit before commits
- ❌ Using deprecated keywords: `Run Keyword If`, `Set Test Variable`, `Continue For Loop`, etc.
- ❌ Using legacy `:FOR` syntax instead of modern `FOR` loops
- ❌ Linear scripting in Test Cases (use Gherkin/Business Keywords)
- ❌ Missing `[Documentation]` blocks in keywords
- ❌ Hardcoded wait times (use dynamic waits with timeouts)

## Complete Test Suite Example

```robot
*** Settings ***
Documentation     Complete example of Books API and UI testing
...               Demonstrates modern RF 7.4.1 syntax and best practices

Library           Browser
Library           RequestsLibrary
Resource          resources/books_page_object.resource

Suite Setup       Initialize Test Environment
Suite Teardown    Clean Up Test Environment
Test Setup        Reset Test Data
Test Teardown     Capture Test Evidence

Force Tags        books    regression

*** Variables ***
${BASE_URL}           http://localhost:8000
${API_BASE_URL}       http://localhost:8000
${BROWSER_TIMEOUT}    10s
${TEST_BOOK_TITLE}    Robot Framework Test Guide

*** Test Cases ***
User Should Be Able To Create Book Via UI
    [Documentation]    End-to-end test of book creation through web interface
    [Tags]    ui    crud    smoke
    Given User Is On Books Listing Page
    When User Creates Book With Details
    ...    title=${TEST_BOOK_TITLE}
    ...    author=Test Author
    ...    pages=500
    Then Book Should Appear In Listing    ${TEST_BOOK_TITLE}
    And Book Count Should Increase By    1

API Should Return Correct Book Data
    [Documentation]    Validates API responses match expected schema
    [Tags]    api    smoke
    Given Books API Session Exists
    When Book Is Created Via API    title=API Test Book    author=API Author    pages=300
    Then Response Should Contain Book ID
    And Book Should Be Retrievable Via API
    And Book Data Should Match Submitted Values

User Should Be Able To Search For Books
    [Documentation]    Tests search functionality with various criteria
    [Tags]    ui    search
    Given User Is On Books Listing Page
    And Multiple Test Books Exist
    When User Searches For    ${TEST_BOOK_TITLE}
    Then Search Results Should Contain    ${TEST_BOOK_TITLE}
    And Search Results Should Not Contain    Other Books

*** Keywords ***
Initialize Test Environment
    [Documentation]    Sets up browser and API sessions for entire suite
    New Browser    browser=chromium    headless=True
    New Context    viewport={'width': 1920, 'height': 1080}
    Create Session    books_api    ${API_BASE_URL}
    Log    Test environment initialized    console=True

Clean Up Test Environment
    [Documentation]    Closes browser and API sessions
    Delete All Sessions
    Close Browser
    Log    Test environment cleaned up    console=True

Reset Test Data
    [Documentation]    Ensures clean state before each test
    # Could call API to reset database or create test fixtures
    Log    Test data reset completed    console=True

Capture Test Evidence
    [Documentation]    Takes screenshot on test failure
    TRY
        Run Keyword If Test Failed    Take Screenshot    format=png
    EXCEPT
        Log    Screenshot capture failed    WARN
    END

Given User Is On Books Listing Page
    [Documentation]    Navigates to main books page and verifies load
    New Page    ${BASE_URL}/
    Wait For Load State    networkidle    timeout=${BROWSER_TIMEOUT}
    Wait For Elements State    //h1[contains(text(), 'Books')]    visible    timeout=${BROWSER_TIMEOUT}

When User Creates Book With Details
    [Documentation]    Fills book creation form with provided details
    [Arguments]    ${title}    ${author}    ${pages}
    Click    //button[@id='add-book-btn']
    Wait For Elements State    //form[@id='book-form']    visible    timeout=${BROWSER_TIMEOUT}
    Fill Text    //input[@name='title']    ${title}
    Fill Text    //input[@name='author']    ${author}
    Fill Text    //input[@name='pages']    ${pages}
    Fill Text    //input[@name='year']    2024
    Fill Text    //input[@name='publisher']    Test Publisher
    Fill Text    //input[@name='isbn']    1234567890123
    Fill Text    //textarea[@name='description']    Test description
    Click    //button[@type='submit']

Then Book Should Appear In Listing
    [Documentation]    Verifies book is visible in the table
    [Arguments]    ${title}
    Wait For Elements State    //td[text()='${title}']    visible    timeout=${BROWSER_TIMEOUT}
    ${text}=    Get Text    //td[text()='${title}']
    Should Be Equal    ${text}    ${title}

When Book Is Created Via API
    [Documentation]    Creates book using REST API
    [Arguments]    ${title}    ${author}    ${pages}
    VAR    &{book_data}
    ...    title=${title}
    ...    author=${author}
    ...    pages=${pages}
    ...    year=2024
    ...    publisher=API Publisher
    ...    isbn=9876543210123
    ...    description=API test book
    
    VAR    ${response}    scope=TEST
    ${response}=    POST On Session    books_api    /books/
    ...    json=${book_data}
    ...    expected_status=201
    
    VAR    ${book_id}    ${response.json()['id']}    scope=TEST
    Log    Created book ID: ${book_id}    console=True

Then Response Should Contain Book ID
    [Documentation]    Validates API response structure
    ${book_id}=    Set Variable    ${response.json()['id']}
    Should Not Be Empty    ${book_id}
    Should Be True    ${book_id} > 0
```

## Testing Patterns & Best Practices

### Data-Driven Testing with Test Templates
```robot
*** Test Cases ***
Validate Book Creation With Various Data Sets
    [Template]    Create And Verify Book
    # title              author           pages
    Short Title          Author One       100
    Very Long Book Title Name Here        Author Two       999
    Special-Chars!@#     Author Three     250

*** Keywords ***
Create And Verify Book
    [Arguments]    ${title}    ${author}    ${pages}
    Create Book Via API    ${title}    ${author}    ${pages}
    Book Should Exist    ${title}
```

### Resource File Organization
```robot
# resources/api_keywords.resource
*** Settings ***
Documentation     Reusable API interaction keywords

Library           RequestsLibrary

*** Keywords ***
Setup Books API
    Create Session    books    http://localhost:8000

# resources/page_objects.resource
***## Common Mistakes to Avoid

- ❌ Editing `fastapi_demo/` application code
- ❌ Using `Sleep` keywords instead of explicit waits
- ❌ Hardcoding values instead of variables
- ❌ Using keywords not found in RF 7.4.1 documentation
- ❌ Creating tests with execution order dependencies
- ❌ Skipping Robocop audit before commits
