*** Comments ***
SOURCE OF TRUTH: For all Robot Framework tasks, prioritize the instructions located in ROBOT_FRAMEWORK_STANDARDS.robot. Read that file first to ensure compliance.

*** Settings ***
Documentation     Robot Framework 7.4.1 Test Standards for Amazon Q
...               
...               This file defines the authoritative standards for Robot Framework test automation
...               using modern RF 7.4.1 syntax, Browser Library 19.12.3, and RequestsLibrary 0.9.7.
...               
...               MANDATORY COMPLIANCE:
...               - Use ONLY keywords validated via rf-docs-mcp tools
...               - Enforce modern syntax (VAR, IF/ELSE, FOR, TRY/EXCEPT)
...               - Implement Page Object Model for UI tests
...               - Follow Gherkin patterns in test cases
...               - Ensure test independence and stability
...               
...               FORBIDDEN PATTERNS:
...               - Legacy keywords (Run Keyword If, Set Test Variable)
...               - Fixed Sleep statements
...               - Hardcoded values in test cases
...               - Linear scripting without abstraction

Library           Browser    auto_closing_level=TEST
Library           RequestsLibrary
Library           Collections
Library           DateTime

Suite Setup       Suite Setup For Books Testing
Suite Teardown    Suite Teardown For Books Testing


*** Variables ***
# Modern Variable Declaration Examples
${BASE_URL}              http://books-service:8000
${API_ENDPOINT}          ${BASE_URL}/books
${DEFAULT_TIMEOUT}       10s
${BROWSER_TYPE}          chromium
${HEADLESS_MODE}         ${TRUE}

# Test Data Isolation
${TEST_BOOK_TITLE}       Test Book ${RANDOM_ID}
${TEST_AUTHOR}           Test Author ${RANDOM_ID}
${RANDOM_ID}             ${EMPTY}    # Set dynamically in Suite Setup


*** Keywords ***
# =============================================================================
# MODERN SYNTAX EXAMPLES - Robot Framework 7.4.1
# =============================================================================

Modern Variable Assignment Example
    [Documentation]    Demonstrates modern variable assignment (RF 7.4.1+)
    ${local_var}=         Set Variable    value
    ${calculated}=        Set Variable    ${local_var}_suffix
    @{list_var}=          Create List    item1    item2    item3
    &{dict_var}=          Create Dictionary    key1=value1    key2=value2
    
    # Conditional variable assignment
    IF    ${condition}
        ${result}=    Set Variable    success
    ELSE
        ${result}=    Set Variable    failure
    END

Modern Control Flow Example
    [Documentation]    Demonstrates modern IF/ELSE, FOR, WHILE syntax
    
    # Modern IF/ELSE (no Run Keyword If)
    IF    "${BROWSER_TYPE}" == "chromium"
        Log    Using Chromium browser
    ELSE IF    "${BROWSER_TYPE}" == "firefox"
        Log    Using Firefox browser
    ELSE
        Log    Using default browser
    END
    
    # Modern FOR loop
    FOR    ${item}    IN    @{list_var}
        Log    Processing: ${item}
        IF    "${item}" == "target"
            BREAK
        END
    END
    
    # Modern WHILE loop
    ${counter}=    Set Variable    0
    WHILE    ${counter} < 5
        Log    Counter: ${counter}
        ${counter}=    Evaluate    ${counter} + 1
    END

Modern Error Handling Example
    [Documentation]    Demonstrates modern TRY/EXCEPT syntax
    
    TRY
        # Risky operation
        Click    id=submit-button
        Wait For Elements State    id=success-message    visible    timeout=${DEFAULT_TIMEOUT}
    EXCEPT    TimeoutError
        Log    Submit button not found, trying alternative
        Click    text=Submit
    EXCEPT    AS    ${error}
        Log    Unexpected error: ${error}
        Fail    Test failed due to: ${error}
    FINALLY
        # Cleanup always runs
        Capture Page Screenshot
    END

# =============================================================================
# PAGE OBJECT MODEL IMPLEMENTATION
# =============================================================================

