*** Settings ***
Documentation     UI tests for Books Database Service
...               Tests web interface functionality using Browser Library 19.12.3
...               Following Gherkin patterns and Page Object Model

Resource          resources/common.resource
Resource          resources/ui_keywords.resource
Resource          resources/api_keywords.resource

Suite Setup       Setup Test Environment
Suite Teardown    Teardown Test Environment
Test Setup        Test Setup For UI Tests
Test Teardown     Test Teardown For UI Tests

Force Tags        ui


*** Keywords ***
Test Setup For UI Tests
    [Documentation]    Prepares environment for individual UI test
    Given Browser Is Open
    Given User Is On Books Page

Test Teardown For UI Tests
    [Documentation]    Cleans up after individual UI test
    Teardown Browser Environment


*** Test Cases ***
User Should Be Able To Add A New Book Via UI
    [Documentation]    Validates complete book creation workflow through web interface
    [Tags]    smoke    crud    add-book
    
    # Generate unique test data
    ${test_data}=    Generate Unique Test Data
    
    # Execute test using Gherkin pattern
    When User Adds A New Book    ${test_data}[title]    ${test_data}[author]
    
    # Verify the book was created by checking via API
    ${all_books}=    Get All Books Via API
    ${found}=    Set Variable    ${FALSE}
    FOR    ${book}    IN    @{all_books}
        IF    "${book}[title]" == "${test_data}[title]"
            ${found}=    Set Variable    ${TRUE}
            Log    Book found via API: ${book}[title]    INFO
            BREAK
        END
    END
    Should Be True    ${found}    Book was not created successfully
    
    # Also verify it appears in UI
    Then Book Should Be Visible    ${test_data}[title]    ${test_data}[author]

User Should Be Able To Search For Books
    [Documentation]    Validates search functionality filters books correctly
    [Tags]    search    functionality
    
    # Setup test data via API for consistent state
    ${book1_data}=    Generate Unique Test Data
    ${book2_data}=    Generate Unique Test Data
    Set To Dictionary    ${book2_data}    title    Different Title ${RANDOM_ID}
    
    ${book1}=    Create Book Via API    ${book1_data}[title]    ${book1_data}[author]
    ${book2}=    Create Book Via API    ${book2_data}[title]    ${book2_data}[author]
    
    # Refresh page to see new books
    Reload
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    
    # Test search functionality
    When User Searches For Book    ${book1_data}[title]
    Then Book Should Be Visible    ${book1_data}[title]    ${book1_data}[author]
    Then Book Should Not Be Visible    ${book2_data}[title]
    
    [Teardown]    Run Keywords
    ...    Cleanup Test Data    ${book1}[id]    AND
    ...    Cleanup Test Data    ${book2}[id]    AND
    ...    Test Teardown For UI Tests

Books Page Should Display All Books When No Search Filter
    [Documentation]    Validates that all books are visible without search filter
    [Tags]    display    all-books
    
    # Create multiple test books
    ${book1_data}=    Generate Unique Test Data
    ${book2_data}=    Generate Unique Test Data
    
    ${book1}=    Create Book Via API    ${book1_data}[title]    ${book1_data}[author]
    ${book2}=    Create Book Via API    ${book2_data}[title]    ${book2_data}[author]
    
    # Refresh page and verify both books are visible
    Reload
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    
    Then Book Should Be Visible    ${book1_data}[title]    ${book1_data}[author]
    Then Book Should Be Visible    ${book2_data}[title]    ${book2_data}[author]
    
    [Teardown]    Run Keywords
    ...    Cleanup Test Data    ${book1}[id]    AND
    ...    Cleanup Test Data    ${book2}[id]    AND
    ...    Test Teardown For UI Tests

Search Should Handle Empty Results Gracefully
    [Documentation]    Validates search behavior when no books match the criteria
    [Tags]    search    edge-case
    
    # Search for non-existent book
    ${non_existent_title}=    Set Variable    NonExistentBook${RANDOM_ID}
    When User Searches For Book    ${non_existent_title}
    
    # Verify no books are displayed
    ${book_count}=    Get Book Count From UI
    Should Be Equal As Integers    ${book_count}    0

User Should Be Able To Clear Search Filter
    [Documentation]    Validates that clearing search shows all books again
    [Tags]    search    clear-filter
    
    # Create test book
    ${test_data}=    Generate Unique Test Data
    ${book}=    Create Book Via API    ${test_data}[title]    ${test_data}[author]
    
    # Refresh page
    Reload
    Wait For Load State    networkidle    timeout=${DEFAULT_TIMEOUT}
    
    # Search for specific book
    When User Searches For Book    ${test_data}[title]
    Then Book Should Be Visible    ${test_data}[title]    ${test_data}[author]
    
    # Clear search and verify book is still visible
    Clear Search
    Then Book Should Be Visible    ${test_data}[title]    ${test_data}[author]
    
    [Teardown]    Run Keywords
    ...    Cleanup Test Data    ${book}[id]    AND
    ...    Test Teardown For UI Tests

Page Should Load Within Acceptable Time
    [Documentation]    Validates page load performance meets requirements
    [Tags]    performance    non-functional
    
    # Measure page load time
    ${start_time}=    Get Time    epoch
    Navigate To Books Page
    ${end_time}=    Get Time    epoch
    
    ${load_time}=    Evaluate    ${end_time} - ${start_time}
    Log    Page load time: ${load_time} seconds    INFO
    Should Be True    ${load_time} < 5    Page load took too long: ${load_time}s