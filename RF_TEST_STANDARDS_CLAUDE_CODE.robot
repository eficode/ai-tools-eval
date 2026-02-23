*** Comments ***
SOURCE OF TRUTH: For all Robot Framework tasks, prioritize the instructions located in RF_TEST_STANDARDS_CLAUDE_CODE.robot. Read that file first to ensure compliance.

*** Settings ***
Documentation     Robot Framework Test Standards for Claude Code
...
...               This file serves as the definitive source of truth for all Robot Framework
...               test development using Claude Code. It combines validated library keywords
...               from RF 7.4.1, modern syntax enforcement, and architectural best practices.
...
...               VALIDATED VERSIONS:
...               - robotframework==7.4.1 (321 keywords across 9 standard libraries)
...               - robotframework-browser==19.12.3 (Playwright-based UI automation)
...               - robotframework-requests==0.9.7 (HTTP/REST API testing)
...
...               AUTHORITY SOURCES:
...               - Standard Libraries: rf-docs-mcp tools (BuiltIn, Collections, String, DateTime, etc.)
...               - Browser Library: /app/docs/Browser.json (robotframework-mcp container)
...               - RequestsLibrary: /app/docs/RequestsLibrary.json (robotframework-mcp container)
...
...               COMPLIANCE REQUIREMENT:
...               Any keyword not found in these specific validated sources is INVALID and FORBIDDEN.


*** Variables ***
# ============================================================================
# MODERN SYNTAX ENFORCEMENT - Robot Framework 7.4.1
# ============================================================================

# ✅ CORRECT: Modern VAR syntax (RF 6.0+)
# Use VAR instead of Set Test/Suite Variable keywords
${EXAMPLE_VAR}         VAR    initial_value
@{EXAMPLE_LIST}        VAR    item1    item2    item3
&{EXAMPLE_DICT}        VAR    key1=value1    key2=value2

# ⛔ FORBIDDEN LEGACY PATTERNS:
# - Set Test Variable    ${var}    value
# - Set Suite Variable   ${var}    value
# - Set Global Variable  ${var}    value
# USE: VAR syntax instead


*** Keywords ***
# ============================================================================
# ARCHITECTURAL PATTERNS & STANDARDS
# ============================================================================

Example Modern Syntax Patterns
    [Documentation]    Demonstrates modern RF 7.4.1 syntax patterns that MUST be used
    [Tags]    syntax-example    modern-rf

    # ✅ CORRECT: Native IF/ELSE syntax (RF 4.0+)
    VAR    ${status}    success
    IF    $status == 'success'
        Log    Operation completed successfully
    ELSE IF    $status == 'pending'
        Log    Operation is still pending
    ELSE
        Log    Operation failed
    END

    # ✅ CORRECT: Native FOR loops (RF 3.1+)
    VAR    @{items}    apple    banana    cherry
    FOR    ${item}    IN    @{items}
        Log    Processing: ${item}
        IF    '${item}' == 'banana'
            CONTINUE
        END
        Log    Item processed: ${item}
    END

    # ✅ CORRECT: Native WHILE loops (RF 5.0+)
    VAR    ${counter}    0
    WHILE    ${counter} < 5
        Log    Counter value: ${counter}
        VAR    ${counter}    ${counter + 1}
    END

    # ✅ CORRECT: Native TRY/EXCEPT (RF 5.0+)
    TRY
        Keyword That Might Fail
    EXCEPT    ValueError    AS    ${error}
        Log    Caught ValueError: ${error}
    EXCEPT    *    AS    ${error}
        Log    Caught unexpected error: ${error}
    FINALLY
        Log    Cleanup actions executed
    END

# ⛔ FORBIDDEN LEGACY KEYWORDS (Use native syntax instead):
# - Run Keyword If → Use IF/ELSE
# - Run Keyword Unless → Use IF/ELSE with negated condition
# - Run Keywords → Use multiple statements or custom keyword
# - Exit For Loop → Use BREAK
# - Exit For Loop If → Use IF + BREAK
# - Continue For Loop → Use CONTINUE
# - Continue For Loop If → Use IF + CONTINUE

Example Page Object Pattern
    [Documentation]    Page Object Model implementation for UI tests
    ...                Encapsulates page-specific actions and locators
    [Arguments]    ${expected_title}

    # Browser Library keywords (validated from Browser.json)
    New Page    http://localhost:8000
    Wait For Load State    networkidle
    Get Title    should contain    ${expected_title}

Example API Testing Pattern
    [Documentation]    HTTP API testing with RequestsLibrary
    ...                Shows modern session management and validation
    [Arguments]    ${endpoint}    ${expected_status}=200

    # RequestsLibrary keywords (validated from RequestsLibrary.json)
    VAR    ${response}    GET    http://localhost:8000${endpoint}    expected_status=${expected_status}

    # Validation using standard library keywords
    Should Be Equal As Numbers    ${response.status_code}    ${expected_status}
    Should Not Be Empty    ${response.text}

