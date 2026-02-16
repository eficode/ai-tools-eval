*** Settings ***
Documentation     Common resource file containing shared variables, keywords, and configurations
...               for the Books Library test automation suite.
...               
...               This resource provides:
...               - Environment configuration variables
...               - Common test data generation utilities
...               - Shared setup and teardown procedures
...               - Cross-cutting utility keywords

Library           Browser    timeout=${UI_TIMEOUT}    retry_assertions_for=5s
Library           RequestsLibrary
Library           Collections
Library           String
Library           DateTime
Library           OperatingSystem


*** Variables ***
# Environment Configuration
${BASE_URL}                   http://books-service:8000
${API_BASE_URL}              ${BASE_URL}
${UI_TIMEOUT}                10s
${API_TIMEOUT}               30
${HEADLESS}                  ${TRUE}
${BROWSER_TYPE}              chromium

# Test Data Configuration
${TEST_DATA_PREFIX}          RF_TEST
${CLEANUP_TIMEOUT}           5s

# API Endpoints
${BOOKS_ENDPOINT}            /books/
${BOOK_DETAIL_ENDPOINT}      /books/{book_id}
${BOOK_FAVORITE_ENDPOINT}    /books/{book_id}/favorite

# UI Selectors - Centralized for maintainability
${BOOKS_LIST_SELECTOR}           css=#books-list
${BOOK_FORM_SELECTOR}            css=#book-form
${TITLE_INPUT_SELECTOR}          css=#title
${AUTHOR_INPUT_SELECTOR}         css=#author
${PAGES_INPUT_SELECTOR}          css=#pages
${CATEGORY_SELECT_SELECTOR}      css=#category
${SUBMIT_BUTTON_SELECTOR}        css=#book-form button[type="submit"]
${SEARCH_INPUT_SELECTOR}         css=#search-input
${CATEGORY_FILTER_SELECTOR}      css=#category-filter
${FAVORITE_FILTER_SELECTOR}      css=#favorite-filter
${EDIT_MODAL_SELECTOR}           css=#edit-modal
${EDIT_FORM_SELECTOR}            css=#edit-form
${MODAL_CLOSE_SELECTOR}          css=.close

# Book Categories for Test Data
@{BOOK_CATEGORIES}               Fiction    Non-Fiction    Fantasy    Science Fiction    Mystery
...                              Thriller    Horror    Romance    Historical Fiction    Biography


*** Keywords ***
Setup Test Environment
    [Documentation]    Configures the complete test environment for both UI and API testing
    ...                
    ...                This keyword:
    ...                1. Verifies the Books service is available
    ...                2. Sets up browser context for UI tests
    ...                3. Creates HTTP session for API tests
    ...                4. Generates unique test identifiers
    
    # Generate unique test session ID
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    ${random_suffix}=    Evaluate    ''.join(random.choices(string.ascii_letters, k=6))    modules=random,string
    ${test_session_id}=    Set Variable    ${TEST_DATA_PREFIX}_${timestamp}_${random_suffix}
    Set Suite Variable    ${TEST_SESSION_ID}    ${test_session_id}
    
    # Verify application availability
    Wait Until Keyword Succeeds    30s    5s    Verify Books Service Is Ready
    
    # Always setup browser for now to debug the issue
    TRY
        Setup Browser Context
        Log    Browser context setup completed successfully
    EXCEPT    Exception    AS    ${error}
        Log    Browser setup failed: ${error}    level=ERROR
        # Continue without browser for API-only tests
    END
    
    # Setup API session
    Setup API Session
    
    # Initialize cleanup list
    @{empty_list}=    Create List
    Set Suite Variable    @{TEST_BOOKS_FOR_CLEANUP}    @{empty_list}
    
    Log    Test environment ready with session ID: ${TEST_SESSION_ID}

Setup Browser Context
    [Documentation]    Initializes browser context with optimal settings for testing
    
    TRY
        New Browser    ${BROWSER_TYPE}    headless=${HEADLESS}
        Log    Browser created successfully
        
        New Context    viewport={'width': 1920, 'height': 1080}
        Log    Browser context created successfully
        
        ${page}=    New Page    ${BASE_URL}
        Set Suite Variable    ${CURRENT_PAGE}    ${page}
        Log    Page created successfully: ${BASE_URL}
        
        # Wait for page to load completely
        Wait For Elements State    css=body    visible    timeout=${UI_TIMEOUT}
        Log    Page loaded successfully
        
    EXCEPT    Exception    AS    ${error}
        Log    Browser setup failed with error: ${error}    level=ERROR
        Fail    Browser setup failed: ${error}
    END

