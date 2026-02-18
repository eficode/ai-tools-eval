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

*** Test Cases ***
Debug Network and Console Issues
    [Documentation]    Debug network requests and console errors during form submission

    # Setup
    New Browser    chromium    headless=${True}
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    http://books-database-service:8000
    Wait For Load State    networkidle    timeout=10s

    # Generate test data
    &{test_book_data}    Generate Unique Book Data    NETWORK Test Book
    Log    Test book title: ${test_book_data}[title]

    # Check for console errors before form submission
    ${console_messages_before}    Get Console Messages
    Log    Console messages before: ${console_messages_before}

    # Fill form
    Log    Filling form with minimal valid data
    Fill Text    ${TITLE_INPUT}    ${test_book_data}[title]
    Fill Text    ${AUTHOR_INPUT}    ${test_book_data}[author]
    Fill Text    ${PAGES_INPUT}    123
    Select Options By    ${CATEGORY_SELECT}    value    Fiction

    # Check form field values to ensure they were filled correctly
    ${title_value}    Get Property    ${TITLE_INPUT}    value
    ${author_value}    Get Property    ${AUTHOR_INPUT}    value
    ${pages_value}    Get Property    ${PAGES_INPUT}    value
    Log    Form values - Title: ${title_value}, Author: ${author_value}, Pages: ${pages_value}

    # Submit form and check for network activity
    Log    Submitting form
    Click    ${SUBMIT_BUTTON}
    Sleep    2s    # Give time for any async operations
    Wait For Load State    networkidle    timeout=10s

    # Check for console errors after submission
    ${console_messages_after}    Get Console Messages
    Log    Console messages after: ${console_messages_after}

    # Check current URL
    ${current_url}    Get Url
    Log    Current URL after submission: ${current_url}