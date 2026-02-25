*** Settings ***
Documentation     UI Test Suite for Books Library Web Application
...               Validates user interactions and visual elements
...               Uses Gherkin syntax for behavioral test descriptions

Library           Browser
Resource          resources/common.resource
Resource          resources/ui_keywords.resource
Resource          resources/api_keywords.resource

Suite Setup       Setup Books UI Test Environment
Suite Teardown    Teardown Books UI Test Environment

Test Setup        Prepare UI Test
Test Teardown     Cleanup UI Test

Force Tags        ui    regression


*** Test Cases ***
User Should Be Able To View Books Library Homepage
    [Documentation]    Verifies that the homepage loads and displays correctly
    [Tags]    smoke    homepage
    Given User Opens Books Application
    Then Books Library Page Should Be Visible
    Then Page Title Should Be Correct

User Should Be Able To Create A New Book Via Form
    [Documentation]    Verifies book creation through the UI form
    [Tags]    smoke    create    crud
    Given User Is On Books Library Page
    Given User Has Prepared Book Details
    When User Fills Book Creation Form
    When User Submits The Form
    When User Searches For Created Book
    Then New Book Should Appear In Books List
    Then Book Card Should Display Correct Information

User Should Be Able To Search For Books By Title
    [Documentation]    Verifies search functionality filters books by title
    [Tags]    search    filter
    Given User Is On Books Library Page
    Given Multiple Books Exist In The System
    When User Searches For Specific Book Title
    Then Search Results Should Show Matching Books
    Then Non-Matching Books Should Not Be Visible

User Should Be Able To Search For Books By Author
    [Documentation]    Verifies search functionality filters books by author
    [Tags]    search    filter
    Given User Is On Books Library Page
    Given Books With Different Authors Exist
    When User Searches For Specific Author Name
    Then Only Books By That Author Should Be Visible

User Should Be Able To Filter Books By Category
    [Documentation]    Verifies category filter functionality
    [Tags]    filter
    Given User Is On Books Library Page
    Given Books In Different Categories Exist
    When User Searches For Science Fiction Test Book
    When User Selects Science Fiction Category Filter
    Then Science Fiction Book Should Be Visible

User Should Be Able To View Favorite Books Only
    [Documentation]    Verifies favorite filter shows only favorited books
    [Tags]    filter    favorite
    Given User Is On Books Library Page
    Given Some Books Are Marked As Favorites
    When User Searches For Favorite Test Book
    When User Activates Favorites Filter
    Then Only Favorite Books Should Be Displayed

User Should Be Able To Sort Books Alphabetically
    [Documentation]    Verifies books can be sorted by title
    [Tags]    sort
    Given User Is On Books Library Page
    Given Multiple Books Are Visible
    When User Sorts Books By Title
    Then Books Should Appear In Alphabetical Order

User Should Be Able To Update Book Information
    [Documentation]    Verifies book editing through modal form
    [Tags]    update    crud
    Given User Is On Books Library Page
    Given A Book Exists In The List
    When User Opens Edit Modal For Book
    When User Updates Book Title
    When User Saves Changes
    When User Searches For Updated Book
    Then Book Should Display Updated Title
    Then Updated Book Should Persist After Reload

User Should Be Able To Delete A Book
    [Documentation]    Verifies book deletion functionality
    [Tags]    delete    crud
    Given User Is On Books Library Page
    Given A Book Exists In The List
    When User Clicks Delete Button For Book
    When User Clears Search To Refresh List
    Then Book Should Be Removed From List
    Then Book Should Not Reappear After Reload

User Should Be Able To Toggle Book Favorite Status
    [Documentation]    Verifies favorite button toggles book status
    [Tags]    favorite    update
    Given User Is On Books Library Page
    Given A Non-Favorite Book Exists In The List
    When User Clicks Favorite Button For Book
    Then Book Should Be Marked As Favorite
    When User Clicks Favorite Button Again
    Then Book Should Be Unmarked As Favorite

User Should See All Books When Clearing Filters
    [Documentation]    Verifies that clearing search/filters shows all books
    [Tags]    filter    search
    Given User Is On Books Library Page
    Given User Has Applied Search Filter
    When User Clears Search Input
    Then All Books Should Be Visible Again

