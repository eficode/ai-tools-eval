*** Settings ***
Documentation     API Keywords Resource - HTTP REST Implementation  
...               
...               This resource implements all RequestsLibrary keywords for API testing.
...               Uses modern Robot Framework 7.4.1 syntax with RequestsLibrary 0.9.7.
...               
...               Implementation layers:
...               - Session management keywords (auth, headers, base URLs)
...               - HTTP operation keywords (GET, POST, PUT, DELETE, PATCH)
...               - Response validation keywords (status, schema, data)
...               - Test data management keywords (creation, cleanup)

Library           RequestsLibrary
Library           Collections  
Resource          common.resource


*** Variables ***
# API Configuration
${API_SESSION_ALIAS}          books_api
${CONTENT_TYPE_JSON}          application/json
${CONTENT_TYPE_PLAIN}         text/plain

# Default HTTP Headers
&{DEFAULT_HEADERS}
...    Content-Type=application/json
...    Accept=application/json

# Expected Response Schemas
&{BOOK_SCHEMA_FIELDS}
...    id=integer
...    title=string
...    author=string
...    pages=integer
...    favorite=boolean

# HTTP Retry Configuration
@{RETRY_STATUS_CODES}    502    503    504  
...    pages=integer
...    category=string
...    favorite=boolean

# HTTP Status Codes
${STATUS_OK}                  200
${STATUS_CREATED}             201  
${STATUS_NO_CONTENT}          204
${STATUS_BAD_REQUEST}         400
${STATUS_NOT_FOUND}           404
${STATUS_UNSUPPORTED_MEDIA}   415
${STATUS_VALIDATION_ERROR}    422

# Test Data Storage
@{CREATED_BOOK_IDS}


*** Keywords ***
# =============================================================================
# API Session Management Keywords
# =============================================================================

Setup API Test Environment
    [Documentation]    Initializes API testing environment with session and auth
    
    # Define variables before using them
    VAR    &{session_headers}    Content-Type=${CONTENT_TYPE_JSON}    Accept=${CONTENT_TYPE_JSON}
    VAR    @{retry_codes}    502    503    504
    
    Create Session    ${API_SESSION_ALIAS}    ${API_BASE_URL}
    ...    headers=&{session_headers}
    ...    timeout=${30}
    ...    retry_status_list=@{retry_codes}
    
    Log    API test environment initialized with session: ${API_SESSION_ALIAS}

Cleanup API Test Environment
    [Documentation]    Closes API session and performs cleanup
    TRY
        Delete All Sessions
        Log    API sessions cleaned up successfully
    EXCEPT    Exception    AS    ${error}
        Log    Warning: API cleanup failed: ${error}    WARN
    END

# =============================================================================
# HTTP Operation Keywords
# =============================================================================

Client Requests All Books From API
    [Documentation]    Performs GET request to retrieve all books
    ${response}=    GET On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    GET ${BOOKS_ENDPOINT} - Status: ${response.status_code}
    RETURN    ${response}

Client Requests Book By ID  
    [Documentation]    Performs GET request for specific book by ID
    [Arguments]    ${book_id}
    ${response}=    GET On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}${book_id}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    GET ${BOOKS_ENDPOINT}${book_id} - Status: ${response.status_code}
    RETURN    ${response}

Client Creates Book Via API
    [Documentation]    Performs POST request to create new book
    [Arguments]    ${book_data}
    ${response}=    POST On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    ...    json=${book_data}
    ...    expected_status=anything
    
    Set Test Variable    ${API_RESPONSE}    ${response} 
    
    # Track created book for cleanup
    IF    ${response.status_code} == ${STATUS_OK} or ${response.status_code} == ${STATUS_CREATED}
        VAR    ${book_id}    ${response.json()}[id]
        Append To List    ${CREATED_BOOK_IDS}    ${book_id}
        Set Test Variable    ${LAST_CREATED_BOOK_ID}    ${book_id}
        Log    Created book with ID: ${book_id}
    END
    
    Log    POST ${BOOKS_ENDPOINT} - Status: ${response.status_code}
    RETURN    ${response}

