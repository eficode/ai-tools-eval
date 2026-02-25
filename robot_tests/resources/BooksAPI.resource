*** Settings ***
Documentation     Books API Resource - REST API interactions for the Books service
...               
...               This resource file encapsulates all API interactions with the Books service.
...               It provides keywords for CRUD operations and response validation.

Library           RequestsLibrary
Library           Collections
Resource          common.resource

*** Keywords ***
Create API Session
    [Documentation]    Creates a new HTTP session for the Books API
    ...                
    ...                This keyword:
    ...                - Creates a session with alias 'books_api'
    ...                - Sets appropriate headers (Content-Type, Accept)
    ...                - Configures timeout and SSL verification
    
    VAR    &{headers}
    ...    Content-Type=application/json
    ...    Accept=application/json
    
    Create Session
    ...    alias=books_api
    ...    url=${BASE_URL}
    ...    headers=&{headers}
    ...    verify=True
    ...    timeout=${LONG_TIMEOUT}
    
    Log    API session created for: ${BASE_URL}

Close API Session
    [Documentation]    Closes all API sessions
    
    Delete All Sessions
    Log    All API sessions closed

Verify API Is Available
    [Documentation]    Verifies that the Books API is available and responding
    
    ${response}=    GET On Session    books_api    ${API_ENDPOINT}    expected_status=200
    Log    Books API is available and healthy

Create Book Via API
    [Documentation]    Creates a new book via POST request
    ...                
    ...                Arguments:
    ...                - book_data: Dictionary containing book information
    ...                  (title, author, pages, category, favorite)
    ...                
    ...                Returns:
    ...                - response: HTTP response object
    ...                
    ...                Example:
    ...                | &{book}= | Generate Unique Book Data |
    ...                | ${response}= | Create Book Via API | ${book} |
    [Arguments]    &{book_data}
    
    ${response}=    POST On Session
    ...    alias=books_api
    ...    url=${API_ENDPOINT}
    ...    json=&{book_data}
    ...    expected_status=200
    
    Request Should Be Successful    ${response}
    Log    Book created successfully: ${book_data}[title]
    RETURN    ${response}

Get All Books Via API
    [Documentation]    Retrieves all books via GET request
    ...                
    ...                Returns:
    ...                - response: HTTP response object containing list of books
    
    ${response}=    GET On Session    books_api    ${API_ENDPOINT}
    Status Should Be    200    ${response}
    Log    Retrieved all books from API
    RETURN    ${response}

Get Book By ID Via API
    [Documentation]    Retrieves a specific book by ID via GET request
    ...                
    ...                Arguments:
    ...                - book_id: ID of the book to retrieve
    ...                
    ...                Returns:
    ...                - response: HTTP response object containing book data
    [Arguments]    ${book_id}
    
    ${response}=    GET On Session    books_api    ${API_ENDPOINT}${book_id}
    Status Should Be    200    ${response}
    Log    Retrieved book with ID: ${book_id}
    RETURN    ${response}

Update Book Via API
    [Documentation]    Updates an existing book via PUT request
    ...                
    ...                Arguments:
    ...                - book_id: ID of the book to update
    ...                - update_data: Dictionary containing fields to update
    ...                
    ...                Returns:
    ...                - response: HTTP response object
    [Arguments]    ${book_id}    &{update_data}
    
    ${response}=    PUT On Session
    ...    alias=books_api
    ...    url=${API_ENDPOINT}${book_id}
    ...    json=&{update_data}
    ...    expected_status=200
    
    Log    Book updated successfully: ID ${book_id}
    RETURN    ${response}

Delete Book Via API
    [Documentation]    Deletes a book via DELETE request
    ...                
    ...                Arguments:
    ...                - book_id: ID of the book to delete
    [Arguments]    ${book_id}
    
    TRY
        ${response}=    DELETE On Session    books_api    ${API_ENDPOINT}${book_id}    expected_status=200
        Log    Book deleted successfully: ID ${book_id}
    EXCEPT    AS    ${error}
        Log    Failed to delete book ${book_id}: ${error}    level=WARN
    END

Verify Book Exists Via API
    [Documentation]    Verifies that a book with the given ID exists
    ...                
    ...                Arguments:
    ...                - book_id: ID of the book to verify
    [Arguments]    ${book_id}
    
    ${response}=    GET On Session    books_api    ${API_ENDPOINT}${book_id}
    Status Should Be    200    ${response}
    Log    Verified book exists: ID ${book_id}

