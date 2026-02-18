*** Settings ***
Documentation    Common resources for Books Library test automation
...              Contains shared variables, keywords, and configuration
...              for both UI and API test suites.

Library          Browser
Library          RequestsLibrary
Library          Collections
Library          String
Library          DateTime
Library          OperatingSystem

*** Variables ***
# Application URLs
${BASE_URL}           http://books-database-service:8000
${API_BASE_URL}       http://books-database-service:8000
${UI_BASE_URL}        http://books-database-service:8000

# Test Configuration
${TIMEOUT}            10s
${RETRY_INTERVAL}     2s
${MAX_RETRIES}        3
${SCREENSHOT_PATH}    /app/results/screenshots

# Test Data
&{VALID_BOOK_DATA}    title=Test Automation Guide    author=Robot Framework    pages=350    category=Business    favorite=${False}
&{UPDATE_BOOK_DATA}   title=Advanced Test Automation    author=Robot Framework Pro    pages=${450}    category=Science    favorite=${True}

@{REQUIRED_BOOK_FIELDS}    id    title    author    pages    category    favorite

# Book Categories
@{BOOK_CATEGORIES}    Fiction    Non-Fiction    Fantasy    Science Fiction    Mystery    Thriller    Horror    Romance    Historical Fiction    Biography    Self-Help    Business    Science    History    Poetry    Children's Books    Young Adult    Travel    Cookbooks    Philosophy

*** Keywords ***
# Common Setup and Teardown
Setup Test Environment
    [Documentation]    Initialize test environment for both API and UI tests
    VAR    ${timestamp}    Get Current Date    result_format=%Y%m%d_%H%M%S
    Log    Test environment setup started at: ${timestamp}

    # Create screenshot directory if it doesn't exist
    TRY
        Create Directory    ${SCREENSHOT_PATH}
    EXCEPT    *
        Log    Screenshot directory already exists or could not be created    WARN
    END

Cleanup Test Environment
    [Documentation]    Clean up resources after test execution
    VAR    ${timestamp}    Get Current Date    result_format=%Y%m%d_%H%M%S
    Log    Test environment cleanup completed at: ${timestamp}

# Error Handling and Debugging
Execute With Error Handling
    [Documentation]    Execute keyword with comprehensive error handling and debugging
    [Arguments]    ${keyword}    @{args}

    TRY
        Run Keyword    ${keyword}    @{args}
    EXCEPT    *    AS    ${error}
        Log    Error occurred executing ${keyword}: ${error}    ERROR
        Capture Evidence    error_${keyword}
        Log Variables
        Fail    ${keyword} failed: ${error}
    END

Capture Evidence
    [Documentation]    Capture screenshot and logs for debugging
    [Arguments]    ${test_name}

    VAR    ${timestamp}    Get Current Date    result_format=%Y%m%d_%H%M%S
    VAR    ${screenshot_file}    ${test_name}_${timestamp}.png
    VAR    ${full_path}    ${SCREENSHOT_PATH}/${screenshot_file}

    TRY
        Take Screenshot    ${full_path}
        Log    Screenshot saved: ${full_path}
    EXCEPT    *    AS    ${error}
        Log    Failed to capture screenshot: ${error}    WARN
    END

Wait With Retry Logic
    [Documentation]    Execute keyword with retry logic for flaky operations
    [Arguments]    ${keyword}    ${max_retries}=${MAX_RETRIES}    ${retry_interval}=${RETRY_INTERVAL}    @{args}

    VAR    ${attempt}    ${1}

    WHILE    ${attempt} <= ${max_retries}
        TRY
            Run Keyword    ${keyword}    @{args}
            BREAK
        EXCEPT    *    AS    ${error}
            Log    Attempt ${attempt} failed: ${error}    WARN
            IF    ${attempt} == ${max_retries}
                Fail    All ${max_retries} attempts failed. Last error: ${error}
            END
            Sleep    ${retry_interval}
            VAR    ${attempt}    ${attempt + 1}
        END
    END

# Data Generation and Validation
Generate Unique Book Data
    [Documentation]    Generate unique book data for testing
    [Arguments]    ${base_title}=Test Book

    ${timestamp}    Get Current Date    result_format=%Y%m%d_%H%M%S
    VAR    ${unique_title}    ${base_title} ${timestamp}

    &{book_data}    Create Dictionary
    ...    title=${unique_title}
    ...    author=Test Author ${timestamp}
    ...    pages=${350}
    ...    category=Fiction
    ...    favorite=${False}

    # Ensure pages is integer type
    Set To Dictionary    ${book_data}    pages    ${350}

    RETURN    &{book_data}

Validate Book Data Structure
    [Documentation]    Validate that book data contains all required fields
    [Arguments]    ${book_data}    ${expected_fields}=@{REQUIRED_BOOK_FIELDS}

    FOR    ${field}    IN    @{expected_fields}
        Dictionary Should Contain Key    ${book_data}    ${field}
        ...    msg=Required field '${field}' is missing from book data
    END

Generate Random Book Category
    [Documentation]    Select a random category from available book categories
    VAR    ${category_count}    Get Length    ${BOOK_CATEGORIES}
    VAR    ${random_index}    Evaluate    random.randint(0, ${category_count} - 1)    modules=random
    VAR    ${random_category}    Get From List    ${BOOK_CATEGORIES}    ${random_index}
    RETURN    ${random_category}

# Comparison and Assertion Helpers
Should Match Book Data
    [Documentation]    Compare actual book data with expected book data
    [Arguments]    ${actual_book}    ${expected_book}    ${ignore_fields}=@{EMPTY}

    FOR    ${field}    IN    @{REQUIRED_BOOK_FIELDS}
        ${should_check}    Evaluate    "${field}" not in @{ignore_fields}
        IF    ${should_check}
            Should Be Equal    ${actual_book}[${field}]    ${expected_book}[${field}]
            ...    msg=Book field '${field}' does not match. Expected: ${expected_book}[${field}], Actual: ${actual_book}[${field}]
        END
    END

Should Be Valid Book ID
    [Documentation]    Validate that book ID is a positive integer
    [Arguments]    ${book_id}

    Should Be True    isinstance(${book_id}, int)    msg=Book ID must be an integer
    Should Be True    ${book_id} > 0    msg=Book ID must be positive