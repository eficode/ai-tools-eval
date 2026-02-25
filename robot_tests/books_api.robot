*** Settings ***
Documentation     API Test Suite for Books REST API
...               Validates all CRUD operations and data integrity
...               Uses Gherkin syntax for behavioral test descriptions

Library           RequestsLibrary
Library           Collections
Resource          resources/common.resource
Resource          resources/api_keywords.resource

Suite Setup       Given Books API Is Available
Suite Teardown    Teardown Books API Session

Test Setup        Log Test Start    ${TEST NAME}
Test Teardown     Log Test End    ${TEST NAME}

Force Tags        api    regression


*** Test Cases ***
User Should Be Able To Retrieve All Books Via API
    [Documentation]    Verifies that GET /books/ returns the list of all books
    [Tags]    smoke    read
    Given Books API Session Exists
    When User Requests All Books
    Then Response Should Contain Books List
    Then Books Count Should Be Greater Than Zero

User Should Be Able To Create A New Book Via API
    [Documentation]    Verifies that POST /books/ creates a new book successfully
    [Tags]    smoke    create    crud
    Given Books API Session Exists    
    Given User Has Valid Book Data
    When User Submits Book Creation Request
    Then Book Should Be Created Successfully
    Then Response Should Contain Book ID
    Then Created Book Should Have Correct Data

User Should Be Able To Retrieve A Specific Book By ID
    [Documentation]    Verifies that GET /books/{id} returns correct book details
    [Tags]    read    crud
    Given Books API Session Exists
    Given A Book Exists In The System
    When User Requests Book By ID
    Then Book Details Should Be Returned
    Then Book Data Should Match Expected Values

User Should Be Able To Update An Existing Book
    [Documentation]    Verifies that PUT /books/{id} updates book information
    [Tags]    update    crud
    Given Books API Session Exists
    Given A Book Exists In The System
    Given User Has Updated Book Data
    When User Submits Book Update Request
    Then Book Should Be Updated Successfully
    Then Updated Book Should Reflect New Data

User Should Be Able To Delete A Book
    [Documentation]    Verifies that DELETE /books/{id} removes a book
    [Tags]    delete    crud
    Given Books API Session Exists
    Given A Book Exists In The System
    When User Submits Book Deletion Request
    Then Book Should Be Deleted Successfully
    Then Deleted Book Should Not Be Retrievable

User Should Be Able To Toggle Book Favorite Status
    [Documentation]    Verifies that PATCH /books/{id}/favorite updates favorite status
    [Tags]    favorite    update
    Given Books API Session Exists
    Given A Book Exists In The System
    When User Toggles Book Favorite Status To True
    Then Book Favorite Status Should Be True
    When User Toggles Book Favorite Status To False
    Then Book Favorite Status Should Be False

User Should Receive Error For Non-Existent Book
    [Documentation]    Verifies that accessing non-existent book returns 404
    [Tags]    negative    error_handling
    Given Books API Session Exists
    When User Requests Non-Existent Book
    Then Response Should Return 404 Status

User Should Be Able To Create Multiple Books
    [Documentation]    Verifies that multiple books can be created in sequence
    [Tags]    stress    create
    Given Books API Session Exists
    When User Creates Three Different Books
    Then All Three Books Should Exist In The System

User Should Maintain Data Integrity After Updates
    [Documentation]    Verifies that partial updates don't corrupt other fields
    [Tags]    data_integrity    update
    Given Books API Session Exists
    Given A Book Exists In The System
    When User Updates Only Book Title
    Then Title Should Be Updated
    Then Other Book Fields Should Remain Unchanged

User Should Be Able To Create Book With All Required Fields
    [Documentation]    Validates that all required fields are accepted
    [Tags]    validation    create
    Given Books API Session Exists
    When User Creates Book With All Required Fields
    Then Book Should Be Created With All Fields
    Then All Field Values Should Match Input


*** Keywords ***
# GIVEN Keywords
Given Books API Is Available
    [Documentation]    Sets up the API session and verifies connection
    Setup Books API Session