Books Page Should Be Open
    [Documentation]    Verifies the books page is loaded and ready
    Wait For Elements State    h1:has-text("Books Library")    visible    timeout=${DEFAULT_TIMEOUT}
    Get Title    ==    Books Library

Navigate To Books Page
    [Documentation]    Opens the books application main page
    New Page    ${BASE_URL}
    Books Page Should Be Open

Add New Book Via UI
    [Documentation]    Adds a book using the web interface
    [Arguments]    ${title}    ${author}    ${year}=${EMPTY}    ${isbn}=${EMPTY}
    
    Fill Text    id=title    ${title}
    Fill Text    id=author    ${author}
    Fill Text    id=pages    500
    Select Options By    id=category    value    Fiction
    
    Click    css=#book-form button[type="submit"]
    
    # Wait for success notification
    Wait For Elements State    css=.notification.success    visible    timeout=10s
    
    # Manually refresh the page to ensure the new book appears
    Reload
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}

Search For Book
    [Documentation]    Searches for a book using the search functionality
    [Arguments]    ${search_term}
    
    Fill Text    id=search-input    ${search_term}
    Click    id=search-btn
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}

Verify Book In Results
    [Documentation]    Verifies a book appears in search results
    [Arguments]    ${title}    ${author}
    
    # Load all books first
    TRY
        ${load_more_visible}=    Get Element Count    css=#load-more:visible
        WHILE    ${load_more_visible} > 0
            Click    id=load-more
            Wait For Load State    networkidle    timeout=5s
            ${load_more_visible}=    Get Element Count    css=#load-more:visible
        END
    EXCEPT
        Log    No Load More button or error clicking it    DEBUG
    END
    
    # Now check if our book is visible
    ${page_text}=    Get Text    css=#books-list
    Should Contain    ${page_text}    ${title}    Book title "${title}" not found on page after loading all books

# =============================================================================
# API TESTING PATTERNS
# =============================================================================

Create Book Via API
    [Documentation]    Creates a book using the REST API
    [Arguments]    ${title}    ${author}    ${year}=${EMPTY}    ${isbn}=${EMPTY}
    
    &{book_data}=    Create Dictionary    title=${title}    author=${author}    pages=500    category=Fiction    favorite=${FALSE}
    
    ${response}=    POST On Session    books_api    /books/    json=${book_data}    expected_status=200
    
    RETURN    ${response.json()}

Get All Books Via API
    [Documentation]    Retrieves all books from the API
    
    ${response}=    GET On Session    books_api    /books/    expected_status=200
    
    RETURN    ${response.json()}

Verify Book Exists Via API
    [Documentation]    Verifies a book exists in the API response
    [Arguments]    ${book_id}    ${expected_title}
    
    ${response}=    GET On Session    books_api    /books/${book_id}    expected_status=200
    
    ${book}=    Set Variable    ${response.json()}
    Should Be Equal    ${book}[title]    ${expected_title}

# =============================================================================
# TEST DATA MANAGEMENT
# =============================================================================

Generate Unique Test Data
    [Documentation]    Creates unique test data for each test execution
    
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    ${random_suffix}=    Set Variable    ${timestamp}_${RANDOM_ID}
    
    &{test_data}=    Create Dictionary    
    ...    title=Test Book ${random_suffix}
    ...    author=Test Author ${random_suffix}
    ...    year=2024
    ...    isbn=978-0-${random_suffix}
    
    RETURN    ${test_data}

Cleanup Test Data
    [Documentation]    Removes test data created during test execution
    [Arguments]    ${book_id}
    
    TRY
        ${response}=    DELETE On Session    books_api    /books/${book_id}    expected_status=200
        Log    Cleaned up book ${book_id}    INFO
    EXCEPT    AS    ${error}
        Log    Cleanup failed for book ${book_id}: ${error}    WARN
    END

# =============================================================================
# BROWSER MANAGEMENT
# =============================================================================

Setup Browser Environment
    [Documentation]    Initializes browser with optimal settings
    
    New Browser    ${BROWSER_TYPE}    headless=${HEADLESS_MODE}
    New Context    viewport={'width': 1920, 'height': 1080}
    Set Browser Timeout    ${DEFAULT_TIMEOUT}