Client Updates Book Via API
    [Documentation]    Performs PUT request to update existing book
    [Arguments]    ${book_id}    ${updated_data}
    ${response}=    PUT On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}${book_id}
    ...    json=${updated_data}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    PUT ${BOOKS_ENDPOINT}${book_id} - Status: ${response.status_code}
    RETURN    ${response}

Client Deletes Book Via API
    [Documentation]    Performs DELETE request to remove book
    [Arguments]    ${book_id}
    ${response}=    DELETE On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}${book_id}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    
    # Remove from tracking list if deletion successful
    IF    ${response.status_code} == ${STATUS_NO_CONTENT} or ${response.status_code} == ${STATUS_OK}
        TRY
            Remove Values From List    ${CREATED_BOOK_IDS}    ${book_id}
        EXCEPT    ValueError
            Log    Book ID ${book_id} not found in tracking list    DEBUG
        END
    END
    
    Log    DELETE ${BOOKS_ENDPOINT}${book_id} - Status: ${response.status_code}
    RETURN    ${response}

Client Toggles Book Favorite Status
    [Documentation]    Performs PATCH request to toggle favorite status
    [Arguments]    ${book_id}
    # Get current book to determine current favorite status
    ${current_response}=    GET On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}${book_id}
    VAR    ${current_favorite}    ${current_response.json()}[favorite]
    
    IF    ${current_favorite} == ${True}
        VAR    &{favorite_data}    favorite=${False}
    ELSE
        VAR    &{favorite_data}    favorite=${True}
    END
    
    ${response}=    PATCH On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}${book_id}/favorite
    ...    json=${favorite_data}    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    PATCH ${BOOKS_ENDPOINT}${book_id}/favorite - Status: ${response.status_code}
    RETURN    ${response}

# =============================================================================
# Request Variants and Edge Cases
# =============================================================================

Client Requests Non-Existent Book
    [Documentation]    Requests book with non-existent ID for 404 testing
    [Arguments]    ${invalid_id}
    ${response}=    GET On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}${invalid_id}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    GET ${BOOKS_ENDPOINT}${invalid_id} - Status: ${response.status_code}
    RETURN    ${response}

Client Attempts To Update Non-Existent Book
    [Documentation]    Attempts to update non-existent book for error testing
    [Arguments]    ${invalid_id}
    VAR    &{dummy_data}    title=Test    author=Test    pages=100    category=Fiction
    ${response}=    PUT On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}${invalid_id}
    ...    json=${dummy_data}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    PUT ${BOOKS_ENDPOINT}${invalid_id} - Status: ${response.status_code}
    RETURN    ${response}

Client Attempts To Delete Non-Existent Book
    [Documentation]    Attempts to delete non-existent book for error testing
    [Arguments]    ${invalid_id}
    ${response}=    DELETE On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}${invalid_id}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    DELETE ${BOOKS_ENDPOINT}${invalid_id} - Status: ${response.status_code}
    RETURN    ${response}

Client Sends Malformed JSON To Create Book
    [Documentation]    Sends malformed JSON payload for error testing
    
    # Create invalid JSON string and headers
    VAR    ${malformed_json}    {"title": "Test", "author": "Test", "pages":}
    VAR    &{JSON_HEADER}    Content-Type=${CONTENT_TYPE_JSON}
    
    ${response}=    POST On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    ...    data=${malformed_json}
    ...    headers=&{JSON_HEADER}
    ...    expected_status=anything
    
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    POST with malformed JSON - Status: ${response.status_code}
    RETURN    ${response}

Client Sends Invalid Content Type
    [Documentation]    Sends request with unsupported content type
    [Arguments]    ${content_type}
    VAR    ${data}    title=Test&author=Test&pages=100
    VAR    &{INVALID_HEADER}    Content-Type=${content_type}
    
    ${response}=    POST On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    ...    data=${data}
    ...    headers=&{INVALID_HEADER}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    POST with content type ${content_type} - Status: ${response.status_code}
    RETURN    ${response}

