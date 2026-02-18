*** Settings ***
Library          RequestsLibrary
Library          Collections
Library          String
Library          DateTime

Resource         resources/common.resource

Suite Setup      Setup API Test Environment
Suite Teardown   Cleanup API Test Environment
Test Setup       Setup Individual API Test
Test Teardown    Cleanup Individual API Test

*** Variables ***
${API_SESSION}        books_api
${CREATED_BOOK_ID}    ${EMPTY}

*** Test Cases ***
Minimal Create Test
    [Documentation]    Minimal version of book creation test
    [Tags]    crud    create    positive

    # Step 1: API Session
    ${response}    GET On Session    ${API_SESSION}    /books/    expected_status=200
    Log    API session verified - received ${response.status_code} response

    # Step 2: Generate Data
    &{book_data}    Generate Unique Book Data    Minimal Test Book
    Log    Generated book data: ${book_data}

    # Step 3: Create Book
    ${response}    POST On Session    ${API_SESSION}    /books/    json=&{book_data}    expected_status=200
    Set Test Variable    ${creation_response}    ${response}
    Set Test Variable    ${input_book_data}    &{book_data}

    # Store created book ID for cleanup
    ${created_book}    Set Variable    ${response.json()}
    Set Suite Variable    ${CREATED_BOOK_ID}    ${created_book}[id]

    # Step 4: Verify Creation
    Should Be Equal As Numbers    ${creation_response.status_code}    200
    ${created_book}    Set Variable    ${creation_response.json()}
    Should Be True    ${created_book}[id] > 0
    # Should Be Valid Book ID    ${created_book}[id]

    # Step 5: Verify Data Match
    # ${created_book}    Set Variable    ${creation_response.json()}
    # Should Match Book Data    ${created_book}    ${input_book_data}    ignore_fields=${{['id']}}

*** Keywords ***
# Suite Level Keywords
Setup API Test Environment
    [Documentation]    Initialize API test environment and create session
    Setup Test Environment
    Create Session    ${API_SESSION}    ${API_BASE_URL}    verify=${True}
    Log    API session created for: ${API_BASE_URL}

Cleanup API Test Environment
    [Documentation]    Clean up API test environment and close sessions
    Delete All Sessions
    Cleanup Test Environment
    Log    API test environment cleanup completed

# Test Level Keywords
Setup Individual API Test
    [Documentation]    Setup for individual API test case
    VAR    ${test_start_time}    Get Current Date
    Log    API test started: ${TEST_NAME} at ${test_start_time}

Cleanup Individual API Test
    [Documentation]    Cleanup after individual API test case
    # Clean up any test data created during the test
    IF    "${CREATED_BOOK_ID}" != "${EMPTY}"
        TRY
            DELETE On Session    ${API_SESSION}    /books/${CREATED_BOOK_ID}    expected_status=any
            Log    Cleaned up test book ID: ${CREATED_BOOK_ID}
        EXCEPT    *
            Log    Could not clean up test book ID: ${CREATED_BOOK_ID}    WARN
        END
        VAR    ${CREATED_BOOK_ID}    ${EMPTY}    scope=SUITE
    END

    VAR    ${test_end_time}    Get Current Date
    Log    API test completed: ${TEST_NAME} at ${test_end_time}