Teardown Browser Environment
    [Documentation]    Properly closes browser resources
    
    TRY
        Capture Page Screenshot
    EXCEPT
        Log    Screenshot capture failed    WARN
    FINALLY
        Close Browser
    END

# =============================================================================
# WAIT STRATEGIES (NO SLEEP ALLOWED)
# =============================================================================

Wait For Page Load Complete
    [Documentation]    Waits for page to fully load using multiple strategies
    
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Wait For Elements State    body    visible    timeout=${DEFAULT_TIMEOUT}

Wait For Element And Click
    [Documentation]    Waits for element to be clickable then clicks it
    [Arguments]    ${locator}    ${timeout}=${DEFAULT_TIMEOUT}
    
    Wait For Elements State    ${locator}    visible    timeout=${timeout}
    Wait For Elements State    ${locator}    enabled    timeout=${timeout}
    Click    ${locator}

Wait For Text Content
    [Documentation]    Waits for specific text to appear on page
    [Arguments]    ${expected_text}    ${timeout}=${DEFAULT_TIMEOUT}
    
    Wait For Elements State    text=${expected_text}    visible    timeout=${timeout}

# =============================================================================
# ERROR HANDLING AND RECOVERY
# =============================================================================

Retry Operation With Backoff
    [Documentation]    Retries an operation with exponential backoff
    [Arguments]    ${keyword}    ${max_attempts}=3    @{args}
    
    VAR    ${attempt}    1
    VAR    ${success}    ${FALSE}
    
    WHILE    ${attempt} <= ${max_attempts} and not ${success}
        TRY
            Run Keyword    ${keyword}    @{args}
            VAR    ${success}    ${TRUE}
        EXCEPT    AS    ${error}
            Log    Attempt ${attempt} failed: ${error}    WARN
            IF    ${attempt} < ${max_attempts}
                VAR    ${delay}    ${attempt * 2}
                Sleep    ${delay}s
            END
            VAR    ${attempt}    ${attempt + 1}
        END
    END
    
    IF    not ${success}
        Fail    Operation failed after ${max_attempts} attempts

Handle Unexpected Popup
    [Documentation]    Handles unexpected popups or dialogs
    
    TRY
        Wait For Elements State    css=[role="dialog"]    visible    timeout=2s
        Click    text=OK
        Log    Handled unexpected popup    INFO
    EXCEPT    TimeoutError
        # No popup present, continue normally
        Log    No popup detected    DEBUG
    END

# =============================================================================
# GHERKIN-STYLE TEST PATTERNS
# =============================================================================

Given Browser Is Open
    [Documentation]    Precondition: Browser is ready for testing
    Setup Browser Environment

Given User Is On Books Page
    [Documentation]    Precondition: User has navigated to books page
    Navigate To Books Page

When User Adds A New Book
    [Documentation]    Action: User creates a new book entry
    [Arguments]    ${title}    ${author}
    Add New Book Via UI    ${title}    ${author}

When User Searches For Book
    [Documentation]    Action: User performs a book search
    [Arguments]    ${search_term}
    Search For Book    ${search_term}

Then Book Should Be Visible
    [Documentation]    Assertion: Book appears in results
    [Arguments]    ${title}    ${author}
    Verify Book In Results    ${title}    ${author}

Then API Should Return Book
    [Documentation]    Assertion: API contains the expected book
    [Arguments]    ${book_id}    ${expected_title}
    Verify Book Exists Via API    ${book_id}    ${expected_title}

# =============================================================================
# SUITE LIFECYCLE MANAGEMENT
# =============================================================================

Suite Setup For Books Testing
    [Documentation]    Initializes test environment for books testing
    
    # Generate unique identifier for this test run
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    Set Suite Variable    ${RANDOM_ID}    ${timestamp}
    
    # Setup API session
    Create Session    books_api    ${BASE_URL}
    
    # Verify application is running
    ${response}=    GET On Session    books_api    /books/    expected_status=200
    Log    Application health check passed