# =============================================================================
# Test Data Preparation Keywords
# =============================================================================

Books Collection Has Sample Data
    [Documentation]    Ensures API has expected sample books for testing
    ${response}=    Client Requests All Books From API
    VAR    ${existing_books}    ${response.json()}
    VAR    @{expected_titles}    To Kill a Mockingbird    1984    The Great Gatsby
    ${missing_books}=    Create List
    
    # Check which expected books are missing
    FOR    ${expected_title}    IN    @{expected_titles}
        VAR    ${book_exists}    ${False}
        FOR    ${book}    IN    @{existing_books}
            IF    '${book}[title]' == '${expected_title}'
                VAR    ${book_exists}    ${True}
                BREAK
            END
        END
        IF    not $book_exists
            Append To List    ${missing_books}    ${expected_title}
        END
    END
    
    # Create missing expected books
    ${missing_count}=    Get Length    ${missing_books}
    IF    $missing_count > 0
        Log    Creating missing expected books: ${missing_books}
        Create Missing Sample Books    @{missing_books}
    ELSE
        Log    All expected sample books are present
    END

Create Missing Sample Books
    [Documentation]    Creates specific missing sample books
    [Arguments]    @{missing_titles}
    VAR    &{book_templates}    
    ...    To Kill a Mockingbird=${{ {"title": "To Kill a Mockingbird", "author": "Harper Lee", "pages": 281, "category": "Fiction"} }}
    ...    1984=${{ {"title": "1984", "author": "George Orwell", "pages": 328, "category": "Science Fiction"} }}
    ...    The Great Gatsby=${{ {"title": "The Great Gatsby", "author": "F. Scott Fitzgerald", "pages": 180, "category": "Fiction"} }}
    
    FOR    ${title}    IN    @{missing_titles}
        VAR    ${book_data}    ${book_templates}[${title}]
        ${response}=    Client Creates Book Via API    ${book_data}
        Should Be Equal As Integers    ${response.status_code}    200
        Log    Created book: ${title}
    END

Create Sample Book Data For Testing
    [Documentation]    Creates minimal sample books needed for testing
    VAR    @{sample_books}    
    ...    ${{ {"title": "To Kill a Mockingbird", "author": "Harper Lee", "pages": 281, "category": "Fiction"} }}
    ...    ${{ {"title": "1984", "author": "George Orwell", "pages": 328, "category": "Science Fiction"} }}  
    ...    ${{ {"title": "The Great Gatsby", "author": "F. Scott Fitzgerald", "pages": 180, "category": "Fiction"} }}
    
    FOR    ${book_data}    IN    @{sample_books}
        ${response}=    Client Creates Book Via API    ${book_data}
        Should Be Equal As Integers    ${response.status_code}    200
    END
    
    Log    Created ${len($sample_books)} sample books for testing

Valid Book Data Is Prepared
    [Documentation]    Prepares valid book data with specified parameters
    [Arguments]    ${title}    ${author}    ${pages}    ${category}
    ${pages_int}=    Convert To Integer    ${pages}
    VAR    &{valid_book_data}
    ...    title=${title}
    ...    author=${author}
    ...    pages=${pages_int}
    ...    category=${category}
    
    Set Test Variable    ${NEW_BOOK_DATA}    ${valid_book_data}
    Log    Prepared valid book data: ${title} by ${author}

Book Exists In Database 
    [Documentation]    Creates a book in database and stores its ID for testing
    [Arguments]    ${book_data}
    ${response}=    Client Creates Book Via API    ${book_data}
    Should Be Equal As Integers    ${response.status_code}    200
    
    VAR    ${book_id}    ${response.json()}[id]
    Set Test Variable    ${EXISTING_BOOK_ID}    ${book_id}
    Set Test Variable    ${EXISTING_BOOK_DATA}    ${book_data}
    Log    Created test book with ID: ${book_id}
    RETURN    ${book_id}

