*** Settings ***
Documentation     API Keywords Resource File for Books Library REST API
...
...               This resource file contains HTTP client keywords and API testing utilities
...               for the Books Library REST API. All keywords follow RequestsLibrary
...               best practices with proper session management and response validation.
...
...               Key Features:
...               - RESTful API testing keywords
...               - HTTP session management
...               - JSON response validation and parsing
...               - Error handling and status code validation
...               - Performance monitoring and timeout handling

Library           RequestsLibrary
Library           Collections
Library           String
Library           BuiltIn
Library           DateTime


*** Variables ***
# ============================================================================
# API ENDPOINT CONFIGURATION
# ============================================================================
${BOOKS_LIST_ENDPOINT}           /books/
${BOOK_DETAILS_ENDPOINT}         /books/{id}
${BOOK_SEARCH_ENDPOINT}          /books/search
${API_VERSION}                   v1

# HTTP Headers
${CONTENT_TYPE_JSON}             application/json
${ACCEPT_JSON}                   application/json
${USER_AGENT}                    Books-Library-Test-Suite/1.0

# Response Validation
${MAX_RESPONSE_SIZE}             1048576    # 1MB
${MIN_RESPONSE_TIME}             0.001      # 1ms
${MAX_RESPONSE_TIME}             2.0        # 2 seconds

# Pagination Defaults
${DEFAULT_PAGE_SIZE}             20
${MAX_PAGE_SIZE}                 100


*** Keywords ***
# ============================================================================
# SESSION MANAGEMENT
# ============================================================================

Create Books API Session
    [Documentation]    Creates HTTP session for Books Library API
    ...                Configures headers, timeout, and authentication if needed
    VAR    &{headers}    Create Dictionary
    ...    Content-Type=${CONTENT_TYPE_JSON}
    ...    Accept=${ACCEPT_JSON}
    ...    User-Agent=${USER_AGENT}

    Create Session    books_api    ${API_BASE_URL}
    ...    headers=${headers}
    ...    timeout=${API_TIMEOUT}
    ...    verify=true
    Log    Books API session created successfully

Destroy Books API Session
    [Documentation]    Closes HTTP session and cleans up resources
    TRY
        Delete All Sessions
        Log    Books API session closed successfully
    EXCEPT    *    AS    ${error}
        Log    Session cleanup warning: ${error}    level=WARN
    END

# ============================================================================
# CORE API REQUEST METHODS
# ============================================================================

Make GET Request To Books API
    [Documentation]    Makes GET request to Books API endpoint with validation
    [Arguments]    ${endpoint}    ${params}=${None}    ${expected_status}=200
    VAR    ${start_time}    Get Time    epoch
    VAR    ${response}    GET On Session    books_api    ${endpoint}
    ...    params=${params}    expected_status=any
    VAR    ${end_time}    Get Time    epoch
    VAR    ${response_time}    Evaluate    ${end_time} - ${start_time}

    # Validate response time
    Should Be True    ${response_time} <= ${MAX_RESPONSE_TIME}
    ...    msg=Response time ${response_time}s exceeds maximum ${MAX_RESPONSE_TIME}s

    # Validate status code if expected
    IF    ${expected_status} != any
        Should Be Equal As Numbers    ${response.status_code}    ${expected_status}
    END

    Set Test Variable    ${LAST_RESPONSE}    ${response}
    Set Test Variable    ${LAST_RESPONSE_TIME}    ${response_time}
    Log    GET request to ${endpoint} completed in ${response_time}s
    RETURN    ${response}

Make POST Request To Books API
    [Documentation]    Makes POST request to Books API endpoint with JSON data
    [Arguments]    ${endpoint}    ${json_data}    ${expected_status}=201
    VAR    ${start_time}    Get Time    epoch
    VAR    ${response}    POST On Session    books_api    ${endpoint}
    ...    json=${json_data}    expected_status=any
    VAR    ${end_time}    Get Time    epoch
    VAR    ${response_time}    Evaluate    ${end_time} - ${start_time}

    Should Be True    ${response_time} <= ${MAX_RESPONSE_TIME}
    IF    ${expected_status} != any
        Should Be Equal As Numbers    ${response.status_code}    ${expected_status}
    END

    Set Test Variable    ${LAST_RESPONSE}    ${response}
    Set Test Variable    ${LAST_RESPONSE_TIME}    ${response_time}
    Log    POST request to ${endpoint} completed in ${response_time}s
    RETURN    ${response}

