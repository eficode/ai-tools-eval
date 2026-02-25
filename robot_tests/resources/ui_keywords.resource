*** Settings ***
Documentation     UI-specific keywords for Books web application testing
...               Page Object Model implementation for Books Library UI

Library           Browser
Resource          common.resource


*** Variables ***
# Page Elements - Main Page
${HEADER_TITLE}              //h1[contains(text(), 'Books Library')]
${ADD_BOOK_FORM}             id=book-form
${BOOKS_LIST}                id=books-list
${SEARCH_INPUT}              id=search-input
${SEARCH_BUTTON}             id=search-btn
${CATEGORY_FILTER}           id=category-filter
${SORT_BY_SELECT}            id=sort-by
${ALL_BOOKS_FILTER}          id=all-books-filter
${FAVORITE_FILTER}           id=favorite-filter

# Page Elements - Book Form
${INPUT_TITLE}               id=title
${INPUT_AUTHOR}              id=author
${INPUT_PAGES}               id=pages
${INPUT_CATEGORY}            id=category
${SUBMIT_BUTTON}             //button[@type='submit' and contains(., 'Add Book')]

# Page Elements - Edit Modal
${EDIT_MODAL}                id=edit-modal
${EDIT_TITLE_INPUT}          id=edit-title
${EDIT_AUTHOR_INPUT}         id=edit-author
${EDIT_PAGES_INPUT}          id=edit-pages
${EDIT_CATEGORY_SELECT}      id=edit-category
${UPDATE_BUTTON}             //button[@type='submit' and contains(., 'Save Changes')]
${CLOSE_MODAL}               css=.close

# Dynamic Locators (use with placeholders)
${BOOK_CARD_BY_TITLE}        //div[contains(@class, 'book-card')]//h3[@class='book-title' and text()='{title}']
${DELETE_BUTTON_BY_TITLE}    //div[contains(@class, 'book-card')]//h3[@class='book-title' and text()='{title}']/ancestor::div[contains(@class, 'book-card')]//button[contains(@class, 'delete-btn')]
${EDIT_BUTTON_BY_TITLE}      //div[contains(@class, 'book-card')]//h3[@class='book-title' and text()='{title}']/ancestor::div[contains(@class, 'book-card')]//button[contains(@class, 'edit-btn')]
${FAVORITE_BUTTON_BY_TITLE}  //div[contains(@class, 'book-card')]//h3[@class='book-title' and text()='{title}']/ancestor::div[contains(@class, 'book-card')]//button[contains(@class, 'favorite-btn')]


*** Keywords ***
Setup Browser For Books Application
    [Documentation]    Initializes browser and creates context for testing
    New Browser    browser=${BROWSER_TYPE}    headless=${HEADLESS}
    New Context    viewport={'width': ${VIEWPORT_WIDTH}, 'height': ${VIEWPORT_HEIGHT}}
    Log    Browser initialized: ${BROWSER_TYPE} (headless=${HEADLESS})    console=True

Teardown Browser
    [Documentation]    Closes browser and all contexts
    Close Browser
    Log    Browser closed    console=True

Navigate To Books Application
    [Documentation]    Opens the Books Library application home page
    New Page    ${BASE_URL}/
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Wait For Elements State    ${HEADER_TITLE}    visible    timeout=${DEFAULT_TIMEOUT}
    Log    Navigated to Books Application    console=True

Reload Books Page
    [Documentation]    Reloads the current page and waits for it to be ready
    Reload
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Wait For Elements State    ${BOOKS_LIST}    visible    timeout=${DEFAULT_TIMEOUT}

Fill Book Creation Form
    [Documentation]    Fills the book creation form with provided data
    [Arguments]    ${title}    ${author}    ${pages}    ${category}=${TEST_CATEGORY}
    Wait For Elements State    ${INPUT_TITLE}    visible    timeout=${DEFAULT_TIMEOUT}
    Fill Text    ${INPUT_TITLE}    ${title}
    Fill Text    ${INPUT_AUTHOR}    ${author}
    Fill Text    ${INPUT_PAGES}    ${pages}
    Select Options By    ${INPUT_CATEGORY}    value    ${category}
    Log    Book form filled: ${title}    console=True

Submit Book Form
    [Documentation]    Submits the book creation form
    Click    ${SUBMIT_BUTTON}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Log    Book form submitted    console=True

Verify Book Appears In UI
    [Documentation]    Verifies that a book with given title is visible in the list
    [Arguments]    ${title}
    Wait For Load State    networkidle    timeout=15
    ${all_cards}=    Get Element Count    //div[contains(@class, 'book-card')]
    Log    Total book cards visible: ${all_cards}    console=True
    ${locator}=    Set Variable    ${BOOK_CARD_BY_TITLE.replace('{title}', '${title}')}
    ${count}=    Get Element Count    ${locator}
    Should Be True    ${count} > 0    msg=Book '${title}' should be visible but found ${count} instances
    Log    Book verified in UI: ${title} (found ${count} instance(s))    console=True