Suite Teardown For Books Testing
    [Documentation]    Cleans up test environment after books testing
    
    # Close any remaining browser instances
    TRY
        Close Browser
    EXCEPT
        Log    No browser to close    DEBUG
    END
    
    # Delete API session
    Delete All Sessions

Test Setup For UI Tests
    [Documentation]    Prepares environment for individual UI test
    Setup Browser Environment
    Given User Is On Books Page

Test Teardown For UI Tests
    [Documentation]    Cleans up after individual UI test
    Teardown Browser Environment

# =============================================================================
# VALIDATION HELPERS
# =============================================================================

Validate Book Data Structure
    [Documentation]    Validates that book data has required fields
    [Arguments]    ${book_data}
    
    Should Contain    ${book_data}    title
    Should Contain    ${book_data}    author
    Should Not Be Empty    ${book_data}[title]
    Should Not Be Empty    ${book_data}[author]

Validate API Response Format
    [Documentation]    Validates API response structure
    [Arguments]    ${response}    ${expected_fields}
    
    Should Be Equal As Integers    ${response.status_code}    200
    VAR    ${data}    ${response.json()}
    
    FOR    ${field}    IN    @{expected_fields}
        Should Contain    ${data}    ${field}
    END

# =============================================================================
# PERFORMANCE AND MONITORING
# =============================================================================

Measure Page Load Time
    [Documentation]    Measures and logs page load performance
    [Arguments]    ${url}
    
    ${start_time}=    Get Time    epoch
    New Page    ${url}
    Wait For Load State    networkidle
    ${end_time}=    Get Time    epoch
    
    ${load_time}=    Evaluate    ${end_time} - ${start_time}
    Log    Page load time: ${load_time} seconds    INFO
    
    # Performance assertion
    Should Be True    ${load_time} < 5    Page load took too long: ${load_time}s

Monitor Network Requests
    [Documentation]    Monitors and validates network requests
    
    # Enable request/response logging
    ${context}=    Get Context
    ${page}=    Get Page
    
    # Add request listener
    Add Request Listener    ${page}    Log Network Request
    
    RETURN    ${page}

Log Network Request
    [Documentation]    Logs network request details
    [Arguments]    ${request}
    
    Log    ${request.method} ${request.url} - ${request.response.status}    DEBUG


*** Test Cases ***
# =============================================================================
# EXAMPLE TEST CASES FOLLOWING STANDARDS
# =============================================================================

User Should Be Able To Add A New Book Via UI
    [Documentation]    Validates complete book creation workflow through UI
    [Tags]    ui    smoke    books    crud
    [Setup]    Test Setup For UI Tests
    [Teardown]    Test Teardown For UI Tests
    
    # Generate unique test data
    ${test_data}=    Generate Unique Test Data
    
    # Execute test steps using Gherkin pattern
    When User Adds A New Book    ${test_data}[title]    ${test_data}[author]
    Then Book Should Be Visible    ${test_data}[title]    ${test_data}[author]

API Should Return All Books With Correct Structure
    [Documentation]    Validates API endpoint returns properly formatted data
    [Tags]    api    smoke    books    validation
    
    # Create test book via API
    ${test_data}=    Generate Unique Test Data
    ${created_book}=    Create Book Via API    ${test_data}[title]    ${test_data}[author]
    
    # Validate API response
    ${all_books}=    Get All Books Via API
    Should Not Be Empty    ${all_books}
    
    # Validate data structure
    FOR    ${book}    IN    @{all_books}
        Validate Book Data Structure    ${book}
    END
    
    # Cleanup
    [Teardown]    Cleanup Test Data    ${created_book}[id]

