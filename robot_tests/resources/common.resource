*** Settings ***
Documentation     Common resource file for Books Database testing
...               Contains shared variables, keywords, and configurations
...               following Robot Framework 7.4.1 standards

Library           Browser    auto_closing_level=TEST
Library           RequestsLibrary
Library           Collections
Library           DateTime


*** Variables ***
${BASE_URL}              http://books-service:8000
${API_ENDPOINT}          ${BASE_URL}/books
${DEFAULT_TIMEOUT}       10s
${BROWSER_TYPE}          chromium
${HEADLESS_MODE}         ${TRUE}
${RANDOM_ID}             ${EMPTY}


*** Keywords ***
Generate Unique Test Data
    [Documentation]    Creates unique test data for each test execution
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    ${random_suffix}=    Set Variable    ${timestamp}
    
    &{test_data}=    Create Dictionary    
    ...    title=Test Book ${random_suffix}
    ...    author=Test Author ${random_suffix}
    ...    year=2024
    ...    isbn=978-0-${random_suffix}
    
    RETURN    ${test_data}

Setup Test Environment
    [Documentation]    Initializes test environment for books testing
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    Set Suite Variable    ${RANDOM_ID}    ${timestamp}
    Create Session    books_api    ${BASE_URL}

Teardown Test Environment
    [Documentation]    Cleans up test environment after testing
    TRY
        Close Browser
    EXCEPT
        Log    No browser to close    DEBUG
    END
    Delete All Sessions

Cleanup Test Data
    [Documentation]    Removes test data created during test execution
    [Arguments]    ${book_id}
    
    TRY
        ${response}=    DELETE On Session    books_api    /books/${book_id}    expected_status=200
        Log    Cleaned up book ${book_id}    INFO
    EXCEPT    AS    ${error}
        Log    Cleanup failed for book ${book_id}: ${error}    WARN
    END