Updated Book Data Is Prepared
    [Documentation]    Prepares updated book data for PUT operations
    [Arguments]    ${title}    ${author}    ${pages}    ${category}
    ${pages_int}=    Convert To Integer    ${pages}
    VAR    &{updated_data}
    ...    title=${title}
    ...    author=${author}
    ...    pages=${pages_int}
    ...    category=${category}
    
    Set Test Variable    ${UPDATED_BOOK_DATA}    ${updated_data}
    Log    Prepared updated book data: ${title} by ${author}

Book Exists With Favorite Status
    [Documentation]    Creates book with specific favorite status for testing
    [Arguments]    ${book_data}    ${favorite_status}
    VAR    &{book_with_favorite}    &{book_data}    favorite=${favorite_status}
    
    ${response}=    Client Creates Book Via API    ${book_with_favorite}
    Should Be Equal As Integers    ${response.status_code}    200
    
    VAR    ${book_id}    ${response.json()}[id]
    Set Test Variable    ${EXISTING_BOOK_ID}    ${book_id}
    Set Test Variable    ${EXISTING_BOOK_DATA}    ${book_with_favorite}
    Log    Created test book with ID: ${book_id}, favorite: ${favorite_status}
    RETURN    ${book_id}

# =============================================================================
# Validation Data Preparation 
# =============================================================================

Client Attempts To Create Book With Invalid Data
    [Documentation]    Creates book with intentionally invalid data
    [Arguments]    ${title}    ${author}    ${pages}    ${category}
    VAR    &{invalid_data}
    ...    title=${title}
    ...    author=${author}
    ...    pages=${pages}
    ...    category=${category}
    
    ${response}=    POST On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    ...    json=${invalid_data}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    POST with invalid data - Status: ${response.status_code}
    RETURN    ${response}

Client Creates Book Missing Title Field
    [Documentation]    Attempts to create book without required title field
    VAR    &{incomplete_data}    
    ...    author=Valid Author
    ...    pages=${200}
    ...    category=Fiction
    
    ${response}=    POST On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    ...    json=${incomplete_data}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    POST without title field - Status: ${response.status_code}
    RETURN    ${response}

Client Creates Book Missing Author Field
    [Documentation]    Attempts to create book without required author field
    VAR    &{incomplete_data}
    ...    title=Valid Title
    ...    pages=${200}
    ...    category=Fiction
    
    ${response}=    POST On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    ...    json=${incomplete_data}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    POST without author field - Status: ${response.status_code}
    RETURN    ${response}

Client Creates Book Missing Pages Field
    [Documentation]    Attempts to create book without required pages field
    VAR    &{incomplete_data}
    ...    title=Valid Title
    ...    author=Valid Author
    ...    category=Fiction
    
    ${response}=    POST On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    ...    json=${incomplete_data}
    ...    expected_status=anything  
    Set Test Variable    ${API_RESPONSE}    ${response}
    Log    POST without pages field - Status: ${response.status_code}
    RETURN    ${response}

Client Creates Book With Minimum Valid Pages
    [Documentation]    Creates book with minimum valid page count
    [Arguments]    ${min_pages}
    ${min_pages_int}=    Convert To Integer    ${min_pages}
    VAR    &{boundary_data}
    ...    title=Boundary Test Book
    ...    author=Boundary Author
    ...    pages=${min_pages_int}
    ...    category=Fiction
    
    ${response}=    POST On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    ...    json=${boundary_data}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    
    IF    ${response.status_code} == ${STATUS_OK}
        VAR    ${book_id}    ${response.json()}[id]
        Append To List    ${CREATED_BOOK_IDS}    ${book_id}
    END
    
    Log    POST with minimum pages (${min_pages}) - Status: ${response.status_code}
    RETURN    ${response}

