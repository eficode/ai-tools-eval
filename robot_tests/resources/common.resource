*** Settings ***
Documentation     Common Resource File - Shared Keywords and Variables
...               
...               This resource provides shared test infrastructure including:
...               - Common test data generation utilities
...               - Environment setup and teardown procedures  
...               - Shared variables and configuration
...               - Test data cleanup and isolation utilities
...               
...               Used by both UI and API test suites to ensure consistency
...               and avoid code duplication across test layers.

Library           Collections
Library           String
Library           DateTime
Library           RequestsLibrary


*** Variables ***
# Environment Configuration
${BASE_URL}                   http://books-service:8000
${API_BASE_URL}               http://books-service:8000
${BOOKS_ENDPOINT}             /books/
${BROWSER_TYPE}               chromium
${HEADLESS}                   true

# Test Data Configuration  
${DEFAULT_TIMEOUT}            30s
${RETRY_INTERVAL}             1s
${MAX_RETRIES}                5

# Test Data Templates
&{DEFAULT_BOOK_DATA}
...    title=Default Test Book
...    author=Test Author
...    pages=200
...    category=Fiction
...    favorite=false

# Dynamic Test Variables (set during execution)
${TEST_BOOK_TITLE}            ${EMPTY}
${TEST_BOOK_AUTHOR}           ${EMPTY} 
${EXISTING_BOOK_ID}           ${EMPTY}
${NEW_BOOK_DATA}              ${EMPTY}
${EXISTING_BOOK_DATA}         ${EMPTY}
${UPDATED_BOOK_DATA}          ${EMPTY}
${LONG_TITLE_255_CHARS}       ${EMPTY}


*** Keywords ***
Generate Unique Test Data
    [Documentation]    Creates unique test data for test isolation
    VAR    ${timestamp}    Get Current Date    result_format=%Y%m%d_%H%M%S_%f
    VAR    ${unique_suffix}    ${timestamp[-6:]}    # Last 6 chars for uniqueness
    
    Set Test Variable    ${TEST_BOOK_TITLE}    Test Book ${unique_suffix}
    Set Test Variable    ${TEST_BOOK_AUTHOR}   Test Author ${unique_suffix}
    
    VAR    &{unique_book_data}
    ...    title=${TEST_BOOK_TITLE}
    ...    author=${TEST_BOOK_AUTHOR}  
    ...    pages=${250}
    ...    category=Fiction
    ...    favorite=${false}
    
    Set Test Variable    ${NEW_BOOK_DATA}    ${unique_book_data}
    
    # Generate long title for boundary testing  
    VAR    ${base_title}    Very Long Book Title For Boundary Testing
    ${title_length}    Get Length    ${base_title}
    ${padding_length}    Evaluate    255 - ${title_length}
    ${padding}    Evaluate    'X' * ${padding_length}
    Set Test Variable    ${LONG_TITLE_255_CHARS}    ${base_title}${padding}

Generate Sample Book Data  
    [Documentation]    Creates consistent sample book data for testing
    [Arguments]    ${title_prefix}=Sample Book    ${category}=Fiction
    
    VAR    ${timestamp}    Get Current Date    result_format=%M%S%f
    VAR    ${unique_id}    ${timestamp[-4:]}
    ${unique_id_int}=    Convert To Integer    ${unique_id}
    ${pages_count}=    Evaluate    200 + ${unique_id_int}
    
    VAR    &{sample_book}
    ...    title=${title_prefix} ${unique_id}
    ...    author=Sample Author ${unique_id}
    ...    pages=${pages_count}
    ...    category=${category}
    ...    favorite=${false}
    
    RETURN    ${sample_book}

Wait For Application To Be Ready
    [Documentation]    Ensures application services are available before testing
    FOR    ${attempt}    IN RANGE    ${MAX_RETRIES}
        TRY
            ${response}=    GET    ${API_BASE_URL}/books/
            IF    ${response.status_code} == 200
                Log    Application is ready for testing
                BREAK
            END
        EXCEPT    ConnectionError
            Log    Waiting for application to start...    WARN
            Sleep    ${RETRY_INTERVAL}
        END
        
        VAR    ${max_retries_minus_one}    Evaluate    ${MAX_RETRIES} - 1
        IF    ${attempt} == ${max_retries_minus_one}
            FAIL    Application failed to start within timeout period
        END
    END

Verify Application Health
    [Documentation]    Performs basic health check on application services
    ${api_response}=    GET    ${API_BASE_URL}/books/
    Should Be Equal As Integers    ${api_response.status_code}    200
    Log    API endpoint is healthy
    
    ${ui_response}=    GET    ${BASE_URL}/
    Should Be Equal As Integers    ${ui_response.status_code}    200
    Log    UI endpoint is healthy

Create Test Book Data Dictionary  
    [Documentation]    Creates book data dictionary with specified parameters
    [Arguments]    ${title}    ${author}    ${pages}    ${category}=Fiction    ${favorite}=false
    
    VAR    &{book_data}
    ...    title=${title}
    ...    author=${author}  
    ...    pages=${pages}
    ...    category=${category}
    ...    favorite=${favorite}
    
    RETURN    ${book_data}

Cleanup Common Test Data
    [Documentation]    Removes test data created during test execution
    ...               Override in specific test suites for custom cleanup
    Log    Test data cleanup completed    INFO

Reset Application State
    [Documentation]    Resets application to clean state between tests
    ...               Override in specific test suites for specific reset logic
    Log    Application state reset completed    INFO

Setup Test Environment
    [Documentation]    Common setup tasks for all test suites
    Log    Setting up test environment    INFO
    Generate Unique Test Data
    Wait For Application To Be Ready
    Verify Application Health

Cleanup Test Environment  
    [Documentation]    Common teardown tasks for all test suites
    Log    Cleaning up test environment    INFO
    Cleanup Common Test Data