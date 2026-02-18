*** Settings ***
Documentation    UI-specific keywords for Books Library web interface automation
...              Contains specialized keywords for browser interactions,
...              form handling, and UI validation patterns.

Library          Browser
Library          Collections
Library          String

Resource         resources/common.resource

*** Variables ***
# Extended UI Selectors for Books Library
${PAGE_HEADER}           css=header h1
${ADD_BOOK_SECTION}      css=.book-form-container
${BOOKS_SECTION}         css=.books-container
${FILTERS_SECTION}       css=.filters
${RESULTS_INFO}          css=.results-info
${PAGINATION_SECTION}    css=.pagination

# Form Elements
${BOOK_FORM}             id=book-form
${TITLE_INPUT}           id=title
${AUTHOR_INPUT}          id=author
${PAGES_INPUT}           id=pages
${CATEGORY_SELECT}       id=category
${SUBMIT_BUTTON}         css=${BOOK_FORM} [type="submit"]

# Books Grid Elements
${BOOKS_GRID}            id=books-list
${BOOK_CARD}             css=.book-card
${BOOK_TITLE}            css=.book-title
${BOOK_AUTHOR}           css=.book-author
${BOOK_PAGES}            css=.book-pages
${BOOK_CATEGORY}         css=.book-category

# Action Buttons on Book Cards
${EDIT_BUTTON}           css=.edit-btn
${DELETE_BUTTON}         css=.delete-btn
${FAVORITE_BUTTON}       css=.favorite-btn

# Search and Filter Elements
${SEARCH_INPUT}          id=search-input
${SEARCH_BUTTON}         id=search-btn
${CATEGORY_FILTER}       id=category-filter
${FAVORITE_FILTER}       css=.favorite-filters
${ALL_BOOKS_FILTER}      id=all-books-filter
${FAVORITES_FILTER}      id=favorite-filter

# Sort Elements
${SORT_SELECT}           id=sort-by
${SORT_DIRECTION}        id=sort-direction

# Modal Elements
${EDIT_MODAL}            id=edit-modal
${EDIT_FORM}             id=edit-form
${EDIT_ID}               id=edit-id
${EDIT_TITLE}            id=edit-title
${EDIT_AUTHOR}           id=edit-author
${EDIT_PAGES}            id=edit-pages
${EDIT_CATEGORY}         id=edit-category
${MODAL_CLOSE}           css=.close
${SAVE_BUTTON}           css=${EDIT_FORM} [type="submit"]

*** Keywords ***
# Browser and Page Management Keywords
Setup Books Library Browser
    [Documentation]    Set up browser specifically optimized for Books Library testing
    [Arguments]    ${browser_type}=chromium    ${headless}=${False}    ${viewport_width}=1920    ${viewport_height}=1080

    New Browser    ${browser_type}    headless=${headless}
    New Context    viewport={'width': ${viewport_width}, 'height': ${viewport_height}}
    Log    Browser setup completed: ${browser_type}, headless=${headless}, viewport=${viewport_width}x${viewport_height}

Navigate To Books Library
    [Documentation]    Navigate to Books Library application with comprehensive loading validation
    [Arguments]    ${url}=${UI_BASE_URL}    ${wait_for_load}=${True}

    New Page    ${url}
    Log    Navigated to Books Library: ${url}

    IF    ${wait_for_load}
        Wait For Books Library Page Load
    END

Wait For Books Library Page Load
    [Documentation]    Wait for Books Library page to fully load with all components
    [Arguments]    ${timeout}=${TIMEOUT}

    # Wait for critical page elements
    Wait For Load State    networkidle    timeout=${timeout}
    Wait For Elements State    selector=${PAGE_HEADER}    state=visible    timeout=${timeout}
    Wait For Elements State    selector=${BOOK_FORM}    state=visible    timeout=${timeout}
    Wait For Elements State    selector=${BOOKS_GRID}    state=visible    timeout=${timeout}

    # Verify page title
    Get Title    contains    Books Library
    Log    Books Library page fully loaded and verified

Refresh Books Library Page
    [Documentation]    Refresh the page and wait for reload
    Reload
    Wait For Books Library Page Load

# Form Interaction Keywords
Fill Book Form
    [Documentation]    Fill the book creation form with provided data
    [Arguments]    ${book_data}    ${clear_first}=${True}

    Log    Filling book form with data: ${book_data}

    IF    ${clear_first}
        Clear Book Form
    END

    Fill Text    ${TITLE_INPUT}    ${book_data}[title]
    Fill Text    ${AUTHOR_INPUT}    ${book_data}[author]
    Fill Text    ${PAGES_INPUT}    ${book_data}[pages]
    Select Options By    ${CATEGORY_SELECT}    value    ${book_data}[category]

    Log    Book form filled successfully