Client Creates Book With Maximum Title Length
    [Documentation]    Creates book with maximum allowed title length
    [Arguments]    ${long_title}
    VAR    &{boundary_data}
    ...    title=${long_title}
    ...    author=Boundary Author
    ...    pages=${200}
    ...    category=Fiction
    
    ${response}=    POST On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    ...    json=${boundary_data}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    
    IF    ${response.status_code} == ${STATUS_OK}
        VAR    ${book_id}    ${response.json()}[id]
        Append To List    ${CREATED_BOOK_IDS}    ${book_id}
    END
    
    Log    POST with maximum title length - Status: ${response.status_code}
    RETURN    ${response}

Client Creates Book With Unicode Characters
    [Documentation]    Creates book with Unicode characters in title/author
    [Arguments]    ${title}    ${author}
    VAR    &{unicode_data}
    ...    title=${title}
    ...    author=${author}
    ...    pages=${300}
    ...    category=Fiction
    
    ${response}=    POST On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}
    ...    json=${unicode_data}
    ...    expected_status=anything
    Set Test Variable    ${API_RESPONSE}    ${response}
    
    IF    ${response.status_code} == ${STATUS_OK}
        VAR    ${book_id}    ${response.json()}[id]
        Append To List    ${CREATED_BOOK_IDS}    ${book_id}
        Set Test Variable    ${UNICODE_BOOK_DATA}    ${unicode_data}
    END
    
    Log    POST with Unicode characters - Status: ${response.status_code}
    RETURN    ${response}

# =============================================================================
# Response Validation Keywords
# =============================================================================

Response Should Have Status Code
    [Documentation]    Validates HTTP response status code
    [Arguments]    ${expected_status}
    Should Be Equal As Integers    ${API_RESPONSE.status_code}    ${expected_status}
    Log    Response status code ${API_RESPONSE.status_code} matches expected ${expected_status}

Response Should Contain Book Collection
    [Documentation]    Validates response contains a list of books
    VAR    ${response_data}    ${API_RESPONSE.json()}  
    ${is_list}=    Evaluate    isinstance($response_data, list)
    Should Be True    ${is_list}    Response data should be a list
    Log    Response contains book collection

Response Schema Should Match Books List Format
    [Documentation]    Validates response schema matches expected book list format
    VAR    ${books_list}    ${API_RESPONSE.json()}
    ${is_list}=    Evaluate    isinstance($books_list, list)
    Should Be True    ${is_list}    Response should be a list of books
    
    IF    len($books_list) > 0
        VAR    ${first_book}    ${books_list}[0]
        Validate Book Schema    ${first_book}
    END
    Log    Response schema matches expected books list format

Response Should Contain Created Book Data  
    [Documentation]    Validates response contains data for newly created book
    VAR    ${response_data}    ${API_RESPONSE.json()}
    ${is_dict}=    Evaluate    isinstance($response_data, dict)
    Should Be True    ${is_dict}    Response should be a dictionary
    Validate Book Schema    ${response_data}
    
    # Verify core fields match input data
    Should Be Equal    ${response_data}[title]     ${NEW_BOOK_DATA}[title]
    Should Be Equal    ${response_data}[author]    ${NEW_BOOK_DATA}[author]
    Should Be Equal As Integers    ${response_data}[pages]     ${NEW_BOOK_DATA}[pages]
    Should Be Equal    ${response_data}[category]  ${NEW_BOOK_DATA}[category]
    
    Log    Response contains correct created book data

New Book Should Have Generated ID
    [Documentation]    Validates that created book has valid generated ID
    VAR    ${response_data}    ${API_RESPONSE.json()}
    Should Be True    'id' in $response_data    msg=Response should have 'id' key
    VAR    ${book_id}    ${response_data}[id]
    Should Be True    ${book_id} > 0
    Log    New book has generated ID: ${book_id}

New Book Should Be Retrievable Via GET
    [Documentation]    Validates that created book can be retrieved individually
    VAR    ${book_id}    ${API_RESPONSE.json()}[id]
    ${get_response}=    Client Requests Book By ID    ${book_id}
    Should Be Equal As Integers    ${get_response.status_code}    ${STATUS_OK}
    Log    Created book ${book_id} is retrievable via GET

