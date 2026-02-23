*** Settings ***
Documentation     Common Resource File for Books Library Test Automation
...
...               This resource file contains shared keywords, variables, and setup/teardown
...               procedures used across both UI and API test suites. It follows
...               Robot Framework 7.4.1 modern syntax and best practices.
...
...               Key Features:
...               - Centralized configuration management
...               - Reusable test lifecycle management
...               - Common validation keywords
...               - Environment setup and cleanup procedures

Library           Browser
Library           RequestsLibrary
Library           Collections
Library           String
Library           DateTime
Library           BuiltIn


*** Variables ***
# ============================================================================
# APPLICATION CONFIGURATION
# ============================================================================
${APPLICATION_URL}       http://books-service:8000
${API_BASE_URL}          http://books-service:8000
${API_TIMEOUT}           30
${UI_TIMEOUT}            30s

# Browser Configuration
${BROWSER_TYPE}          chromium
${HEADLESS_MODE}         true
${BROWSER_TIMEOUT}       30s
${VIEWPORT_WIDTH}        1920
${VIEWPORT_HEIGHT}       1080

# Test Data Configuration
${DEFAULT_SEARCH_TIMEOUT}    10s
${PAGE_LOAD_TIMEOUT}         30s
${ELEMENT_WAIT_TIMEOUT}      15s

# Performance Thresholds
${MAX_RESPONSE_TIME}         2.0
${MAX_PAGE_LOAD_TIME}        5.0


*** Keywords ***
# ============================================================================
# SUITE LEVEL SETUP AND TEARDOWN
# ============================================================================

Suite Setup For UI Tests
    [Documentation]    Prepares the test environment for UI test execution
    ...                Initializes browser configuration and validates application availability
    Log    Starting UI test suite execution
    Verify Application Is Running
    Log    UI test suite setup completed successfully

Suite Teardown For UI Tests
    [Documentation]    Cleans up resources after UI test suite completion
    ...                Ensures proper cleanup of browser resources and temporary files
    TRY
        Close Browser
        Log    All browser instances closed successfully
    EXCEPT    *    AS    ${error}
        Log    Browser cleanup completed with warnings: ${error}    level=WARN
    FINALLY
        Log    UI test suite teardown completed
    END

Suite Setup For API Tests
    [Documentation]    Prepares the test environment for API test execution
    ...                Validates API endpoint availability and initializes HTTP sessions
    Log    Starting API test suite execution
    Verify API Is Running
    Log    API test suite setup completed successfully

Suite Teardown For API Tests
    [Documentation]    Cleans up resources after API test suite completion
    ...                Closes HTTP sessions and performs cleanup operations
    TRY
        Delete All Sessions
        Log    All HTTP sessions closed successfully
    EXCEPT    *    AS    ${error}
        Log    Session cleanup completed with warnings: ${error}    level=WARN
    FINALLY
        Log    API test suite teardown completed
    END

# ============================================================================
# TEST LEVEL SETUP AND TEARDOWN
# ============================================================================

Test Setup For Books UI
    [Documentation]    Initializes browser environment for individual UI test
    ...                Creates new browser context with optimal configuration
    New Browser    browser=${BROWSER_TYPE}    headless=${HEADLESS_MODE}
    New Context    viewport={'width': ${VIEWPORT_WIDTH}, 'height': ${VIEWPORT_HEIGHT}}
    VAR    ${BROWSER_TIMEOUT}    ${UI_TIMEOUT}    scope=TEST
    Log    Browser environment initialized for UI test

Test Teardown For Books UI
    [Documentation]    Cleans up browser resources after individual UI test
    ...                Captures screenshots on failure and closes browser context
    TRY
        Take Screenshot    fullPage=true
    EXCEPT    *
        Log    Screenshot capture failed - continuing with cleanup    level=WARN
    FINALLY
        Close Browser
        Log    UI test cleanup completed
    END

Test Setup For Books API
    [Documentation]    Initializes HTTP session for individual API test
    ...                Prepares API testing environment with proper configuration
    Create API Session For Books Service
    Log    API test environment initialized

