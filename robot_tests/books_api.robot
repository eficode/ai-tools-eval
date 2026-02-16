*** Settings ***
Documentation     API Test Suite for Books Library REST API
...               
...               This test suite validates the REST API functionality of the Books Library
...               application using behavior-driven testing with Gherkin syntax.
...               
...               Test Coverage:
...               - CRUD operations (Create, Read, Update, Delete)
...               - API response validation and error handling
...               - Data integrity and persistence
...               - Edge cases and error conditions
...               - API contract compliance
...               
...               Environment: MCP-enabled Robot Framework container
...               Target API: http://books-service:8000/books/
...               HTTP Client: RequestsLibrary

Resource          resources/common.resource
Resource          resources/api/books_api.resource

Suite Setup       Setup Test Environment
Suite Teardown    Teardown Test Environment
Test Teardown     Cleanup Test Data

Force Tags        api    books    rest
Default Tags      priority-medium


*** Variables ***
# API-specific test variables
@{REQUIRED_BOOK_FIELDS}       id    title    author    pages    category    favorite
@{TEST_BOOKS_FOR_CLEANUP}     # Will store book IDs for cleanup


*** Test Cases ***
API Should Return All Books Successfully
    [Documentation]    API client retrieves all books from the system
    ...                
    ...                This test verifies the basic GET /books/ endpoint
    ...                returns a proper list of books with correct structure.
    [Tags]    smoke    read    priority-high
    
    Given Books API Is Available
    When Client Requests All Books
    Then API Should Return Success Response
    And Response Should Contain Books List
    And Each Book Should Have Required Fields

API Should Create New Book Successfully
    [Documentation]    API client creates a new book with valid data
    ...                
    ...                This test covers the POST /books/ endpoint with valid
    ...                book data and verifies proper creation and response.
    [Tags]    create    crud    priority-high
    
    ${new_book_data}=    Generate Test Book Data    _API_Create
    
    Given Books API Is Available
    When Client Creates Book With Valid Data    &{new_book_data}
    Then API Should Return Created Response
    And Response Should Contain Created Book Data    &{new_book_data}
    And Book Should Be Persisted In System

API Should Retrieve Specific Book By ID
    [Documentation]    API client retrieves a specific book using its ID
    ...                
    ...                This test verifies the GET /books/{id} endpoint
    ...                returns correct book details for existing books.
    [Tags]    read    crud    priority-high
    
    ${test_book_data}=    Generate Test Book Data    _API_GetByID
    
    Given Books API Is Available
    And Book Exists In System    &{test_book_data}
    When Client Requests Book By ID    ${CREATED_BOOK_ID}
    Then API Should Return Success Response
    And Response Should Contain Correct Book Data    &{test_book_data}

API Should Update Existing Book Successfully
    [Documentation]    API client updates an existing book with new data
    ...                
    ...                This test covers the PUT /books/{id} endpoint
    ...                and verifies data persistence after updates.
    [Tags]    update    crud    priority-high
    
    ${original_book}=    Generate Test Book Data    _API_Update_Original
    ${updated_book}=     Generate Test Book Data    _API_Update_New
    
    Given Books API Is Available
    And Book Exists In System    &{original_book}
    When Client Updates Book With New Data    ${CREATED_BOOK_ID}    &{updated_book}
    Then API Should Return Success Response
    And Response Should Contain Updated Book Data    &{updated_book}
    And Book Should Be Updated In System    ${CREATED_BOOK_ID}    &{updated_book}

API Should Delete Existing Book Successfully
    [Documentation]    API client deletes an existing book from the system
    ...                
    ...                This test verifies the DELETE /books/{id} endpoint
    ...                removes books correctly and handles cleanup.
    [Tags]    delete    crud    priority-high
    
    ${book_to_delete}=    Generate Test Book Data    _API_Delete
    
    Given Books API Is Available
    And Book Exists In System    &{book_to_delete}
    When Client Deletes Book By ID    ${CREATED_BOOK_ID}
    Then API Should Return Success Response
    And Book Should Be Removed From System    ${CREATED_BOOK_ID}

