*** Settings ***
Documentation    Books Library API Test Suite
...
...              This suite tests all CRUD operations for the Books Library REST API.
...              Covers book creation, retrieval, update, deletion, and favorite management.
...              Uses Gherkin syntax for clear business-focused test scenarios.
...
...              API Base URL: ${API_BASE_URL}
...              Test Database: Read-only approach - minimal modifications

Library          RequestsLibrary
Library          Collections
Library          String
Library          DateTime

Resource         resources/common.resource

Suite Setup      Setup API Test Environment
Suite Teardown   Cleanup API Test Environment
Test Setup       Setup Individual API Test
Test Teardown    Cleanup Individual API Test

Force Tags       api    books    regression

*** Variables ***
${API_SESSION}        books_api
${CREATED_BOOK_ID}    ${EMPTY}

*** Test Cases ***
User Can Retrieve All Books From API
    [Documentation]    Verify that the API returns a list of all books in the system
    [Tags]    smoke    get    positive
    Given API Session Is Established
    When All Books Are Requested
    Then Books List Should Be Returned
    And Response Should Have Valid Structure

User Can Create New Book Via API
    [Documentation]    Verify that a new book can be created through the API with valid data
    [Tags]    crud    create    positive
    Given API Session Is Established
    When New Book Is Created With Valid Data
    Then Book Should Be Created Successfully
    And Created Book Should Match Input Data

User Can Retrieve Specific Book By ID
    [Documentation]    Verify that a specific book can be retrieved using its ID
    [Tags]    crud    read    positive
    Given Book Exists In System
    When Book Is Retrieved By ID
    Then Book Data Should Be Returned
    And All Required Fields Should Be Present

User Can Update Existing Book Data
    [Documentation]    Verify that existing book data can be modified via PUT request
    [Tags]    crud    update    positive
    Given Book Exists In System
    When Book Data Is Updated With Valid Changes
    Then Update Should Be Successful
    And Updated Data Should Be Reflected In Response

User Can Toggle Book Favorite Status
    [Documentation]    Verify that book favorite status can be toggled via PATCH request
    [Tags]    favorite    patch    positive
    Given Book Exists In System
    When Book Favorite Status Is Toggled
    Then Favorite Status Should Be Updated
    And Book Should Reflect New Favorite Status

User Can Delete Existing Book
    [Documentation]    Verify that an existing book can be removed from the system
    [Tags]    crud    delete    positive
    Given Book Exists In System
    When Book Is Deleted
    Then Deletion Should Be Successful
    And Book Should No Longer Exist

API Handles Invalid Book ID Gracefully
    [Documentation]    Verify that API returns 404 for non-existent book ID
    [Tags]    negative    error-handling    404
    Given API Session Is Established
    When Non-Existent Book Is Requested
    Then Not Found Error Should Be Returned
    And Error Message Should Be Descriptive

API Validates Required Fields For Book Creation
    [Documentation]    Verify that API validates required fields when creating books
    [Tags]    validation    negative    400
    Given API Session Is Established
    When Book Is Created With Missing Required Fields
    Then Validation Error Should Be Returned
    And Error Should Indicate Missing Fields

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

# Given Keywords (Preconditions)
Given API Session Is Established
    [Documentation]    Verify that API session is working
    ${response}    GET On Session    ${API_SESSION}    /books/    expected_status=200
    Log    API session verified - received ${response.status_code} response

Given Book Exists In System
    [Documentation]    Ensure a test book exists in the system for testing
    When New Book Is Created With Valid Data
    Set Suite Variable    ${EXISTING_BOOK_ID}    ${CREATED_BOOK_ID}

# When Keywords (Actions)
When All Books Are Requested
    [Documentation]    Request list of all books from API
    ${response}    GET On Session    ${API_SESSION}    /books/    expected_status=200
    Set Test Variable    ${books_response}    ${response}

When New Book Is Created With Valid Data
    [Documentation]    Create a new book with valid test data
    &{book_data}    Generate Unique Book Data    API Test Book
    ${response}    POST On Session    ${API_SESSION}    /books/    json=&{book_data}    expected_status=200
    Set Test Variable    ${creation_response}    ${response}
    Set Test Variable    ${input_book_data}    &{book_data}

    # Store created book ID for cleanup
    ${created_book}    Set Variable    ${response.json()}
    Set Suite Variable    ${CREATED_BOOK_ID}    ${created_book}[id]

