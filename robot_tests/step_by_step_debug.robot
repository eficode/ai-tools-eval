*** Settings ***
Library          RequestsLibrary
Resource         resources/common.resource

*** Variables ***
${API_BASE_URL}       http://books-database-service:8000
${API_SESSION}        debug_api

*** Test Cases ***
Step 1 - API Session
    [Documentation]    Test API session establishment
    Create Session    ${API_SESSION}    ${API_BASE_URL}    verify=${True}
    ${response}    GET On Session    ${API_SESSION}    /books/    expected_status=200
    Log    Step 1 passed

Step 2 - Generate Data
    [Documentation]    Test data generation
    &{book_data}    Generate Unique Book Data    Step Test Book
    Log    Generated data: ${book_data}
    Log    Step 2 passed

Step 3 - Create Book
    [Documentation]    Test book creation
    Create Session    ${API_SESSION}    ${API_BASE_URL}    verify=${True}
    &{book_data}    Generate Unique Book Data    Step Test Book
    ${response}    POST On Session    ${API_SESSION}    /books/    json=&{book_data}    expected_status=200
    Set Test Variable    ${creation_response}    ${response}
    Set Test Variable    ${input_book_data}    &{book_data}
    Log    Step 3 passed

Step 4 - Extract Created Book
    [Documentation]    Test extracting created book data
    ${created_book}    Set Variable    ${creation_response.json()}
    Log    Created book: ${created_book}
    Log    Step 4 passed

Step 5 - Validate Book ID
    [Documentation]    Test book ID validation
    Create Session    ${API_SESSION}    ${API_BASE_URL}    verify=${True}
    &{book_data}    Generate Unique Book Data    Step Test Book
    ${response}    POST On Session    ${API_SESSION}    /books/    json=&{book_data}    expected_status=200
    ${created_book}    Set Variable    ${response.json()}
    Should Be Valid Book ID    ${created_book}[id]
    Log    Step 5 passed

Step 6 - Match Book Data
    [Documentation]    Test book data matching
    Create Session    ${API_SESSION}    ${API_BASE_URL}    verify=${True}
    &{book_data}    Generate Unique Book Data    Step Test Book
    ${response}    POST On Session    ${API_SESSION}    /books/    json=&{book_data}    expected_status=200
    ${created_book}    Set Variable    ${response.json()}
    Should Match Book Data    ${created_book}    ${book_data}    ignore_fields=${{['id']}}
    Log    Step 6 passed