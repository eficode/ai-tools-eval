*** Settings ***
Documentation     Books Library API Test Suite - REST API Validation
...               
...               This test suite validates the Books Library REST API endpoints
...               using modern Robot Framework 7.4.1 syntax with full HTTP operations.
...               
...               API endpoints tested:
...               - GET /books/ (list all books)
...               - POST /books/ (create new book)  
...               - GET /books/{id} (get specific book)
...               - PUT /books/{id} (update existing book)
...               - DELETE /books/{id} (delete book)
...               - PATCH /books/{id}/favorite (toggle favorite status)

Resource          resources/common.resource  
Resource          resources/api_keywords.resource

Suite Setup       Setup API Test Environment
Suite Teardown    Cleanup API Test Environment
Test Setup        Generate Unique Test Data
Test Teardown     Cleanup Test Data

Force Tags        books    api    rest
Default Tags      integration


*** Variables ***
# Using API_BASE_URL and BOOKS_ENDPOINT from common.resource


*** Test Cases ***
API Should Return All Books When Getting Book Collection
    [Documentation]    Validates GET /books/ endpoint returns book collection
    [Tags]    books    api    get    collection    happy-path
    Given Books Collection Has Sample Data
    When Client Requests All Books From API
    Then Response Should Have Status Code    200
    And Response Should Contain Book Collection
    And Response Schema Should Match Books List Format
    And Collection Should Include Expected Sample Books

API Should Create New Book With Valid Data
    [Documentation]    Validates POST /books/ creates book with complete data
    [Tags]    books    api    post    create    happy-path
    Given Valid Book Data Is Prepared
    ...    title=${TEST_BOOK_TITLE}
    ...    author=Test Author
    ...    pages=250
    ...    category=Fiction
    When Client Creates Book Via API    ${NEW_BOOK_DATA}
    Then Response Should Have Status Code    200
    And Response Should Contain Created Book Data
    And New Book Should Have Generated ID
    And New Book Should Be Retrievable Via GET
    And Book Should Have Default Favorite Status    false

API Should Retrieve Specific Book By ID
    [Documentation]    Validates GET /books/{id} returns specific book details
    [Tags]    books    api    get    single    happy-path  
    Given Valid Book Data Is Prepared    Test Retrieval Book    Test Author    300    Fiction
    And Book Exists In Database    ${NEW_BOOK_DATA}
    When Client Requests Book By ID    ${EXISTING_BOOK_ID}
    Then Response Should Have Status Code    200
    And Response Should Contain Correct Book Data    ${NEW_BOOK_DATA}
    And Response Schema Should Match Book Detail Format

API Should Update Existing Book With Valid Changes
    [Documentation]    Validates PUT /books/{id} updates book completely
    [Tags]    books    api    put    update    happy-path
    Given Valid Book Data Is Prepared    Original Book    Original Author    250    Fiction
    And Book Exists In Database    ${NEW_BOOK_DATA}
    And Updated Book Data Is Prepared
    ...    title=Updated Test Title
    ...    author=Updated Author  
    ...    pages=400
    ...    category=Science Fiction
    When Client Updates Book Via API    ${EXISTING_BOOK_ID}    ${UPDATED_BOOK_DATA}
    Then Response Should Have Status Code    200
    And Response Should Contain Updated Book Data
    And Updated Book Should Be Retrievable Via GET
    And Original Data Should Be Completely Replaced

API Should Delete Book Successfully  
    [Documentation]    Validates DELETE /books/{id} removes book from system
    [Tags]    books    api    delete    removal    happy-path
    Given Valid Book Data Is Prepared    Book To Delete    Test Author    350    Biography
    And Book Exists In Database    ${NEW_BOOK_DATA}
    When Client Deletes Book Via API    ${EXISTING_BOOK_ID}
    Then Response Should Have Status Code    200
    And Deleted Book Should Not Be Retrievable    ${EXISTING_BOOK_ID}
    And Book Should Be Removed From Collection

API Should Toggle Book Favorite Status
    [Documentation]    Validates PATCH /books/{id}/favorite toggles favorite flag
    [Tags]    books    api    patch    favorites    happy-path 
    Given Valid Book Data Is Prepared    Favorite Test Book    Test Author    280    Fiction
    And Book Exists With Favorite Status    ${NEW_BOOK_DATA}    false
    When Client Toggles Book Favorite Status    ${EXISTING_BOOK_ID}
    Then Response Should Have Status Code    200
    And Book Favorite Status Should Be Updated    true
    When Client Toggles Book Favorite Status Again    ${EXISTING_BOOK_ID}  
    Then Book Favorite Status Should Be Updated    false

API Should Reject Book Creation With Invalid Data
    [Documentation]    Validates POST /books/ handles validation errors properly
    [Tags]    books    api    post    validation    edge-case
    When Client Attempts To Create Book With Invalid Data
    ...    title=${EMPTY}
    ...    author=Valid Author
    ...    pages=not_a_number
    ...    category=${EMPTY}
    Then Response Should Have Status Code    422
    And Response Should Contain Validation Error Details
    And No Book Should Be Created In Database

API Should Return 404 For Non-Existent Book Operations
    [Documentation]    Validates proper 404 handling for missing books
    [Tags]    books    api    error-handling    negative
    When Client Requests Non-Existent Book    99999
    Then Response Should Have Status Code    404
    And Response Should Contain Not Found Error
    When Client Attempts To Update Non-Existent Book    99999
    Then Response Should Have Status Code    404
    When Client Attempts To Delete Non-Existent Book    99999
    Then Response Should Have Status Code    404

API Should Handle Malformed Request Bodies Gracefully
    [Documentation]    Validates API error handling for malformed JSON
    [Tags]    books    api    error-handling    malformed    negative
    When Client Sends Malformed JSON To Create Book
    Then Response Should Have Status Code    422
    And Response Should Contain JSON Parse Error
    When Client Sends Invalid Content Type    text/plain
    Then Response Should Have Status Code    422
    And Response Should Indicate Unsupported Media Type

API Should Enforce Required Fields For Book Creation
    [Documentation]    Validates all required fields are enforced consistently
    [Tags]    books    api    validation    required-fields    edge-case
    When Client Creates Book Missing Title Field
    Then Response Should Have Status Code    422
    And Error Should Indicate Missing Title Field
    When Client Creates Book Missing Author Field  
    Then Response Should Have Status Code    422
    And Error Should Indicate Missing Author Field
    When Client Creates Book Missing Pages Field
    Then Response Should Have Status Code    422
    And Error Should Indicate Missing Pages Field

API Should Accept Books With Boundary Value Data
    [Documentation]    Validates API handles edge cases for valid data ranges
    [Tags]    books    api    boundary    validation    edge-case
    When Client Creates Book With Minimum Valid Pages    1
    Then Response Should Have Status Code    200  
    When Client Creates Book With Maximum Title Length    ${LONG_TITLE_255_CHARS}
    Then Response Should Have Status Code    200
    When Client Creates Book With Unicode Characters
    ...    title=测试书籍 📚 🤖
    ...    author=Тест Автор
    Then Response Should Have Status Code    200
    And Unicode Data Should Be Preserved Correctly