Verify Book Does Not Appear In UI
    [Documentation]    Verifies that a book with given title is not visible
    [Arguments]    ${title}
    VAR    ${locator}    ${BOOK_CARD_BY_TITLE.replace('{title}', '${title}')}
    TRY
        Wait For Elements State    ${locator}    hidden    timeout=3s
        Log    Verified book not in UI: ${title}    console=True
    EXCEPT
        ${count}=    Get Element Count    ${locator}
        Should Be Equal As Integers    ${count}    0
        ...    msg=Book '${title}' should not be visible but found ${count} instances
    END

Search For Book
    [Documentation]    Uses the search functionality to find books
    [Arguments]    ${search_term}
    Fill Text    ${SEARCH_INPUT}    ${search_term}
    Click    ${SEARCH_BUTTON}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Log    Searched for: ${search_term}    console=True

Filter Books By Category
    [Documentation]    Filters books by selecting a category
    [Arguments]    ${category}
    Select Options By    ${CATEGORY_FILTER}    value    ${category}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Log    Filtered by category: ${category}    console=True

Filter Favorites Only
    [Documentation]    Clicks the favorites filter button
    Click    ${FAVORITE_FILTER}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Log    Showing favorites only    console=True

Show All Books
    [Documentation]    Clicks the all books filter button
    Click    ${ALL_BOOKS_FILTER}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Log    Showing all books    console=True

Sort Books By
    [Documentation]    Sorts books by specified field
    [Arguments]    ${sort_field}
    Select Options By    ${SORT_BY_SELECT}    value    ${sort_field}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Log    Sorted by: ${sort_field}    console=True

Click Delete Button For Book
    [Documentation]    Clicks the delete button for a specific book
    [Arguments]    ${title}
    VAR    ${locator}    ${DELETE_BUTTON_BY_TITLE.replace('{title}', '${title}')}
    Wait For Elements State    ${locator}    visible    timeout=${DEFAULT_TIMEOUT}
    Click    ${locator}
    # Handle confirmation dialog if present
    TRY
        Wait For Alert    timeout=2s
        Handle Future Dialogs    action=accept
    EXCEPT
        Log    No alert dialog appeared    DEBUG
    END
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Log    Clicked delete for: ${title}    console=True

Click Edit Button For Book
    [Documentation]    Opens edit modal for a specific book
    [Arguments]    ${title}
    VAR    ${locator}    ${EDIT_BUTTON_BY_TITLE.replace('{title}', '${title}')}
    Wait For Elements State    ${locator}    visible    timeout=${DEFAULT_TIMEOUT}
    Click    ${locator}
    Wait For Elements State    ${EDIT_MODAL}    visible    timeout=${DEFAULT_TIMEOUT}
    Log    Opened edit modal for: ${title}    console=True

Update Book In Edit Form
    [Documentation]    Updates book fields in the edit modal
    [Arguments]    ${new_title}=${EMPTY}    ${new_author}=${EMPTY}    ${new_pages}=${EMPTY}
    Wait For Elements State    ${EDIT_MODAL}    visible    timeout=${DEFAULT_TIMEOUT}
    
    IF    '${new_title}' != '${EMPTY}'
        Fill Text    ${EDIT_TITLE_INPUT}    ${new_title}
    END
    IF    '${new_author}' != '${EMPTY}'
        Fill Text    ${EDIT_AUTHOR_INPUT}    ${new_author}
    END
    IF    '${new_pages}' != '${EMPTY}'
        Fill Text    ${EDIT_PAGES_INPUT}    ${new_pages}
    END
    
    Click    ${UPDATE_BUTTON}
    Wait For Elements State    ${EDIT_MODAL}    hidden    timeout=${DEFAULT_TIMEOUT}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Log    Book updated in edit form    console=True

Toggle Favorite For Book
    [Documentation]    Toggles the favorite status of a book
    [Arguments]    ${title}
    VAR    ${locator}    ${FAVORITE_BUTTON_BY_TITLE.replace('{title}', '${title}')}
    Wait For Elements State    ${locator}    visible    timeout=${DEFAULT_TIMEOUT}
    Click    ${locator}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Log    Toggled favorite for: ${title}    console=True

Get Books Count In UI
    [Documentation]    Returns the count of book cards visible on the page
    ${count}=    Get Element Count    css=.book-card
    RETURN    ${count}

Verify Books Count
    [Documentation]    Verifies the number of books displayed matches expected count
    [Arguments]    ${expected_count}
    ${actual_count}=    Get Books Count In UI
    Should Be Equal As Integers    ${actual_count}    ${expected_count}
    ...    msg=Expected ${expected_count} books but found ${actual_count}

Clear Search Input
    [Documentation]    Clears the search input field
    Fill Text    ${SEARCH_INPUT}    ${EMPTY}
    Click    ${SEARCH_BUTTON}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}

Take Screenshot On Failure
    [Documentation]    Captures screenshot when test fails
    [Arguments]    ${test_name}=test_failure
    TRY
        VAR    ${timestamp}    Get Current Date    result_format=%Y%m%d_%H%M%S
        Take Screenshot    filename=${test_name}_${timestamp}    fullPage=True
        Log    Screenshot captured: ${test_name}_${timestamp}    console=True
    EXCEPT    AS    ${error}
        Log    Failed to capture screenshot: ${error}    WARN
    END