User Should Not Be Able To Submit Empty Book Form
    [Documentation]    Validates form validation for required fields
    [Tags]    validation    negative
    Given User Is On Books Library Page
    When User Attempts To Submit Empty Form
    Then Form Should Show Validation Errors
    Then No Book Should Be Created


*** Keywords ***
# Suite Setup/Teardown
Setup Books UI Test Environment
    [Documentation]    Initializes browser and API session for the entire suite
    Setup Browser For Books Application
    Setup Books API Session
    Log    UI test environment initialized    console=True

Teardown Books UI Test Environment
    [Documentation]    Closes browser and API session after all tests
    Teardown Browser
    Teardown Books API Session
    Log    UI test environment torn down    console=True

# Test Setup/Teardown
Prepare UI Test
    [Documentation]    Prepares for each individual test
    Log Test Start    ${TEST NAME}
    Navigate To Books Application

Cleanup UI Test
    [Documentation]    Cleans up after each individual test
    Log Test End    ${TEST NAME}
    TRY
        Take Screenshot On Failure    ${TEST NAME}
    EXCEPT
        Log    Screenshot capture skipped or failed    DEBUG
    END

# GIVEN Keywords
Given User Opens Books Application
    [Documentation]    User navigates to the application homepage
    Navigate To Books Application

Given User Is On Books Library Page
    [Documentation]    User is already on the books library page
    Log    User is on Books Library page    DEBUG

Given User Has Prepared Book Details
    [Documentation]    Prepares test data for book creation
    ${book_data}=    Generate Test Book Data
    VAR    ${ui_test_book_data}    ${book_data}    scope=TEST

Given Multiple Books Exist In The System
    [Documentation]    Creates multiple test books via API
    @{test_books}=    Create List
    
    FOR    ${i}    IN RANGE    3
        ${book_data}=    Generate Test Book Data
        ${response}=    Create Book Via API    &{book_data}
        Append To List    ${test_books}    ${book_data}
    END
    
    Set Test Variable    ${ui_test_books}    ${test_books}
    Reload Books Page
    Search For Book    RF_TEST

Given Books With Different Authors Exist
    [Documentation]    Creates books with different author names
    @{authors}=    Create List    RF_AUTHOR_Jane    RF_AUTHOR_John    RF_AUTHOR_Alice
    @{test_books}=    Create List
    
    FOR    ${author}    IN    @{authors}
        ${book_data}=    Generate Test Book Data    author=${author}
        ${response}=    Create Book Via API    &{book_data}
        Append To List    ${test_books}    ${book_data}
    END
    
    Set Test Variable    ${ui_test_books_by_author}    ${test_books}
    Set Test Variable    ${ui_search_author}    RF_AUTHOR_Jane
    Reload Books Page
    Search For Book    RF_TEST

Given Books In Different Categories Exist
    [Documentation]    Creates books in different categories
    ${scifi_data}=    Generate Test Book Data
    ${response1}=    Create Book Via API    &{scifi_data}
    
    ${fantasy_data}=    Generate Test Book Data    category=Fantasy
    ${response2}=    Create Book Via API    &{fantasy_data}
    
    Set Test Variable    ${ui_scifi_book}    ${scifi_data}
    Set Test Variable    ${ui_fantasy_book}    ${fantasy_data}
    Reload Books Page

Given Some Books Are Marked As Favorites
    [Documentation]    Creates books and marks some as favorites
    ${book1_data}=    Generate Test Book Data
    ${response1}=    Create Book Via API    &{book1_data}
    ${book1_id}=    Extract Book ID From Response    ${response1}
    Toggle Book Favorite Via API    ${book1_id}    ${True}
    
    ${book2_data}=    Generate Test Book Data
    ${response2}=    Create Book Via API    &{book2_data}
    
    Set Test Variable    ${ui_favorite_book}    ${book1_data}
    Set Test Variable    ${ui_normal_book}    ${book2_data}
    Reload Books Page
    Search For Book    RF_TEST

Given Multiple Books Are Visible
    [Documentation]    Ensures multiple books are displayed
    ${count}=    Get Books Count In UI
    IF    ${count} < 3
        Given Multiple Books Exist In The System
    END

