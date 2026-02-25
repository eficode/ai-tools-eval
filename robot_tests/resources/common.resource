*** Settings ***
Documentation     Common resource file containing shared variables and keywords
...               Used across both UI and API test suites

Library           Browser
Library           RequestsLibrary
Library           Collections
Library           String
Library           DateTime


*** Variables ***
# Application URLs
${BASE_URL}              http://books-service:8000
${API_BASE_URL}          http://books-service:8000

# Timeouts
${DEFAULT_TIMEOUT}       10s
${API_TIMEOUT}           5

# Browser Configuration
${BROWSER_TYPE}          chromium
${HEADLESS}              ${TRUE}
${VIEWPORT_WIDTH}        1920
${VIEWPORT_HEIGHT}       1080

# Test Data
${TEST_TITLE_PREFIX}     RF_TEST_BOOK
${TEST_AUTHOR}           Robot Framework Author
${TEST_PAGES}            300
${TEST_YEAR}             2026
${TEST_PUBLISHER}        Test Publisher
${TEST_ISBN}             9781234567890
${TEST_DESCRIPTION}      Test book created by Robot Framework automated test
${TEST_CATEGORY}         Science Fiction


*** Keywords ***
Generate Unique Book Title
    [Documentation]    Generates a unique book title using timestamp
    ...                to avoid conflicts in test execution
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    ${unique_title}=    Set Variable    ${TEST_TITLE_PREFIX}_${timestamp}
    RETURN    ${unique_title}

Generate Test Book Data
    [Documentation]    Creates a complete book data dictionary for testing
    [Arguments]    ${title}=${EMPTY}    ${author}=${TEST_AUTHOR}    ${pages}=${TEST_PAGES}    ${category}=${TEST_CATEGORY}
    VAR    ${book_title}    ${title}
    IF    '${book_title}' == '${EMPTY}'
        ${book_title}=    Generate Unique Book Title
    END
    
    VAR    &{book_data}
    ...    title=${book_title}
    ...    author=${author}
    ...    pages=${pages}
    ...    category=${category}
    
    RETURN    ${book_data}

Log Test Start
    [Documentation]    Logs the start of a test with timestamp
    [Arguments]    ${test_name}
    VAR    ${current_time}    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    Log    Starting test: ${test_name} at ${current_time}    console=True

Log Test End
    [Documentation]    Logs the end of a test with timestamp
    [Arguments]    ${test_name}
    VAR    ${current_time}    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    Log    Completed test: ${test_name} at ${current_time}    console=True

Verify Response Status
    [Documentation]    Validates HTTP response status code
    [Arguments]    ${response}    ${expected_status}=200
    VAR    ${actual_status}    ${response.status_code}
    Should Be Equal As Integers    ${actual_status}    ${expected_status}
    ...    msg=Expected status ${expected_status} but got ${actual_status}

Extract Book ID From Response
    [Documentation]    Extracts book ID from API response
    [Arguments]    ${response}
    ${response_json}=    Set Variable    ${response.json()}
    ${book_id}=    Set Variable    ${response_json['id']}
    Should Be True    ${book_id} > 0    msg=Book ID should be positive integer
    RETURN    ${book_id}