When Book Is Retrieved By ID
    [Documentation]    Retrieve a specific book using its ID
    ${response}    GET On Session    ${API_SESSION}    /books/${EXISTING_BOOK_ID}    expected_status=200
    Set Test Variable    ${book_response}    ${response}

When Book Data Is Updated With Valid Changes
    [Documentation]    Update book data with valid modifications
    &{update_data}    Copy Dictionary    ${UPDATE_BOOK_DATA}
    ${response}    PUT On Session    ${API_SESSION}    /books/${EXISTING_BOOK_ID}    json=&{update_data}    expected_status=200
    Set Test Variable    ${update_response}    ${response}
    Set Test Variable    ${update_input_data}    &{update_data}

When Book Favorite Status Is Toggled
    [Documentation]    Toggle the favorite status of a book
    &{favorite_data}    Create Dictionary    favorite=${True}
    ${response}    PATCH On Session    ${API_SESSION}    /books/${EXISTING_BOOK_ID}/favorite    json=&{favorite_data}    expected_status=200
    Set Test Variable    ${favorite_response}    ${response}
    Set Test Variable    ${expected_favorite_status}    ${True}

When Book Is Deleted
    [Documentation]    Delete a book from the system
    ${response}    DELETE On Session    ${API_SESSION}    /books/${EXISTING_BOOK_ID}    expected_status=200
    Set Test Variable    ${deletion_response}    ${response}

When Non-Existent Book Is Requested
    [Documentation]    Request a book with non-existent ID
    VAR    ${non_existent_id}    ${99999}
    ${response}    GET On Session    ${API_SESSION}    /books/${non_existent_id}    expected_status=404
    Set Test Variable    ${error_response}    ${response}

When Book Is Created With Missing Required Fields
    [Documentation]    Attempt to create book with incomplete data
    &{incomplete_data}    Create Dictionary    title=Incomplete Book
    # Missing: author, pages (required fields)
    ${response}    POST On Session    ${API_SESSION}    /books/    json=&{incomplete_data}    expected_status=422
    Set Test Variable    ${validation_response}    ${response}

# Then Keywords (Assertions)
Then Books List Should Be Returned
    [Documentation]    Verify that books list is returned properly
    Should Be Equal As Numbers    ${books_response.status_code}    200
    ${books_data}    Set Variable    ${books_response.json()}
    Should Be True    isinstance($books_data, list)    msg=Response should be a list of books

Then Response Should Have Valid Structure
    [Documentation]    Verify response structure is correct
    ${books_data}    Set Variable    ${books_response.json()}

    FOR    ${book}    IN    @{books_data}
        Validate Book Data Structure    ${book}
    END

Response Should Have Valid Structure
    [Documentation]    Verify response structure is correct
    ${books_data}    Set Variable    ${books_response.json()}

    FOR    ${book}    IN    @{books_data}
        Validate Book Data Structure    ${book}
    END

Then Book Should Be Created Successfully
    [Documentation]    Verify book creation was successful
    Should Be Equal As Numbers    ${creation_response.status_code}    200
    ${created_book}    Set Variable    ${creation_response.json()}
    Should Be True    ${created_book}[id] > 0
    Should Be Valid Book ID    ${created_book}[id]

Then Created Book Should Match Input Data
    [Documentation]    Verify created book matches input data
    ${created_book}    Set Variable    ${creation_response.json()}
    Should Match Book Data    ${created_book}    ${input_book_data}    ignore_fields=${{['id']}}

Then Book Data Should Be Returned
    [Documentation]    Verify that book data is returned correctly
    Should Be Equal As Numbers    ${book_response.status_code}    200
    ${book_data}    Set Variable    ${book_response.json()}
    Should Not Be Empty    ${book_data}

Then All Required Fields Should Be Present
    [Documentation]    Verify all required fields are present in response
    ${book_data}    Set Variable    ${book_response.json()}
    Validate Book Data Structure    ${book_data}