Make PUT Request To Books API
    [Documentation]    Makes PUT request to Books API endpoint with JSON data
    [Arguments]    ${endpoint}    ${json_data}    ${expected_status}=200
    VAR    ${start_time}    Get Time    epoch
    VAR    ${response}    PUT On Session    books_api    ${endpoint}
    ...    json=${json_data}    expected_status=any
    VAR    ${end_time}    Get Time    epoch
    VAR    ${response_time}    Evaluate    ${end_time} - ${start_time}

    Should Be True    ${response_time} <= ${MAX_RESPONSE_TIME}
    IF    ${expected_status} != any
        Should Be Equal As Numbers    ${response.status_code}    ${expected_status}
    END

    Set Test Variable    ${LAST_RESPONSE}    ${response}
    Set Test Variable    ${LAST_RESPONSE_TIME}    ${response_time}
    Log    PUT request to ${endpoint} completed in ${response_time}s
    RETURN    ${response}

Make DELETE Request To Books API
    [Documentation]    Makes DELETE request to Books API endpoint
    [Arguments]    ${endpoint}    ${expected_status}=204
    VAR    ${start_time}    Get Time    epoch
    VAR    ${response}    DELETE On Session    books_api    ${endpoint}    expected_status=any
    VAR    ${end_time}    Get Time    epoch
    VAR    ${response_time}    Evaluate    ${end_time} - ${start_time}

    Should Be True    ${response_time} <= ${MAX_RESPONSE_TIME}
    IF    ${expected_status} != any
        Should Be Equal As Numbers    ${response.status_code}    ${expected_status}
    END

    Set Test Variable    ${LAST_RESPONSE}    ${response}
    Set Test Variable    ${LAST_RESPONSE_TIME}    ${response_time}
    Log    DELETE request to ${endpoint} completed in ${response_time}s
    RETURN    ${response}

# ============================================================================
# BOOKS API SPECIFIC OPERATIONS
# ============================================================================

Get All Books From API
    [Documentation]    Retrieves complete list of books from the API
    [Arguments]    ${limit}=${None}    ${offset}=${None}
    VAR    &{params}    Create Dictionary
    IF    ${limit} != ${None}
        Set To Dictionary    ${params}    limit=${limit}
    END
    IF    ${offset} != ${None}
        Set To Dictionary    ${params}    offset=${offset}
    END

    VAR    ${response}    Make GET Request To Books API    ${BOOKS_LIST_ENDPOINT}    ${params}
    VAR    ${books_data}    ${response.json()}
    Should Be True    isinstance($books_data, list)    msg=Expected list response, got ${type(books_data)}
    Log    Retrieved ${len(books_data)} books from API
    RETURN    ${books_data}

Get Book By ID From API
    [Documentation]    Retrieves specific book details by ID from the API
    [Arguments]    ${book_id}    ${expected_status}=200
    VAR    ${endpoint}    Replace String    ${BOOK_DETAILS_ENDPOINT}    {id}    ${book_id}
    VAR    ${response}    Make GET Request To Books API    ${endpoint}    expected_status=${expected_status}

    IF    ${response.status_code} == 200
        VAR    ${book_data}    ${response.json()}
        Should Be True    isinstance($book_data, dict)    msg=Expected dict response, got ${type(book_data)}
        Dictionary Should Contain Key    ${book_data}    id
        Should Be Equal As Numbers    ${book_data}[id]    ${book_id}
        Log    Retrieved book with ID ${book_id}: "${book_data}[title]"
        RETURN    ${book_data}
    ELSE
        Log    Book with ID ${book_id} not found or error occurred
        RETURN    ${None}
    END