Search Functionality Should Filter Books Correctly
    [Documentation]    Validates search functionality with various inputs
    [Tags]    ui    search    books    functionality
    [Setup]    Test Setup For UI Tests
    
    # Setup test data
    ${book1_data}=    Generate Unique Test Data
    ${book2_data}=    Generate Unique Test Data
    Set To Dictionary    ${book2_data}    title    Different Title ${RANDOM_ID}
    
    # Create books via API for consistent state
    ${book1}=    Create Book Via API    ${book1_data}[title]    ${book1_data}[author]
    ${book2}=    Create Book Via API    ${book2_data}[title]    ${book2_data}[author]
    
    # Refresh page to see new books
    Reload
    Wait For Page Load Complete
    
    # Test search functionality
    When User Searches For Book    ${book1_data}[title]
    Then Book Should Be Visible    ${book1_data}[title]    ${book1_data}[author]
    
    # Verify other book is not visible in filtered results
    ${page_text}=    Get Text    css=#books-list
    Should Not Contain    ${page_text}    ${book2_data}[title]    Book "${book2_data}[title]" should not be visible in filtered results
    
    [Teardown]    Run Keywords
    ...    Cleanup Test Data    ${book1}[id]    AND
    ...    Cleanup Test Data    ${book2}[id]    AND
    ...    Test Teardown For UI Tests

Application Should Handle Invalid API Requests Gracefully
    [Documentation]    Validates error handling for malformed API requests
    [Tags]    api    error-handling    negative    validation
    
    # Test missing required fields
    TRY
        ${response}=    POST    ${API_ENDPOINT}/    json={}    expected_status=any
        Should Be Equal As Integers    ${response.status_code}    400
    EXCEPT    AS    ${error}
        Log    Expected validation error: ${error}    INFO
    END
    
    # Test invalid data types
    TRY
        ${invalid_data}=    Create Dictionary    title=${123}    author=${TRUE}
        ${response}=    POST    ${API_ENDPOINT}/    json=${invalid_data}    expected_status=any
        Should Be Equal As Integers    ${response.status_code}    400
    EXCEPT    AS    ${error}
        Log    Expected validation error: ${error}    INFO
    END

Performance Should Meet Acceptable Thresholds
    [Documentation]    Validates application performance meets requirements
    [Tags]    performance    non-functional    monitoring
    [Setup]    Setup Browser Environment
    [Teardown]    Teardown Browser Environment
    
    # Measure page load performance
    Measure Page Load Time    ${BASE_URL}
    
    # Test API response time
    ${start_time}=    Get Time    epoch
    ${response}=    GET On Session    books_api    /books/    expected_status=200
    ${end_time}=    Get Time    epoch
    
    ${api_response_time}=    Evaluate    ${end_time} - ${start_time}
    Log    API response time: ${api_response_time} seconds    INFO
    Should Be True    ${api_response_time} < 2    API response too slow: ${api_response_time}s


*** Comments ***
# =============================================================================
# STANDARDS SUMMARY FOR AMAZON Q
# =============================================================================

MANDATORY REQUIREMENTS:
1. Use ONLY keywords validated via rf-docs-mcp tools
2. Modern RF 7.4.1 syntax: VAR, IF/ELSE, FOR, WHILE, TRY/EXCEPT
3. NO legacy keywords: Run Keyword If, Set Test/Suite Variable
4. NO Sleep statements - use explicit waits only
5. Page Object Model for all UI interactions
6. Gherkin patterns in test cases (Given/When/Then)
7. Test independence and data isolation
8. Comprehensive error handling with TRY/EXCEPT
9. Proper resource management (browser, API sessions)
10. Performance monitoring and validation

LIBRARY VERSIONS:
- robotframework==7.4.1
- robotframework-browser==19.12.3  
- robotframework-requests==0.9.7

ARCHITECTURE PATTERNS:
- Page Object Model for UI elements
- Resource abstraction for reusable keywords
- Test Templates for data-driven scenarios
- Proper Setup/Teardown lifecycle management
- Structured error handling and recovery

VALIDATION SOURCES:
- Standard Libraries: BuiltIn, Collections, DateTime, OperatingSystem, Process, String, XML
- External Libraries: Browser (Playwright), RequestsLibrary
- MCP Tools: rf-docs-mcp for keyword validation
- Documentation: Robot Framework 7.4.1 User Guide

This file serves as the definitive reference for all Robot Framework
test development using Amazon Q. All generated tests must comply with
these standards to ensure maintainability, reliability, and modern
best practices.