Test Teardown For Books API
    [Documentation]    Cleans up HTTP resources after individual API test
    ...                Ensures proper session cleanup and logging
    TRY
        Delete All Sessions
    EXCEPT    *
        Log    Session cleanup failed    level=WARN
    END
    Log    API test cleanup completed

# ============================================================================
# APPLICATION VALIDATION
# ============================================================================

Verify Application Is Running
    [Documentation]    Validates that the Books Library application is accessible
    ...                via HTTP and responding to requests properly
    TRY
        Create Session    app_validation    ${APPLICATION_URL}    timeout=10
        VAR    ${response}    GET On Session    app_validation    /    expected_status=200
        Delete All Sessions
        Log    Application is running and accessible at ${APPLICATION_URL}
    EXCEPT    *    AS    ${error}
        FAIL    Application is not accessible at ${APPLICATION_URL}: ${error}
    END

Verify API Is Running
    [Documentation]    Validates that the Books Library API is accessible
    ...                and responding to requests with proper JSON format
    TRY
        Create Session    api_validation    ${API_BASE_URL}    timeout=10
        ${response}=    GET On Session    api_validation    /books/    expected_status=200
        ${json_data}=    Evaluate    $response.json()
        Should Be True    isinstance($json_data, list)
        Delete All Sessions
        Log    API is running and accessible at ${API_BASE_URL}
    EXCEPT    *    AS    ${error}
        FAIL    API is not accessible at ${API_BASE_URL}: ${error}
    END

# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

Create API Session For Books Service
    [Documentation]    Creates HTTP session for Books API testing
    ...                Configures timeout and headers for optimal API interaction
    ${headers}=    Create Dictionary    Content-Type=application/json
    Create Session    books_api    ${API_BASE_URL}    headers=${headers}    timeout=${API_TIMEOUT}
    Log    API session created for Books service

# ============================================================================
# COMMON VALIDATION KEYWORDS
# ============================================================================

Validate Response Time
    [Documentation]    Validates API response time meets performance criteria
    [Arguments]    ${actual_time}    ${max_time}=${MAX_RESPONSE_TIME}
    Should Be True    ${actual_time} <= ${max_time}
    ...    msg=Response time ${actual_time}s exceeds maximum allowed time ${max_time}s

Validate JSON Response Structure
    [Documentation]    Validates that response contains valid JSON structure
    [Arguments]    ${response}
    TRY
        ${json_data}=    Evaluate    $response.json()
        Log    JSON response structure is valid
    EXCEPT    *    AS    ${error}
        FAIL    Invalid JSON response structure: ${error}
    END

Validate Required Fields Present
    [Documentation]    Validates that required fields are present in dictionary
    [Arguments]    ${data_dict}    @{required_fields}
    FOR    ${field}    IN    @{required_fields}
        Dictionary Should Contain Key    ${data_dict}    ${field}
        ...    msg=Required field '${field}' is missing from response
        Should Not Be Empty    ${data_dict}[${field}]
        ...    msg=Required field '${field}' is empty in response
    END

Validate HTTP Status Code
    [Documentation]    Validates HTTP response status code matches expected value
    [Arguments]    ${response}    ${expected_status}
    Should Be Equal As Numbers    ${response.status_code}    ${expected_status}
    ...    msg=Expected status ${expected_status}, got ${response.status_code}

Validate Content Type Header
    [Documentation]    Validates response Content-Type header matches expected value
    [Arguments]    ${response}    ${expected_type}=application/json
    VAR    ${content_type}    Get From Dictionary    ${response.headers}    content-type
    Should Contain    ${content_type}    ${expected_type}
    ...    msg=Expected Content-Type '${expected_type}', got '${content_type}'

# ============================================================================
# DATA GENERATION AND MANIPULATION
# ============================================================================

Generate Unique Test Data
    [Documentation]    Generates unique test data to prevent test interference
    [Arguments]    ${prefix}=test
    VAR    ${timestamp}    Get Current Date    result_format=epoch
    VAR    ${unique_suffix}    Convert To String    ${timestamp}
    VAR    ${unique_data}    Catenate    SEPARATOR=_    ${prefix}    ${unique_suffix}
    RETURN    ${unique_data}