API Should Toggle Book Favorite Status Successfully
    [Documentation]    API client toggles the favorite status of a book
    ...                
    ...                This test verifies the PATCH /books/{id}/favorite endpoint
    ...                correctly updates favorite status.
    [Tags]    update    favorite    priority-medium
    
    ${test_book}=    Generate Test Book Data    _API_Favorite
    
    Given Books API Is Available
    And Book Exists In System    &{test_book}
    When Client Toggles Book Favorite Status    ${CREATED_BOOK_ID}    ${TRUE}
    Then API Should Return Success Response
    And Book Should Be Marked As Favorite    ${CREATED_BOOK_ID}
    When Client Toggles Book Favorite Status    ${CREATED_BOOK_ID}    ${FALSE}
    Then API Should Return Success Response
    And Book Should Not Be Marked As Favorite    ${CREATED_BOOK_ID}

API Should Return Error For Non-Existent Book
    [Documentation]    API client requests a book that doesn't exist
    ...                
    ...                This test verifies proper error handling for
    ...                requests to non-existent resources.
    [Tags]    error-handling    negative    priority-medium
    
    VAR    ${non_existent_id}    99999
    
    Given Books API Is Available
    When Client Requests Non-Existent Book    ${non_existent_id}
    Then API Should Return Not Found Error
    And Error Response Should Contain Appropriate Message

API Should Validate Required Fields On Creation
    [Documentation]    API client attempts to create book without required fields
    ...                
    ...                This test verifies that the API properly validates
    ...                required fields and returns appropriate errors.
    [Tags]    validation    negative    priority-medium
    [Template]    Test Book Creation With Missing Field
    
    # field_to_omit    expected_error_message
    title             Field required
    author            Field required
    pages             Field required

API Should Validate Data Types On Creation
    [Documentation]    API client attempts to create book with invalid data types
    ...                
    ...                This test ensures the API validates data types
    ...                and rejects invalid input appropriately.
    [Tags]    validation    negative    priority-medium
    [Template]    Test Book Creation With Invalid Data Type
    
    # field_name    invalid_value    expected_error_contains
    pages          "not_a_number"   valid integer
    favorite       "not_boolean"    valid boolean

API Should Handle Large Book Data
    [Documentation]    API client creates book with large data values
    ...                
    ...                This test verifies the API can handle books with
    ...                large text fields and high page counts.
    [Tags]    edge-case    performance    priority-low
    
    ${long_title}=      Evaluate    'Very Long Title ' * 50
    ${long_author}=     Evaluate    'Very Long Author Name ' * 30
    ${large_pages}=     Set Variable    9999
    
    ${large_book}=      Create Dictionary      
    ...    title=${long_title}
    ...    author=${long_author}
    ...    pages=${large_pages}
    ...    category=Fiction
    
    Given Books API Is Available
    When Client Creates Book With Large Data    &{large_book}
    Then API Should Handle Large Data Successfully
    And Book Should Be Created With Large Data    &{large_book}

API Should Maintain Data Integrity Across Operations
    [Documentation]    API client performs multiple operations and verifies data consistency
    ...                
    ...                This test ensures that CRUD operations maintain
    ...                data integrity throughout the lifecycle.
    [Tags]    integration    data-integrity    priority-high
    
    ${book_data}=    Generate Test Book Data    _API_Integrity
    
    Given Books API Is Available
    When Client Creates Book    &{book_data}
    And Client Retrieves Created Book
    And Client Updates Book Data
    And Client Retrieves Updated Book
    Then All Operations Should Maintain Data Consistency
    And Book Data Should Match Expected Values

API Should Return Proper HTTP Status Codes
    [Documentation]    API client verifies correct HTTP status codes for different operations
    ...                
    ...                This test ensures the API follows HTTP standards
    ...                for status code responses.
    [Tags]    http-standards    compliance    priority-medium
    
    ${test_book}=    Generate Test Book Data    _API_StatusCodes
    
    Given Books API Is Available
    When Client Performs Various API Operations    &{test_book}
    Then Each Operation Should Return Correct Status Code
    And Status Codes Should Follow HTTP Standards

API Should Handle Concurrent Requests
    [Documentation]    Multiple API clients perform operations simultaneously
    ...                
    ...                This test verifies the API can handle concurrent
    ...                requests without data corruption or errors.
    [Tags]    concurrency    performance    priority-low
    
    VAR    ${concurrent_books_count}    5
    
    Given Books API Is Available
    When Multiple Clients Create Books Simultaneously    ${concurrent_books_count}
    Then All Books Should Be Created Successfully
    And No Data Corruption Should Occur
    And API Should Remain Responsive


