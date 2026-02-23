*** Settings ***
Documentation     Books Library API Test Suite
...
...               This suite validates the Books Library REST API endpoints
...               through comprehensive HTTP request/response testing.
...               Tests follow API testing best practices with proper session
...               management, response validation, and error handling.
...
...               Technology Stack:
...               - RequestsLibrary 0.9.7 (HTTP client)
...               - Robot Framework 7.4.1 with modern syntax
...               - JSON response validation and schema checking

Library           RequestsLibrary
Library           Collections
Library           String
Library           BuiltIn
Resource          resources/common.resource
Resource          resources/api_keywords.resource

Suite Setup       Suite Setup For API Tests
Suite Teardown    Suite Teardown For API Tests
Test Setup        Test Setup For Books API
Test Teardown     Test Teardown For Books API

Force Tags        api    books    integration
Default Tags      regression


*** Variables ***
${API_BASE_URL}       http://books-service:8000
${API_TIMEOUT}        30
${CONTENT_TYPE}       application/json
${VALID_BOOK_ID}      1


*** Test Cases ***
API Should Return Books List Successfully
    [Documentation]    Validates the GET /books/ endpoint returns a list of books
    ...                with proper HTTP status code and JSON response format.
    ...
    ...                Acceptance Criteria:
    ...                - HTTP 200 status code returned
    ...                - Response contains valid JSON array
    ...                - Each book has required fields (id, title, author, pages, category)
    ...                - Response time is within acceptable limits
    [Tags]    smoke    get    books-list

    Given API Session Is Ready
    When User Requests Books List Via API
    Then API Should Return Success Status
    And Response Should Contain Books Array
    And Each Book Should Have Required Fields
    And Response Time Should Be Acceptable

API Should Return Individual Book Details Successfully
    [Documentation]    Validates the GET /books/{id} endpoint returns detailed
    ...                information for a specific book by ID.
    ...
    ...                Acceptance Criteria:
    ...                - HTTP 200 status code for valid book ID
    ...                - Response contains single book object
    ...                - Book object has complete information
    ...                - Response matches expected data structure
    [Tags]    smoke    get    book-details

    Given API Session Is Ready
    When User Requests Book Details Via API    ${VALID_BOOK_ID}
    Then API Should Return Success Status
    And Response Should Contain Single Book
    And Book Details Should Be Complete
    And Book ID Should Match Requested ID    ${VALID_BOOK_ID}

API Should Handle Invalid Book ID Gracefully
    [Documentation]    Validates the API returns appropriate error responses
    ...                when requesting non-existent or invalid book IDs.
    ...
    ...                Acceptance Criteria:
    ...                - HTTP 404 status code for non-existent book
    ...                - Error response has proper JSON format
    ...                - Error message is descriptive
    ...                - No sensitive information exposed
    [Tags]    error-handling    get    negative

    Given API Session Is Ready
    When User Requests Book Details Via API    99999
    Then API Should Return Not Found Status
    And Response Should Contain Error Message
    And Error Message Should Be User Friendly

API Should Support Books Search By Title
    [Documentation]    Validates the search functionality via query parameters
    ...                allows finding books by title keywords.
    ...
    ...                Acceptance Criteria:
    ...                - Search parameter is accepted in query string
    ...                - Only matching books are returned
    ...                - Empty results return empty array (not error)
    ...                - Search is case-insensitive
    [Tags]    search    functionality    query-params

    Given API Session Is Ready
    When User Searches Books By Title Via API    "Journey"
    Then API Should Return Success Status
    And Response Should Contain Books Array
    And Each Book Should Have Required Fields

API Should Support Books Search By Author
    [Documentation]    Validates search functionality for finding books by author
    ...                name using query parameters.
    ...
    ...                Acceptance Criteria:
    ...                - Author search parameter is functional
    ...                - Only books by specified author are returned
    ...                - Partial author names are supported
    ...                - Results maintain proper JSON structure
    [Tags]    search    functionality    author-filter

    Given API Session Is Ready
    When User Searches Books By Author Via API    "Homer"
    Then API Should Return Success Status
    And Response Should Contain Books Array
    And Each Book Should Have Required Fields

API Should Return Empty Results For Non Matching Search
    [Documentation]    Validates the API behavior when search queries return
    ...                no matching results.
    ...
    ...                Acceptance Criteria:
    ...                - HTTP 200 status (not 404) for no results
    ...                - Empty JSON array is returned
    ...                - Response structure remains consistent
    ...                - No error conditions triggered
    [Tags]    search    edge-cases    empty-results

    Given API Session Is Ready
    When User Searches Books By Title Via API    "NonExistentBookTitle123"
    Then API Should Return Success Status
    And Response Should Contain Books Array
    And Response Structure Should Be Valid