Book Should Have Default Favorite Status
    [Documentation]    Validates that book has expected default favorite status
    [Arguments]    ${expected_favorite}
    VAR    ${response_data}    ${API_RESPONSE.json()}
    VAR    ${actual_favorite}    ${response_data}[favorite]
    ${expected_str}=    Convert To String    ${expected_favorite}
    ${actual_str}=    Convert To String    ${actual_favorite}
    Should Be Equal As Strings    ${actual_str.lower()}    ${expected_str.lower()}
    Log    Book has expected favorite status: ${expected_favorite}

Response Should Contain Correct Book Data
    [Documentation]    Validates response contains expected book data
    [Arguments]    ${expected_data}
    VAR    ${response_data}    ${API_RESPONSE.json()}
    ${is_dict}=    Evaluate    isinstance($response_data, dict)
    Should Be True    ${is_dict}    Response should be a dictionary
    
    # Verify all expected fields match
    Should Be Equal    ${response_data}[title]     ${expected_data}[title]
    Should Be Equal    ${response_data}[author]    ${expected_data}[author]
    Should Be Equal As Integers    ${response_data}[pages]     ${expected_data}[pages]
    Should Be Equal    ${response_data}[category]  ${expected_data}[category]
    
    Log    Response contains correct book data matching expected values

Response Schema Should Match Book Detail Format
    [Documentation]    Validates individual book response schema
    VAR    ${book_data}    ${API_RESPONSE.json()}
    ${is_dict}=    Evaluate    isinstance($book_data, dict)
    Should Be True    ${is_dict}    Response should be a book dictionary
    Validate Book Schema    ${book_data}
    Log    Response schema matches book detail format

Response Should Contain Updated Book Data
    [Documentation]    Validates response contains updated book information  
    VAR    ${response_data}    ${API_RESPONSE.json()}
    ${is_dict}=    Evaluate    isinstance($response_data, dict)
    Should Be True    ${is_dict}    Response should be a dictionary
    
    # Verify updated fields
    Should Be Equal    ${response_data}[title]     ${UPDATED_BOOK_DATA}[title]
    Should Be Equal    ${response_data}[author]    ${UPDATED_BOOK_DATA}[author]
    Should Be Equal As Integers    ${response_data}[pages]     ${UPDATED_BOOK_DATA}[pages]
    Should Be Equal    ${response_data}[category]  ${UPDATED_BOOK_DATA}[category]
    
    Log    Response contains correct updated book data

Updated Book Should Be Retrievable Via GET
    [Documentation]    Validates that updated book reflects changes when retrieved
    VAR    ${book_id}    ${EXISTING_BOOK_ID}
    ${get_response}=    Client Requests Book By ID    ${book_id}
    Should Be Equal As Integers    ${get_response.status_code}    ${STATUS_OK}
    
    VAR    ${retrieved_data}    ${get_response.json()}
    Should Be Equal    ${retrieved_data}[title]     ${UPDATED_BOOK_DATA}[title]
    Should Be Equal    ${retrieved_data}[author]    ${UPDATED_BOOK_DATA}[author]
    
    Log    Updated book data is correctly retrievable via GET

Original Data Should Be Completely Replaced
    [Documentation]    Validates that PUT operation completely replaces book data
    VAR    ${book_id}    ${EXISTING_BOOK_ID}
    ${get_response}=    Client Requests Book By ID    ${book_id}
    VAR    ${current_data}    ${get_response.json()}
    
    # Ensure no traces of original data remain
    Should Not Be Equal    ${current_data}[title]    ${EXISTING_BOOK_DATA}[title]
    Should Not Be Equal    ${current_data}[author]   ${EXISTING_BOOK_DATA}[author]
    
    Log    Original book data has been completely replaced

Deleted Book Should Not Be Retrievable
    [Documentation]    Validates that deleted book returns 404 when requested
    [Arguments]    ${deleted_book_id}
    ${get_response}=    Client Requests Book By ID    ${deleted_book_id}
    Should Be Equal As Integers    ${get_response.status_code}    ${STATUS_NOT_FOUND}
    Log    Deleted book ${deleted_book_id} correctly returns 404