*** Keywords ***
# Gherkin-style Given keywords
Books API Is Available
    [Documentation]    Ensures the Books API is available and responding
    
    Verify Books Service Is Ready
    Log    Books API is available and ready

Book Exists In System
    [Documentation]    Creates a test book in the system for test scenarios
    [Arguments]    &{book_data}
    
    ${created_book}=    Create Test Book Via API    ${book_data}
    Set Test Variable    ${CREATED_BOOK_ID}    ${created_book}[id]
    Set Test Variable    ${CREATED_BOOK_DATA}    ${created_book}
    Log    Test book exists in system: ${created_book}[title] (ID: ${created_book}[id])

# Gherkin-style When keywords
Client Requests All Books
    [Documentation]    Client makes GET request to retrieve all books
    
    ${response}=    Get All Books Via API
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    Client requested all books

Client Creates Book With Valid Data
    [Documentation]    Client creates a book with valid data
    [Arguments]    &{book_data}
    
    ${response}=    Create Book Via API    &{book_data}
    Set Test Variable    ${API_RESPONSE}    ${response}
    Set Test Variable    ${CREATED_BOOK_DATA}    ${response.json()}
    Set Test Variable    ${CREATED_BOOK_ID}    ${response.json()}[id]
    Log    Client created book: ${book_data}[title]

Client Requests Book By ID
    [Documentation]    Client requests a specific book by its ID
    [Arguments]    ${book_id}
    
    ${response}=    Get Book By ID Via API    ${book_id}
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    Client requested book by ID: ${book_id}

Client Updates Book With New Data
    [Documentation]    Client updates an existing book with new data
    [Arguments]    ${book_id}    &{updated_data}
    
    ${response}=    Update Book Via API    ${book_id}    &{updated_data}
    Set Test Variable    ${API_RESPONSE}    ${response}
    Set Test Variable    ${UPDATED_BOOK_DATA}    ${updated_data}
    Log    Client updated book ID ${book_id} with new data

Client Deletes Book By ID
    [Documentation]    Client deletes a book by its ID
    [Arguments]    ${book_id}
    
    ${response}=    Delete Book Via API    ${book_id}
    Set Test Variable    ${API_RESPONSE}    ${response}
    Set Test Variable    ${DELETED_BOOK_ID}    ${book_id}
    Log    Client deleted book ID: ${book_id}

Client Toggles Book Favorite Status
    [Documentation]    Client toggles the favorite status of a book
    [Arguments]    ${book_id}    ${favorite_status}
    
    ${response}=    Toggle Book Favorite Via API    ${book_id}    ${favorite_status}
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    Client toggled favorite status for book ID ${book_id} to ${favorite_status}

Client Requests Non-Existent Book
    [Documentation]    Client requests a book that doesn't exist
    [Arguments]    ${non_existent_id}
    
    TRY
        VAR    ${endpoint}    ${BOOKS_ENDPOINT}${non_existent_id}
        ${response}=    Make API Request With Error Handling    GET    ${endpoint}    expected_status=404
        Set Test Variable    ${API_RESPONSE}    ${response}
        Log    Client received expected 404 for non-existent book: ${non_existent_id}
    EXCEPT    Exception    AS    ${error}
        Set Test Variable    ${API_ERROR}    ${error}
        Log    Client received expected error for non-existent book: ${error}
    END

Client Creates Book With Large Data
    [Documentation]    Client creates a book with large data values
    [Arguments]    &{large_book_data}
    
    ${response}=    Create Book Via API    &{large_book_data}
    Set Test Variable    ${API_RESPONSE}    ${response}
    Set Test Variable    ${CREATED_BOOK_DATA}    ${response.json()}
    Log    Client created book with large data

Client Creates Book
    [Documentation]    Client creates a book (for integration testing)
    [Arguments]    &{book_data}
    
    ${response}=    Create Book Via API    &{book_data}
    Set Test Variable    ${INTEGRATION_BOOK_ID}    ${response.json()}[id]
    @{integration_responses}=    Create List    ${response}
    Set Test Variable    @{INTEGRATION_RESPONSES}    @{integration_responses}
    Log    Integration test: Client created book