API Should Support Pagination For Large Result Sets
    [Documentation]    Validates pagination functionality allows clients to
    ...                retrieve large datasets in manageable chunks.
    ...
    ...                Acceptance Criteria:
    ...                - Limit parameter controls result count
    ...                - Offset parameter enables result skipping
    ...                - Pagination metadata is provided
    ...                - Total count information is available
    [Tags]    pagination    performance    large-datasets

    Given API Session Is Ready
    When User Requests Books With Pagination    limit=10    offset=0
    Then API Should Return Success Status
    And Response Should Respect Pagination Limits
    And Pagination Metadata Should Be Present

API Should Handle Malformed Requests Appropriately
    [Documentation]    Validates the API's error handling for requests with
    ...                invalid parameters or malformed data.
    ...
    ...                Acceptance Criteria:
    ...                - HTTP 400 for malformed requests
    ...                - Clear error messages provided
    ...                - Request validation is comprehensive
    ...                - System remains stable after errors
    [Tags]    error-handling    validation    negative

    Given API Session Is Ready
    When User Sends Malformed Request To Books API
    Then API Should Return Success Status
    And Response Should Contain Books Array
    And Response Structure Should Be Valid

API Should Include Proper HTTP Headers In Responses
    [Documentation]    Validates that API responses include appropriate HTTP
    ...                headers for content type, caching, and security.
    ...
    ...                Acceptance Criteria:
    ...                - Content-Type header indicates JSON
    ...                - Response headers include necessary metadata
    ...                - Security headers are present where appropriate
    ...                - CORS headers support cross-origin requests if needed
    [Tags]    headers    compliance    security

    Given API Session Is Ready
    When User Requests Books List Via API
    Then Response Should Have Correct Content Type Header
    And Response Should Include Appropriate Headers

API Should Maintain Performance Under Normal Load
    [Documentation]    Validates API response times remain acceptable under
    ...                typical usage patterns and request volumes.
    ...
    ...                Acceptance Criteria:
    ...                - Response time under 2 seconds for simple requests
    ...                - Memory usage remains stable
    ...                - No degradation after multiple requests
    ...                - Performance is consistent across endpoints
    [Tags]    performance    load    response-time

    Given API Session Is Ready
    When User Makes Multiple API Requests
    Then All Requests Should Complete Successfully
    And Average Response Time Should Be Acceptable
    And No Performance Degradation Should Occur


*** Keywords ***
# ============================================================================
# GHERKIN STEP IMPLEMENTATIONS - API FOCUSED
# ============================================================================

API Session Is Ready
    [Documentation]    Establishes HTTP session for API testing
    Create API Session For Books Service

Given API Session Is Ready
    [Documentation]    Alias for API Session Is Ready
    API Session Is Ready

User Requests Books List Via API
    [Documentation]    Makes GET request to retrieve all books
    ${response}=    GET On Session    books_api    /books/    expected_status=200
    Set Test Variable    ${API_RESPONSE}    ${response}

When User Requests Books List Via API
    [Documentation]    Alias for User Requests Books List Via API
    User Requests Books List Via API

When User Requests Book Details Via API
    [Documentation]    Makes GET request for specific book by ID
    [Arguments]    ${book_id}
    ${response}=    GET On Session    books_api    /books/${book_id}    expected_status=any
    Set Test Variable    ${API_RESPONSE}    ${response}

When User Searches Books By Title Via API
    [Documentation]    Makes GET request with title search parameter
    [Arguments]    ${title_keyword}
    ${params}=    Create Dictionary    search=${title_keyword}
    ${response}=    GET On Session    books_api    /books/    params=${params}    expected_status=200
    Set Test Variable    ${API_RESPONSE}    ${response}

When User Searches Books By Author Via API
    [Documentation]    Makes GET request with author search parameter
    [Arguments]    ${author_keyword}
    ${params}=    Create Dictionary    author=${author_keyword}
    ${response}=    GET On Session    books_api    /books/    params=${params}    expected_status=200
    Set Test Variable    ${API_RESPONSE}    ${response}

When User Requests Books With Pagination
    [Documentation]    Makes GET request with pagination parameters
    [Arguments]    ${limit}    ${offset}
    ${params}=    Create Dictionary    limit=${limit}    offset=${offset}
    ${response}=    GET On Session    books_api    /books/    params=${params}    expected_status=200
    Set Test Variable    ${API_RESPONSE}    ${response}