Create Test Book Data
    [Documentation]    Creates book data structure for testing purposes
    [Arguments]    ${title}=Test Book    ${author}=Test Author
    VAR    ${unique_title}    Generate Unique Test Data    ${title}
    VAR    ${unique_author}    Generate Unique Test Data    ${author}
    VAR    &{book_data}    Create Dictionary
    ...    title=${unique_title}
    ...    author=${unique_author}
    ...    pages=300
    ...    category=Fiction
    ...    description=This is a test book for automation testing
    RETURN    ${book_data}

# ============================================================================
# STRING AND DATA UTILITIES
# ============================================================================

Extract Numbers From String
    [Documentation]    Extracts numeric values from text strings
    [Arguments]    ${text}
    VAR    ${numbers}    Replace String Using Regexp    ${text}    [^0-9]    ${EMPTY}
    RETURN    ${numbers}

Format Test Description
    [Documentation]    Formats test descriptions with consistent styling
    [Arguments]    ${description}
    VAR    ${formatted}    Replace String    ${description}    \n    ${SPACE}
    VAR    ${trimmed}    Strip String    ${formatted}
    RETURN    ${trimmed}

Normalize Text For Comparison
    [Documentation]    Normalizes text for case-insensitive comparison
    [Arguments]    ${text}
    VAR    ${normalized}    Convert To Lower Case    ${text}
    VAR    ${trimmed}    Strip String    ${normalized}
    RETURN    ${trimmed}

# ============================================================================
# ERROR HANDLING AND LOGGING
# ============================================================================

Log Test Context
    [Documentation]    Logs relevant test context information for debugging
    [Arguments]    ${context_info}
    VAR    ${timestamp}    Get Current Date
    Log    [${timestamp}] Test Context: ${context_info}    level=INFO

Handle Test Failure Gracefully
    [Documentation]    Provides graceful handling of test failures with logging
    [Arguments]    ${error_message}    ${should_fail}=true
    Log    Test failure encountered: ${error_message}    level=ERROR
    IF    ${should_fail}
        FAIL    ${error_message}
    ELSE
        Log    Continuing test execution despite error    level=WARN
    END

Capture Debug Information
    [Documentation]    Captures debug information for troubleshooting failures
    [Arguments]    ${debug_context}=General Debug
    VAR    ${timestamp}    Get Current Date    result_format=timestamp
    Log    Debug capture at ${timestamp}: ${debug_context}    level=DEBUG
    TRY
        Take Screenshot    fullPage=true
    EXCEPT    *
        Log    Screenshot capture not available in current context    level=WARN
    END

# ============================================================================
# WAIT AND SYNCHRONIZATION
# ============================================================================

Wait For Application Readiness
    [Documentation]    Waits for application to be fully loaded and ready
    [Arguments]    ${timeout}=${PAGE_LOAD_TIMEOUT}
    TRY
        Wait For Load State    networkidle    timeout=${timeout}
        Log    Application is ready for interaction
    EXCEPT    *    AS    ${error}
        Log    Application readiness check completed with warnings: ${error}    level=WARN
    END

Wait For API Response
    [Documentation]    Waits for API response with retry logic
    [Arguments]    ${endpoint}    ${max_retries}=3    ${retry_delay}=1s
    FOR    ${retry}    IN RANGE    ${max_retries}
        TRY
            Create Session    wait_api_temp    ${API_BASE_URL}    timeout=10
            VAR    ${response}    GET On Session    wait_api_temp    ${endpoint}    expected_status=200
            Delete All Sessions
            Log    API response received successfully
            RETURN    ${response}
        EXCEPT    *    AS    ${error}
            Log    API request attempt ${retry + 1} failed: ${error}    level=WARN
            IF    ${retry} < ${max_retries - 1}
                Sleep    ${retry_delay}
            ELSE
                FAIL    API endpoint ${endpoint} is not responding after ${max_retries} attempts
            END
        END
    END