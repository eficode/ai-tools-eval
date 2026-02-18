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
Debug Simple Form Submission
    [Documentation]    Debug form submission with hardcoded simple values

    # Setup
    New Browser    chromium    headless=${True}
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    http://books-database-service:8000
    Wait For Load State    networkidle    timeout=10s

    # Fill form with very simple values
    Log    Filling form with hardcoded values
    Fill Text    ${TITLE_INPUT}    Simple Test Book
    Fill Text    ${AUTHOR_INPUT}    Test Author
    Fill Text    ${PAGES_INPUT}    100
    Select Options By    ${CATEGORY_SELECT}    value    Fiction

    # Verify form was filled
    ${title_value}    Get Property    ${TITLE_INPUT}    value
    ${author_value}    Get Property    ${AUTHOR_INPUT}    value
    ${pages_value}    Get Property    ${PAGES_INPUT}    value
    Log    Filled values - Title: ${title_value}, Author: ${author_value}, Pages: ${pages_value}

    # Check page URL before submission
    ${url_before}    Get Url
    Log    URL before submission: ${url_before}

    # Submit form
    Log    Clicking submit button
    Click    ${SUBMIT_BUTTON}

    # Wait and check URL after submission
    Sleep    3s
    ${url_after}    Get Url
    Log    URL after submission: ${url_after}

    # Check if the page content changed or redirected
    Wait For Load State    networkidle    timeout=10s

    # Try to find the book in the page
    ${page_source}    Get Text    body
    ${contains_book}    Run Keyword And Return Status
    ...    Should Contain    ${page_source}    Simple Test Book
    Log    Page contains our test book: ${contains_book}