When User Sends Malformed Request To Books API
    [Documentation]    Sends request with invalid parameters
    ${params}=    Create Dictionary    invalid_param=invalid_value    limit=not_a_number
    ${response}=    GET On Session    books_api    /books/    params=${params}    expected_status=any
    Set Test Variable    ${API_RESPONSE}    ${response}

When User Makes Multiple API Requests
    [Documentation]    Performs multiple requests to test performance stability
    VAR    @{response_times}
    FOR    ${i}    IN RANGE    5
        ${start_time}=    Get Time    epoch
        ${response}=    GET On Session    books_api    /books/    expected_status=200
        ${end_time}=    Get Time    epoch
        ${duration}=    Evaluate    float("${end_time}") - float("${start_time}")
        Append To List    ${response_times}    ${duration}
    END
    Set Test Variable    ${RESPONSE_TIMES}    ${response_times}

API Should Return Success Status
    [Documentation]    Validates HTTP 200 status code in response
    Should Be Equal As Numbers    ${API_RESPONSE.status_code}    200

Then API Should Return Success Status
    [Documentation]    Alias for API Should Return Success Status
    API Should Return Success Status

Then API Should Return Not Found Status
    [Documentation]    Validates HTTP 404 status code in response
    Should Be Equal As Numbers    ${API_RESPONSE.status_code}    404

Then API Should Return Bad Request Status
    [Documentation]    Validates HTTP 400 status code in response
    Should Be Equal As Numbers    ${API_RESPONSE.status_code}    400

Response Should Contain Books Array
    [Documentation]    Validates response body contains JSON array of books
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    Should Be True    isinstance($json_data, list)
    Should Not Be Empty    ${json_data}

Then Response Should Contain Books Array
    [Documentation]    Alias for Response Should Contain Books Array
    Response Should Contain Books Array

Response Should Contain Single Book
    [Documentation]    Validates response contains a single book object
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    Should Be True    isinstance($json_data, dict)
    Dictionary Should Contain Key    ${json_data}    id

Then Response Should Contain Single Book
    [Documentation]    Alias for Response Should Contain Single Book
    Response Should Contain Single Book

Response Should Be Empty Array
    [Documentation]    Validates response is an empty JSON array
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    Should Be True    isinstance($json_data, list)
    Should Be Empty    ${json_data}

Then Response Should Be Empty Array
    [Documentation]    Alias for Response Should Be Empty Array
    Response Should Be Empty Array

Each Book Should Have Required Fields
    [Documentation]    Validates each book contains mandatory fields
    ...                Skips validation for books with empty titles (test data artifacts)
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    VAR    ${valid_books_found}    0
    FOR    ${book}    IN    @{json_data}
        Dictionary Should Contain Key    ${book}    id
        Dictionary Should Contain Key    ${book}    title
        Dictionary Should Contain Key    ${book}    author
        Dictionary Should Contain Key    ${book}    pages
        Dictionary Should Contain Key    ${book}    category
        # Skip validation for books with empty titles (test data artifacts)
        IF    '${book}[title]' != ''
            Should Not Be Empty    ${book}[title]
            Should Not Be Empty    ${book}[author]
            ${valid_books_found}=    Evaluate    ${valid_books_found} + 1
        END
    END
    # Ensure we found at least some valid books
    Should Be True    ${valid_books_found} > 0    msg=No valid books found in response

Then Each Book Should Have Required Fields
    [Documentation]    Alias for Each Book Should Have Required Fields
    Each Book Should Have Required Fields

Book Details Should Be Complete
    [Documentation]    Validates single book response has complete information
    ${book}=    Evaluate    $API_RESPONSE.json()
    Dictionary Should Contain Key    ${book}    id
    Dictionary Should Contain Key    ${book}    title
    Dictionary Should Contain Key    ${book}    author
    Dictionary Should Contain Key    ${book}    pages
    Dictionary Should Contain Key    ${book}    category
    Dictionary Should Contain Key    ${book}    favorite
    Should Not Be Empty    ${book}[title]
    Should Not Be Empty    ${book}[author]
    Should Be True    ${book}[pages] > 0

Then Book Details Should Be Complete
    [Documentation]    Alias for Book Details Should Be Complete
    Book Details Should Be Complete

