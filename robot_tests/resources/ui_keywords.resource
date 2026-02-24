*** Settings ***
Documentation    UI interaction keywords for Books application

*** Variables ***
${BTN_SUBMIT}         css=#book-form button[type="submit"]
${INPUT_TITLE}        id=title
${INPUT_AUTHOR}       id=author
${INPUT_PAGES}        id=pages
${SELECT_CATEGORY}    id=category

*** Keywords ***
User Is On Books Page
    [Documentation]    Navigate to books page and verify loaded
    New Page    ${BASE_URL}
    Wait For Load State    networkidle
    Get Title    ==    Books Library

User Fills Book Form
    [Arguments]    ${title}    ${author}    ${pages}    ${category}
    [Documentation]    Fill book creation form
    Fill Text    ${INPUT_TITLE}    ${title}
    Fill Text    ${INPUT_AUTHOR}    ${author}
    Fill Text    ${INPUT_PAGES}    ${pages}
    Select Options By    ${SELECT_CATEGORY}    value    ${category}

User Submits Book Form
    [Documentation]    Submit book form and wait for response
    Click    ${BTN_SUBMIT}
    Sleep    2s
    Reload
    Sleep    2s

Book Should Appear In List
    [Arguments]    ${title}
    [Documentation]    Verify book appears in UI
    Sleep    2s
    ${text}=    Get Text    css=.books-grid
    Should Contain    ${text}    ${title}

User Searches For Book
    [Arguments]    ${search_term}
    [Documentation]    Search for book by title or author
    Reload
    Sleep    1s
    Fill Text    id=search-input    ${search_term}
    Wait For Load State    networkidle

User Filters By Category
    [Arguments]    ${category}
    [Documentation]    Filter books by category
    Select Options By    id=category-filter    value    ${category}
    Wait For Load State    networkidle

Visible Books Count Should Be
    [Arguments]    ${expected_count}
    [Documentation]    Verify number of visible books
    ${count}=    Get Element Count    css=.book-card
    Should Be Equal As Integers    ${count}    ${expected_count}
