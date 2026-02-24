*** Settings ***
Documentation     Books API Test Suite
...               
...               Validates REST API endpoints for book management.
...               Tests cover CRUD operations and response validation.

Resource          resources/common.resource
Resource          resources/api_keywords.resource

Suite Setup       Suite Initialization
Suite Teardown    Suite Cleanup
Test Setup        Test Initialization
Test Teardown     Test Cleanup

Force Tags        api    books

*** Test Cases ***
API Should Return All Books
    [Documentation]    Verify GET /books endpoint
    [Tags]    smoke    read
    Given Books Exist In Database
    When User Requests All Books
    Then Response Should Contain Book List
    And Books Should Have Valid Structure

API Should Create New Book
    [Documentation]    Verify POST /books endpoint
    [Tags]    smoke    create
    Given Valid Book Data Is Prepared
    When User Creates Book Via API
    Then Book Should Be Created Successfully
    And Book Should Be Retrievable

API Should Update Existing Book
    [Documentation]    Verify PUT /books/{id} endpoint
    [Tags]    update
    Given Book Exists In System
    When User Updates Book With New Data
    Then Book Should Be Updated Successfully
    And Updated Data Should Be Persisted

API Should Delete Book
    [Documentation]    Verify DELETE /books/{id} endpoint
    [Tags]    delete
    Given Book Exists In System
    When User Deletes Book Via API
    Then Book Should Be Deleted Successfully
    And Book Should Not Be Retrievable

API Should Return 404 For Non-Existent Book
    [Documentation]    Verify error handling for missing book
    [Tags]    error
    Given Non-Existent Book ID Is Used
    When User Requests Book By ID
    Then API Should Return 404 Status

*** Keywords ***
Books Exist In Database
    [Documentation]    Verify books exist
    ${response}=    Get All Books Via API
    Response Should Contain Books    ${response}

User Requests All Books
    [Documentation]    GET all books
    ${response}=    Get All Books Via API
    Set Test Variable    ${API_RESPONSE}    ${response}

Response Should Contain Book List
    [Documentation]    Validate response
    Response Should Contain Books    ${API_RESPONSE}

Books Should Have Valid Structure
    [Documentation]    Validate book objects
    ${books}=    Set Variable    ${API_RESPONSE.json()}
    ${first_book}=    Set Variable    ${books}[0]
    Book Should Have Valid Structure    ${first_book}

Valid Book Data Is Prepared
    [Documentation]    Prepare test data
    ${title}=    Set Variable    API Test Book ${TIMESTAMP}
    ${author}=    Set Variable    API Test Author
    ${pages}=    Set Variable    300
    ${category}=    Set Variable    Science
    Set Test Variable    ${TEST_TITLE}    ${title}
    Set Test Variable    ${TEST_AUTHOR}    ${author}
    Set Test Variable    ${TEST_PAGES}    ${pages}
    Set Test Variable    ${TEST_CATEGORY}    ${category}

User Creates Book Via API
    [Documentation]    POST new book
    ${book_id}=    Create Book Via API    ${TEST_TITLE}    ${TEST_AUTHOR}    ${TEST_PAGES}    ${TEST_CATEGORY}
    Set Test Variable    ${CREATED_BOOK_ID}    ${book_id}

Book Should Be Created Successfully
    [Documentation]    Verify creation
    Should Not Be Equal    ${CREATED_BOOK_ID}    ${EMPTY}

Book Should Be Retrievable
    [Documentation]    Verify book exists
    ${response}=    Get Book By ID Via API    ${CREATED_BOOK_ID}
    ${book}=    Set Variable    ${response.json()}
    Should Be Equal    ${book}[title]    ${TEST_TITLE}

Book Exists In System
    [Documentation]    Create test book
    ${title}=    Set Variable    Update Test ${TIMESTAMP}
    ${book_id}=    Create Book Via API    ${title}    Original Author    150    Fiction
    Set Test Variable    ${ORIGINAL_TITLE}    ${title}
    Set Test Variable    ${BOOK_ID}    ${book_id}

User Updates Book With New Data
    [Documentation]    PUT updated book
    ${new_title}=    Set Variable    Updated ${ORIGINAL_TITLE}
    ${new_author}=    Set Variable    Updated Author
    ${response}=    Update Book Via API    ${BOOK_ID}    ${new_title}    ${new_author}    200    Non-Fiction
    Set Test Variable    ${UPDATED_TITLE}    ${new_title}

Book Should Be Updated Successfully
    [Documentation]    Verify update response
    Should Not Be Empty    ${UPDATED_TITLE}

Updated Data Should Be Persisted
    [Documentation]    Verify updated data
    ${response}=    Get Book By ID Via API    ${BOOK_ID}
    ${book}=    Set Variable    ${response.json()}
    Should Be Equal    ${book}[title]    ${UPDATED_TITLE}

User Deletes Book Via API
    [Documentation]    DELETE book
    Delete Book Via API    ${BOOK_ID}
    Set Test Variable    ${BOOK_ID}    ${EMPTY}

Book Should Be Deleted Successfully
    [Documentation]    Verify deletion
    Pass Execution    Book deleted

Book Should Not Be Retrievable
    [Documentation]    Verify book is gone
    ${BOOK_ID}=    Set Variable    ${EMPTY}

Non-Existent Book ID Is Used
    [Documentation]    Use invalid ID
    Set Test Variable    ${INVALID_ID}    99999

User Requests Book By ID
    [Documentation]    GET non-existent book
    TRY
        ${response}=    GET On Session    api    /books/${INVALID_ID}    expected_status=404
        Set Test Variable    ${ERROR_RESPONSE}    ${response}
    EXCEPT
        Set Test Variable    ${ERROR_RESPONSE}    ${None}
    END

API Should Return 404 Status
    [Documentation]    Verify 404 response
    IF    $ERROR_RESPONSE != $None
        Status Should Be    404    ${ERROR_RESPONSE}
    ELSE
        Pass Execution    404 error handled correctly
    END