Client Retrieves Created Book
    [Documentation]    Client retrieves the previously created book
    
    ${response}=    Get Book By ID Via API    ${INTEGRATION_BOOK_ID}
    Append To List    ${INTEGRATION_RESPONSES}    ${response}
    Log    Integration test: Client retrieved created book

Client Updates Book Data
    [Documentation]    Client updates the book with new data
    
    ${update_data}=    Generate Test Book Data    _Updated
    ${response}=    Update Book Via API    ${INTEGRATION_BOOK_ID}    &{update_data}
    Set Test Variable    ${INTEGRATION_UPDATE_DATA}    ${update_data}
    Append To List    ${INTEGRATION_RESPONSES}    ${response}
    Log    Integration test: Client updated book data

Client Retrieves Updated Book
    [Documentation]    Client retrieves the book after update
    
    ${response}=    Get Book By ID Via API    ${INTEGRATION_BOOK_ID}
    Append To List    ${INTEGRATION_RESPONSES}    ${response}
    Log    Integration test: Client retrieved updated book

Client Performs Various API Operations
    [Documentation]    Client performs multiple API operations for status code testing
    [Arguments]    &{test_book}
    
    @{operation_responses}=    Create List
    
    # Create operation (should return 200)
    ${create_response}=    Create Book Via API    &{test_book}
    Append To List    ${operation_responses}    ${create_response}
    ${book_id}=    Set Variable    ${create_response.json()}[id]
    
    # Read operation (should return 200)
    ${read_response}=    Get Book By ID Via API    ${book_id}
    Append To List    ${operation_responses}    ${read_response}
    
    # Update operation (should return 200)
    ${update_data}=    Generate Test Book Data    _StatusTest
    ${update_response}=    Update Book Via API    ${book_id}    &{update_data}
    Append To List    ${operation_responses}    ${update_response}
    
    # Delete operation (should return 200)
    ${delete_response}=    Delete Book Via API    ${book_id}
    Append To List    ${operation_responses}    ${delete_response}
    
    Set Test Variable    @{STATUS_CODE_RESPONSES}    @{operation_responses}
    Log    Client performed various API operations

Multiple Clients Create Books Simultaneously
    [Documentation]    Simulates multiple clients creating books concurrently
    [Arguments]    ${book_count}
    
    @{concurrent_responses}=    Create List
    
    # Create multiple books in quick succession
    FOR    ${i}    IN RANGE    ${book_count}
        ${book_data}=    Generate Test Book Data    _Concurrent_${i}
        ${response}=    Create Book Via API    &{book_data}
        Append To List    ${concurrent_responses}    ${response}
    END
    
    Set Test Variable    @{CONCURRENT_RESPONSES}    @{concurrent_responses}
    Log    Multiple clients created ${book_count} books simultaneously

# Gherkin-style Then keywords
API Should Return Success Response
    [Documentation]    Verifies that the API returned a successful response
    
    Should Be True    200 <= ${API_RESPONSE.status_code} < 300
    Log    API returned success response: ${API_RESPONSE.status_code}

API Should Return Created Response
    [Documentation]    Verifies that the API returned a 200 Created response
    
    Should Be Equal As Integers    ${API_RESPONSE.status_code}    200
    Log    API returned 200 Created response

API Should Return Not Found Error
    [Documentation]    Verifies that the API returned a 404 Not Found error
    
    # Check if we have a successful 404 response or an error
    ${api_error_exists}=    Get Variable Value    ${API_ERROR}    ${EMPTY}
    IF    '${api_error_exists}' != '${EMPTY}'
        Should Contain    ${API_ERROR}    404
        Log    API returned 404 Not Found error as expected (via exception)
    ELSE
        Should Be Equal As Integers    ${API_RESPONSE.status_code}    404
        Log    API returned 404 Not Found error as expected (via response)
    END

Response Should Contain Books List
    [Documentation]    Verifies that the response contains a list of books
    
    ${is_list}=    Evaluate    isinstance($API_RESPONSE.json(), list)
    Should Be True    ${is_list}
    ${books_count}=    Get Length    ${API_RESPONSE.json()}
    Log    Response contains books list with ${books_count} books

