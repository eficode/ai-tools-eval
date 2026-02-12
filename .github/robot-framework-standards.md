SOURCE OF TRUTH: For all Robot Framework tasks, prioritize the instructions located in .github/copilot-instructions.md. Read that file first to ensure compliance.

# Robot Framework 7.4.1 Test Standards for GitHub Copilot

## CRITICAL SYNTAX MANDATE - Robot Framework 7.4.1

**⛔ FORBIDDEN LEGACY PATTERNS:**
- `Set Test Variable` / `Set Suite Variable` → Use `VAR` instead
- `Run Keyword If`, `Run Keyword Unless` → Use native `IF/ELSE` instead  
- `Repeat Keyword` → Use native `FOR` loops instead
- `Should Be Equal As Strings` → Use assertions with type validation

**✅ MODERN SYNTAX REQUIREMENTS:**
```robot
*** Variables ***
# Modern variable declaration
VAR    ${API_URL}    http://localhost:8000/books/
VAR    @{BROWSER_ARGS}    --disable-dev-shm-usage    --no-sandbox

*** Test Cases ***
Modern Control Flow Example
    VAR    ${book_title}    Test Book Title
    
    IF    ${book_title} != ""
        Log    Creating book: ${book_title}
    ELSE
        FAIL    Book title cannot be empty
    END
    
    FOR    ${attempt}    IN RANGE    3
        ${response}=    GET    ${API_URL}
        IF    ${response.status_code} == 200
            BREAK
        END
        Sleep    1s
    END
    
    TRY
        ${result}=    Perform Complex Operation
    EXCEPT    ConnectionError
        Log    Network issue, retrying...
        ${result}=    Retry Complex Operation
    END
```

## ARCHITECTURAL MANDATES

### ⛔ ANTI-PATTERN: LINEAR SCRIPTING
**FORBIDDEN in Test Cases:**
```robot
*** Test Cases ***
# ❌ WRONG - Raw library keywords in test case
Bad Test Case
    New Browser    chromium    headless=true
    New Page    http://localhost:8000
    Click    id=add-book-btn
    Type Text    id=title    My Book
    Click    id=submit-btn
    Get Text    .success-message    ==    Book added successfully
```

**✅ REQUIRED - Business Keywords Only:**
```robot
*** Test Cases ***
User Should Be Able To Add New Book
    [Documentation]    Verifies book creation functionality end-to-end
    [Tags]    books    ui    happy-path
    Given User Is On Books Management Page
    When User Adds New Book    title=My Test Book    author=John Doe    year=2024
    Then Book Should Be Displayed In List    My Test Book
    And Success Message Should Be Shown    Book added successfully
```

### KEYWORD LAYER STRUCTURE

**Implementation Keywords (in Resource Files):**
```robot
*** Keywords ***
User Is On Books Management Page
    [Documentation]    Opens browser and navigates to books page
    New Browser    chromium    headless=${HEADLESS}
    New Page    ${BASE_URL}
    Wait For Elements State    .books-container    visible

User Adds New Book
    [Documentation]    Fills and submits the book creation form
    [Arguments]    ${title}    ${author}    ${year}
    Click    data-testid=add-book-button
    Fill Text    id=book-title    ${title}
    Fill Text    id=book-author    ${author}
    Fill Text    id=book-year    ${year}
    Click    data-testid=submit-book
```

## VERIFIED LIBRARY STANDARDS

### Browser Library 19.12.3 (Playwright)
**Core Navigation & Interaction:**
- `New Browser(browser, headless=true)`, `New Page(url)`, `Close Browser`
- `Click(selector)`, `Fill Text(selector, text)`, `Type Text(selector, text)`
- `Get Text(selector)`, `Wait For Elements State(selector, state)`

**Modern Selectors (CSS default):**
```robot
Click    data-testid=submit-btn    # data-testid preferred
Fill Text    #book-title    My Title    # CSS ID (escape #)
Click    //button[text()='Save']    # XPath for text matching
Get Text    .error-message    # CSS class
```

### RequestsLibrary 0.9.7
**Session Management:**
```robot
*** Keywords ***
Setup API Session
    Create Session    books_api    ${API_BASE_URL}
    
API Test Template
    [Arguments]    ${endpoint}    ${expected_status}=200
    ${response}=    GET On Session    books_api    ${endpoint}
    Status Should Be    ${expected_status}    ${response}
    RETURN    ${response}
```

**Core HTTP Keywords:**
- `GET(url, params, headers)`, `POST(url, json, data)`, `PUT`, `DELETE`
- `GET On Session`, `POST On Session` (with session management)
- `Create Session(alias, base_url)`, `Delete All Sessions`