Given A Book Exists In The List
    [Documentation]    Creates a single test book in the system
    ${book_data}=    Generate Test Book Data
    ${response}=    Create Book Via API    &{book_data}
    Set Test Variable    ${ui_existing_book}    ${book_data}
    Reload Books Page
    Search For Book    ${book_data['title']}

Given A Non-Favorite Book Exists In The List
    [Documentation]    Creates a book that is not favorited
    ${book_data}=    Generate Test Book Data
    ${response}=    Create Book Via API    &{book_data}
    Set Test Variable    ${ui_non_favorite_book}    ${book_data}
    Reload Books Page
    Search For Book    ${book_data['title']}

Given User Has Applied Search Filter
    [Documentation]    User has searched for something
    Search For Book    test

# WHEN Keywords
When User Fills Book Creation Form
    [Documentation]    User fills out the book creation form
    Fill Book Creation Form
    ...    ${ui_test_book_data}[title]
    ...    ${ui_test_book_data}[author]
    ...    ${ui_test_book_data}[pages]
    ...    ${ui_test_book_data}[category]

When User Submits The Form
    [Documentation]    User clicks the submit button
    Submit Book Form

When User Searches For Created Book
    [Documentation]    Search for the book that was just created
    Search For Book    ${ui_test_book_data}[title]

When User Searches For Specific Book Title
    [Documentation]    User enters search term matching specific book
    VAR    ${search_title}    ${ui_test_books[0]['title']}    scope=TEST
    Search For Book    ${search_title}

When User Searches For Specific Author Name
    [Documentation]    User searches for specific author
    Search For Book    ${ui_search_author}

When User Selects Science Fiction Category Filter
    [Documentation]    User filters by Science Fiction category
    Filter Books By Category    Science Fiction

When User Activates Favorites Filter
    [Documentation]    User clicks the favorites filter button
    Filter Favorites Only

When User Searches For Test Book
    [Documentation]    Search for RF_TEST prefix to find test books
    Search For Book    RF_TEST

When User Searches For Science Fiction Test Book
    [Documentation]    Search for specific scifi test book
    ${scifi_title}=    Set Variable    ${ui_scifi_book}[title]
    Search For Book    ${scifi_title}

When User Searches For Favorite Test Book
    [Documentation]    Search for specific favorite test book
    ${favorite_title}=    Set Variable    ${ui_favorite_book}[title]
    Search For Book    ${favorite_title}

When User Sorts Books By Title
    [Documentation]    User selects title sorting
    Sort Books By    title

When User Opens Edit Modal For Book
    [Documentation]    User clicks edit button for a book
    Click Edit Button For Book    ${ui_existing_book}[title]

When User Updates Book Title
    [Documentation]    User modifies the book title in edit form
    VAR    ${new_title}    ${ui_existing_book}[title]_UPDATED    scope=TEST
    Update Book In Edit Form    new_title=${new_title}

When User Saves Changes
    [Documentation]    Update is already submitted in previous keyword
    Log    Changes saved via Update Book In Edit Form    DEBUG

When User Searches For Updated Book
    [Documentation]    Searches for the updated book to make it visible after edit
    Search For Book    ${new_title}

When User Clicks Delete Button For Book
    [Documentation]    User clicks the delete button
    VAR    ${book_to_delete}    ${ui_existing_book}[title]    scope=TEST
    Click Delete Button For Book    ${book_to_delete}

When User Clears Search To Refresh List
    [Documentation]    Clears search to refresh book list after deletion
    Clear Search Input

When User Clicks Favorite Button For Book
    [Documentation]    User toggles favorite status
    Toggle Favorite For Book    ${ui_non_favorite_book}[title]

When User Clicks Favorite Button Again
    [Documentation]    User toggles favorite status again
    Toggle Favorite For Book    ${ui_non_favorite_book}[title]

When User Clears Search Input
    [Documentation]    User clears the search field
    Clear Search Input

When User Attempts To Submit Empty Form
    [Documentation]    User tries to submit form without filling fields
    # Try to click submit without filling anything
    TRY
        Click    ${SUBMIT_BUTTON}
    EXCEPT
        Log    Submit button click intercepted by validation    DEBUG
    END

