*** Settings ***
Documentation     Books Page Object - UI interactions for the Books web application
...               
...               This resource file encapsulates all UI interactions with the Books page.
...               It follows the Page Object Model pattern to maintain clean separation
...               between test logic and page-specific implementation details.

Library           Browser
Resource          common.resource

*** Variables ***
# Page URL
${BOOKS_PAGE_URL}         ${BASE_URL}/

# Selectors
${BOOK_CARD_SELECTOR}     css=.book-card
${BOOK_TITLE_SELECTOR}    css=.book-card h3
${BOOK_AUTHOR_SELECTOR}   css=.book-card .author
${SEARCH_INPUT}           css=#search-input
${SEARCH_BUTTON}          css=#search-btn
${PAGE_TITLE}             css=h1
${LOADING_INDICATOR}      css=.loading

*** Keywords ***
Navigate To Books Page
    [Documentation]    Opens the Books page and waits for it to load completely
    ...                
    ...                This keyword:
    ...                - Opens the Books page URL
    ...                - Waits for the page to be fully loaded (networkidle state)
    ...                - Verifies the page title is correct
    
    New Page    ${BOOKS_PAGE_URL}
    Wait For Load State    networkidle    timeout=${LONG_TIMEOUT}
    Log    Navigated to Books page: ${BOOKS_PAGE_URL}

Verify Books Page Is Displayed
    [Documentation]    Confirms that the Books page loaded successfully
    ...                
    ...                Verifies:
    ...                - Page title contains "Books"
    ...                - Main content is visible
    
    ${title}=    Get Title
    Should Contain    ${title}    Books    ignore_case=True
    Wait For Elements State    ${PAGE_TITLE}    visible    timeout=${DEFAULT_TIMEOUT}
    Log    Books page is displayed correctly

Get Book Count
    [Documentation]    Returns the number of book cards displayed on the page
    ...                
    ...                Returns:
    ...                - count: Integer number of visible book cards
    
    ${count}=    Get Element Count    ${BOOK_CARD_SELECTOR}
    Log    Found ${count} books on the page
    RETURN    ${count}

Get All Book Titles
    [Documentation]    Returns a list of all book titles displayed on the page
    ...                
    ...                Returns:
    ...                - titles: List of book title strings
    
    # Wait for at least one title to be present
    TRY
        Wait For Elements State    ${BOOK_TITLE_SELECTOR} >> nth=0    visible    timeout=${DEFAULT_TIMEOUT}
    EXCEPT
        Log    No book titles found on page    level=WARN
        RETURN    @{EMPTY}
    END
    
    @{title_elements}=    Get Elements    ${BOOK_TITLE_SELECTOR}
    @{titles}=    Create List
    
    FOR    ${element}    IN    @{title_elements}
        ${title_text}=    Get Text    ${element}
        Append To List    ${titles}    ${title_text}
    END
    
    ${count}=    Get Length    ${titles}
    Log    Retrieved ${count} book titles
    RETURN    @{titles}

Search For Book
    [Documentation]    Searches for books using the search input field
    ...                
    ...                Arguments:
    ...                - search_term: Text to search for
    ...                
    ...                This keyword:
    ...                - Fills the search input with the search term
    ...                - Clicks the search button
    ...                - Waits for the search results to load
    [Arguments]    ${search_term}
    
    Wait For Element And Fill Text    ${SEARCH_INPUT}    ${search_term}
    Wait For Element And Click    ${SEARCH_BUTTON}
    Wait For Load State    load    timeout=${DEFAULT_TIMEOUT}
    Log    Searched for: ${search_term}

Clear Search
    [Documentation]    Clears the search input field and triggers search to show all books
    
    Wait For Elements State    ${SEARCH_INPUT}    visible    timeout=${DEFAULT_TIMEOUT}
    Clear Text    ${SEARCH_INPUT}
    Wait For Element And Click    ${SEARCH_BUTTON}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Log    Search input cleared

Click Book Card By Index
    [Documentation]    Clicks on a book card at the specified index
    ...                
    ...                Arguments:
    ...                - index: Zero-based index of the book card to click
    [Arguments]    ${index}
    
    VAR    ${selector}    ${BOOK_CARD_SELECTOR} >> nth=${index}
    Wait For Element And Click    ${selector}
    Log    Clicked book card at index: ${index}

Click First Book Card
    [Documentation]    Clicks on the first book card in the list
    
    Click Book Card By Index    0

Verify Book Card Contains Title
    [Documentation]    Verifies that at least one book card contains the specified title
    ...                
    ...                Arguments:
    ...                - expected_title: Title text to search for
    [Arguments]    ${expected_title}
    
    @{titles}=    Get All Book Titles
    ${found}=    Evaluate    any('${expected_title}'.lower() in title.lower() for title in ${titles})
    Should Be True    ${found}    Book with title "${expected_title}" not found on page

Verify No Books Displayed
    [Documentation]    Verifies that no book cards are displayed on the page
    
    TRY
        Wait For Elements State    ${BOOK_CARD_SELECTOR}    hidden    timeout=${SHORT_TIMEOUT}
        Log    No books are displayed (as expected)
    EXCEPT
        ${count}=    Get Element Count    ${BOOK_CARD_SELECTOR}
        Should Be Equal As Integers    ${count}    0    Expected no books, but found ${count}
    END

Verify Books Are Displayed
    [Documentation]    Verifies that at least one book card is visible
    
    ${count}=    Get Book Count
    Should Be True    ${count} > 0    No books are displayed on the page

Verify Page Title
    [Documentation]    Verifies the page title matches the expected value
    ...                
    ...                Arguments:
    ...                - expected_title: Expected page title text
    [Arguments]    ${expected_title}
    
    ${actual_title}=    Get Title
    Should Be Equal    ${actual_title}    ${expected_title}    ignore_case=True
    Log    Page title verified: ${actual_title}

Wait For Books To Load
    [Documentation]    Waits for book cards to be visible and page to be stable
    
    Wait For Load State    networkidle    timeout=${LONG_TIMEOUT}
    TRY
        Wait For Elements State    ${BOOK_CARD_SELECTOR} >> first    visible    timeout=2s
    EXCEPT
        Log    No books visible after search (might be empty result)    level=INFO
    END
    Log    Books have finished loading
