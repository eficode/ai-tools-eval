*** Settings ***
Documentation     UI-specific keywords for Books Database testing
...               Implements Page Object Model patterns for web interface testing

Resource          common.resource


*** Keywords ***
# =============================================================================
# BROWSER MANAGEMENT
# =============================================================================

Setup Browser Environment
    [Documentation]    Initializes browser with optimal settings
    New Browser    ${BROWSER_TYPE}    headless=${HEADLESS_MODE}
    New Context    viewport={'width': 1920, 'height': 1080}
    Set Browser Timeout    ${DEFAULT_TIMEOUT}

Teardown Browser Environment
    [Documentation]    Properly closes browser resources
    TRY
        Capture Page Screenshot
    EXCEPT
        Log    Screenshot capture failed    WARN
    FINALLY
        Close Browser
    END

# =============================================================================
# PAGE NAVIGATION
# =============================================================================

Navigate To Books Page
    [Documentation]    Opens the books application main page
    New Page    ${BASE_URL}
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    Books Page Should Be Open

Books Page Should Be Open
    [Documentation]    Verifies the books page is loaded and ready
    Wait For Elements State    h1:has-text("Books Library")    visible    timeout=${DEFAULT_TIMEOUT}
    Get Title    ==    Books Library

# =============================================================================
# BOOK MANAGEMENT UI ACTIONS
# =============================================================================

Add New Book Via UI
    [Documentation]    Adds a book using the web interface
    [Arguments]    ${title}    ${author}    ${year}=${EMPTY}    ${isbn}=${EMPTY}
    
    Fill Text    id=title    ${title}
    Fill Text    id=author    ${author}
    Fill Text    id=pages    500
    Select Options By    id=category    value    Fiction
    
    Click    css=#book-form button[type="submit"]
    
    # Wait for success notification
    Wait For Elements State    css=.notification.success    visible    timeout=10s
    
    # Manually refresh the page to ensure the new book appears
    Reload
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}

Search For Book
    [Documentation]    Searches for a book using the search functionality
    [Arguments]    ${search_term}
    
    Fill Text    id=search-input    ${search_term}
    Click    id=search-btn
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}

Clear Search
    [Documentation]    Clears the search input and shows all books
    Fill Text    id=search-input    ${EMPTY}
    Click    id=search-btn
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}

# =============================================================================
# BOOK VERIFICATION
# =============================================================================

Verify Book In Results
    [Documentation]    Verifies a book appears in search results
    [Arguments]    ${title}    ${author}
    
    # First check if Load More button exists and click it to load all books
    TRY
        ${load_more_visible}=    Get Element Count    css=#load-more:visible
        WHILE    ${load_more_visible} > 0
            Click    id=load-more
            Wait For Load State    networkidle    timeout=5s
            ${load_more_visible}=    Get Element Count    css=#load-more:visible
        END
    EXCEPT
        Log    No Load More button or error clicking it    DEBUG
    END
    
    # Now check if our book is visible
    ${page_text}=    Get Text    css=#books-list
    Should Contain    ${page_text}    ${title}    Book title "${title}" not found on page after loading all books

Verify Book Not In Results
    [Documentation]    Verifies a book does not appear in search results
    [Arguments]    ${title}
    
    # Load all books first
    TRY
        ${load_more_visible}=    Get Element Count    css=#load-more:visible
        WHILE    ${load_more_visible} > 0
            Click    id=load-more
            Wait For Load State    networkidle    timeout=5s
            ${load_more_visible}=    Get Element Count    css=#load-more:visible
        END
    EXCEPT
        Log    No Load More button or error clicking it    DEBUG
    END
    
    # Check that the book is NOT visible
    ${page_text}=    Get Text    css=#books-list
    Should Not Contain    ${page_text}    ${title}    Book title "${title}" should not be visible in filtered results

Get Book Count From UI
    [Documentation]    Returns the number of books displayed on the page
    ${count}=    Get Element Count    css=.book-card
    RETURN    ${count}

# =============================================================================
# GHERKIN-STYLE KEYWORDS
# =============================================================================

Given Browser Is Open
    [Documentation]    Precondition: Browser is ready for testing
    Setup Browser Environment

Given User Is On Books Page
    [Documentation]    Precondition: User has navigated to books page
    Navigate To Books Page

When User Adds A New Book
    [Documentation]    Action: User creates a new book entry
    [Arguments]    ${title}    ${author}
    Add New Book Via UI    ${title}    ${author}

When User Searches For Book
    [Documentation]    Action: User performs a book search
    [Arguments]    ${search_term}
    Search For Book    ${search_term}

Then Book Should Be Visible
    [Documentation]    Assertion: Book appears in results
    [Arguments]    ${title}    ${author}
    Verify Book In Results    ${title}    ${author}

Then Book Should Not Be Visible
    [Documentation]    Assertion: Book does not appear in results
    [Arguments]    ${title}
    Verify Book Not In Results    ${title}