Search Books By Title
    [Documentation]    Searches for books by title keyword via API
    [Arguments]    ${title_keyword}    ${exact_match}=false
    VAR    &{params}    Create Dictionary
    IF    ${exact_match}
        Set To Dictionary    ${params}    title=${title_keyword}
    ELSE
        Set To Dictionary    ${params}    search=${title_keyword}
    END

    VAR    ${response}    Make GET Request To Books API    ${BOOKS_LIST_ENDPOINT}    ${params}
    VAR    ${books_data}    ${response.json()}
    Should Be True    isinstance($books_data, list)
    Log    Found ${len(books_data)} books matching title "${title_keyword}"
    RETURN    ${books_data}

Search Books By Author
    [Documentation]    Searches for books by author name via API
    [Arguments]    ${author_keyword}    ${exact_match}=false
    VAR    &{params}    Create Dictionary
    IF    ${exact_match}
        Set To Dictionary    ${params}    author=${author_keyword}
    ELSE
        Set To Dictionary    ${params}    author=${author_keyword}
    END

    VAR    ${response}    Make GET Request To Books API    ${BOOKS_LIST_ENDPOINT}    ${params}
    VAR    ${books_data}    ${response.json()}
    Should Be True    isinstance($books_data, list)
    Log    Found ${len(books_data)} books by author "${author_keyword}"
    RETURN    ${books_data}

# ============================================================================
# RESPONSE VALIDATION KEYWORDS
# ============================================================================

Validate Books List Response
    [Documentation]    Validates books list API response structure and content
    [Arguments]    ${response}
    Should Be Equal As Numbers    ${response.status_code}    200
    Validate JSON Response Structure    ${response}
    VAR    ${books_data}    ${response.json()}
    Should Be True    isinstance($books_data, list)    msg=Books list should be an array

    IF    ${books_data}
        FOR    ${book}    IN    @{books_data}
            Validate Single Book Structure    ${book}
        END
    ELSE
        Log    Books list is empty - this may be expected for filtered results    level=INFO
    END

Validate Single Book Response
    [Documentation]    Validates single book API response structure and content
    [Arguments]    ${response}
    Should Be Equal As Numbers    ${response.status_code}    200
    Validate JSON Response Structure    ${response}
    VAR    ${book_data}    ${response.json()}
    Should Be True    isinstance($book_data, dict)    msg=Single book should be an object
    Validate Single Book Structure    ${book_data}

Validate Single Book Structure
    [Documentation]    Validates individual book object has required fields
    [Arguments]    ${book_object}
    VAR    @{required_fields}    Create List    id    title    author    pages    category
    FOR    ${field}    IN    @{required_fields}
        Dictionary Should Contain Key    ${book_object}    ${field}
        ...    msg=Book object missing required field: ${field}
        Should Not Be Empty    ${book_object}[${field}]
        ...    msg=Book field '${field}' should not be empty
    END

    # Validate field types
    Should Be True    isinstance($book_object['id'], int)    msg=Book ID should be integer
    Should Be True    isinstance($book_object['title'], str)    msg=Book title should be string
    Should Be True    isinstance($book_object['author'], str)    msg=Book author should be string
    Should Be True    isinstance($book_object['pages'], int)    msg=Book pages should be integer
    Should Be True    isinstance($book_object['category'], str)    msg=Book category should be string

Validate Error Response Structure
    [Documentation]    Validates API error response follows expected format
    [Arguments]    ${response}    ${expected_status}=400
    Should Be Equal As Numbers    ${response.status_code}    ${expected_status}
    Validate JSON Response Structure    ${response}
    VAR    ${error_data}    ${response.json()}
    Dictionary Should Contain Key    ${error_data}    detail
    Should Not Be Empty    ${error_data}[detail]    msg=Error detail should not be empty

