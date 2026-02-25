*** Settings ***
Documentation     API-specific keywords for Books REST API testing
...               Provides reusable keywords for all HTTP operations

Library           RequestsLibrary
Library           Collections
Resource          common.resource


*** Keywords ***
Setup Books API Session
    [Documentation]    Creates HTTP session for Books API with default headers
    Create Session    books_api    ${API_BASE_URL}
    ...    verify=${True}
    ...    headers={"Content-Type": "application/json", "Accept": "application/json"}
    Log    API session created for ${API_BASE_URL}    console=True

Teardown Books API Session
    [Documentation]    Closes all HTTP sessions
    Delete All Sessions
    Log    All API sessions closed    console=True

Get All Books Via API
    [Documentation]    Retrieves all books from the API
    ...                Returns the response object for validation
    ${response}=    GET On Session    books_api    /books/
    ...    expected_status=200
    ...    timeout=${API_TIMEOUT}
    RETURN    ${response}

Create Book Via API
    [Documentation]    Creates a new book via POST request
    [Arguments]    &{book_data}
    ${response}=    POST On Session    books_api    /books/
    ...    json=${book_data}
    ...    expected_status=200
    ...    timeout=${API_TIMEOUT}
    Log    Book created: ${book_data}[title]    console=True
    RETURN    ${response}

Get Book By ID Via API
    [Documentation]    Retrieves a specific book by its ID
    [Arguments]    ${book_id}
    ${response}=    GET On Session    books_api    /books/${book_id}
    ...    expected_status=200
    ...    timeout=${API_TIMEOUT}
    RETURN    ${response}

Update Book Via API
    [Documentation]    Updates an existing book via PUT request
    [Arguments]    ${book_id}    &{book_data}
    ${response}=    PUT On Session    books_api    /books/${book_id}
    ...    json=${book_data}
    ...    expected_status=200
    ...    timeout=${API_TIMEOUT}
    Log    Book updated: ID ${book_id}    console=True
    RETURN    ${response}

Delete Book Via API
    [Documentation]    Deletes a book by its ID
    [Arguments]    ${book_id}
    ${response}=    DELETE On Session    books_api    /books/${book_id}
    ...    expected_status=200
    ...    timeout=${API_TIMEOUT}
    Log    Book deleted: ID ${book_id}    console=True
    RETURN    ${response}

Toggle Book Favorite Via API
    [Documentation]    Toggles the favorite status of a book
    [Arguments]    ${book_id}    ${favorite_status}=${True}
    VAR    &{favorite_data}    favorite=${favorite_status}
    ${response}=    PATCH On Session    books_api    /books/${book_id}/favorite
    ...    json=${favorite_data}
    ...    expected_status=200
    ...    timeout=${API_TIMEOUT}
    Log    Book ${book_id} favorite status set to: ${favorite_status}    console=True
    RETURN    ${response}

Verify Book Exists In Response
    [Documentation]    Validates that a book with specific title exists in API response
    [Arguments]    ${response}    ${expected_title}
    ${books}=    Set Variable    ${response.json()}
    VAR    ${found}    ${False}
    
    FOR    ${book}    IN    @{books}
        IF    '${book['title']}' == '${expected_title}'
            VAR    ${found}    ${True}
            BREAK
        END
    END
    
    Should Be True    ${found}    msg=Book with title '${expected_title}' not found in response

Verify Book Data Matches
    [Documentation]    Validates that book data in response matches expected values
    [Arguments]    ${response}    &{expected_data}
    ${book}=    Set Variable    ${response.json()}
    
    FOR    ${key}    ${value}    IN    &{expected_data}
        IF    '${key}' == 'pages' or '${key}' == 'year'
            Should Be Equal As Integers    ${book['${key}']}    ${value}
            ...    msg=Book ${key} mismatch: expected '${value}', got '${book['${key}']}'
        ELSE
            Should Be Equal    ${book['${key}']}    ${value}
            ...    msg=Book ${key} mismatch: expected '${value}', got '${book['${key}']}'
        END
    END

Verify Book Does Not Exist
    [Documentation]    Verifies that a book with given ID returns 404
    [Arguments]    ${book_id}
    TRY
        ${response}=    GET On Session    books_api    /books/${book_id}
        ...    expected_status=404
        ...    timeout=${API_TIMEOUT}
        Log    Verified book ${book_id} does not exist (404 received)    console=True
    EXCEPT    AS    ${error}
        Log    Error message: ${error}    WARN
        Fail    Expected 404 status for non-existent book ${book_id}
    END

Count Books In Response
    [Documentation]    Returns the number of books in API response
    [Arguments]    ${response}
    ${books}=    Set Variable    ${response.json()}
    ${count}=    Get Length    ${books}
    RETURN    ${count}
