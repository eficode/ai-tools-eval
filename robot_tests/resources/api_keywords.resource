*** Settings ***
Documentation    API interaction keywords for Books application

*** Keywords ***
Create Book Via API
    [Arguments]    ${title}    ${author}    ${pages}    ${category}
    [Documentation]    Create book via POST /books
    &{book_data}=    Create Dictionary    title=${title}    author=${author}    pages=${pages}    category=${category}
    ${response}=    POST On Session    api    /books/    json=${book_data}
    Status Should Be    200    ${response}
    ${json}=    Set Variable    ${response.json()}
    ${book_id}=    Set Variable    ${json}[id]
    Set Test Variable    ${BOOK_ID}    ${book_id}
    RETURN    ${book_id}

Get All Books Via API
    [Documentation]    Retrieve all books via GET /books
    ${response}=    GET On Session    api    /books/
    Status Should Be    200    ${response}
    RETURN    ${response}

Get Book By ID Via API
    [Arguments]    ${book_id}
    [Documentation]    Retrieve specific book via GET /books/{id}
    ${response}=    GET On Session    api    /books/${book_id}
    Status Should Be    200    ${response}
    RETURN    ${response}

Update Book Via API
    [Arguments]    ${book_id}    ${title}    ${author}    ${pages}    ${category}
    [Documentation]    Update book via PUT /books/{id}
    &{book_data}=    Create Dictionary    title=${title}    author=${author}    pages=${pages}    category=${category}
    ${response}=    PUT On Session    api    /books/${book_id}    json=${book_data}
    Status Should Be    200    ${response}
    RETURN    ${response}

Delete Book Via API
    [Arguments]    ${book_id}
    [Documentation]    Delete book via DELETE /books/{id}
    ${response}=    DELETE On Session    api    /books/${book_id}
    Status Should Be    200    ${response}

Response Should Contain Books
    [Arguments]    ${response}
    [Documentation]    Validate response contains book list
    ${books}=    Set Variable    ${response.json()}
    Should Not Be Empty    ${books}

Book Should Have Valid Structure
    [Arguments]    ${book}
    [Documentation]    Validate book object structure
    Dictionary Should Contain Key    ${book}    id
    Dictionary Should Contain Key    ${book}    title
    Dictionary Should Contain Key    ${book}    author
    Dictionary Should Contain Key    ${book}    pages
    Dictionary Should Contain Key    ${book}    category