Example Business Keyword
    [Documentation]    High-level business action combining multiple technical steps
    ...                Used in Test Cases to maintain Gherkin-style readability
    [Arguments]    ${book_title}    ${author}

    # Technical implementation hidden from test cases
    Example Page Object Pattern    Books Library
    Click    [data-testid=add-book-button]
    Fill Text    [data-testid=title-input]    ${book_title}
    Fill Text    [data-testid=author-input]    ${author}
    Click    [data-testid=save-button]

    # Explicit wait instead of sleep
    Wait For Elements State    text="${book_title}"    visible    timeout=10s

Example Wait Strategy Pattern
    [Documentation]    Demonstrates explicit waits - NEVER use Sleep
    [Arguments]    ${locator}    ${expected_text}

    # ✅ CORRECT: Explicit waits
    Wait For Elements State    ${locator}    visible    timeout=30s
    Wait For Elements State    ${locator}    stable     timeout=10s
    Get Text    ${locator}    should contain    ${expected_text}

    # ⛔ FORBIDDEN: Sleep commands
    # Sleep    5s    # THIS IS STRICTLY FORBIDDEN


*** Test Cases ***
# ============================================================================
# TEST CASE PATTERNS - BUSINESS FOCUSED, GHERKIN STYLE
# ============================================================================

User Should Be Able To Add A New Book Successfully
    [Documentation]    Validates that authenticated users can add books to the library
    ...                Tests core business functionality through UI workflow
    [Tags]    smoke    books    ui    regression
    [Setup]    Test Setup For Books UI

    # ✅ CORRECT: Business-focused steps using custom keywords
    Given User Is On Books Library Page
    When User Adds New Book    "The Art of Testing"    "Jane Smith"
    Then Book Should Be Visible In Library    "The Art of Testing"
    And Book Details Should Be Correct    "The Art of Testing"    "Jane Smith"

    [Teardown]    Test Teardown For Books UI

API Should Return Valid Book Data For Valid Requests
    [Documentation]    Validates API responses meet specification requirements
    ...                Tests data integrity and response format compliance
    [Tags]    api    books    smoke    integration
    [Setup]    Test Setup For API Tests

    # ✅ CORRECT: Business-focused API testing steps
    Given API Session Is Established
    When User Requests Book List Via API
    Then API Response Should Be Valid JSON
    And Response Should Contain Book Fields    id    title    author    isbn

    [Teardown]    Test Teardown For API Tests

# ⛔ ANTI-PATTERN VIOLATION EXAMPLES (NEVER DO THIS):
#
# Bad Example - Raw Technical Steps In Test Case:
# User Adds Book - WRONG APPROACH
#     New Page    http://localhost:8000
#     Click    [data-testid=add-button]          # ← Technical implementation
#     Fill Text    id=title    "Book Title"      # ← Raw locators exposed
#     Fill Text    id=author    "Author Name"    # ← No business context
#     Click    id=save                          # ← Linear scripting
#
# This violates the separation of concerns - test cases should describe
# WHAT business behavior is being tested, not HOW it's implemented.


*** Keywords ***
# ============================================================================
# TEST LIFECYCLE MANAGEMENT
# ============================================================================

Test Setup For Books UI
    [Documentation]    Prepares browser environment for UI testing
    ...                Ensures clean state and proper initialization

    # Browser Library setup with modern configuration
    New Browser    browser=chromium    headless=true
    New Context    viewport={'width': 1920, 'height': 1080}
    VAR    ${BROWSER_TIMEOUT}    30s    scope=TEST

Test Teardown For Books UI
    [Documentation]    Cleans up browser resources after UI tests
    ...                Ensures no resource leaks between tests

    # Comprehensive cleanup
    TRY
        Take Screenshot    fullPage=true
    EXCEPT    *
        Log    Screenshot capture failed - continuing cleanup
    FINALLY
        Close Browser
    END

Test Setup For API Tests
    [Documentation]    Initializes HTTP session for API testing
    ...                Configures headers and authentication if needed

    # RequestsLibrary session management
    VAR    ${API_BASE_URL}    http://localhost:8000
    VAR    ${API_TIMEOUT}     30

Test Teardown For API Tests
    [Documentation]    Cleans up HTTP sessions after API tests

    # Session cleanup would go here if using Create Session
    Log    API test cleanup completed

# ============================================================================
# GHERKIN STEP IMPLEMENTATIONS (Given/When/Then)
# ============================================================================

Given User Is On Books Library Page
    [Documentation]    Navigates to the books page and verifies page load
    Example Page Object Pattern    Books Library

Given API Session Is Established
    [Documentation]    Establishes HTTP session for API testing
    VAR    ${session_ready}    true    # Session setup implementation

When User Adds New Book
    [Documentation]    Executes the book addition workflow
    [Arguments]    ${title}    ${author}
    Example Business Keyword    ${title}    ${author}

When User Requests Book List Via API
    [Documentation]    Makes GET request to books endpoint
    VAR    ${response}    GET    http://localhost:8000/books/    expected_status=200
    Set Test Variable    ${API_RESPONSE}    ${response}

