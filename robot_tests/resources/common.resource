*** Settings ***
Documentation     Common keywords and variables shared across all test suites
...               
...               This resource file contains:
...               - Common variables (URLs, timeouts, browser settings)
...               - Utility keywords for test data generation
...               - Shared assertion keywords
...               - Common setup/teardown logic

Library           Browser
Library           RequestsLibrary
Library           Collections
Library           DateTime
Library           String

*** Variables ***
# Application Configuration
${BASE_URL}               http://books-service:8000
${API_ENDPOINT}           /books/
${HEALTH_ENDPOINT}        /health

# Browser Configuration
${BROWSER}                chromium
${HEADLESS}               ${True}
${VIEWPORT_WIDTH}         1920
${VIEWPORT_HEIGHT}        1080

# Timeouts
${DEFAULT_TIMEOUT}        10s
${LONG_TIMEOUT}           30
${SHORT_TIMEOUT}          5s

# Test Data
${TEST_BOOK_TITLE}        Test Book
${TEST_BOOK_AUTHOR}       Test Author

*** Keywords ***
Generate Unique Book Data
    [Documentation]    Generates unique book data for test isolation
    ...                
    ...                Returns a dictionary containing:
    ...                - title: Unique book title with timestamp
    ...                - author: Unique author name with timestamp
    ...                - pages: Random page count
    ...                - category: Random category
    ...                - favorite: Boolean favorite status
    ...                
    ...                Example:
    ...                | &{book}= | Generate Unique Book Data |
    ...                | Log | ${book}[title] |
    
    ${timestamp}=    Get Time    epoch
    VAR    @{categories}    Fiction    Non-Fiction    Science    History    Biography    Young Adult
    ${random_category}=    Evaluate    random.choice(${categories})    modules=random
    ${random_pages}=    Evaluate    random.randint(100, 1000)    modules=random
    
    VAR    &{book_data}
    ...    title=Test Book ${timestamp}
    ...    author=Test Author ${timestamp}
    ...    pages=${random_pages}
    ...    category=${random_category}
    ...    favorite=${False}
    
    RETURN    &{book_data}

Generate Unique Timestamp
    [Documentation]    Generates a unique timestamp for test data isolation
    
    ${timestamp}=    Get Time    epoch
    RETURN    ${timestamp}

Verify Service Is Available
    [Documentation]    Verifies that the Books service is available and responding
    ...                
    ...                This keyword checks the books endpoint to ensure
    ...                the service is ready before running tests.
    
    ${response}=    GET    ${BASE_URL}${API_ENDPOINT}    expected_status=200
    Log    Books service is available and healthy

Wait For Element And Click
    [Documentation]    Waits for element to be visible and stable, then clicks it
    ...                
    ...                Arguments:
    ...                - selector: Element selector (CSS, XPath, etc.)
    ...                - timeout: Maximum wait time (default: ${DEFAULT_TIMEOUT})
    [Arguments]    ${selector}    ${timeout}=${DEFAULT_TIMEOUT}
    
    Wait For Elements State    ${selector}    visible    timeout=${timeout}
    Wait For Elements State    ${selector}    stable     timeout=${SHORT_TIMEOUT}
    Click    ${selector}
    Log    Clicked element: ${selector}

Wait For Element And Fill Text
    [Documentation]    Waits for element to be visible, clears it, and fills with text
    ...                
    ...                Arguments:
    ...                - selector: Element selector
    ...                - text: Text to fill
    ...                - timeout: Maximum wait time (default: ${DEFAULT_TIMEOUT})
    [Arguments]    ${selector}    ${text}    ${timeout}=${DEFAULT_TIMEOUT}
    
    Wait For Elements State    ${selector}    visible    timeout=${timeout}
    Clear Text    ${selector}
    Fill Text    ${selector}    ${text}
    Log    Filled text in element: ${selector}

Verify Element Contains Text
    [Documentation]    Verifies that an element contains the expected text
    ...                
    ...                Arguments:
    ...                - selector: Element selector
    ...                - expected_text: Text that should be present
    ...                - timeout: Maximum wait time (default: ${DEFAULT_TIMEOUT})
    [Arguments]    ${selector}    ${expected_text}    ${timeout}=${DEFAULT_TIMEOUT}
    
    Wait For Elements State    ${selector}    visible    timeout=${timeout}
    ${actual_text}=    Get Text    ${selector}
    Should Contain    ${actual_text}    ${expected_text}    ignore_case=True
    Log    Element ${selector} contains expected text: ${expected_text}

Take Screenshot On Failure
    [Documentation]    Takes a full-page screenshot if the test fails
    ...                
    ...                This keyword should be called in test teardown to capture
    ...                the state of the application when a test fails.
    
    Run Keyword If Test Failed    Take Screenshot    fullPage=True

Log Test Duration
    [Documentation]    Logs the duration of the test execution
    ...                
    ...                Arguments:
    ...                - start_time: Test start time in epoch format
    [Arguments]    ${start_time}
    
    ${end_time}=    Get Time    epoch
    ${duration}=    Evaluate    ${end_time} - ${start_time}
    Log    Test duration: ${duration} seconds    level=INFO
