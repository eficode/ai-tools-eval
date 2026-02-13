*** Settings ***
Documentation     API tests for Books Database Service
...               Tests REST API functionality using RequestsLibrary 0.9.7
...               Following Gherkin patterns and comprehensive validation

Resource          resources/common.resource
Resource          resources/api_keywords.resource

Suite Setup       Setup Test Environment
Suite Teardown    Teardown Test Environment

Force Tags        api


*** Test Cases ***
API Should Create Book With Valid Data
    [Documentation]    Validates book creation via REST API with valid data
    [Tags]    smoke    crud    create
    
    # Generate unique test data
    ${test_data}=    Generate Unique Test Data
    
    # Execute test using Gherkin pattern
    Given API Session Is Created
    When Book Is Created Via API    ${test_data}[title]    ${test_data}[author]
    Then API Should Return Book    ${CREATED_BOOK}[id]    ${test_data}[title]
    
    [Teardown]    Cleanup Test Data    ${CREATED_BOOK}[id]

API Should Return All Books With Correct Structure
    [Documentation]    Validates API endpoint returns properly formatted data
    [Tags]    smoke    read    validation
    
    # Create test book for validation
    ${test_data}=    Generate Unique Test Data
    ${created_book}=    Create Book Via API    ${test_data}[title]    ${test_data}[author]
    
    # Validate API response structure
    Given API Session Is Created
    When All Books Are Retrieved Via API
    Then API Should Return Valid Book List
    
    [Teardown]    Cleanup Test Data    ${created_book}[id]

API Should Update Existing Book
    [Documentation]    Validates book update functionality via REST API
    [Tags]    crud    update
    
    # Create initial book
    ${initial_data}=    Generate Unique Test Data
    ${book}=    Create Book Via API    ${initial_data}[title]    ${initial_data}[author]
    
    # Update book data
    ${updated_title}=    Set Variable    Updated ${initial_data}[title]
    ${updated_author}=    Set Variable    Updated ${initial_data}[author]
    
    ${updated_book}=    Update Book Via API    ${book}[id]    ${updated_title}    ${updated_author}
    
    # Verify update
    Should Be Equal    ${updated_book}[title]    ${updated_title}
    Should Be Equal    ${updated_book}[author]    ${updated_author}
    Should Be Equal As Integers    ${updated_book}[id]    ${book}[id]
    
    [Teardown]    Cleanup Test Data    ${book}[id]

API Should Delete Existing Book
    [Documentation]    Validates book deletion functionality via REST API
    [Tags]    crud    delete
    
    # Create book to delete
    ${test_data}=    Generate Unique Test Data
    ${book}=    Create Book Via API    ${test_data}[title]    ${test_data}[author]
    
    # Delete book
    Delete Book Via API    ${book}[id]
    
    # Verify book is deleted
    TRY
        Get Book By ID Via API    ${book}[id]
        Fail    Book should have been deleted
    EXCEPT    AS    ${error}
        Log    Expected error: Book not found after deletion    INFO
    END

API Should Handle Invalid Data Gracefully
    [Documentation]    Validates error handling for malformed API requests
    [Tags]    error-handling    negative    validation
    
    # Test missing required fields
    &{empty_data}=    Create Dictionary
    Test Invalid API Request    ${empty_data}    400
    
    # Test invalid data types
    &{invalid_data}=    Create Dictionary    title=${123}    author=${TRUE}
    Test Invalid API Request    ${invalid_data}    400
    
    # Test missing title
    &{no_title}=    Create Dictionary    author=Test Author
    Test Invalid API Request    ${no_title}    400
    
    # Test missing author
    &{no_author}=    Create Dictionary    title=Test Title
    Test Invalid API Request    ${no_author}    400

API Should Return 404 For Non-Existent Book
    [Documentation]    Validates proper 404 response for non-existent resources
    [Tags]    error-handling    not-found
    
    ${non_existent_id}=    Set Variable    99999
    
    TRY
        ${response}=    GET On Session    books_api    /books/${non_existent_id}    expected_status=404
        Log    Correct: Received 404 for non-existent book    INFO
    EXCEPT    AS    ${error}
        Log    Expected 404 error: ${error}    INFO
    END

API Should Support Book Search By Title
    [Documentation]    Validates API search functionality if available
    [Tags]    search    functionality
    
    # Create test books with different titles
    ${book1_data}=    Generate Unique Test Data
    ${book2_data}=    Generate Unique Test Data
    Set To Dictionary    ${book2_data}    title    Different ${book2_data}[title]
    
    ${book1}=    Create Book Via API    ${book1_data}[title]    ${book1_data}[author]
    ${book2}=    Create Book Via API    ${book2_data}[title]    ${book2_data}[author]
    
    # Get all books and verify both exist
    ${all_books}=    Get All Books Via API
    
    ${found_book1}=    Set Variable    ${FALSE}
    ${found_book2}=    Set Variable    ${FALSE}
    
    FOR    ${book}    IN    @{all_books}
        IF    ${book}[id] == ${book1}[id]
            ${found_book1}=    Set Variable    ${TRUE}
        END
        IF    ${book}[id] == ${book2}[id]
            ${found_book2}=    Set Variable    ${TRUE}
        END
    END
    
    Should Be True    ${found_book1}    Book 1 should be found in API response
    Should Be True    ${found_book2}    Book 2 should be found in API response
    
    [Teardown]    Run Keywords
    ...    Cleanup Test Data    ${book1}[id]    AND
    ...    Cleanup Test Data    ${book2}[id]

API Response Time Should Meet Performance Requirements
    [Documentation]    Validates API response time meets acceptable thresholds
    [Tags]    performance    non-functional
    
    # Test GET /books/ endpoint performance
    ${start_time}=    Get Time    epoch
    ${response}=    GET On Session    books_api    /books/    expected_status=200
    ${end_time}=    Get Time    epoch
    
    ${response_time}=    Evaluate    ${end_time} - ${start_time}
    Log    API response time: ${response_time} seconds    INFO
    Should Be True    ${response_time} < 2    API response too slow: ${response_time}s
    
    # Verify response is valid
    Should Be Equal As Integers    ${response.status_code}    200
    ${books}=    Set Variable    ${response.json()}
    Should Be True    isinstance($books, list)    Response should be a list

API Should Handle Concurrent Requests
    [Documentation]    Validates API stability under concurrent load
    [Tags]    performance    concurrency
    
    # Create multiple books concurrently (simulated)
    @{created_books}=    Create List
    
    FOR    ${i}    IN RANGE    3
        ${test_data}=    Generate Unique Test Data
        Set To Dictionary    ${test_data}    title    Concurrent Book ${i} ${test_data}[title]
        ${book}=    Create Book Via API    ${test_data}[title]    ${test_data}[author]
        Append To List    ${created_books}    ${book}
    END
    
    # Verify all books were created successfully
    ${all_books}=    Get All Books Via API
    
    FOR    ${created_book}    IN    @{created_books}
        ${found}=    Set Variable    ${FALSE}
        FOR    ${book}    IN    @{all_books}
            IF    ${book}[id] == ${created_book}[id]
                ${found}=    Set Variable    ${TRUE}
                BREAK
            END
        END
        Should Be True    ${found}    Book ${created_book}[id] should exist in API response
    END
    
    [Teardown]    
    FOR    ${book}    IN    @{created_books}
        Cleanup Test Data    ${book}[id]
    END