Clear Book Form
    [Documentation]    Clear all fields in the book creation form
    Clear Text    ${TITLE_INPUT}
    Clear Text    ${AUTHOR_INPUT}
    Clear Text    ${PAGES_INPUT}
    Select Options By    ${CATEGORY_SELECT}    index    0
    Log    Book form cleared

Submit Book Form
    [Documentation]    Submit the book creation form and wait for completion
    [Arguments]    ${wait_for_result}=${True}

    Click    ${SUBMIT_BUTTON}
    Log    Book form submitted

    IF    ${wait_for_result}
        Wait For Load State    networkidle    timeout=${TIMEOUT}
        Log    Form submission completed
    END

Verify Form Validation
    [Documentation]    Verify form validation messages are displayed
    [Arguments]    ${expected_invalid_fields}

    FOR    ${field}    IN    @{expected_invalid_fields}
        IF    "${field}" == "title"
            VAR    ${is_valid}    Get Property    ${TITLE_INPUT}    validity.valid
            Should Be Equal    ${is_valid}    ${False}    msg=Title field should be invalid
        ELSE IF    "${field}" == "author"
            VAR    ${is_valid}    Get Property    ${AUTHOR_INPUT}    validity.valid
            Should Be Equal    ${is_valid}    ${False}    msg=Author field should be invalid
        ELSE IF    "${field}" == "pages"
            VAR    ${is_valid}    Get Property    ${PAGES_INPUT}    validity.valid
            Should Be Equal    ${is_valid}    ${False}    msg=Pages field should be invalid
        END
    END

    Log    Form validation verified for fields: ${expected_invalid_fields}

# Books Grid Interaction Keywords
Get Books Count From Grid
    [Documentation]    Get the current number of books displayed in the grid
    VAR    ${book_elements}    Get Elements    css=${BOOKS_GRID} ${BOOK_CARD}
    VAR    ${count}    Get Length    ${book_elements}
    Log    Current books count in grid: ${count}
    RETURN    ${count}

Get Book Card By Index
    [Documentation]    Get book card element by index (0-based)
    [Arguments]    ${index}

    VAR    ${book_cards}    Get Elements    css=${BOOKS_GRID} ${BOOK_CARD}
    VAR    ${cards_count}    Get Length    ${book_cards}

    Should Be True    ${index} < ${cards_count}    msg=Index ${index} exceeds available books count ${cards_count}
    VAR    ${book_card}    Get From List    ${book_cards}    ${index}

    RETURN    ${book_card}

Get Book Card By Title
    [Documentation]    Find book card by title text
    [Arguments]    ${book_title}

    VAR    ${book_cards}    Get Elements    css=${BOOKS_GRID} ${BOOK_CARD}

    FOR    ${card}    IN    @{book_cards}
        VAR    ${title_element}    Get Element    ${card} >> ${BOOK_TITLE}
        VAR    ${card_title}    Get Text    ${title_element}
        IF    "${card_title}" == "${book_title}"
            RETURN    ${card}
        END
    END

    Fail    Book card not found with title: ${book_title}

Get Book Details From Card
    [Documentation]    Extract book details from a book card element
    [Arguments]    ${book_card}

    VAR    ${title}       Get Text    ${book_card} >> ${BOOK_TITLE}
    VAR    ${author}      Get Text    ${book_card} >> ${BOOK_AUTHOR}
    VAR    ${pages_text}  Get Text    ${book_card} >> ${BOOK_PAGES}
    VAR    ${category}    Get Text    ${book_card} >> ${BOOK_CATEGORY}

    # Extract pages number from text (e.g., "350 pages" -> 350)
    VAR    ${pages}    Replace String    ${pages_text}    pages    ${EMPTY}
    VAR    ${pages}    Strip String    ${pages}
    VAR    ${pages}    Convert To Integer    ${pages}

    &{book_details}    Create Dictionary
    ...    title=${title}
    ...    author=${author}
    ...    pages=${pages}
    ...    category=${category}

    RETURN    &{book_details}

Verify Book Appears In Grid
    [Documentation]    Verify that a book with given details appears in the grid
    [Arguments]    ${expected_book_data}    ${timeout}=${TIMEOUT}

    VAR    ${title}    ${expected_book_data}[title]
    Log    Verifying book appears in grid: ${title}

    Wait For Elements State    selector=${BOOKS_GRID} ${BOOK_CARD}    state=visible    timeout=${timeout}

    TRY
        Get Book Card By Title    ${title}
        Log    Book found in grid: ${title}
    EXCEPT    *
        Capture Evidence    book_not_found_${title}
        Fail    Book not found in grid: ${title}
    END

