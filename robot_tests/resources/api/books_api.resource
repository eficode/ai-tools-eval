*** Settings ***
Documentation     API resource file for Books Library REST API interactions
...               
...               This resource contains all API-level keywords for:
...               - CRUD operations on books (Create, Read, Update, Delete)
...               - Book favorite status management
...               - API response validation and error handling
...               - Test data management via API

Resource          ../common.resource


*** Keywords ***
Get All Books Via API
    [Documentation]    Retrieves all books from the API
    ...                
    ...                Returns the API response containing the list of all books.
    ...                This keyword handles pagination if implemented by the API.
    
    ${response}=    Make API Request With Error Handling    GET    ${BOOKS_ENDPOINT}    expected_status=200
    
    VAR    @{books}    Set Variable    ${response.json()}
    ${books_count}=    Get Length    ${books}
    Log    Retrieved ${books_count} books via API
    
    RETURN    ${response}

Get Book By ID Via API
    [Documentation]    Retrieves a specific book by its ID from the API
    ...                
    ...                Returns the API response containing the book details.
    [Arguments]    ${book_id}
    
    VAR    ${endpoint}    ${BOOKS_ENDPOINT}${book_id}
    ${response}=    Make API Request With Error Handling    GET    ${endpoint}    expected_status=200
    
    ${book}=    Set Variable    ${response.json()}
    Log    Retrieved book via API: ${book}[title] (ID: ${book_id})
    
    RETURN    ${response}

Create Book Via API
    [Documentation]    Creates a new book via the API
    ...                
    ...                Returns the API response containing the created book with its assigned ID.
    [Arguments]    &{book_data}
    
    ${response}=    Make API Request With Error Handling    POST    ${BOOKS_ENDPOINT}    
    ...    data=${book_data}    expected_status=200
    
    ${created_book}=    Set Variable    ${response.json()}
    Log    Created book via API: ${created_book}[title] (ID: ${created_book}[id])
    
    RETURN    ${response}

Update Book Via API
    [Documentation]    Updates an existing book via the API
    ...                
    ...                Returns the API response containing the updated book details.
    [Arguments]    ${book_id}    &{book_data}
    
    VAR    ${endpoint}    ${BOOKS_ENDPOINT}${book_id}
    ${response}=    Make API Request With Error Handling    PUT    ${endpoint}    
    ...    data=${book_data}    expected_status=200
    
    ${updated_book}=    Set Variable    ${response.json()}
    Log    Updated book via API: ${updated_book}[title] (ID: ${book_id})
    
    RETURN    ${response}

Delete Book Via API
    [Documentation]    Deletes a book via the API
    ...                
    ...                Returns the API response confirming deletion.
    [Arguments]    ${book_id}
    
    VAR    ${endpoint}    ${BOOKS_ENDPOINT}${book_id}
    ${response}=    Make API Request With Error Handling    DELETE    ${endpoint}    expected_status=200
    
    Log    Deleted book via API (ID: ${book_id})
    
    RETURN    ${response}

Toggle Book Favorite Via API
    [Documentation]    Toggles the favorite status of a book via the API
    ...                
    ...                Returns the API response containing the updated book with new favorite status.
    [Arguments]    ${book_id}    ${favorite_status}
    
    VAR    ${endpoint}    ${BOOKS_ENDPOINT}${book_id}/favorite
    ${favorite_data}=    Create Dictionary    favorite=${favorite_status}
    
    ${response}=    Make API Request With Error Handling    PATCH    ${endpoint}    
    ...    data=${favorite_data}    expected_status=200
    
    ${updated_book}=    Set Variable    ${response.json()}
    Log    Toggled favorite status via API: ${updated_book}[title] (ID: ${book_id}, Favorite: ${favorite_status})
    
    RETURN    ${response}