Given Books API Session Exists
    [Documentation]    Verifies that API session is active (no-op if already setup)
    Log    API session already configured in suite setup    DEBUG

Given User Has Valid Book Data
    [Documentation]    Prepares valid book data for creation
    &{test_book_data}=    Generate Test Book Data
    Set Test Variable    &{test_book_data}

Given A Book Exists In The System
    [Documentation]    Creates a test book and stores its ID
    ${book_data}=    Generate Test Book Data
    ${response}=    Create Book Via API    &{book_data}
    ${test_book_id}=    Extract Book ID From Response    ${response}
    Set Test Variable    ${test_book_id}
    ${test_book_title}=    Set Variable    ${book_data['title']}
    Set Test Variable    ${test_book_title}
    Set Test Variable    ${book_data}
    Set Test Variable    ${original_book_data}    ${book_data}

Given User Has Updated Book Data
    [Documentation]    Prepares modified book data for update operation
    ${updated_title}=    Set Variable    ${test_book_title}_UPDATED
    Set Test Variable    ${updated_title}
    VAR    &{update_data}
    ...    title=${updated_title}
    ...    author=${TEST_AUTHOR}_UPDATED
    ...    pages=500
    ...    category=${TEST_CATEGORY}
    
    Set Test Variable    ${test_update_data}    ${update_data}

# WHEN Keywords
When User Requests All Books
    [Documentation]    Executes GET request to retrieve all books
    ${all_books_response}=    Get All Books Via API
    VAR    ${all_books_response}    ${all_books_response}    scope=TEST

When User Submits Book Creation Request
    [Documentation]    Executes POST request to create a book
    ${create_response}=    Create Book Via API    &{test_book_data}
    VAR    ${create_response}    ${create_response}    scope=TEST

When User Requests Book By ID
    [Documentation]    Executes GET request for specific book
    ${get_book_response}=    Get Book By ID Via API    ${test_book_id}
    VAR    ${get_book_response}    ${get_book_response}    scope=TEST

When User Submits Book Update Request
    [Documentation]    Executes PUT request to update book
    ${update_response}=    Update Book Via API    ${test_book_id}    &{test_update_data}
    VAR    ${update_response}    ${update_response}    scope=TEST

When User Submits Book Deletion Request
    [Documentation]    Executes DELETE request to remove book
    ${delete_response}=    Delete Book Via API    ${test_book_id}
    VAR    ${delete_response}    ${delete_response}    scope=TEST

When User Toggles Book Favorite Status To True
    [Documentation]    Sets book favorite status to true
    ${favorite_response}=    Toggle Book Favorite Via API    ${test_book_id}    ${True}
    VAR    ${favorite_response}    ${favorite_response}    scope=TEST

When User Toggles Book Favorite Status To False
    [Documentation]    Sets book favorite status to false
    ${favorite_response}=    Toggle Book Favorite Via API    ${test_book_id}    ${False}
    VAR    ${favorite_response}    ${favorite_response}    scope=TEST

When User Requests Non-Existent Book
    [Documentation]    Attempts to get a book that doesn't exist
    VAR    ${non_existent_id}    999999
    Verify Book Does Not Exist    ${non_existent_id}

When User Creates Three Different Books
    [Documentation]    Creates three books with different data
    @{created_books}=    Create List
    
    FOR    ${i}    IN RANGE    3
        ${book_data}=    Generate Test Book Data
        ${response}=    Create Book Via API    &{book_data}
        ${book_id}=    Extract Book ID From Response    ${response}
        Append To List    ${created_books}    ${book_id}
    END
    
    Set Test Variable    ${test_created_books}    ${created_books}

When User Updates Only Book Title
    [Documentation]    Updates only the title field of the book
    VAR    ${new_title}    ${test_book_title}_TITLE_ONLY_UPDATE    scope=TEST
    VAR    &{partial_update}
    ...    title=${new_title}
    ...    author=${original_book_data['author']}
    ...    pages=${original_book_data['pages']}
    ...    category=${original_book_data['category']}
    
    ${partial_update_response}=    Update Book Via API    ${test_book_id}    &{partial_update}
    VAR    ${partial_update_response}    ${partial_update_response}    scope=TEST