Verify Book Does Not Appear In Grid
    [Documentation]    Verify that a book with given title does not appear in the grid
    [Arguments]    ${book_title}

    Log    Verifying book does not appear in grid: ${book_title}

    TRY
        Get Book Card By Title    ${book_title}
        Fail    Book unexpectedly found in grid: ${book_title}
    EXCEPT    *
        Log    Verified book not in grid: ${book_title}
    END

# Book Actions Keywords
Click Edit Button On Book
    [Documentation]    Click edit button on a specific book
    [Arguments]    ${book_identifier}    ${identifier_type}=index

    IF    "${identifier_type}" == "index"
        VAR    ${book_card}    Get Book Card By Index    ${book_identifier}
    ELSE IF    "${identifier_type}" == "title"
        VAR    ${book_card}    Get Book Card By Title    ${book_identifier}
    ELSE
        Fail    Invalid identifier type: ${identifier_type}. Use 'index' or 'title'
    END

    VAR    ${edit_btn}    Get Element    ${book_card} >> ${EDIT_BUTTON}
    Click    ${edit_btn}
    Wait For Elements State    selector=${EDIT_MODAL}    state=visible    timeout=${TIMEOUT}
    Log    Edit button clicked for book: ${book_identifier}

Click Delete Button On Book
    [Documentation]    Click delete button on a specific book
    [Arguments]    ${book_identifier}    ${identifier_type}=index    ${confirm_deletion}=${True}

    IF    "${identifier_type}" == "index"
        VAR    ${book_card}    Get Book Card By Index    ${book_identifier}
    ELSE IF    "${identifier_type}" == "title"
        VAR    ${book_card}    Get Book Card By Title    ${book_identifier}
    ELSE
        Fail    Invalid identifier type: ${identifier_type}. Use 'index' or 'title'
    END

    VAR    ${delete_btn}    Get Element    ${book_card} >> ${DELETE_BUTTON}
    Click    ${delete_btn}

    # Handle confirmation dialog if present
    IF    ${confirm_deletion}
        TRY
            Wait For Elements State    selector=.confirm-dialog    state=visible    timeout=3s
            Click    css=.confirm-dialog .confirm-yes
            Log    Deletion confirmed
        EXCEPT    *
            Log    No confirmation dialog appeared    INFO
        END
    END

    Wait For Load State    networkidle    timeout=${TIMEOUT}
    Log    Delete button clicked for book: ${book_identifier}

Click Favorite Button On Book
    [Documentation]    Click favorite button on a specific book
    [Arguments]    ${book_identifier}    ${identifier_type}=index

    IF    "${identifier_type}" == "index"
        VAR    ${book_card}    Get Book Card By Index    ${book_identifier}
    ELSE IF    "${identifier_type}" == "title"
        VAR    ${book_card}    Get Book Card By Title    ${book_identifier}
    ELSE
        Fail    Invalid identifier type: ${identifier_type}. Use 'index' or 'title'
    END

    VAR    ${favorite_btn}    Get Element    ${book_card} >> ${FAVORITE_BUTTON}
    Click    ${favorite_btn}
    Wait For Load State    networkidle    timeout=${TIMEOUT}
    Log    Favorite button clicked for book: ${book_identifier}

Verify Book Favorite Status
    [Documentation]    Verify the favorite status of a book
    [Arguments]    ${book_identifier}    ${expected_status}    ${identifier_type}=index

    IF    "${identifier_type}" == "index"
        VAR    ${book_card}    Get Book Card By Index    ${book_identifier}
    ELSE IF    "${identifier_type}" == "title"
        VAR    ${book_card}    Get Book Card By Title    ${book_identifier}
    ELSE
        Fail    Invalid identifier type: ${identifier_type}. Use 'index' or 'title'
    END

    VAR    ${favorite_btn}    Get Element    ${book_card} >> ${FAVORITE_BUTTON}
    VAR    ${btn_classes}    Get Attribute    ${favorite_btn}    class

    IF    ${expected_status}
        Should Contain    ${btn_classes}    active    msg=Book should be marked as favorite
    ELSE
        Should Not Contain    ${btn_classes}    active    msg=Book should not be marked as favorite
    END

    Log    Verified favorite status for book ${book_identifier}: ${expected_status}