Validate Response Headers
    [Documentation]    Validates API response headers contain expected values
    [Arguments]    ${response}
    VAR    ${headers}    ${response.headers}
    Dictionary Should Contain Key    ${headers}    content-type
    Should Contain    ${headers}[content-type]    application/json
    Dictionary Should Contain Key    ${headers}    content-length

# ============================================================================
# SEARCH AND FILTER VALIDATION
# ============================================================================

Validate Search Results For Title
    [Documentation]    Validates search results contain books matching title criteria
    [Arguments]    ${books_list}    ${search_keyword}
    Should Not Be Empty    ${books_list}    msg=Search results should not be empty for "${search_keyword}"
    FOR    ${book}    IN    @{books_list}
        VAR    ${normalized_title}    Normalize Text For Comparison    ${book}[title]
        VAR    ${normalized_keyword}    Normalize Text For Comparison    ${search_keyword}
        Should Contain    ${normalized_title}    ${normalized_keyword}
        ...    msg=Book "${book}[title]" does not contain search keyword "${search_keyword}"
    END
    Log    All ${len(books_list)} search results contain "${search_keyword}" in title

Validate Search Results For Author
    [Documentation]    Validates search results contain books by matching author
    [Arguments]    ${books_list}    ${author_keyword}
    Should Not Be Empty    ${books_list}    msg=Search results should not be empty for author "${author_keyword}"
    FOR    ${book}    IN    @{books_list}
        VAR    ${normalized_author}    Normalize Text For Comparison    ${book}[author]
        VAR    ${normalized_keyword}    Normalize Text For Comparison    ${author_keyword}
        Should Contain    ${normalized_author}    ${normalized_keyword}
        ...    msg=Book by "${book}[author]" does not match author keyword "${author_keyword}"
    END
    Log    All ${len(books_list)} search results match author "${author_keyword}"

# ============================================================================
# PAGINATION VALIDATION
# ============================================================================

Validate Pagination Response
    [Documentation]    Validates paginated API response structure and metadata
    [Arguments]    ${response}    ${expected_limit}=${DEFAULT_PAGE_SIZE}
    Validate Books List Response    ${response}
    VAR    ${books_data}    ${response.json()}
    VAR    ${actual_count}    Get Length    ${books_data}
    Should Be True    ${actual_count} <= ${expected_limit}
    ...    msg=Returned ${actual_count} books, expected max ${expected_limit}

    # Check for pagination headers (if implemented)
    VAR    ${headers}    ${response.headers}
    TRY
        Dictionary Should Contain Key    ${headers}    x-total-count
        VAR    ${total_count}    Get From Dictionary    ${headers}    x-total-count
        Should Be True    int($total_count) >= ${actual_count}
        Log    Pagination metadata: ${actual_count}/${total_count} books
    EXCEPT    *
        Log    Pagination metadata headers not found - implementation may vary    level=INFO
    END

# ============================================================================
# PERFORMANCE AND LOAD TESTING
# ============================================================================

Measure API Response Time
    [Documentation]    Measures and validates API endpoint response time
    [Arguments]    ${endpoint}    ${max_response_time}=${MAX_RESPONSE_TIME}
    VAR    ${start_time}    Get Time    epoch
    VAR    ${response}    Make GET Request To Books API    ${endpoint}
    VAR    ${end_time}    Get Time    epoch
    VAR    ${response_time}    Evaluate    ${end_time} - ${start_time}

    Should Be True    ${response_time} <= ${max_response_time}
    ...    msg=Response time ${response_time}s exceeds limit ${max_response_time}s
    Log    API endpoint ${endpoint} responded in ${response_time}s
    RETURN    ${response_time}