Setup API Session
    [Documentation]    Creates reusable HTTP session for API testing with proper configuration
    
    Create Session    books_api    ${API_BASE_URL}
    ...    headers={'Content-Type': 'application/json', 'Accept': 'application/json'}
    ...    timeout=${API_TIMEOUT}

Verify Books Service Is Ready
    [Documentation]    Ensures the Books service is available and responding correctly
    
    TRY
        ${response}=    GET    ${BASE_URL}${BOOKS_ENDPOINT}    timeout=5
        Should Be Equal As Integers    ${response.status_code}    200
        Log    Books service is ready and responding
    EXCEPT    Exception    AS    ${error}
        Log    Books service check failed: ${error}    level=ERROR
        Fail    Books service is not available at ${BASE_URL}
    END

Generate Test Book Data
    [Documentation]    Creates unique test book data to ensure test isolation
    ...                
    ...                Returns a dictionary containing book data with unique identifiers
    ...                to prevent conflicts between test runs.
    [Arguments]    ${title_suffix}=${EMPTY}    ${category}=Fiction
    
    ${unique_id}=    Evaluate    ''.join(random.choices(string.ascii_letters + string.digits, k=8))    modules=random,string
    ${title}=    Set Variable    ${TEST_SESSION_ID}_Book_${unique_id}${title_suffix}
    ${author}=    Set Variable    ${TEST_SESSION_ID}_Author_${unique_id}
    ${pages}=    Evaluate    random.randint(50, 500)    modules=random
    
    ${book_data}=    Create Dictionary    
    ...    title=${title}
    ...    author=${author}
    ...    pages=${pages}
    ...    category=${category}
    ...    favorite=${FALSE}
    
    RETURN    ${book_data}

Create Test Book Via API
    [Documentation]    Creates a test book via API and returns the book data with ID
    ...                
    ...                This keyword is used for test setup when a book needs to exist
    ...                before the actual test scenario begins.
    [Arguments]    ${book_data}=${None}
    
    IF    $book_data is None
        ${book_data}=    Generate Test Book Data
    END
    
    ${response}=    POST On Session    books_api    ${BOOKS_ENDPOINT}
    ...    json=${book_data}    expected_status=200
    
    ${created_book}=    Copy Dictionary    ${book_data}
    Set To Dictionary    ${created_book}    id=${response.json()['id']}
    
    # Store for cleanup
    IF    '${TEST_BOOKS_FOR_CLEANUP}' == '${EMPTY}'
        @{test_books}=    Create List    ${created_book['id']}
        Set Suite Variable    @{TEST_BOOKS_FOR_CLEANUP}    @{test_books}
    ELSE
        Append To List    ${TEST_BOOKS_FOR_CLEANUP}    ${created_book['id']}
    END
    
    Log    Created test book: ${created_book['title']} (ID: ${created_book['id']})
    RETURN    ${created_book}

Cleanup Test Data
    [Documentation]    Removes all test data created during test execution
    ...                
    ...                This keyword attempts to clean up test books but does not fail
    ...                the test if cleanup encounters issues, only logs warnings.
    
    TRY
        IF    '${TEST_BOOKS_FOR_CLEANUP}' != '${EMPTY}'
            FOR    ${book_id}    IN    @{TEST_BOOKS_FOR_CLEANUP}
                TRY
                    DELETE On Session    books_api    ${BOOKS_ENDPOINT}${book_id}    expected_status=any
                    Log    Cleaned up test book ID: ${book_id}
                EXCEPT    Exception    AS    ${error}
                    Log    Warning: Could not clean up book ID ${book_id}: ${error}    level=WARN
                END
            END
            # Clear the cleanup list
            @{empty_list}=    Create List
            Set Suite Variable    @{TEST_BOOKS_FOR_CLEANUP}    @{empty_list}
        END
    EXCEPT    Exception    AS    ${error}
        Log    Cleanup warning: ${error}    level=WARN
    END