### Robot Framework 7.4.1 Standard Libraries
**BuiltIn (Always Available):**
- `Log(message, level=INFO)`, `Sleep(time)`, `Set Variable(value)`
- `Should Be Equal(first, second)`, `Should Contain(container, item)`
- `Length Should Be(item, length)`, `Should Be True(condition)`

**Collections (import required):**
- `Get From Dictionary(dictionary, key)`, `Set To Dictionary`
- `Append To List(list, *values)`, `Get From List(list, index)`

**String (import required):**
- `Replace String(string, search_for, replace_with)`
- `Get Substring(string, start, end)`, `Should Match Regexp`

## STABILITY PATTERNS

### Explicit Waits (No Sleep!)
```robot
*** Keywords ***
Wait For Book To Appear
    [Arguments]    ${book_title}
    Wait For Elements State    
    ...    xpath=//div[@class='book-card']//h3[text()='${book_title}']
    ...    visible    timeout=10s

Wait For API Response
    [Arguments]    ${endpoint}
    FOR    ${i}    IN RANGE    10
        ${response}=    GET    ${endpoint}
        IF    ${response.status_code} == 200
            RETURN    ${response}
        END
        Sleep    500ms
    END
    FAIL    API endpoint ${endpoint} not ready after 5 seconds
```

### Error Handling Patterns
```robot
*** Keywords ***
Robust Book Creation
    [Arguments]    ${book_data}
    TRY
        ${response}=    POST    ${API_URL}/books/    json=${book_data}
        Status Should Be    201    ${response}
    EXCEPT    ConnectionError
        Log    Network issue detected    WARN
        Sleep    2s
        ${response}=    POST    ${API_URL}/books/    json=${book_data}
    EXCEPT    AS    ${error}
        Log    Unexpected error: ${error}    ERROR
        FAIL    Book creation failed: ${error}
    END
    RETURN    ${response}
```

## DATA ISOLATION & TEST INDEPENDENCE

### Unique Test Data Generation
```robot
*** Keywords ***
Generate Unique Book Data
    [Arguments]    ${base_title}=Test Book
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    ${unique_title}=    Set Variable    ${base_title}_${timestamp}
    VAR    &{book_data}    
    ...    title=${unique_title}
    ...    author=Test Author ${timestamp}
    ...    year=2024
    ...    favorite=false
    RETURN    &{book_data}

Clean Test Environment
    [Documentation]    Ensures clean state before each test
    Delete All Sessions
    TRY
        Delete All Books Via API
    EXCEPT    
        Log    Could not clean books, continuing    WARN
    END
```

## GITHUB COPILOT OPTIMIZATION HINTS

**File Organization:**
```
robot_tests/
├── suites/
│   ├── api_tests.robot          # API-focused test suites
│   └── ui_tests.robot           # Browser-based test suites
├── resources/
│   ├── api_keywords.robot       # RequestsLibrary implementations
│   ├── ui_keywords.robot        # Browser Library implementations  
│   └── common_keywords.robot    # Shared business logic
└── variables/
    └── test_config.robot        # Environment configurations
```

**Test Case Naming Patterns:**
- Behavior-driven: "User Should Be Able To [Action]"
- API focused: "API Should [Behavior] When [Condition]"  
- Error cases: "System Should Handle [Error Condition] Gracefully"

**Tag Strategy:**
```robot
*** Test Cases ***
User Should Be Able To Add Book
    [Tags]    books    ui    create    happy-path    smoke

API Should Reject Invalid Book Data
    [Tags]    books    api    create    validation    edge-case
```

**Variable Scope Management:**
```robot
*** Variables ***
# Suite-level configuration
${BASE_URL}         http://localhost:8000
${API_BASE_URL}     http://localhost:8000
${HEADLESS}         true

# Test-specific data should use VAR in keywords
# Never hardcode URLs or test data in keywords
```

## FORBIDDEN PRACTICES

❌ **Never use these legacy patterns:**
- `Run Keyword If`, `Run Keyword Unless` 
- `Set Test Variable`, `Set Suite Variable`
- `Sleep` for synchronization (use explicit waits)
- Business logic mixed with implementation details
- Hardcoded test data or timing values
- Raw library keywords in test cases

✅ **Always enforce:**
- Business keywords in test cases only
- Modern RF 7.4.1 syntax (`VAR`, `IF/ELSE`, `FOR`, `TRY/EXCEPT`)
- Explicit waits with meaningful timeouts
- Unique test data generation
- Error handling with recovery strategies
- Clear separation between UI and API test layers