# Modal Interaction Keywords
Fill Edit Modal
    [Documentation]    Fill the edit modal with book data
    [Arguments]    ${book_data}    ${clear_first}=${True}

    Wait For Elements State    selector=${EDIT_MODAL}    state=visible    timeout=${TIMEOUT}
    Log    Filling edit modal with data: ${book_data}

    IF    ${clear_first}
        Clear Text    ${EDIT_TITLE}
        Clear Text    ${EDIT_AUTHOR}
        Clear Text    ${EDIT_PAGES}
    END

    Fill Text    ${EDIT_TITLE}    ${book_data}[title]
    Fill Text    ${EDIT_AUTHOR}    ${book_data}[author]
    Fill Text    ${EDIT_PAGES}    ${book_data}[pages]
    Select Options By    ${EDIT_CATEGORY}    value    ${book_data}[category]

    Log    Edit modal filled successfully

Save Edit Modal
    [Documentation]    Save changes in the edit modal
    [Arguments]    ${wait_for_close}=${True}

    Click    ${SAVE_BUTTON}
    Log    Edit modal save button clicked

    IF    ${wait_for_close}
        Wait For Elements State    selector=${EDIT_MODAL}    state=hidden    timeout=${TIMEOUT}
        Wait For Load State    networkidle    timeout=${TIMEOUT}
        Log    Edit modal closed and changes saved
    END

Close Edit Modal
    [Documentation]    Close the edit modal without saving
    Click    ${MODAL_CLOSE}
    Wait For Elements State    selector=${EDIT_MODAL}    state=hidden    timeout=${TIMEOUT}
    Log    Edit modal closed without saving

Get Current Book Data From Edit Modal
    [Documentation]    Get current book data from edit modal fields
    Wait For Elements State    selector=${EDIT_MODAL}    state=visible    timeout=${TIMEOUT}

    VAR    ${title}     Get Text    ${EDIT_TITLE}
    VAR    ${author}    Get Text    ${EDIT_AUTHOR}
    VAR    ${pages}     Get Text    ${EDIT_PAGES}
    VAR    ${category}  Get Selected Options    ${EDIT_CATEGORY}

    &{book_data}    Create Dictionary
    ...    title=${title}
    ...    author=${author}
    ...    pages=${pages}
    ...    category=${category[0]}

    RETURN    &{book_data}

# Search and Filter Keywords
Search For Books
    [Documentation]    Search for books using the search functionality
    [Arguments]    ${search_term}    ${wait_for_results}=${True}

    Fill Text    ${SEARCH_INPUT}    ${search_term}
    Click    ${SEARCH_BUTTON}
    Log    Searching for books with term: ${search_term}

    IF    ${wait_for_results}
        Wait For Load State    networkidle    timeout=${TIMEOUT}
        Log    Search results loaded
    END

Clear Search
    [Documentation]    Clear the search input and reset results
    Clear Text    ${SEARCH_INPUT}
    Click    ${SEARCH_BUTTON}
    Wait For Load State    networkidle    timeout=${TIMEOUT}
    Log    Search cleared and results reset

Filter Books By Category
    [Documentation]    Filter books by selected category
    [Arguments]    ${category}    ${wait_for_results}=${True}

    Select Options By    ${CATEGORY_FILTER}    value    ${category}
    Log    Filtering books by category: ${category}

    IF    ${wait_for_results}
        Wait For Load State    networkidle    timeout=${TIMEOUT}
        Log    Category filter applied
    END

Filter Books By Favorite Status
    [Documentation]    Filter books by favorite status
    [Arguments]    ${show_favorites_only}=${True}

    IF    ${show_favorites_only}
        Click    ${FAVORITES_FILTER}
        Log    Filtering to show favorites only
    ELSE
        Click    ${ALL_BOOKS_FILTER}
        Log    Showing all books (favorites and non-favorites)
    END

    Wait For Load State    networkidle    timeout=${TIMEOUT}

Sort Books
    [Documentation]    Sort books by specified criteria and direction
    [Arguments]    ${sort_by}    ${ascending}=${True}

    Select Options By    ${SORT_SELECT}    value    ${sort_by}
    Log    Sorting books by: ${sort_by}

    # Check current sort direction and toggle if needed
    VAR    ${direction_btn}    Get Element    ${SORT_DIRECTION}
    VAR    ${current_classes}    Get Attribute    ${direction_btn}    class

    VAR    ${is_currently_ascending}    Evaluate    'fa-sort-up' in '${current_classes}'

    IF    ${ascending} != ${is_currently_ascending}
        Click    ${SORT_DIRECTION}
        Log    Toggled sort direction
    END

    Wait For Load State    networkidle    timeout=${TIMEOUT}
    Log    Books sorted by ${sort_by}, ascending: ${ascending}

