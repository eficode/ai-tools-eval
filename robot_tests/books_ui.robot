*** Settings ***
Documentation     Books UI Test Suite
...               
...               This suite tests the Books web application UI functionality including:
...               - Viewing the books list
...               - Searching for books
...               - Verifying book display
...               - Page navigation and loading
...               
...               Prerequisites:
...               - Books service running at http://books-service:8000
...               - Database initialized with sample data
...               - Browser library installed and configured

Library           Browser
Resource          resources/common.resource
Resource          resources/BooksPageUI.resource

Suite Setup       Initialize UI Test Suite
Suite Teardown    Cleanup UI Test Suite
Test Setup        Initialize Browser For Test
Test Teardown     Cleanup Browser After Test

Force Tags        ui    books
Default Tags      regression

*** Variables ***
${SUITE_START_TIME}       ${EMPTY}

*** Test Cases ***
User Should Be Able To View All Books
    [Documentation]    Verify that a user can view the complete list of books
    ...                
    ...                This test verifies:
    ...                - Books page loads successfully
    ...                - Book cards are displayed
    ...                - At least one book is visible
    [Tags]    smoke    view    priority-high
    
    Given User Opens The Books Application
    When User Navigates To Books Page
    Then All Books Should Be Displayed
    And Book Count Should Be Greater Than Zero

User Should Be Able To Search For Books By Title
    [Documentation]    Verify that a user can search for books using the search feature
    ...                
    ...                This test verifies:
    ...                - Search input is functional
    ...                - Search results are filtered correctly
    ...                - Search results contain the search term
    [Tags]    search    priority-high
    
    Given User Opens The Books Application
    And User Navigates To Books Page
    When User Searches For Book    Mystery
    Then Search Results Should Be Displayed
    And Search Results Should Contain    Mystery

User Should See Books After Clearing Search
    [Documentation]    Verify that clearing the search shows all books again
    ...                
    ...                This test verifies:
    ...                - Search can be cleared
    ...                - All books are displayed after clearing search
    [Tags]    search    priority-medium
    
    Given User Opens The Books Application
    And User Navigates To Books Page
    And User Searches For Book    Python
    When User Clears The Search
    Then All Books Should Be Displayed
    And Book Count Should Be Greater Than Zero

User Should See No Results For Nonexistent Book
    [Documentation]    Verify that searching for a nonexistent book shows no results
    ...                
    ...                This test verifies:
    ...                - Search handles nonexistent terms gracefully
    ...                - No books are displayed for invalid search
    [Tags]    search    negative    priority-low
    
    Given User Opens The Books Application
    And User Navigates To Books Page
    When User Searches For Book    XYZ123NonexistentBook999
    Then No Books Should Be Displayed

User Should See Correct Page Title
    [Documentation]    Verify that the page title is correct
    ...                
    ...                This test verifies:
    ...                - Page title matches expected value
    ...                - Page metadata is correct
    [Tags]    smoke    priority-medium
    
    Given User Opens The Books Application
    When User Navigates To Books Page
    Then Page Title Should Be Correct

Books Should Load Within Acceptable Time
    [Documentation]    Verify that books load within acceptable time limits
    ...                
    ...                This test verifies:
    ...                - Page loads within timeout
    ...                - Books are displayed promptly
    ...                - No excessive loading delays
    [Tags]    performance    priority-medium
    
    Given User Opens The Books Application
    When User Navigates To Books Page
    Then Books Should Load Quickly

*** Keywords ***
Initialize UI Test Suite
    [Documentation]    Runs once before all UI tests in this suite
    ...                
    ...                This keyword:
    ...                - Logs suite start
    ...                - Records suite start time
    ...                - Verifies service availability
    
    Log    Starting Books UI Test Suite    level=INFO
    ${start_time}=    Get Time    epoch
    VAR    ${SUITE_START_TIME}    ${start_time}    scope=SUITE
    Verify Service Is Available

Cleanup UI Test Suite
    [Documentation]    Runs once after all UI tests in this suite
    ...                
    ...                This keyword:
    ...                - Logs suite completion
    ...                - Calculates and logs suite duration
    
    TRY
        ${end_time}=    Get Time    epoch
        ${duration}=    Evaluate    ${end_time} - ${SUITE_START_TIME}
        Log    Books UI Test Suite completed in ${duration} seconds    level=INFO
    EXCEPT
        Log    Suite duration calculation skipped (suite setup may have failed)    level=WARN
    END