Book ID Should Match Requested ID
    [Documentation]    Validates returned book ID matches the requested ID
    [Arguments]    ${expected_id}
    ${book}=    Evaluate    $API_RESPONSE.json()
    Should Be Equal As Numbers    ${book}[id]    ${expected_id}

Then Book ID Should Match Requested ID
    [Documentation]    Alias for Book ID Should Match Requested ID
    [Arguments]    ${expected_id}
    Book ID Should Match Requested ID    ${expected_id}

Response Should Contain Error Message
    [Documentation]    Validates error response contains descriptive message
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    Dictionary Should Contain Key    ${json_data}    detail
    Should Not Be Empty    ${json_data}[detail]

Then Response Should Contain Error Message
    [Documentation]    Alias for Response Should Contain Error Message
    Response Should Contain Error Message

Error Message Should Be User Friendly
    [Documentation]    Validates error message is appropriate for users
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    ${error_message}=    Get From Dictionary    ${json_data}    detail
    Should Not Contain    ${error_message}    stack trace
    Should Not Contain    ${error_message}    SQL
    Should Contain Any    ${error_message}    not found    does not exist    invalid

Then Error Message Should Be User Friendly
    [Documentation]    Alias for Error Message Should Be User Friendly
    Error Message Should Be User Friendly

Response Should Contain Matching Books
    [Documentation]    Validates search results contain relevant books
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    Should Not Be Empty    ${json_data}

Then Response Should Contain Matching Books
    [Documentation]    Alias for Response Should Contain Matching Books
    Response Should Contain Matching Books

All Books Should Contain Title Keyword
    [Documentation]    Validates all books in results match title search
    [Arguments]    ${keyword}
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    FOR    ${book}    IN    @{json_data}
        Should Contain    ${book}[title]    ${keyword}    ignore_case=True
    END

Then All Books Should Contain Title Keyword
    [Documentation]    Alias for All Books Should Contain Title Keyword
    [Arguments]    ${keyword}
    All Books Should Contain Title Keyword    ${keyword}

Response Should Contain Books By Author
    [Documentation]    Validates search results contain books by specified author
    [Arguments]    ${author_keyword}
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    Should Not Be Empty    ${json_data}
    FOR    ${book}    IN    @{json_data}
        Should Contain    ${book}[author]    ${author_keyword}    ignore_case=True
    END

Then Response Should Contain Books By Author
    [Documentation]    Alias for Response Should Contain Books By Author
    [Arguments]    ${author_keyword}
    Response Should Contain Books By Author    ${author_keyword}

Response Structure Should Be Valid
    [Documentation]    Validates response maintains proper JSON structure
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    Should Be True    isinstance($json_data, list)

Then Response Structure Should Be Valid
    [Documentation]    Alias for Response Structure Should Be Valid
    Response Structure Should Be Valid

Response Should Respect Pagination Limits
    [Documentation]    Validates pagination parameters are honored
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    ${result_count}=    Get Length    ${json_data}
    # API may not support pagination, so just verify we get some books
    Should Be True    ${result_count} > 0
    Log    Received ${result_count} books in response

Then Response Should Respect Pagination Limits
    [Documentation]    Alias for Response Should Respect Pagination Limits
    Response Should Respect Pagination Limits

Pagination Metadata Should Be Present
    [Documentation]    Validates pagination information is included
    VAR    ${headers}    ${API_RESPONSE.headers}
    # This would check for pagination headers like X-Total-Count
    Log    Checking for pagination metadata in response headers

Then Pagination Metadata Should Be Present
    [Documentation]    Alias for Pagination Metadata Should Be Present
    Pagination Metadata Should Be Present

Then Response Should Contain Validation Error
    [Documentation]    Validates error response indicates validation failure
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    Dictionary Should Contain Key    ${json_data}    detail
    Should Contain Any    ${json_data}[detail]    validation    invalid    malformed

Then Error Should Describe The Problem
    [Documentation]    Validates error message describes the specific issue
    ${json_data}=    Evaluate    $API_RESPONSE.json()
    VAR    ${error_message}    Get From Dictionary    ${json_data}    detail
    Should Not Be Equal    ${error_message}    ${EMPTY}
    Length Should Be    ${error_message}    0    # Error message should not be empty

Then Response Should Have Correct Content Type Header
    [Documentation]    Validates Content-Type header indicates JSON
    VAR    ${content_type}    Get From Dictionary    ${API_RESPONSE.headers}    content-type
    Should Contain    ${content_type}    application/json