Execute Load Test On API Endpoint
    [Documentation]    Executes simple load test on API endpoint
    [Arguments]    ${endpoint}    ${request_count}=10    ${max_avg_time}=${MAX_RESPONSE_TIME}
    VAR    @{response_times}    Create List
    FOR    ${i}    IN RANGE    ${request_count}
        VAR    ${response_time}    Measure API Response Time    ${endpoint}    ${MAX_RESPONSE_TIME}
        Append To List    ${response_times}    ${response_time}
    END

    VAR    ${total_time}    Evaluate    sum($response_times)
    VAR    ${average_time}    Evaluate    ${total_time} / ${request_count}
    VAR    ${min_time}    Evaluate    min($response_times)
    VAR    ${max_time}    Evaluate    max($response_times)

    Should Be True    ${average_time} <= ${max_avg_time}
    ...    msg=Average response time ${average_time}s exceeds limit ${max_avg_time}s

    Log    Load test results: ${request_count} requests, avg=${average_time}s, min=${min_time}s, max=${max_time}s
    RETURN    ${response_times}

# ============================================================================
# ERROR HANDLING AND NEGATIVE TESTING
# ============================================================================

Test Invalid Book ID Response
    [Documentation]    Tests API behavior with invalid book IDs
    [Arguments]    ${invalid_id}    ${expected_status}=404
    VAR    ${response}    Get Book By ID From API    ${invalid_id}    ${expected_status}
    Should Be Equal As Numbers    ${response.status_code}    ${expected_status}
    Validate Error Response Structure    ${response}    ${expected_status}

Test Malformed Request Parameters
    [Documentation]    Tests API behavior with malformed or invalid parameters
    [Arguments]    &{invalid_params}
    VAR    ${response}    Make GET Request To Books API    ${BOOKS_LIST_ENDPOINT}
    ...    ${invalid_params}    expected_status=400
    Should Be Equal As Numbers    ${response.status_code}    400
    Validate Error Response Structure    ${response}    400

# ============================================================================
# UTILITY AND HELPER KEYWORDS
# ============================================================================

Get Random Book ID From API
    [Documentation]    Retrieves a random valid book ID from the books list
    VAR    ${books_data}    Get All Books From API    limit=10
    Should Not Be Empty    ${books_data}    msg=No books available to get random ID
    VAR    ${random_index}    Evaluate    random.randint(0, len($books_data) - 1)    modules=random
    VAR    ${random_book}    Get From List    ${books_data}    ${random_index}
    VAR    ${book_id}    Get From Dictionary    ${random_book}    id
    Log    Selected random book ID: ${book_id}
    RETURN    ${book_id}

Convert Response To Pretty JSON
    [Documentation]    Converts API response to formatted JSON for debugging
    [Arguments]    ${response}
    ${json_data}=    Evaluate    $response.json()
    VAR    ${pretty_json}    Evaluate    json.dumps($json_data, indent=2)    modules=json
    Log    ${pretty_json}    level=DEBUG
    RETURN    ${pretty_json}

Log API Request Details
    [Documentation]    Logs detailed information about API request for debugging
    [Arguments]    ${method}    ${endpoint}    ${params}=${None}    ${data}=${None}
    Log    API Request Details:    level=DEBUG
    Log    Method: ${method}    level=DEBUG
    Log    Endpoint: ${endpoint}    level=DEBUG
    IF    ${params}
        Log    Parameters: ${params}    level=DEBUG
    END
    IF    ${data}
        Log    Data: ${data}    level=DEBUG
    END

# ============================================================================
# JSON SCHEMA VALIDATION
# ============================================================================

Validate JSON Schema For Book
    [Documentation]    Validates book object against expected JSON schema
    [Arguments]    ${book_object}
    # Basic schema validation - could be extended with jsonschema library
    VAR    @{required_properties}    Create List    id    title    author    pages    category
    VAR    @{optional_properties}    Create List    description    publication_date    genre

    FOR    ${property}    IN    @{required_properties}
        Dictionary Should Contain Key    ${book_object}    ${property}
        Should Not Be Empty    ${book_object}[${property}]
    END

    # Validate data types
    Should Be True    isinstance($book_object['id'], int)
    Should Be True    isinstance($book_object['title'], str)
    Should Be True    isinstance($book_object['author'], str)
    Should Be True    isinstance($book_object['pages'], int)
    Should Be True    isinstance($book_object['category'], str)

    Log    Book object schema validation completed successfully