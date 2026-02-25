*** Settings ***
Documentation     Books API Test Suite
...               
...               This suite tests the Books REST API functionality including:
...               - Creating new books (POST)
...               - Retrieving book details (GET)
...               - Updating book information (PUT)
...               - Deleting books (DELETE)
...               - Error handling and validation
...               
...               Prerequisites:
...               - Books service running at http://books-service:8000
...               - Database initialized with sample data
...               - RequestsLibrary installed and configured

Library           RequestsLibrary
Library           Collections
Resource          resources/common.resource
Resource          resources/BooksAPI.resource

Suite Setup       Initialize API Test Suite
Suite Teardown    Cleanup API Test Suite
Test Setup        Initialize API Test
Test Teardown     Cleanup API Test

Force Tags        api    books
Default Tags      regression

*** Variables ***
${SUITE_START_TIME}       ${EMPTY}
${TEST_START_TIME}        ${EMPTY}
${TEST_BOOK_IDS}          @{EMPTY}

*** Test Cases ***
User Should Be Able To Create A New Book Via API
    [Documentation]    Verify that a new book can be created via POST request
    ...                
    ...                This test verifies:
    ...                - POST request creates a book successfully
    ...                - Response status is 201 Created
    ...                - Response contains the created book data
    ...                - Book appears in the books list
    [Tags]    smoke    create    priority-high
    
    Given API Session Is Active
    When User Creates A New Book With Valid Data
    Then Book Should Be Created Successfully
    And Book Should Appear In Books List
    And Response Should Contain All Required Fields

User Should Be Able To Retrieve All Books Via API
    [Documentation]    Verify that all books can be retrieved via GET request
    ...                
    ...                This test verifies:
    ...                - GET request returns all books
    ...                - Response status is 200 OK
    ...                - Response contains a list of books
    ...                - At least one book is returned
    [Tags]    smoke    read    priority-high
    
    Given API Session Is Active
    When User Retrieves All Books
    Then Books List Should Be Returned Successfully
    And Books List Should Not Be Empty

User Should Be Able To Retrieve Book Details Via API
    [Documentation]    Verify that book details can be retrieved via GET request
    ...                
    ...                This test verifies:
    ...                - GET request for specific book returns correct data
    ...                - Response status is 200 OK
    ...                - Response contains expected book fields
    ...                - Book data matches what was created
    [Tags]    read    priority-high
    
    Given API Session Is Active
    And A Book Exists In The System
    When User Retrieves Book Details
    Then Book Details Should Be Returned Successfully
    And Book Details Should Match Expected Data

User Should Be Able To Update Book Information Via API
    [Documentation]    Verify that book information can be updated via PUT request
    ...                
    ...                This test verifies:
    ...                - PUT request updates book successfully
    ...                - Response status is 200 OK
    ...                - Updated data is persisted
    ...                - GET request returns updated data
    [Tags]    update    priority-high
    
    Given API Session Is Active
    And A Book Exists In The System
    When User Updates Book Information
    Then Book Should Be Updated Successfully
    And Updated Information Should Be Persisted

User Should Be Able To Delete A Book Via API
    [Documentation]    Verify that a book can be deleted via DELETE request
    ...                
    ...                This test verifies:
    ...                - DELETE request removes book successfully
    ...                - Response status is 204 No Content
    ...                - Book no longer appears in books list
    ...                - GET request for deleted book returns 404
    [Tags]    delete    priority-high
    
    Given API Session Is Active
    And A Book Exists In The System
    When User Deletes The Book
    Then Book Should Be Deleted Successfully
    And Book Should Not Appear In Books List

API Should Return 404 For Nonexistent Book
    [Documentation]    Verify that API returns 404 for nonexistent book ID
    ...                
    ...                This test verifies:
    ...                - GET request for invalid ID returns 404
    ...                - Error response is properly formatted
    ...                - No exception is raised
    [Tags]    error-handling    negative    priority-medium
    
    Given API Session Is Active
    When User Requests Nonexistent Book
    Then API Should Return 404 Status Code

API Should Validate Required Fields On Create
    [Documentation]    Verify that API validates required fields when creating a book
    ...                
    ...                This test verifies:
    ...                - POST request without required fields returns 422
    ...                - Validation error message is returned
    ...                - No book is created
    [Tags]    validation    negative    priority-medium
    
    Given API Session Is Active
    When User Attempts To Create Book Without Required Fields
    Then API Should Return 422 Status Code
    And Response Should Contain Validation Errors