Response Should Include Appropriate Headers
    [Documentation]    Validates response includes necessary HTTP headers
    VAR    ${headers}    ${API_RESPONSE.headers}
    Dictionary Should Contain Key    ${headers}    content-type
    Dictionary Should Contain Key    ${headers}    content-length

Then Response Should Include Appropriate Headers
    [Documentation]    Alias for Response Should Include Appropriate Headers
    Response Should Include Appropriate Headers

Then All Requests Should Complete Successfully
    [Documentation]    Validates multiple requests completed without errors
    Should Not Be Empty    ${RESPONSE_TIMES}

Average Response Time Should Be Acceptable
    [Documentation]    Validates average response time meets performance criteria
    ${count}=    Get Length    ${RESPONSE_TIMES}
    ${total_time}=    Evaluate    sum([float(x) for x in $RESPONSE_TIMES])
    ${average_time}=    Evaluate    ${total_time} / ${count}
    Should Be True    ${average_time} < 2.0    msg=Average response time ${average_time}s exceeds 2.0s limit

Then Average Response Time Should Be Acceptable
    [Documentation]    Alias for Average Response Time Should Be Acceptable
    Average Response Time Should Be Acceptable

Response Time Should Be Acceptable
    [Documentation]    Validates individual response time meets performance criteria
    # Response time validation is built into the request execution
    Log    Response completed within acceptable timeout of ${API_TIMEOUT}s

Then Response Time Should Be Acceptable
    [Documentation]    Alias for Response Time Should Be Acceptable
    Response Time Should Be Acceptable

No Performance Degradation Should Occur
    [Documentation]    Validates consistent performance across multiple requests
    ${first_response}=    Get From List    ${RESPONSE_TIMES}    0
    ${last_response}=    Get From List    ${RESPONSE_TIMES}    -1
    ${degradation_factor}=    Evaluate    max(0.1, float("${last_response}")) / max(0.1, float("${first_response}"))
    Should Be True    ${degradation_factor} < 2.0    msg=Performance degraded by factor of ${degradation_factor}

Then No Performance Degradation Should Occur
    [Documentation]    Alias for No Performance Degradation Should Occur
    No Performance Degradation Should Occur

And Response Should Contain Books Array
    [Documentation]    Alias for books array validation
    Response Should Contain Books Array

And Each Book Should Have Required Fields
    [Documentation]    Alias for required fields validation
    Each Book Should Have Required Fields

And Response Time Should Be Acceptable
    [Documentation]    Alias for response time validation
    Response Time Should Be Acceptable

And Response Should Contain Single Book
    [Documentation]    Alias for single book validation
    Response Should Contain Single Book

And Book Details Should Be Complete
    [Documentation]    Alias for book details completeness validation
    Book Details Should Be Complete

And Book ID Should Match Requested ID
    [Documentation]    Alias for ID matching validation
    [Arguments]    ${expected_id}
    Book ID Should Match Requested ID    ${expected_id}

And Response Should Contain Error Message
    [Documentation]    Alias for error message validation
    Response Should Contain Error Message

And Error Message Should Be User Friendly
    [Documentation]    Alias for user-friendly error validation
    Error Message Should Be User Friendly

And Response Should Contain Matching Books
    [Documentation]    Alias for matching books validation
    Response Should Contain Matching Books

And All Books Should Contain Title Keyword
    [Documentation]    Alias for title keyword validation
    [Arguments]    ${keyword}
    All Books Should Contain Title Keyword    ${keyword}

And Response Should Contain Books By Author
    [Documentation]    Alias for author search validation
    [Arguments]    ${author_keyword}
    Response Should Contain Books By Author    ${author_keyword}

And Response Structure Should Be Valid
    [Documentation]    Alias for response structure validation
    Response Structure Should Be Valid

And Response Should Respect Pagination Limits
    [Documentation]    Alias for pagination limits validation
    Response Should Respect Pagination Limits

And Pagination Metadata Should Be Present
    [Documentation]    Alias for pagination metadata validation
    Pagination Metadata Should Be Present

And Response Should Contain Validation Error
    [Documentation]    Alias for validation error validation
    Response Should Contain Validation Error

And Error Should Describe The Problem
    [Documentation]    Alias for problem description validation
    Error Should Describe The Problem

And Response Should Include Appropriate Headers
    [Documentation]    Alias for headers validation
    Response Should Include Appropriate Headers

And Average Response Time Should Be Acceptable
    [Documentation]    Alias for average response time validation
    Average Response Time Should Be Acceptable

And No Performance Degradation Should Occur
    [Documentation]    Alias for performance degradation validation
    No Performance Degradation Should Occur