Verify Book Does Not Exist Via API
    [Documentation]    Verifies that a book with the given ID does not exist
    ...                
    ...                Arguments:
    ...                - book_id: ID of the book to verify
    [Arguments]    ${book_id}
    
    ${response}=    GET On Session    books_api    ${API_ENDPOINT}${book_id}    expected_status=404
    Status Should Be    404    ${response}
    Log    Verified book does not exist: ID ${book_id}

Extract Book ID From Response
    [Documentation]    Extracts the book ID from an API response
    ...                
    ...                Arguments:
    ...                - response: HTTP response object
    ...                
    ...                Returns:
    ...                - book_id: Extracted book ID
    [Arguments]    ${response}
    
    ${json_data}=    Set Variable    ${response.json()}
    ${book_id}=    Set Variable    ${json_data}[id]
    Log    Extracted book ID: ${book_id}
    RETURN    ${book_id}

Verify Response Contains Book Data
    [Documentation]    Verifies that the response contains expected book data
    ...                
    ...                Arguments:
    ...                - response: HTTP response object
    ...                - expected_data: Dictionary of expected field values
    [Arguments]    ${response}    &{expected_data}
    
    ${json_data}=    Set Variable    ${response.json()}
    
    FOR    ${key}    ${expected_value}    IN    &{expected_data}
        Dictionary Should Contain Key    ${json_data}    ${key}
        Should Be Equal    ${json_data}[${key}]    ${expected_value}
        Log    Verified field ${key} = ${expected_value}
    END

Verify Response Contains Required Fields
    [Documentation]    Verifies that the response contains all required book fields
    ...                
    ...                Arguments:
    ...                - response: HTTP response object
    [Arguments]    ${response}
    
    ${json_data}=    Set Variable    ${response.json()}
    @{required_fields}=    Create List    id    title    author    pages    category    favorite
    
    FOR    ${field}    IN    @{required_fields}
        Dictionary Should Contain Key    ${json_data}    ${field}
        Log    Verified required field exists: ${field}
    END

Get Book Count From Response
    [Documentation]    Returns the number of books in the API response
    ...                
    ...                Arguments:
    ...                - response: HTTP response object containing list of books
    ...                
    ...                Returns:
    ...                - count: Number of books in the response
    [Arguments]    ${response}
    
    ${books}=    Set Variable    ${response.json()}
    ${count}=    Get Length    ${books}
    Log    Response contains ${count} books
    RETURN    ${count}

Find Book By Title In Response
    [Documentation]    Finds a book by title in the API response
    ...                
    ...                Arguments:
    ...                - response: HTTP response object containing list of books
    ...                - title: Title to search for
    ...                
    ...                Returns:
    ...                - book: Book dictionary if found, None otherwise
    [Arguments]    ${response}    ${title}
    
    ${books}=    Set Variable    ${response.json()}
    ${book}=    Set Variable    ${None}
    
    FOR    ${current_book}    IN    @{books}
        IF    '${current_book}[title]' == '${title}'
            ${book}=    Set Variable    ${current_book}
            Log    Found book: ${title}
            BREAK
        END
    END
    
    RETURN    ${book}

Verify Book In List
    [Documentation]    Verifies that a book with the given ID exists in the books list
    ...                
    ...                Arguments:
    ...                - response: HTTP response object containing list of books
    ...                - book_id: ID of the book to find
    [Arguments]    ${response}    ${book_id}
    
    ${books}=    Set Variable    ${response.json()}
    @{book_ids}=    Create List
    
    FOR    ${book}    IN    @{books}
        Append To List    ${book_ids}    ${book}[id]
    END
    
    List Should Contain Value    ${book_ids}    ${book_id}
    Log    Verified book ${book_id} exists in list

Verify Book Not In List
    [Documentation]    Verifies that a book with the given ID does not exist in the books list
    ...                
    ...                Arguments:
    ...                - response: HTTP response object containing list of books
    ...                - book_id: ID of the book to verify is absent
    [Arguments]    ${response}    ${book_id}
    
    ${books}=    Set Variable    ${response.json()}
    @{book_ids}=    Create List
    
    FOR    ${book}    IN    @{books}
        Append To List    ${book_ids}    ${book}[id]
    END
    
    List Should Not Contain Value    ${book_ids}    ${book_id}
    Log    Verified book ${book_id} does not exist in list