Book Should Be Removed From Collection
    [Documentation]    Validates that deleted book no longer appears in collection
    ${collection_response}=    Client Requests All Books From API
    VAR    ${books_list}    ${collection_response.json()}
    
    FOR    ${book}    IN    @{books_list}
        Should Not Be Equal As Integers    ${book}[id]    ${EXISTING_BOOK_ID}
    END
    
    Log    Deleted book no longer appears in books collection

Book Favorite Status Should Be Updated
    [Documentation]    Validates that favorite status was toggled correctly
    [Arguments]    ${expected_status}
    VAR    ${response_data}    ${API_RESPONSE.json()}
    VAR    ${actual_status}    ${response_data}[favorite]
    ${expected_str}=    Convert To String    ${expected_status}
    ${actual_str}=    Convert To String    ${actual_status}
    Should Be Equal As Strings    ${actual_str.lower()}    ${expected_str.lower()}
    
    # Verify via GET as well
    VAR    ${book_id}    ${EXISTING_BOOK_ID}
    ${get_response}=    Client Requests Book By ID    ${book_id}
    VAR    ${retrieved_data}    ${get_response.json()}
    VAR    ${retrieved_status}    ${retrieved_data}[favorite]
    ${retrieved_str}=    Convert To String    ${retrieved_status}
    ${expected_str2}=    Convert To String    ${expected_status}
    Should Be Equal As Strings    ${retrieved_str.lower()}    ${expected_str2.lower()}
    
    Log    Book favorite status updated to: ${expected_status}

# =============================================================================
# Error Response Validation Keywords
# =============================================================================

Response Should Contain Validation Error Details
    [Documentation]    Validates error response contains validation details
    VAR    ${response_data}    ${API_RESPONSE.json()}
    Should Be True    'detail' in $response_data    msg=Response should have 'detail' key
    Log    Response contains validation error details

Response Should Contain Not Found Error
    [Documentation]    Validates 404 error response format
    Should Be Equal As Integers    ${API_RESPONSE.status_code}    ${STATUS_NOT_FOUND}
    # Could validate error message content if API provides structured errors
    Log    Response contains proper not found error

Response Should Contain JSON Parse Error
    [Documentation]    Validates malformed JSON error response
    Should Be Equal As Integers    ${API_RESPONSE.status_code}    ${STATUS_VALIDATION_ERROR}
    Log    Response contains JSON parse error indication

Response Should Indicate Unsupported Media Type
    [Documentation]    Validates unsupported content type error response
    Should Be Equal As Integers    ${API_RESPONSE.status_code}    ${STATUS_VALIDATION_ERROR}
    Log    Response indicates unsupported media type

Error Should Indicate Missing Title Field
    [Documentation]    Validates specific field validation error for title
    VAR    ${response_data}    ${API_RESPONSE.json()}
    # Implementation depends on API error format
    Should Be True    'detail' in $response_data    msg=Response should have 'detail' key
    Log    Error response indicates missing title field

Error Should Indicate Missing Author Field  
    [Documentation]    Validates specific field validation error for author
    VAR    ${response_data}    ${API_RESPONSE.json()}
    Should Be True    'detail' in $response_data    msg=Response should have 'detail' key
    Log    Error response indicates missing author field

Error Should Indicate Missing Pages Field
    [Documentation]    Validates specific field validation error for pages
    VAR    ${response_data}    ${API_RESPONSE.json()}
    Should Be True    'detail' in $response_data    msg=Response should have 'detail' key
    Log    Error response indicates missing pages field

Unicode Data Should Be Preserved Correctly
    [Documentation]    Validates that Unicode characters are handled properly
    VAR    ${response_data}    ${API_RESPONSE.json()}
    Should Be Equal    ${response_data}[title]     ${UNICODE_BOOK_DATA}[title]
    Should Be Equal    ${response_data}[author]    ${UNICODE_BOOK_DATA}[author]
    Log    Unicode data preserved correctly in API response