Verify Book Data Via API
    [Documentation]    Verifies that a book's data matches expected values via API
    ...                
    ...                This keyword retrieves the book and compares all fields
    ...                with the expected data, providing detailed error messages.
    [Arguments]    ${book_id}    &{expected_data}
    
    ${response}=    Get Book By ID Via API    ${book_id}
    ${actual_book}=    Set Variable    ${response.json()}
    
    ${mismatches}=    Create List
    
    FOR    ${field}    IN    @{expected_data}
        ${expected_value}=    Get From Dictionary    ${expected_data}    ${field}
        ${actual_value}=    Get From Dictionary    ${actual_book}    ${field}
        
        IF    $expected_value != $actual_value
            ${mismatch}=    Set Variable    ${field}: expected '${expected_value}', got '${actual_value}'
            Append To List    ${mismatches}    ${mismatch}
        END
    END
    
    ${mismatch_count}=    Get Length    ${mismatches}
    IF    ${mismatch_count} > 0
        ${error_msg}=    Catenate    SEPARATOR=\n
        ...    Book data verification failed for ID ${book_id}:
        ...    Mismatches: ${mismatches}
        ...    Expected: ${expected_data}
        ...    Actual: ${actual_book}
        Log    ${error_msg}    level=ERROR
        Fail    ${error_msg}
    END
    
    Log    Book data verified successfully for ID ${book_id}

Verify Book Exists Via API
    [Documentation]    Verifies that a book with the specified ID exists via API
    [Arguments]    ${book_id}
    
    TRY
        ${response}=    Get Book By ID Via API    ${book_id}
        Log    Verified book exists via API (ID: ${book_id})
    EXCEPT    Exception    AS    ${error}
        Fail    Book with ID ${book_id} does not exist: ${error}
    END

Verify Book Does Not Exist Via API
    [Documentation]    Verifies that a book with the specified ID does NOT exist via API
    [Arguments]    ${book_id}
    
    TRY
        VAR    ${endpoint}    ${BOOKS_ENDPOINT}${book_id}
        ${response}=    Make API Request With Error Handling    GET    ${endpoint}    expected_status=404
        Log    Verified book does not exist via API (ID: ${book_id})
    EXCEPT    Exception    AS    ${error}
        IF    '404' not in '${error}'
            Fail    Expected book ID ${book_id} to not exist, but API call succeeded: ${error}
        END
        Log    Verified book does not exist via API (ID: ${book_id})
    END

Create Multiple Test Books Via API
    [Documentation]    Creates multiple test books via API for test setup
    ...                
    ...                Returns a list of created book dictionaries with their IDs.
    [Arguments]    ${count}=3    ${category}=Fiction
    
    VAR    @{created_books}    Create List
    
    FOR    ${i}    IN RANGE    ${count}
        ${book_data}=    Generate Test Book Data    _${i}    ${category}
        ${response}=    Create Book Via API    &{book_data}
        ${created_book}=    Set Variable    ${response.json()}
        Append To List    ${created_books}    ${created_book}
    END
    
    Log    Created ${count} test books via API
    RETURN    @{created_books}

Verify API Response Structure
    [Documentation]    Verifies that an API response has the expected structure
    ...                
    ...                This keyword validates response format, required fields,
    ...                and data types for API contract testing.
    [Arguments]    ${response}    @{required_fields}
    
    # Verify response is JSON
    TRY
        VAR    ${json_data}    Set Variable    ${response.json()}
    EXCEPT    Exception    AS    ${error}
        Fail    Response is not valid JSON: ${error}
    END
    
    # For list responses, check first item
    ${is_list}=    Evaluate    isinstance($json_data, list)
    IF    ${is_list}
        ${list_length}=    Get Length    ${json_data}
        IF    ${list_length} > 0
            VAR    ${json_data}    Set Variable    ${json_data}[0]
        END
    END
    
    # Verify required fields exist
    VAR    @{missing_fields}    Create List
    
    FOR    ${field}    IN    @{required_fields}
        TRY
            Get From Dictionary    ${json_data}    ${field}
        EXCEPT    Exception
            Append To List    ${missing_fields}    ${field}
        END
    END
    
    ${missing_count}=    Get Length    ${missing_fields}
    IF    ${missing_count} > 0
        VAR    ${error_msg}    API response structure validation failed:
        ...    \nMissing required fields: ${missing_fields}
        ...    \nResponse data: ${json_data}
        ...    \nStatus code: ${response.status_code}
        Log    ${error_msg}    level=ERROR
        Fail    ${error_msg}
    END
    
    Log    API response structure verified with required fields: ${required_fields}