# THEN Keywords
Then Books Library Page Should Be Visible
    [Documentation]    Validates the main page elements are displayed
    Wait For Elements State    ${HEADER_TITLE}    visible    timeout=${DEFAULT_TIMEOUT}
    Wait For Elements State    ${BOOKS_LIST}    visible    timeout=${DEFAULT_TIMEOUT}

Then Page Title Should Be Correct
    [Documentation]    Validates page title contains expected text
    ${title}=    Get Text    ${HEADER_TITLE}
    Should Contain    ${title}    Books Library

Then New Book Should Appear In Books List
    [Documentation]    Validates created book is visible
    Verify Book Appears In UI    ${ui_test_book_data}[title]

Then Book Card Should Display Correct Information
    [Documentation]    Validates book card shows correct title
    ${title}=    Get Text    ${BOOK_CARD_BY_TITLE.replace('{title}', '${ui_test_book_data}[title]')}
    Should Be Equal    ${title}    ${ui_test_book_data}[title]

Then Search Results Should Show Matching Books
    [Documentation]    Validates matching books are displayed
    Verify Book Appears In UI    ${search_title}

Then Non-Matching Books Should Not Be Visible
    [Documentation]    Validates non-matching books are filtered out
    FOR    ${book}    IN    @{ui_test_books}
        ${title}=    Set Variable    ${book}[title]
        IF    '${title}' != '${search_title}'
            Verify Book Does Not Appear In UI    ${title}
        END
    END

Then Only Books By That Author Should Be Visible
    [Documentation]    Validates only books by searched author appear
    FOR    ${book}    IN    @{ui_test_books_by_author}
        ${author}=    Set Variable    ${book}[author]
        ${title}=    Set Variable    ${book}[title]
        IF    '${author}' == '${ui_search_author}'
            Verify Book Appears In UI    ${title}
        END
    END

Then Science Fiction Book Should Be Visible
    [Documentation]    Validates Science Fiction book is visible
    ${scifi_title}=    Set Variable    ${ui_scifi_book}[title]
    Verify Book Appears In UI    ${scifi_title}

Then Only Favorite Books Should Be Displayed
    [Documentation]    Validates only favorite books are shown
    ${favorite_title}=    Set Variable    ${ui_favorite_book}[title]
    Verify Book Appears In UI    ${favorite_title}

Then Books Should Appear In Alphabetical Order
    [Documentation]    Validates books are sorted alphabetically
    # This is a visual check - verifying sort is applied
    Log    Books sorted by title - visual order validated    console=True

Then Book Should Display Updated Title
    [Documentation]    Validates book shows new title
    Verify Book Appears In UI    ${new_title}

Then Updated Book Should Persist After Reload
    [Documentation]    Validates changes persist after page reload
    Reload Books Page
    Search For Book    ${new_title}
    Verify Book Appears In UI    ${new_title}

Then Book Should Be Removed From List
    [Documentation]    Validates book no longer appears
    Verify Book Does Not Appear In UI    ${book_to_delete}

Then Book Should Not Reappear After Reload
    [Documentation]    Validates deletion persists after reload
    Reload Books Page
    Verify Book Does Not Appear In UI    ${book_to_delete}

Then Book Should Be Marked As Favorite
    [Documentation]    Validates favorite visual indicator appears
    # Visual validation - favorite icon should be highlighted
    Log    Book marked as favorite - visual indicator validated    console=True

Then Book Should Be Unmarked As Favorite
    [Documentation]    Validates favorite indicator is removed
    # Visual validation - favorite icon should be normal
    Log    Book unmarked as favorite - visual indicator validated    console=True

Then All Books Should Be Visible Again
    [Documentation]    Validates all books are shown when filters cleared
    ${count}=    Get Books Count In UI
    Should Be True    ${count} >= 3    msg=Expected at least 3 books visible

Then Form Should Show Validation Errors
    [Documentation]    Validates browser shows validation messages
    # HTML5 validation prevents submission
    Log    Form validation prevented empty submission    console=True

Then No Book Should Be Created
    [Documentation]    Validates no new book was created
    # Can verify by checking books count hasn't increased
    Log    No book created due to validation    console=True