Then Update Should Be Successful
    [Documentation]    Verify book update was successful
    Should Be Equal As Numbers    ${update_response.status_code}    200

Then Updated Data Should Be Reflected In Response
    [Documentation]    Verify updated data is reflected in the response
    ${updated_book}    Set Variable    ${update_response.json()}
    Should Match Book Data    ${updated_book}    ${update_input_data}    ignore_fields=${{['id']}}

Then Favorite Status Should Be Updated
    [Documentation]    Verify favorite status was updated successfully
    Should Be Equal As Numbers    ${favorite_response.status_code}    200

Then Book Should Reflect New Favorite Status
    [Documentation]    Verify book reflects the new favorite status
    ${updated_book}    Set Variable    ${favorite_response.json()}
    Should Be Equal    ${updated_book}[favorite]    ${expected_favorite_status}

Then Deletion Should Be Successful
    [Documentation]    Verify book deletion was successful
    Should Be Equal As Numbers    ${deletion_response.status_code}    200
    ${deletion_message}    Set Variable    ${deletion_response.json()}
    Dictionary Should Contain Key    ${deletion_message}    message

Then Book Should No Longer Exist
    [Documentation]    Verify deleted book no longer exists
    ${response}    GET On Session    ${API_SESSION}    /books/${EXISTING_BOOK_ID}    expected_status=404

Then Not Found Error Should Be Returned
    [Documentation]    Verify 404 error is returned for non-existent resource
    Should Be Equal As Numbers    ${error_response.status_code}    404

Then Error Message Should Be Descriptive
    [Documentation]    Verify error message is descriptive
    ${error_data}    Set Variable    ${error_response.json()}
    Dictionary Should Contain Key    ${error_data}    detail
    Should Not Be Empty    ${error_data}[detail]

Then Validation Error Should Be Returned
    [Documentation]    Verify validation error is returned for invalid data
    Should Be Equal As Numbers    ${validation_response.status_code}    422

Then Error Should Indicate Missing Fields
    [Documentation]    Verify error indicates which fields are missing
    ${error_data}    Set Variable    ${validation_response.json()}
    Dictionary Should Contain Key    ${error_data}    detail
    Should Be True    isinstance(${error_data}[detail], list)    msg=Validation errors should be a list

# Additional keywords for "And" usage (Robot Framework strips Gherkin prefixes)
Created Book Should Match Input Data
    [Documentation]    Verify created book matches input data
    ${created_book}    Set Variable    ${creation_response.json()}
    Should Match Book Data    ${created_book}    ${input_book_data}    ignore_fields=${{['id']}}

All Required Fields Should Be Present
    [Documentation]    Verify all required fields are present in response
    ${book_data}    Set Variable    ${book_response.json()}
    Validate Book Data Structure    ${book_data}

Updated Data Should Be Reflected In Response
    [Documentation]    Verify updated data is reflected in the response
    ${updated_book}    Set Variable    ${update_response.json()}
    Should Match Book Data    ${updated_book}    ${update_input_data}    ignore_fields=${{['id']}}

Book Should Reflect New Favorite Status
    [Documentation]    Verify book reflects the new favorite status
    ${updated_book}    Set Variable    ${favorite_response.json()}
    Should Be Equal    ${updated_book}[favorite]    ${expected_favorite_status}

Book Should No Longer Exist
    [Documentation]    Verify deleted book no longer exists
    ${response}    GET On Session    ${API_SESSION}    /books/${EXISTING_BOOK_ID}    expected_status=404

Error Message Should Be Descriptive
    [Documentation]    Verify error message is descriptive
    ${error_data}    Set Variable    ${error_response.json()}
    Dictionary Should Contain Key    ${error_data}    detail
    Should Not Be Empty    ${error_data}[detail]

Error Should Indicate Missing Fields
    [Documentation]    Verify error indicates which fields are missing
    ${error_data}    Set Variable    ${validation_response.json()}
    Dictionary Should Contain Key    ${error_data}    detail
    Should Be True    isinstance(${error_data}[detail], list)    msg=Validation errors should be a list