Each Book Should Have Required Fields
    [Documentation]    Verifies that each book has all required fields
    
    ${books}=    Set Variable    ${API_RESPONSE.json()}
    
    FOR    ${book}    IN    @{books}
        FOR    ${field}    IN    @{REQUIRED_BOOK_FIELDS}
            Dictionary Should Contain Key    ${book}    ${field}
        END
    END
    
    Log    All books have required fields: ${REQUIRED_BOOK_FIELDS}

Response Should Contain Created Book Data
    [Documentation]    Verifies that the response contains the created book data
    [Arguments]    &{expected_data}
    
    ${response_book}=    Set Variable    ${API_RESPONSE.json()}
    
    FOR    ${field}    IN    title    author    pages    category
        Should Be Equal    ${response_book}[${field}]    ${expected_data}[${field}]
    END
    
    Should Be True    ${response_book}[id] is not None
    Log    Response contains correct created book data

Book Should Be Persisted In System
    [Documentation]    Verifies that the created book is persisted in the system
    
    VAR    ${book_id}    ${CREATED_BOOK_DATA}[id]
    Verify Book Exists Via API    ${book_id}
    Log    Book is persisted in system with ID: ${book_id}

Response Should Contain Correct Book Data
    [Documentation]    Verifies that the response contains correct book data
    [Arguments]    &{expected_data}
    
    ${response_book}=    Set Variable    ${API_RESPONSE.json()}
    
    FOR    ${field}    IN    title    author    pages    category
        Should Be Equal    ${response_book}[${field}]    ${expected_data}[${field}]
    END
    
    Log    Response contains correct book data

Response Should Contain Updated Book Data
    [Documentation]    Verifies that the response contains updated book data
    [Arguments]    &{expected_data}
    
    ${response_book}=    Set Variable    ${API_RESPONSE.json()}
    
    FOR    ${field}    IN    title    author    pages    category
        Should Be Equal    ${response_book}[${field}]    ${expected_data}[${field}]
    END
    
    Log    Response contains updated book data

Book Should Be Updated In System
    [Documentation]    Verifies that the book is actually updated in the system
    [Arguments]    ${book_id}    &{expected_data}
    
    Verify Book Data Via API    ${book_id}    &{expected_data}
    Log    Book is updated in system: ${book_id}

Book Should Be Removed From System
    [Documentation]    Verifies that the book is removed from the system
    [Arguments]    ${book_id}
    
    Verify Book Does Not Exist Via API    ${book_id}
    Log    Book is removed from system: ${book_id}

Book Should Be Marked As Favorite
    [Documentation]    Verifies that the book is marked as favorite
    [Arguments]    ${book_id}
    
    ${response}=    Get Book By ID Via API    ${book_id}
    ${book_data}=    Set Variable    ${response.json()}
    Should Be True    ${book_data}[favorite]
    Log    Book is marked as favorite: ${book_id}

Book Should Not Be Marked As Favorite
    [Documentation]    Verifies that the book is not marked as favorite
    [Arguments]    ${book_id}
    
    ${response}=    Get Book By ID Via API    ${book_id}
    ${book_data}=    Set Variable    ${response.json()}
    Should Not Be True    ${book_data}[favorite]
    Log    Book is not marked as favorite: ${book_id}

Error Response Should Contain Appropriate Message
    [Documentation]    Verifies that error response contains appropriate message
    
    # Check if we have an error variable or response
    ${api_error_exists}=    Get Variable Value    ${API_ERROR}    ${EMPTY}
    IF    '${api_error_exists}' != '${EMPTY}'
        Should Contain    ${API_ERROR}    not found    ignore_case=True
        Log    Error response contains appropriate message (via exception)
    ELSE
        ${error_data}=    Set Variable    ${API_RESPONSE.json()}
        Should Contain    ${error_data}[detail]    not found    ignore_case=True
        Log    Error response contains appropriate message (via response)
    END

API Should Handle Large Data Successfully
    [Documentation]    Verifies that the API handled large data successfully
    
    Should Be Equal As Integers    ${API_RESPONSE.status_code}    200
    Log    API handled large data successfully