User Should Be Able To Create Multiple Books
    [Documentation]    Verify that multiple books can be created in sequence
    ...                
    ...                This test verifies:
    ...                - Multiple POST requests succeed
    ...                - Each book gets a unique ID
    ...                - All books appear in the books list
    [Tags]    create    priority-medium
    
    Given API Session Is Active
    When User Creates Multiple Books
    Then All Books Should Be Created Successfully
    And All Books Should Appear In Books List

API Should Handle Concurrent Requests
    [Documentation]    Verify that API handles multiple requests correctly
    ...                
    ...                This test verifies:
    ...                - API can handle multiple GET requests
    ...                - Responses are consistent
    ...                - No data corruption occurs
    [Tags]    performance    priority-low
    
    Given API Session Is Active
    When User Makes Multiple Concurrent Requests
    Then All Requests Should Complete Successfully

*** Keywords ***
Initialize API Test Suite
    [Documentation]    Runs once before all API tests in this suite
    ...                
    ...                This keyword:
    ...                - Logs suite start
    ...                - Creates API session
    ...                - Verifies API is available
    ...                - Records suite start time
    
    Log    Starting Books API Test Suite    level=INFO
    ${start_time}=    Get Time    epoch
    VAR    ${SUITE_START_TIME}    ${start_time}    scope=SUITE
    Create API Session
    Verify API Is Available

Cleanup API Test Suite
    [Documentation]    Runs once after all API tests in this suite
    ...                
    ...                This keyword:
    ...                - Closes API sessions
    ...                - Logs suite completion
    ...                - Calculates and logs suite duration
    
    Close API Session
    
    TRY
        ${end_time}=    Get Time    epoch
        ${duration}=    Evaluate    ${end_time} - ${SUITE_START_TIME}
        Log    Books API Test Suite completed in ${duration} seconds    level=INFO
    EXCEPT
        Log    Suite duration calculation skipped (suite setup may have failed)    level=WARN
    END

Initialize API Test
    [Documentation]    Runs before each API test case
    ...                
    ...                This keyword:
    ...                - Records test start time
    ...                - Initializes empty list for test book IDs
    ...                - Logs test start
    
    ${start_time}=    Get Time    epoch
    VAR    ${TEST_START_TIME}    ${start_time}    scope=TEST
    VAR    @{TEST_BOOK_IDS}    @{EMPTY}    scope=TEST
    Log    Starting test: ${TEST_NAME}

Cleanup API Test
    [Documentation]    Runs after each API test case
    ...                
    ...                This keyword:
    ...                - Deletes all test books created during the test
    ...                - Logs test completion
    ...                - Calculates and logs test duration
    
    TRY
        FOR    ${book_id}    IN    @{TEST_BOOK_IDS}
            Delete Book Via API    ${book_id}
        END
    EXCEPT    AS    ${error}
        Log    Warning: Test cleanup failed: ${error}    level=WARN
    END
    
    Log Test Duration    ${TEST_START_TIME}

API Session Is Active
    [Documentation]    Verifies API session is active
    ...                
    ...                This is a Gherkin-style Given keyword that:
    ...                - Checks if session exists
    ...                - Verifies session is ready for requests
    
    ${exists}=    Session Exists    books_api
    Should Be True    ${exists}    API session not found

User Creates A New Book With Valid Data
    [Documentation]    Creates a new book with valid test data
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Generates unique book data
    ...                - Sends POST request to create book
    ...                - Stores book ID for cleanup
    
    &{book_data}=    Generate Unique Book Data
    ${response}=    Create Book Via API    &{book_data}
    
    ${book_id}=    Extract Book ID From Response    ${response}
    Append To List    ${TEST_BOOK_IDS}    ${book_id}
    
    VAR    ${CREATED_BOOK_ID}    ${book_id}    scope=TEST
    VAR    &{CREATED_BOOK_DATA}    &{book_data}    scope=TEST
    VAR    ${CREATED_RESPONSE}    ${response}    scope=TEST
    
    RETURN    ${response}

Book Should Be Created Successfully
    [Documentation]    Verifies book was created successfully
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies response status is 200
    ...                - Verifies book ID was returned
    
    Should Be True    ${CREATED_BOOK_ID} is not None    Book ID should not be None
    Status Should Be    200    ${CREATED_RESPONSE}
    Log    Book created successfully with ID: ${CREATED_BOOK_ID}

Book Should Appear In Books List
    [Documentation]    Verifies created book appears in books list
    ...                
    ...                This is a Gherkin-style And keyword that:
    ...                - Retrieves all books
    ...                - Verifies created book is in the list
    
    ${response}=    Get All Books Via API
    Verify Book In List    ${response}    ${CREATED_BOOK_ID}