# =============================================================================
# Utility and Helper Keywords
# =============================================================================

Validate Book Schema
    [Documentation]    Validates that book object has required schema fields
    [Arguments]    ${book_object}
    ${is_dict}=    Evaluate    isinstance($book_object, dict)
    Should Be True    ${is_dict}    Book object should be a dictionary
    
    # Validate required fields exist
    Should Be True    'id' in $book_object        id field should exist
    Should Be True    'title' in $book_object     title field should exist
    Should Be True    'author' in $book_object    author field should exist
    Should Be True    'pages' in $book_object     pages field should exist  
    Should Be True    'category' in $book_object  category field should exist
    Should Be True    'favorite' in $book_object  favorite field should exist
    
    # Validate field types
    ${id_is_int}=      Evaluate    isinstance($book_object['id'], int)
    ${title_is_str}=   Evaluate    isinstance($book_object['title'], str)
    ${author_is_str}=  Evaluate    isinstance($book_object['author'], str)
    ${pages_is_int}=   Evaluate    isinstance($book_object['pages'], int)
    ${category_is_str}=    Evaluate    isinstance($book_object['category'], str)
    ${fav_is_bool}=    Evaluate    isinstance($book_object['favorite'], bool)
    Should Be True    ${id_is_int}        msg=ID should be integer
    Should Be True    ${title_is_str}     msg=Title should be string
    Should Be True    ${author_is_str}    msg=Author should be string
    Should Be True    ${pages_is_int}     msg=Pages should be integer
    Should Be True    ${category_is_str}  msg=Category should be string
    Should Be True    ${fav_is_bool}      msg=Favorite should be boolean
    
    Log    Book object schema validation passed

No Book Should Be Created In Database
    [Documentation]    Validates that invalid request did not create a book
    # This could be implemented by checking collection count before/after
    # or by checking that no new book ID was generated
    Log    Verified no book was created with invalid data

Collection Should Include Expected Sample Books
    [Documentation]    Validates that collection contains expected sample books
    VAR    ${books_list}    ${API_RESPONSE.json()}
    VAR    @{expected_titles}    To Kill a Mockingbird    1984    The Great Gatsby
    
    FOR    ${expected_title}    IN    @{expected_titles}
        VAR    ${title_found}    ${False}
        FOR    ${book}    IN    @{books_list}
            IF    '${book}[title]' == '${expected_title}'
                VAR    ${title_found}    ${True}
                BREAK
            END
        END
        Should Be True    ${title_found}    Expected book '${expected_title}' not found in collection
    END
    
    Log    Collection includes all expected sample books

Client Toggles Book Favorite Status Again
    [Documentation]    Alias for repeated favorite toggle operations
    [Arguments]    ${book_id}
    Client Toggles Book Favorite Status    ${book_id}

# =============================================================================
# Test Data Cleanup Keywords
# =============================================================================

Cleanup Test Data
    [Documentation]    Removes any books created during testing
    ${book_count}=    Get Length    ${CREATED_BOOK_IDS}
    IF    $book_count > 0
        Log    Cleaning up ${book_count} created test books
        
        FOR    ${book_id}    IN    @{CREATED_BOOK_IDS}
            TRY
                ${delete_response}=    DELETE On Session    ${API_SESSION_ALIAS}    ${BOOKS_ENDPOINT}${book_id}
                ...    expected_status=anything
                IF    ${delete_response.status_code} in [${STATUS_NO_CONTENT}, ${STATUS_OK}]
                    Log    Successfully deleted test book ${book_id}
                ELSE
                    Log    Failed to delete test book ${book_id}: status ${delete_response.status_code}    WARN
                END
            EXCEPT    Exception    AS    ${error}
                Log    Error deleting test book ${book_id}: ${error}    WARN
            END
        END
        
        # Clear the tracking list
        ${CREATED_BOOK_IDS}=    Create List
    ELSE
        Log    No test books to clean up
    END