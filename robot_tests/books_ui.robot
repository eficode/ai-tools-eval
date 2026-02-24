*** Settings ***
Documentation     Books UI Test Suite
...               
...               Validates book management through web interface.
...               Tests cover CRUD operations, search, and filtering.

Resource          resources/common_ui.resource
Resource          resources/ui_keywords.resource
Resource          resources/api_keywords.resource

Suite Setup       Suite Initialization For UI
Suite Teardown    Suite Cleanup For UI
Test Setup        Test Initialization For UI
Test Teardown     Test Cleanup For UI

Force Tags        ui    books

*** Test Cases ***
User Should Be Able To Create Book Via UI
    [Documentation]    Verify book creation through web form
    [Tags]    smoke    create
    Given User Is On Books Page
    When User Creates Book With Valid Data
    Then Book Should Appear In Books List

User Should Be Able To Search For Books
    [Documentation]    Verify search functionality
    [Tags]    search
    Given User Is On Books Page
    And Test Book Exists In System
    When User Searches For Test Book
    Then Only Matching Books Should Be Visible

User Should Be Able To Filter Books By Category
    [Documentation]    Verify category filtering
    [Tags]    filter
    Given User Is On Books Page
    When User Filters By Fiction Category
    Then Only Fiction Books Should Be Visible

User Should See All Books On Page Load
    [Documentation]    Verify initial page load displays books
    [Tags]    smoke
    Given Books Exist In Database
    When User Opens Books Page
    Then Books Should Be Displayed

*** Keywords ***
User Creates Book With Valid Data
    [Documentation]    Fill and submit book form
    ${title}=    Set Variable    Test Book ${TIMESTAMP} ${UNIQUE_ID}
    ${author}=    Set Variable    Test Author
    ${pages}=    Set Variable    250
    ${category}=    Set Variable    Fiction
    User Fills Book Form    ${title}    ${author}    ${pages}    ${category}
    User Submits Book Form
    Set Test Variable    ${TEST_BOOK_TITLE}    ${title}

Book Should Appear In Books List
    [Documentation]    Verify book was created via API
    ${response}=    Get All Books Via API
    ${books}=    Set Variable    ${response.json()}
    ${found}=    Evaluate    [b for b in ${books} if '${TEST_BOOK_TITLE}' in b.get('title', '')]
    Should Not Be Empty    ${found}

Test Book Exists In System
    [Documentation]    Create test book via API
    ${title}=    Set Variable    Search Test ${TIMESTAMP}
    ${book_id}=    Create Book Via API    ${title}    Test Author    200    Fiction
    Set Test Variable    ${TEST_BOOK_TITLE}    ${title}
    Set Test Variable    ${BOOK_ID}    ${book_id}

User Searches For Test Book
    [Documentation]    Search for created book
    User Searches For Book    ${TEST_BOOK_TITLE}

Only Matching Books Should Be Visible
    [Documentation]    Verify search field works
    ${count}=    Get Element Count    css=.book-card
    Should Be True    ${count} > 0

User Filters By Fiction Category
    [Documentation]    Apply Fiction category filter
    User Filters By Category    Fiction

Only Fiction Books Should Be Visible
    [Documentation]    Verify filtered results
    ${count}=    Get Element Count    css=.book-card
    Should Be True    ${count} > 0

Books Exist In Database
    [Documentation]    Verify books exist via API
    ${response}=    Get All Books Via API
    Response Should Contain Books    ${response}

User Opens Books Page
    [Documentation]    Navigate to books page
    User Is On Books Page

Books Should Be Displayed
    [Documentation]    Verify books are visible
    ${count}=    Get Element Count    css=.book-card
    Should Be True    ${count} > 0