Initialize Browser For Test
    [Documentation]    Initializes browser for each test case
    ...                
    ...                This keyword:
    ...                - Creates new browser instance
    ...                - Sets viewport size
    ...                - Records test start time
    
    New Browser    ${BROWSER}    headless=${HEADLESS}
    New Context    viewport={'width': ${VIEWPORT_WIDTH}, 'height': ${VIEWPORT_HEIGHT}}
    ${start_time}=    Get Time    epoch
    VAR    ${TEST_START_TIME}    ${start_time}    scope=TEST
    Log    Browser initialized for test: ${TEST_NAME}

Cleanup Browser After Test
    [Documentation]    Cleans up browser after each test case
    ...                
    ...                This keyword:
    ...                - Takes screenshot on failure
    ...                - Closes browser
    ...                - Logs test duration
    
    Take Screenshot On Failure
    
    TRY
        Close Browser
    EXCEPT    AS    ${error}
        Log    Browser cleanup failed: ${error}    level=WARN
    END
    
    Log Test Duration    ${TEST_START_TIME}

User Opens The Books Application
    [Documentation]    Opens the Books application in browser
    ...                
    ...                This is a Gherkin-style Given keyword that:
    ...                - Navigates to the Books page URL
    ...                - Waits for page to load
    
    Navigate To Books Page

User Navigates To Books Page
    [Documentation]    Navigates to the Books page and verifies it loaded
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Verifies the Books page is displayed
    ...                - Confirms page title is correct
    
    Verify Books Page Is Displayed

All Books Should Be Displayed
    [Documentation]    Verifies that books are visible on the page
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Waits for book cards to be visible
    ...                - Confirms at least one book is displayed
    
    Verify Books Are Displayed

Book Count Should Be Greater Than Zero
    [Documentation]    Verifies at least one book is displayed
    ...                
    ...                This is a Gherkin-style And keyword that:
    ...                - Gets the count of displayed books
    ...                - Asserts count is greater than zero
    
    ${count}=    Get Book Count
    Should Be True    ${count} > 0    No books displayed on page
    Log    Verified ${count} books are displayed

User Searches For Book
    [Documentation]    Performs a book search
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Enters search term in search input
    ...                - Waits for search results to load
    ...                
    ...                Arguments:
    ...                - search_term: Text to search for
    [Arguments]    ${search_term}
    
    Search For Book    ${search_term}

Search Results Should Be Displayed
    [Documentation]    Verifies that search results are displayed
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies at least one result is shown
    
    Verify Books Are Displayed

Search Results Should Contain
    [Documentation]    Verifies search results contain the expected term
    ...                
    ...                This is a Gherkin-style And keyword that:
    ...                - Gets all displayed book titles
    ...                - Verifies at least one contains the search term
    ...                
    ...                Arguments:
    ...                - expected_term: Term that should appear in results
    [Arguments]    ${expected_term}
    
    @{titles}=    Get All Book Titles
    ${found}=    Evaluate    any('${expected_term}'.lower() in title.lower() for title in ${titles})
    Should Be True    ${found}    No book titles contain "${expected_term}"
    Log    Search results contain expected term: ${expected_term}

User Clears The Search
    [Documentation]    Clears the search input
    ...                
    ...                This is a Gherkin-style When keyword that:
    ...                - Clears the search input field
    ...                - Waits for all books to reload
    
    Clear Search

No Books Should Be Displayed
    [Documentation]    Verifies that no books are displayed
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Verifies no book cards are visible
    ...                - Confirms empty state is shown
    
    Verify No Books Displayed

Page Title Should Be Correct
    [Documentation]    Verifies the page title is correct
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Gets the page title
    ...                - Verifies it contains "Books"
    
    ${title}=    Get Title
    Should Contain    ${title}    Books    ignore_case=True
    Log    Page title is correct: ${title}

Books Should Load Quickly
    [Documentation]    Verifies books load within acceptable time
    ...                
    ...                This is a Gherkin-style Then keyword that:
    ...                - Waits for books to load
    ...                - Verifies loading completed within timeout
    
    Wait For Books To Load
    Verify Books Are Displayed
    Log    Books loaded within acceptable time