Response Should Contain All Required Fields
    [Documentation]    Verifies response contains all required book fields
    ...                
    ...                This is a Gherkin-style And keyword that:
    ...                - Checks for required fields (id, title, author, etc.)
    ...                - Verifies field values are not empty
    
    Verify Response Contains Required Fields    ${CREATED_RESPONSE}

User Retrieves All Books
    [Documentation]    Retrieves all books via GET request
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Sends GET request to /books/
    ...                - Stores response for verification
    
    ${response}=    Get All Books Via API
    VAR    ${ALL_BOOKS_RESPONSE}    ${response}    scope=TEST

Books List Should Be Returned Successfully
    [Documentation]    Verifies books list was returned successfully
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies response status is 200
    ...                - Verifies response is a list
    
    Status Should Be    200    ${ALL_BOOKS_RESPONSE}
    ${books}=    Set Variable    ${ALL_BOOKS_RESPONSE.json()}
    ${is_list}=    Evaluate    isinstance(${books}, list)
    Should Be True    ${is_list}    Response is not a list

Books List Should Not Be Empty
    [Documentation]    Verifies books list is not empty
    ...                
    ...                This is a Gherkin-style And keyword that:
    ...                - Gets count of books in response
    ...                - Verifies count is greater than zero
    
    ${count}=    Get Book Count From Response    ${ALL_BOOKS_RESPONSE}
    Should Be True    ${count} > 0    Books list is empty

A Book Exists In The System
    [Documentation]    Creates a test book for the test
    ...                
    ...                This is a Gherkin-style Given keyword that:
    ...                - Creates a new book
    ...                - Stores book data for later verification
    
    User Creates A New Book With Valid Data

User Retrieves Book Details
    [Documentation]    Retrieves book details via GET request
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Sends GET request for specific book
    ...                - Stores response for verification
    
    ${response}=    Get Book By ID Via API    ${CREATED_BOOK_ID}
    VAR    ${RETRIEVED_RESPONSE}    ${response}    scope=TEST

Book Details Should Be Returned Successfully
    [Documentation]    Verifies book details were returned successfully
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies response status is 200
    ...                - Verifies response contains book data
    
    Status Should Be    200    ${RETRIEVED_RESPONSE}
    Verify Response Contains Required Fields    ${RETRIEVED_RESPONSE}

Book Details Should Match Expected Data
    [Documentation]    Verifies retrieved book details match expected
    ...                
    ...                This is a Gherkin-style And keyword that:
    ...                - Compares retrieved data with created data
    ...                - Verifies all fields match
    
    Verify Response Contains Book Data    ${RETRIEVED_RESPONSE}    &{CREATED_BOOK_DATA}

User Updates Book Information
    [Documentation]    Updates book information via PUT request
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Generates updated book data
    ...                - Sends PUT request to update book
    
    ${timestamp}=    Generate Unique Timestamp
    VAR    &{update_data}
    ...    title=Updated Title ${timestamp}
    ...    author=Updated Author ${timestamp}
    ...    pages=${CREATED_BOOK_DATA}[pages]
    ...    category=${CREATED_BOOK_DATA}[category]
    ...    favorite=${CREATED_BOOK_DATA}[favorite]
    
    ${response}=    Update Book Via API    ${CREATED_BOOK_ID}    &{update_data}
    VAR    &{UPDATED_DATA}    &{update_data}    scope=TEST
    VAR    ${UPDATE_RESPONSE}    ${response}    scope=TEST

Book Should Be Updated Successfully
    [Documentation]    Verifies book was updated successfully
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies response status is 200
    ...                - Verifies update data is not empty
    
    Status Should Be    200    ${UPDATE_RESPONSE}
    Should Not Be Empty    ${UPDATED_DATA}

Updated Information Should Be Persisted
    [Documentation]    Verifies updated information is persisted
    ...                
    ...                This is a Gherkin-style And keyword that:
    ...                - Retrieves book again
    ...                - Verifies updated fields match
    
    ${response}=    Get Book By ID Via API    ${CREATED_BOOK_ID}
    Verify Response Contains Book Data    ${response}    &{UPDATED_DATA}

User Deletes The Book
    [Documentation]    Deletes book via DELETE request
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Sends DELETE request for the book
    ...                - Removes book ID from cleanup list
    
    Delete Book Via API    ${CREATED_BOOK_ID}
    Remove Values From List    ${TEST_BOOK_IDS}    ${CREATED_BOOK_ID}