# Results and Validation Keywords
Get Search Results Count
    [Documentation]    Get the number of books currently displayed after search/filter
    VAR    ${results_text}    Get Text    ${RESULTS_INFO}
    VAR    ${match}    Get Regexp Matches    ${results_text}    Showing (\\d+) of (\\d+) books    1    2

    IF    ${match}
        VAR    ${shown_count}    Convert To Integer    ${match[0][0]}
        VAR    ${total_count}    Convert To Integer    ${match[0][1]}
        Log    Search results: ${shown_count} shown out of ${total_count} total
        RETURN    ${shown_count}    ${total_count}
    ELSE
        Log    Could not parse results count from: ${results_text}    WARN
        RETURN    ${0}    ${0}
    END

Verify Search Results
    [Documentation]    Verify search results contain expected term
    [Arguments]    ${search_term}    ${search_field}=title

    VAR    ${visible_books}    Get Elements    css=${BOOKS_GRID} ${BOOK_CARD}:visible
    VAR    ${matching_count}    ${0}

    FOR    ${book_card}    IN    @{visible_books}
        IF    "${search_field}" == "title"
            VAR    ${field_text}    Get Text    ${book_card} >> ${BOOK_TITLE}
        ELSE IF    "${search_field}" == "author"
            VAR    ${field_text}    Get Text    ${book_card} >> ${BOOK_AUTHOR}
        ELSE
            Fail    Invalid search field: ${search_field}
        END

        VAR    ${contains_term}    Evaluate    "${search_term}".lower() in "${field_text}".lower()
        IF    ${contains_term}
            VAR    ${matching_count}    ${matching_count + 1}
        END
    END

    Should Be True    ${matching_count} > 0    msg=No books found matching search term: ${search_term}
    Log    Found ${matching_count} books matching search term: ${search_term}

Verify Filter Results
    [Documentation]    Verify filter results show only books from specified category
    [Arguments]    ${expected_category}

    VAR    ${visible_books}    Get Elements    css=${BOOKS_GRID} ${BOOK_CARD}:visible

    FOR    ${book_card}    IN    @{visible_books}
        VAR    ${category_text}    Get Text    ${book_card} >> ${BOOK_CATEGORY}
        Should Be Equal    ${category_text}    ${expected_category}
        ...    msg=Book category ${category_text} does not match filter ${expected_category}
    END

    VAR    ${visible_count}    Get Length    ${visible_books}
    Log    Verified ${visible_count} books match category filter: ${expected_category}

Verify Sort Order
    [Documentation]    Verify books are sorted correctly by specified field
    [Arguments]    ${sort_field}    ${ascending}=${True}

    VAR    ${visible_books}    Get Elements    css=${BOOKS_GRID} ${BOOK_CARD}:visible
    @{field_values}    Create List

    FOR    ${book_card}    IN    @{visible_books}
        IF    "${sort_field}" == "title"
            VAR    ${field_value}    Get Text    ${book_card} >> ${BOOK_TITLE}
        ELSE IF    "${sort_field}" == "author"
            VAR    ${field_value}    Get Text    ${book_card} >> ${BOOK_AUTHOR}
        ELSE IF    "${sort_field}" == "pages"
            VAR    ${pages_text}    Get Text    ${book_card} >> ${BOOK_PAGES}
            VAR    ${field_value}    Replace String    ${pages_text}    pages    ${EMPTY}
            VAR    ${field_value}    Strip String    ${field_value}
            VAR    ${field_value}    Convert To Integer    ${field_value}
        ELSE IF    "${sort_field}" == "category"
            VAR    ${field_value}    Get Text    ${book_card} >> ${BOOK_CATEGORY}
        ELSE
            Fail    Invalid sort field: ${sort_field}
        END

        Append To List    ${field_values}    ${field_value}
    END

    # Verify sort order
    @{sorted_values}    Copy List    ${field_values}
    IF    "${sort_field}" == "pages"
        Sort List    ${sorted_values}
    ELSE
        Sort List    ${sorted_values}
    END

    IF    not ${ascending}
        Reverse List    ${sorted_values}
    END

    Should Be Equal    ${field_values}    ${sorted_values}
    ...    msg=Books are not sorted correctly by ${sort_field} (ascending: ${ascending})

    Log    Verified sort order for ${sort_field}, ascending: ${ascending}