When User Creates Book With All Required Fields
    [Documentation]    Creates a book ensuring all required fields are present
    ${book_data}=    Generate Test Book Data
    ${all_fields_response}=    Create Book Via API    &{book_data}
    VAR    ${all_fields_response}    ${all_fields_response}    scope=TEST
    Set Test Variable    ${all_fields_data}    ${book_data}

# THEN Keywords
Then Response Should Contain Books List
    [Documentation]    Validates response contains a list of books
    ${books}=    Set Variable    ${all_books_response.json()}
    Should Not Be Empty    ${books}    msg=Books list should not be empty

Then Books Count Should Be Greater Than Zero
    [Documentation]    Verifies at least one book exists
    ${count}=    Count Books In Response    ${all_books_response}
    Should Be True    ${count} > 0    msg=Books count should be greater than zero

Then Book Should Be Created Successfully
    [Documentation]    Validates successful book creation (200 status)
    Verify Response Status    ${create_response}    200

Then Response Should Contain Book ID
    [Documentation]    Validates response includes a valid book ID
    ${book_id}=    Extract Book ID From Response    ${create_response}
    VAR    ${created_book_id}    ${book_id}    scope=TEST

Then Created Book Should Have Correct Data
    [Documentation]    Validates created book data matches input
    Verify Book Data Matches    ${create_response}    &{test_book_data}

Then Book Details Should Be Returned
    [Documentation]    Validates successful book retrieval (200 status)
    Verify Response Status    ${get_book_response}    200

Then Book Data Should Match Expected Values
    [Documentation]    Validates retrieved book data is correct
    ${book}=    Set Variable    ${get_book_response.json()}
    Should Be Equal As Integers    ${book['id']}    ${test_book_id}

Then Book Should Be Updated Successfully
    [Documentation]    Validates successful update (200 status)
    Verify Response Status    ${update_response}    200

Then Updated Book Should Reflect New Data
    [Documentation]    Validates updated book has new values
    Verify Book Data Matches    ${update_response}    &{test_update_data}

Then Book Should Be Deleted Successfully
    [Documentation]    Validates successful deletion (200 status)
    Verify Response Status    ${delete_response}    200

Then Deleted Book Should Not Be Retrievable
    [Documentation]    Validates deleted book returns 404
    Verify Book Does Not Exist    ${test_book_id}

Then Book Favorite Status Should Be True
    [Documentation]    Validates favorite status is true
    ${book}=    Set Variable    ${favorite_response.json()}
    Should Be True    ${book['favorite']}    msg=Favorite status should be True

Then Book Favorite Status Should Be False
    [Documentation]    Validates favorite status is false
    ${book}=    Set Variable    ${favorite_response.json()}
    Should Not Be True    ${book['favorite']}    msg=Favorite status should be False

Then Response Should Return 404 Status
    [Documentation]    Already validated in WHEN keyword (no-op)
    Log    404 status already verified    DEBUG

Then All Three Books Should Exist In The System
    [Documentation]    Validates all three created books are retrievable
    FOR    ${book_id}    IN    @{test_created_books}
        ${response}=    Get Book By ID Via API    ${book_id}
        Verify Response Status    ${response}    200
    END

Then Title Should Be Updated
    [Documentation]    Validates title field was updated
    ${book}=    Set Variable    ${partial_update_response.json()}
    Should Be Equal    ${book['title']}    ${new_title}
    ...    msg=Title should be updated to ${new_title}

Then Other Book Fields Should Remain Unchanged
    [Documentation]    Validates other fields were not modified
    ${book}=    Set Variable    ${partial_update_response.json()}
    Should Be Equal    ${book['author']}    ${original_book_data['author']}
    Should Be Equal As Integers    ${book['pages']}    ${original_book_data['pages']}

Then Book Should Be Created With All Fields
    [Documentation]    Validates book creation with all fields
    Verify Response Status    ${all_fields_response}    200

Then All Field Values Should Match Input
    [Documentation]    Validates all field values match the input data
    Verify Book Data Matches    ${all_fields_response}    &{all_fields_data}