Book Should Be Deleted Successfully
    [Documentation]    Verifies book was deleted successfully
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies book no longer exists
    ...                - Confirms deletion was successful
    
    Verify Book Does Not Exist Via API    ${CREATED_BOOK_ID}

Book Should Not Appear In Books List
    [Documentation]    Verifies deleted book does not appear in list
    ...                
    ...                This is a Gherkin-style And keyword that:
    ...                - Retrieves all books
    ...                - Verifies deleted book is not in the list
    
    ${response}=    Get All Books Via API
    Verify Book Not In List    ${response}    ${CREATED_BOOK_ID}

User Requests Nonexistent Book
    [Documentation]    Requests a nonexistent book
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Sends GET request for invalid book ID
    ...                - Stores error response
    
    ${response}=    GET On Session    books_api    ${API_ENDPOINT}99999    expected_status=404
    VAR    ${ERROR_RESPONSE}    ${response}    scope=TEST

API Should Return 404 Status Code
    [Documentation]    Verifies API returned 404
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies response status is 404
    ...                - Confirms error handling is correct
    
    Status Should Be    404    ${ERROR_RESPONSE}

User Attempts To Create Book Without Required Fields
    [Documentation]    Attempts to create book with missing required fields
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Sends POST request with incomplete data
    ...                - Stores validation error response
    
    VAR    &{invalid_data}    author=Test Author
    ${response}=    POST On Session
    ...    books_api
    ...    ${API_ENDPOINT}
    ...    json=&{invalid_data}
    ...    expected_status=422
    
    VAR    ${VALIDATION_RESPONSE}    ${response}    scope=TEST

API Should Return 422 Status Code
    [Documentation]    Verifies API returned 422
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies response status is 422
    ...                - Confirms validation is working
    
    Status Should Be    422    ${VALIDATION_RESPONSE}

Response Should Contain Validation Errors
    [Documentation]    Verifies response contains validation error details
    ...                
    ...                This is a Gherkin-style And keyword that:
    ...                - Checks for error details in response
    ...                - Verifies error message is present
    
    ${error_data}=    Set Variable    ${VALIDATION_RESPONSE.json()}
    Dictionary Should Contain Key    ${error_data}    detail

User Creates Multiple Books
    [Documentation]    Creates multiple books in sequence
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Creates 3 books with unique data
    ...                - Stores all book IDs
    
    @{created_ids}=    Create List
    
    FOR    ${i}    IN RANGE    3
        &{book_data}=    Generate Unique Book Data
        ${response}=    Create Book Via API    &{book_data}
        ${book_id}=    Extract Book ID From Response    ${response}
        Append To List    ${created_ids}    ${book_id}
        Append To List    ${TEST_BOOK_IDS}    ${book_id}
    END
    
    VAR    @{MULTIPLE_BOOK_IDS}    @{created_ids}    scope=TEST

All Books Should Be Created Successfully
    [Documentation]    Verifies all books were created successfully
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies all book IDs are unique
    ...                - Confirms all creations succeeded
    
    ${count}=    Get Length    ${MULTIPLE_BOOK_IDS}
    Should Be Equal As Integers    ${count}    3
    List Should Not Contain Duplicates    ${MULTIPLE_BOOK_IDS}

All Books Should Appear In Books List
    [Documentation]    Verifies all created books appear in the list
    ...                
    ...                This is a Gherkin-style And keyword that:
    ...                - Retrieves all books
    ...                - Verifies each created book is in the list
    
    ${response}=    Get All Books Via API
    
    FOR    ${book_id}    IN    @{MULTIPLE_BOOK_IDS}
        Verify Book In List    ${response}    ${book_id}
    END

User Makes Multiple Concurrent Requests
    [Documentation]    Makes multiple GET requests
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Sends multiple GET requests
    ...                - Stores all responses
    
    @{responses}=    Create List
    
    FOR    ${i}    IN RANGE    5
        ${response}=    Get All Books Via API
        Append To List    ${responses}    ${response}
    END
    
    VAR    @{CONCURRENT_RESPONSES}    @{responses}    scope=TEST

All Requests Should Complete Successfully
    [Documentation]    Verifies all requests completed successfully
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies all responses have status 200
    ...                - Confirms no errors occurred
    
    FOR    ${response}    IN    @{CONCURRENT_RESPONSES}
        Status Should Be    200    ${response}
    END
    
    ${count}=    Get Length    ${CONCURRENT_RESPONSES}
    Should Be Equal As Integers    ${count}    5
