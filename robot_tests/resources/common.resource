*** Settings ***
Documentation    Common resources for Books application testing
Library          Browser    timeout=10s    retry_assertions_for=3s
Library          RequestsLibrary
Library          String
Library          Collections
Library          DateTime

*** Variables ***
${BASE_URL}           http://localhost:8000
${API_URL}            http://books-service:8000
${BROWSER}            chromium
${HEADLESS}           true

*** Keywords ***
Suite Initialization
    [Documentation]    Initialize test environment
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    Set Suite Variable    ${TIMESTAMP}    ${timestamp}
    Create Session    api    ${API_URL}    verify=true

Suite Cleanup
    [Documentation]    Cleanup test environment
    Delete All Sessions

Test Initialization
    [Documentation]    Setup for each test
    ${unique_id}=    Generate Random String    8    [LETTERS][NUMBERS]
    Set Test Variable    ${UNIQUE_ID}    ${unique_id}
    Set Test Variable    ${BOOK_ID}    ${EMPTY}

Test Cleanup
    [Documentation]    Cleanup after each test
    IF    '${BOOK_ID}' != '${EMPTY}'
        TRY
            DELETE On Session    api    /books/${BOOK_ID}
        EXCEPT
            Log    Cleanup failed for book ${BOOK_ID}    level=WARN
        END
    END
