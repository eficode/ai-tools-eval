*** Settings ***
Library          Browser
Library          RequestsLibrary
Resource         resources/common.resource

*** Test Cases ***
Debug API During UI Test
    [Documentation]    Test if API works while UI browser is running

    # Setup Browser (same as UI test)
    New Browser    chromium    headless=${True}
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    http://books-database-service:8000
    Wait For Load State    networkidle    timeout=10s

    # Setup API Session (same as API test)
    Create Session    books_api    http://books-database-service:8000    verify=${False}

    # Generate test data
    &{test_book_data}    Generate Unique Book Data    API UI Test Book

    # Test API directly while browser is open
    Log    Testing API directly from UI test context
    ${response}    POST On Session    books_api    /books/
    ...    json=&{test_book_data}    expected_status=200
    Log    API response: ${response.json()}

    # Check if the book now appears in the browser
    Log    Refreshing browser page to check for new book
    Reload
    Wait For Load State    networkidle    timeout=10s

    # Check if book appears in page content
    ${page_content}    Get Text    id=books-list
    ${contains_book}    Run Keyword And Return Status
    ...    Should Contain    ${page_content}    ${test_book_data}[title]
    Log    Page contains new book after API creation: ${contains_book}
    Log    Book title we're looking for: ${test_book_data}[title]