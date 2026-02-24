*** Settings ***
Documentation    Common resources for UI testing
Library          Browser    timeout=10s    retry_assertions_for=3s
Library          RequestsLibrary
Library          String
Library          Collections
Library          DateTime

*** Variables ***
${BASE_URL}           http://books-service:8000
${API_URL}            http://books-service:8000
${BROWSER}            chromium
${HEADLESS}           true

*** Keywords ***
Suite Initialization For UI
    [Documentation]    Initialize test environment with browser
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    Set Suite Variable    ${TIMESTAMP}    ${timestamp}
    Create Session    api    ${API_URL}    verify=true
    New Browser    ${BROWSER}    headless=${HEADLESS}
    New Context    viewport={'width': 1920, 'height': 1080}

Suite Cleanup For UI
    [Documentation]    Cleanup test environment
    Delete All Sessions
    Close Browser

Test Initialization For UI
    [Documentation]    Setup for each test
    ${unique_id}=    Generate Random String    8    [LETTERS][NUMBERS]
    Set Test Variable    ${UNIQUE_ID}    ${unique_id}
    Set Test Variable    ${BOOK_ID}    ${EMPTY}

Test Cleanup For UI
    [Documentation]    Cleanup after each test
    Run Keyword If Test Failed    Take Screenshot    ${TEST_NAME}_failure
    IF    '${BOOK_ID}' != '${EMPTY}'
        TRY
            DELETE On Session    api    /books/${BOOK_ID}
        EXCEPT
            Log    Cleanup failed for book ${BOOK_ID}    level=WARN
        END
    END