Teardown Test Environment
    [Documentation]    Performs complete test environment cleanup
    
    # Cleanup test data
    Cleanup Test Data
    
    # Close browser contexts
    TRY
        Close Browser
    EXCEPT    Exception    AS    ${error}
        Log    Browser cleanup warning: ${error}    level=WARN
    END

Wait For Element And Interact
    [Documentation]    Safely waits for element and performs interaction with error handling
    ...                
    ...                This keyword provides a robust way to interact with UI elements
    ...                by ensuring they are visible and enabled before interaction.
    [Arguments]    ${selector}    ${action}=click    ${text}=${EMPTY}    ${timeout}=${UI_TIMEOUT}
    
    # Wait for element to be visible and enabled
    Wait For Elements State    ${selector}    visible    timeout=${timeout}
    Wait For Elements State    ${selector}    enabled    timeout=${timeout}
    
    # Perform the requested action
    IF    '${action}' == 'click'
        Click    ${selector}
    ELSE IF    '${action}' == 'fill'
        Fill Text    ${selector}    ${text}
    ELSE IF    '${action}' == 'select'
        Select Options By    ${selector}    text    ${text}
    ELSE IF    '${action}' == 'clear'
        Clear Text    ${selector}
    ELSE
        Fail    Unsupported action: ${action}
    END
    
    # Brief wait for any UI updates
    Sleep    0.5s

Verify Element Contains Text
    [Documentation]    Verifies that an element contains expected text with detailed error context
    [Arguments]    ${selector}    ${expected_text}    ${timeout}=${UI_TIMEOUT}
    
    Wait For Elements State    ${selector}    visible    timeout=${timeout}
    VAR    ${actual_text}    Get Text    ${selector}
    
    IF    $expected_text not in $actual_text
        VAR    ${error_msg}    Element text verification failed:
        ...    \nSelector: ${selector}
        ...    \nExpected text to contain: ${expected_text}
        ...    \nActual text: ${actual_text}
        ...    \nCurrent URL: ${CURRENT_URL}
        Log    ${error_msg}    level=ERROR
        Fail    ${error_msg}
    END

Make API Request With Error Handling
    [Documentation]    Makes API request with comprehensive error handling and logging
    [Arguments]    ${method}    ${endpoint}    ${data}=${None}    ${expected_status}=200
    
    VAR    ${full_endpoint}    ${endpoint}
    
    TRY
        IF    '${method}' == 'GET'
            ${response}=    GET On Session    books_api    ${full_endpoint}    expected_status=${expected_status}
        ELSE IF    '${method}' == 'POST'
            ${response}=    POST On Session    books_api    ${full_endpoint}    json=${data}    expected_status=${expected_status}
        ELSE IF    '${method}' == 'PUT'
            ${response}=    PUT On Session    books_api    ${full_endpoint}    json=${data}    expected_status=${expected_status}
        ELSE IF    '${method}' == 'DELETE'
            ${response}=    DELETE On Session    books_api    ${full_endpoint}    expected_status=${expected_status}
        ELSE IF    '${method}' == 'PATCH'
            ${response}=    PATCH On Session    books_api    ${full_endpoint}    json=${data}    expected_status=${expected_status}
        ELSE
            Fail    Unsupported HTTP method: ${method}
        END
        
        Log    API ${method} ${full_endpoint} successful (${response.status_code})
        RETURN    ${response}
        
    EXCEPT    Exception    AS    ${error}
        VAR    ${error_msg}    API request failed:
        ...    \nMethod: ${method}
        ...    \nEndpoint: ${full_endpoint}
        ...    \nExpected Status: ${expected_status}
        ...    \nError: ${error}
        Log    ${error_msg}    level=ERROR
        Fail    ${error_msg}
    END

Get Current Timestamp
    [Documentation]    Returns current timestamp in a format suitable for test data
    
    VAR    ${timestamp}    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    RETURN    ${timestamp}

Generate Random String
    [Documentation]    Generates a random string of specified length and character set
    [Arguments]    ${length}=8    ${chars}=[LETTERS][NUMBERS]
    
    VAR    ${random_string}    Generate Random String    ${length}    ${chars}
    RETURN    ${random_string}