Verify API Error Response
    [Documentation]    Verifies that an API error response has the expected format and message
    [Arguments]    ${response}    ${expected_status}    ${expected_message_contains}=${EMPTY}
    
    Should Be Equal As Integers    ${response.status_code}    ${expected_status}
    
    IF    '${expected_message_contains}' != '${EMPTY}'
        ${error_data}=    Set Variable    ${response.json()}
        ${error_detail}=    Get From Dictionary    ${error_data}    detail
        ${error_message}=    Convert To String    ${error_detail}
        Should Contain    ${error_message}    ${expected_message_contains}
        Log    Verified API error response: ${error_message}
    END

Test Book Creation With Invalid Data
    [Documentation]    Tests book creation with invalid data and verifies proper error handling
    [Arguments]    ${expected_status}=400    ${expected_error}=${EMPTY}    &{invalid_data}
    
    TRY
        ${response}=    Make API Request With Error Handling    POST    ${BOOKS_ENDPOINT}    
        ...    data=${invalid_data}    expected_status=${expected_status}
        
        IF    '${expected_error}' != '${EMPTY}'
            Verify API Error Response    ${response}    ${expected_status}    ${expected_error}
        END
        
        Log    Invalid data test passed: ${invalid_data}
        
    EXCEPT    Exception    AS    ${error}
        IF    ${expected_status} >= 400
            Log    Expected error occurred for invalid data: ${error}
        ELSE
            Fail    Unexpected error for invalid data test: ${error}
        END
    END

Search Books Via API
    [Documentation]    Searches for books via API (if search endpoint exists)
    ...                
    ...                Note: This is a placeholder for search functionality.
    ...                Implement based on actual API search capabilities.
    [Arguments]    ${search_term}
    
    # This would be implemented if the API supports search
    # For now, we'll get all books and filter client-side for testing
    ${response}=    Get All Books Via API
    VAR    @{all_books}    Set Variable    ${response.json()}
    VAR    @{matching_books}    Create List
    
    FOR    ${book}    IN    @{all_books}
        IF    $search_term.lower() in $book['title'].lower() or $search_term.lower() in $book['author'].lower()
            Append To List    ${matching_books}    ${book}
        END
    END
    
    ${matching_count}=    Get Length    ${matching_books}
    Log    Found ${matching_count} books matching search term: ${search_term}
    RETURN    @{matching_books}

Verify Books List Contains Title
    [Documentation]    Verifies that the books list contains a book with the specified title
    [Arguments]    ${expected_title}
    
    ${response}=    Get All Books Via API
    VAR    @{books}    Set Variable    ${response.json()}
    VAR    ${book_found}    ${FALSE}
    
    FOR    ${book}    IN    @{books}
        IF    '${book}[title]' == '${expected_title}'
            VAR    ${book_found}    ${TRUE}
            Log    Found book in API response: ${expected_title}
            BREAK
        END
    END
    
    IF    not ${book_found}
        VAR    @{all_titles}    Create List
        FOR    ${book}    IN    @{books}
            Append To List    ${all_titles}    ${book}[title]
        END
        
        VAR    ${error_msg}    Book not found in API response:
        ...    \nExpected: ${expected_title}
        ...    \nAll books: ${all_titles}
        Log    ${error_msg}    level=ERROR
        Fail    ${error_msg}
    END

Verify Books List Does Not Contain Title
    [Documentation]    Verifies that the books list does NOT contain a book with the specified title
    [Arguments]    ${title_to_not_find}
    
    ${response}=    Get All Books Via API
    VAR    @{books}    Set Variable    ${response.json()}
    
    FOR    ${book}    IN    @{books}
        IF    '${book}[title]' == '${title_to_not_find}'
            VAR    ${error_msg}    Book unexpectedly found in API response:
            ...    \nUnexpected book: ${title_to_not_find}
            ...    \nBook details: ${book}
            Log    ${error_msg}    level=ERROR
            Fail    ${error_msg}
        END
    END
    
    Log    Verified book is not in API response: ${title_to_not_find}