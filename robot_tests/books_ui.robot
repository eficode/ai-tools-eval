*** Settings ***
Documentation     Books Library UI Test Suite - Gherkin Style
...               
...               This test suite validates the Books Library web application UI functionality
...               using modern Robot Framework 7.4.1 syntax with Gherkin-style keywords.
...               
...               Test focus areas:
...               - Book creation through web form
...               - Book listing and display validation  
...               - Search and filter functionality
...               - Favorite books management
...               - Error handling for invalid inputs

Resource          resources/common.resource
Resource          resources/ui_keywords.resource

Suite Setup       Setup Test Environment
Suite Teardown    Cleanup Test Environment
Test Teardown     Reset Application State

Force Tags        books    ui    e2e
Default Tags      smoke


*** Variables ***
# Browser configuration - using BASE_URL from common.resource
${BROWSER_TYPE}       chromium
${HEADLESS}           true


*** Test Cases ***
User Should Be Able To Add New Book Through Web Form
    [Documentation]    Validates complete book creation workflow through web UI
    [Tags]    books    ui    create    happy-path
    Given User Is On Books Library Homepage
    When User Fills Book Creation Form
    ...    title=Robot Framework Testing Guide
    ...    author=Test Automation Team  
    ...    pages=350
    ...    category=Non-Fiction
    And User Submits The Book Form
    Then New Book Should Appear In Books List    Robot Framework Testing Guide
    And Success Notification Should Be Displayed
    And Form Fields Should Be Reset

User Should Be Able To Search For Books By Title
    [Documentation]    Validates book search functionality using title search
    [Tags]    books    ui    search    filter
    Given User Is On Books Library Homepage  
    And Sample Books Are Already Present
    When User Searches For Book    title=1984
    Then Only Matching Books Should Be Displayed    1984
    And Search Results Count Should Be Updated

User Should Be Able To Filter Books By Category
    [Documentation]    Validates category-based filtering of book collection
    [Tags]    books    ui    filter    category
    Given User Is On Books Library Homepage
    And Sample Books Are Already Present
    When User Filters Books By Category    Science Fiction
    Then Only Books From Category Should Be Displayed    Science Fiction
    And Category Filter Should Remain Active    Science Fiction

User Should Be Able To Mark Books As Favorites
    [Documentation]    Validates favorite books toggle functionality
    [Tags]    books    ui    favorites    interaction
    Given User Is On Books Library Homepage
    And Sample Books Are Already Present
    ${book_title}=    User Marks First Book As Favorite
    Then Book Should Display Favorite Status    ${book_title}
    When User Filters By Favorites Only
    Then Only Favorite Books Should Be Displayed

User Should Be Able To Sort Books By Different Criteria
    [Documentation]    Validates book sorting functionality with different sort options
    [Tags]    books    ui    sorting    display
    Given User Is On Books Library Homepage
    And Sample Books Are Already Present
    When User Sorts Books By    pages
    And User Changes Sort Direction To    ascending
    Then Books Should Be Displayed In Correct Order    pages    ascending

System Should Validate Required Fields On Book Creation
    [Documentation]    Validates form validation for required fields
    [Tags]    books    ui    validation    edge-case
    Given User Is On Books Library Homepage
    When User Attempts To Submit Empty Book Form
    Then Form Validation Errors Should Be Displayed
    And No New Book Should Be Created
    When User Fills Only Title Field    Incomplete Book Entry
    And User Submits The Book Form  
    Then Remaining Required Field Errors Should Be Displayed

System Should Handle Large Book Collections Gracefully
    [Documentation]    Validates pagination and performance with many books
    [Tags]    books    ui    performance    pagination
    Given User Is On Books Library Homepage
    And Large Number Of Books Are Present
    When User Scrolls To Bottom Of Books List
    Then Load More Button Should Be Available
    When User Clicks Load More Button
    Then Additional Books Should Be Loaded
    And Page Should Remain Responsive

System Should Handle Network Errors Gracefully  
    [Documentation]    Validates error handling when API is unavailable
    [Tags]    books    ui    error-handling    negative
    Given User Is On Books Library Homepage
    When API Service Becomes Unavailable
    And User Attempts To Add New Book
    ...    title=Network Test Book
    ...    author=Error Handler
    ...    pages=200
    ...    category=Fiction
    Then Network Error Message Should Be Displayed
    And User Should Be Able To Retry Operation