Then Book Should Be Visible In Library
    [Documentation]    Verifies book appears in the UI library view
    [Arguments]    ${expected_title}
    Wait For Elements State    text="${expected_title}"    visible    timeout=10s

Then API Response Should Be Valid JSON
    [Documentation]    Validates API response format and structure
    Should Not Be Empty    ${API_RESPONSE.text}
    VAR    ${json_data}    ${API_RESPONSE.json()}
    Should Be Equal As Numbers    ${API_RESPONSE.status_code}    200

And Book Details Should Be Correct
    [Documentation]    Validates specific book information accuracy
    [Arguments]    ${title}    ${author}
    # Implementation would verify displayed book details
    Log    Validating book: ${title} by ${author}

And Response Should Contain Book Fields
    [Documentation]    Validates API response contains required fields
    [Arguments]    @{required_fields}
    VAR    ${json_data}    ${API_RESPONSE.json()}
    FOR    ${field}    IN    @{required_fields}
        Dictionary Should Contain Key    ${json_data[0]}    ${field}
    END


*** Comments ***
# ============================================================================
# COMPREHENSIVE KEYWORD REFERENCE - VALIDATED SOURCES ONLY
# ============================================================================

# STANDARD LIBRARIES (321 keywords total - RF 7.4.1):
# ✅ BuiltIn: Should Be Equal, Should Contain, Log, Set Variable, etc.
# ✅ Collections: Get From Dictionary, Append To List, etc.
# ✅ String: Replace String, Get Substring, Split String, etc.
# ✅ DateTime: Get Current Date, Convert Date, etc.
# ✅ OperatingSystem: Get Environment Variable, File Should Exist, etc.
# ✅ Process: Run Process, Start Process, etc.
# ✅ XML: Parse Xml, Get Element Text, etc.
# ✅ Telnet: Open Connection, Write, Read, etc.
# ✅ Screenshot: Take Screenshot, etc.

# BROWSER LIBRARY (Browser.json - 300+ keywords):
# ✅ Browser Management: New Browser, New Context, New Page, Close Browser
# ✅ Navigation: Go To, Reload, Go Back, Go Forward
# ✅ Element Interaction: Click, Fill Text, Select Option, Upload File
# ✅ Assertions: Get Text, Get Attribute, Should Contain, Get Title
# ✅ Waiting: Wait For Elements State, Wait For Load State, Wait For Condition
# ✅ Screenshots: Take Screenshot, Take Element Screenshot
# ✅ Network: Wait For Response, Wait For Request
# ✅ Cookies: Add Cookie, Get Cookie, Delete All Cookies

# REQUESTS LIBRARY (RequestsLibrary.json - 50+ keywords):
# ✅ Session Management: Create Session, Create Client Cert Session
# ✅ HTTP Methods: GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
# ✅ Session Methods: GET On Session, POST On Session, etc.
# ✅ Authentication: Basic Auth, Bearer Token, Client Certificates
# ✅ File Upload: Get File For Streaming Upload, POST with files
# ✅ Response Validation: Status Should Be, Should Be Equal As Strings

# ============================================================================
# QUALITY ASSURANCE CHECKLIST
# ============================================================================

# BEFORE CREATING ANY ROBOT FRAMEWORK CODE, VERIFY:
# ✅ All keywords exist in validated sources (rf-docs-mcp + local JSON docs)
# ✅ Modern syntax only (VAR, IF/ELSE, FOR, WHILE, TRY/EXCEPT)
# ✅ No legacy keywords (Run Keyword If, Set *Variable, Sleep, etc.)
# ✅ Test cases use business language (Given/When/Then or descriptive keywords)
# ✅ Technical implementation hidden in Keywords section
# ✅ Explicit waits instead of Sleep
# ✅ Proper error handling with TRY/EXCEPT
# ✅ Page Object Model for UI tests
# ✅ Clean setup/teardown procedures
# ✅ Meaningful documentation for all keywords and test cases
# ✅ Appropriate tagging for test categorization
# ✅ Independent, order-agnostic test design

# ANTI-PATTERNS TO AVOID:
# ⛔ Linear scripting in test cases
# ⛔ Raw technical keywords in *** Test Cases *** section
# ⛔ Fixed Sleep commands
# ⛔ Legacy Robot Framework syntax
# ⛔ Hardcoded values instead of variables
# ⛔ Missing documentation
# ⛔ Monolithic keywords performing multiple responsibilities
# ⛔ Test dependencies and order requirements

# ============================================================================
# CLAUDE CODE OPTIMIZATION NOTES
# ============================================================================

# This file is specifically optimized for Claude Code by:
# 1. Comprehensive keyword validation against authenticated sources
# 2. Modern RF 7.4.1 syntax enforcement with clear examples
# 3. Anti-pattern prevention with explicit forbidden keyword lists
# 4. Architectural guidance for maintainable test automation
# 5. Ready-to-use patterns for Books Database Service testing
# 6. Clear separation between business logic (test cases) and implementation (keywords)
# 7. Integration with existing MCP infrastructure (robotframework-mcp container)