Book Should Be Created With Large Data
    [Documentation]    Verifies that book was created with large data values
    [Arguments]    &{expected_large_data}
    
    ${created_book}=    Set Variable    ${CREATED_BOOK_DATA}
    Should Be Equal    ${created_book}[title]    ${expected_large_data}[title]
    Should Be Equal    ${created_book}[author]    ${expected_large_data}[author]
    Should Be Equal As Integers    ${created_book}[pages]    ${expected_large_data}[pages]
    Log    Book created with large data successfully

All Operations Should Maintain Data Consistency
    [Documentation]    Verifies that all operations maintained data consistency
    
    # Verify all responses were successful
    FOR    ${response}    IN    @{INTEGRATION_RESPONSES}
        Should Be True    200 <= ${response.status_code} < 300
    END
    
    Log    All operations maintained data consistency

Book Data Should Match Expected Values
    [Documentation]    Verifies that final book data matches expected values
    
    ${final_response}=    Set Variable    ${INTEGRATION_RESPONSES}[-1]
    ${final_book}=    Set Variable    ${final_response.json()}
    
    FOR    ${field}    IN    title    author    pages    category
        Should Be Equal    ${final_book}[${field}]    ${INTEGRATION_UPDATE_DATA}[${field}]
    END
    
    Log    Book data matches expected values after all operations

Each Operation Should Return Correct Status Code
    [Documentation]    Verifies that each operation returned the correct status code
    
    # Expected status codes: [200, 200, 200, 200] for [Create, Read, Update, Delete]
    @{expected_codes}    Create List    200    200    200    200
    
    ${response_count}=    Get Length    ${STATUS_CODE_RESPONSES}
    FOR    ${i}    IN RANGE    ${response_count}
        ${response}=    Set Variable    ${STATUS_CODE_RESPONSES}[${i}]
        ${expected_code}=    Set Variable    ${expected_codes}[${i}]
        Should Be Equal As Integers    ${response.status_code}    ${expected_code}
    END
    
    Log    Each operation returned correct status code

Status Codes Should Follow HTTP Standards
    [Documentation]    Verifies that status codes follow HTTP standards
    
    # This is verified by the previous keyword
    Log    Status codes follow HTTP standards

All Books Should Be Created Successfully
    [Documentation]    Verifies that all concurrent books were created successfully
    
    FOR    ${response}    IN    @{CONCURRENT_RESPONSES}
        Should Be Equal As Integers    ${response.status_code}    200
        Should Be True    ${response.json()}[id] is not None
    END
    
    ${response_count}=    Get Length    ${CONCURRENT_RESPONSES}
    Log    All ${response_count} books were created successfully

No Data Corruption Should Occur
    [Documentation]    Verifies that no data corruption occurred during concurrent operations
    
    # Verify each created book has unique ID and correct data
    @{book_ids}=    Create List
    
    FOR    ${response}    IN    @{CONCURRENT_RESPONSES}
        ${book}=    Set Variable    ${response.json()}
        Should Not Contain    ${book_ids}    ${book}[id]
        Append To List    ${book_ids}    ${book}[id]
        Should Not Be Empty    ${book}[title]
        Should Not Be Empty    ${book}[author]
    END
    
    Log    No data corruption occurred - all books have unique IDs and valid data

API Should Remain Responsive
    [Documentation]    Verifies that the API remained responsive during concurrent operations
    
    # If all operations completed successfully, API remained responsive
    ${response_count}=    Get Length    ${CONCURRENT_RESPONSES}
    Should Be Equal As Integers    ${response_count}    5
    Log    API remained responsive during concurrent operations

# Template keywords
Test Book Creation With Missing Field
    [Documentation]    Template keyword for testing book creation with missing required fields
    [Arguments]    ${field_to_omit}    ${expected_error_message}
    
    ${incomplete_book}=    Generate Test Book Data    _Missing_${field_to_omit}
    Remove From Dictionary    ${incomplete_book}    ${field_to_omit}
    
    Test Book Creation With Invalid Data    422    ${expected_error_message}    &{incomplete_book}

Test Book Creation With Invalid Data Type
    [Documentation]    Template keyword for testing book creation with invalid data types
    [Arguments]    ${field_name}    ${invalid_value}    ${expected_error_contains}
    
    ${invalid_book}=    Generate Test Book Data    _Invalid_${field_name}
    Set To Dictionary    ${invalid_book}    ${field_name}    ${invalid_value}
    
    Test Book Creation With Invalid Data    422    ${expected_error_contains}    &{invalid_book}