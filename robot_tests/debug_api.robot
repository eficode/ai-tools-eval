*** Settings ***
Library          RequestsLibrary
Resource         resources/common.resource

*** Variables ***
${API_BASE_URL}       http://books-database-service:8000
${API_SESSION}        debug_api

*** Test Cases ***
Debug API Session
    [Documentation]    Debug API session establishment
    Create Session    ${API_SESSION}    ${API_BASE_URL}    verify=${True}
    ${response}    GET On Session    ${API_SESSION}    /books/    expected_status=200
    Log    GET Response status: ${response.status_code}

Debug Book Creation
    [Documentation]    Debug book creation
    Create Session    ${API_SESSION}    ${API_BASE_URL}    verify=${True}
    &{book_data}    Create Dictionary    title=Debug Book    author=Debug Author    pages=100    category=Fiction    favorite=${False}
    ${response}    POST On Session    ${API_SESSION}    /books/    json=&{book_data}    expected_status=any
    Log    POST Response status: ${response.status_code}
    Log    POST Response headers: ${response.headers}
    Log    POST Response body: ${response.text}

Debug Book Validation
    [Documentation]    Debug book validation
    Create Session    ${API_SESSION}    ${API_BASE_URL}    verify=${True}
    &{book_data}    Create Dictionary    title=Debug Book 2    author=Debug Author 2    pages=${200}    category=Fiction    favorite=${False}
    Set To Dictionary    ${book_data}    pages    ${200}    # Ensure integer type
    ${response}    POST On Session    ${API_SESSION}    /books/    json=&{book_data}    expected_status=200
    ${created_book}    Set Variable    ${response.json()}
    Log    Created book: ${created_book}
    Should Be Valid Book ID    ${created_book}[id]
    Should Match Book Data    ${created_book}    ${book_data}    ignore_fields=${{['id']}}