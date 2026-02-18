*** Settings ***
Library          Browser
Resource         resources/common.resource

*** Variables ***
${BOOK_FORM}          id=book-form
${TITLE_INPUT}        id=title
${AUTHOR_INPUT}       id=author
${PAGES_INPUT}        id=pages
${CATEGORY_SELECT}    id=category
${SUBMIT_BUTTON}      css=#book-form [type="submit"]
${BOOKS_GRID}         id=books-list

*** Test Cases ***
Debug Form Submission Process
    [Documentation]    Debug the form submission process step by step

    # Setup
    New Browser    chromium    headless=${True}
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    http://books-database-service:8000
    Wait For Load State    networkidle    timeout=10s

    # Generate test data
    &{test_book_data}    Generate Unique Book Data    DEBUG Test Book
    Log    Test book title: ${test_book_data}[title]

    # Fill form
    Log    Filling form with test data
    Fill Text    ${TITLE_INPUT}    ${test_book_data}[title]
    Fill Text    ${AUTHOR_INPUT}    ${test_book_data}[author]
    Fill Text    ${PAGES_INPUT}    ${test_book_data}[pages]
    Select Options By    ${CATEGORY_SELECT}    value    ${test_book_data}[category]

    # Get page content before submission
    ${content_before}    Get Text    ${BOOKS_GRID}
    Log    Books grid content before submission: ${content_before}

    # Submit form
    Log    Submitting form
    Click    ${SUBMIT_BUTTON}
    Wait For Load State    networkidle    timeout=10s

    # Get page content after submission
    ${content_after}    Get Text    ${BOOKS_GRID}
    Log    Books grid content after submission: ${content_after}

    # Check if new book appears
    ${page_contains_book}    Run Keyword And Return Status
    ...    Get Text    ${BOOKS_GRID}    contains    ${test_book_data}[title]
    Log    Page contains new book: ${page_contains_book}