*** Settings ***
Documentation    API-specific keywords for Books Library test automation
...              Contains specialized keywords for REST API interactions,
...              request/response handling, and API validation patterns.

Library          RequestsLibrary
Library          Collections
Library          String
Library          DateTime
Library          JSONLibrary

Resource         resources/common.resource

*** Keywords ***
# Session Management Keywords
Create Books API Session
    [Documentation]    Create a session specifically for Books API with optimal configuration
    [Arguments]    ${base_url}=${API_BASE_URL}    ${timeout}=30s    ${retry}=3

    &{headers}    Create Dictionary
    ...    Content-Type=application/json
    ...    Accept=application/json
    ...    User-Agent=BooksLibrary-TestAutomation/1.0

    &{session_config}    Create Dictionary
    ...    timeout=${timeout}
    ...    max_retries=${retry}
    ...    verify=${True}

    Create Session    books_api    ${base_url}    headers=&{headers}    **&{session_config}
    Log    Books API session created with base URL: ${base_url}

Verify API Health
    [Documentation]    Verify API is healthy and responsive
    [Arguments]    ${session_name}=books_api

    TRY
        VAR    ${response}    GET On Session    ${session_name}    /books/    expected_status=200
        Log    API health check passed - status: ${response.status_code}
        RETURN    ${True}
    EXCEPT    *    AS    ${error}
        Log    API health check failed: ${error}    ERROR
        RETURN    ${False}
    END

# CRUD Operation Keywords
Create Book Via API
    [Documentation]    Create a book through API with comprehensive validation
    [Arguments]    ${book_data}    ${session_name}=books_api    ${expected_status}=201

    Log    Creating book via API: ${book_data}    DEBUG

    VAR    ${response}    POST On Session    ${session_name}    /books/    json=${book_data}    expected_status=${expected_status}
    VAR    ${created_book}    Set Variable    ${response.json()}

    # Validate response structure
    Should Not Be Empty    ${created_book}
    Dictionary Should Contain Key    ${created_book}    id
    Should Be Valid Book ID    ${created_book}[id]

    Log    Book created successfully with ID: ${created_book}[id]
    RETURN    ${created_book}

Get Book Via API
    [Documentation]    Retrieve a book by ID through API
    [Arguments]    ${book_id}    ${session_name}=books_api    ${expected_status}=200

    Log    Retrieving book via API: ID ${book_id}    DEBUG

    VAR    ${response}    GET On Session    ${session_name}    /books/${book_id}    expected_status=${expected_status}

    IF    ${expected_status} == 200
        VAR    ${book_data}    Set Variable    ${response.json()}
        Validate Book Data Structure    ${book_data}
        Log    Book retrieved successfully: ${book_data}[title]
        RETURN    ${book_data}
    ELSE
        Log    Book retrieval returned status: ${response.status_code}
        RETURN    ${response.json()}
    END

Get All Books Via API
    [Documentation]    Retrieve all books through API with optional filtering
    [Arguments]    ${session_name}=books_api    ${params}=${EMPTY}

    Log    Retrieving all books via API    DEBUG

    IF    ${params} != ${EMPTY}
        VAR    ${response}    GET On Session    ${session_name}    /books/    params=${params}    expected_status=200
    ELSE
        VAR    ${response}    GET On Session    ${session_name}    /books/    expected_status=200
    END

    VAR    ${books_list}    Set Variable    ${response.json()}
    Should Be True    isinstance($books_list, list)    msg=Response should be a list

    Log    Retrieved ${len($books_list)} books from API
    RETURN    ${books_list}

Update Book Via API
    [Documentation]    Update an existing book through API
    [Arguments]    ${book_id}    ${update_data}    ${session_name}=books_api    ${expected_status}=200

    Log    Updating book via API: ID ${book_id} with data ${update_data}    DEBUG

    VAR    ${response}    PUT On Session    ${session_name}    /books/${book_id}    json=${update_data}    expected_status=${expected_status}

    IF    ${expected_status} == 200
        VAR    ${updated_book}    Set Variable    ${response.json()}
        Validate Book Data Structure    ${updated_book}
        Log    Book updated successfully: ${updated_book}[title]
        RETURN    ${updated_book}
    ELSE
        Log    Book update returned status: ${response.status_code}
        RETURN    ${response.json()}
    END

Delete Book Via API
    [Documentation]    Delete a book through API
    [Arguments]    ${book_id}    ${session_name}=books_api    ${expected_status}=200

    Log    Deleting book via API: ID ${book_id}    DEBUG

    VAR    ${response}    DELETE On Session    ${session_name}    /books/${book_id}    expected_status=${expected_status}

    IF    ${expected_status} == 200
        VAR    ${delete_response}    Set Variable    ${response.json()}
        Dictionary Should Contain Key    ${delete_response}    message
        Log    Book deleted successfully: ${delete_response}[message]
        RETURN    ${delete_response}
    ELSE
        Log    Book deletion returned status: ${response.status_code}
        RETURN    ${response.json()}
    END

Toggle Book Favorite Via API
    [Documentation]    Toggle book favorite status through API
    [Arguments]    ${book_id}    ${favorite_status}    ${session_name}=books_api    ${expected_status}=200

    Log    Toggling book favorite via API: ID ${book_id} to ${favorite_status}    DEBUG

    &{favorite_data}    Create Dictionary    favorite=${favorite_status}
    VAR    ${response}    PATCH On Session    ${session_name}    /books/${book_id}/favorite    json=&{favorite_data}    expected_status=${expected_status}

    IF    ${expected_status} == 200
        VAR    ${updated_book}    Set Variable    ${response.json()}
        Should Be Equal    ${updated_book}[favorite]    ${favorite_status}
        Log    Book favorite status updated: ${updated_book}[favorite]
        RETURN    ${updated_book}
    ELSE
        Log    Favorite toggle returned status: ${response.status_code}
        RETURN    ${response.json()}
    END

# Validation and Verification Keywords
Verify Book Exists In API
    [Documentation]    Verify that a book exists in the system via API
    [Arguments]    ${book_id}    ${session_name}=books_api

    TRY
        Get Book Via API    ${book_id}    ${session_name}
        Log    Book exists in system: ID ${book_id}
        RETURN    ${True}
    EXCEPT    *
        Log    Book does not exist in system: ID ${book_id}
        RETURN    ${False}
    END

Verify Book Does Not Exist In API
    [Documentation]    Verify that a book does not exist in the system via API
    [Arguments]    ${book_id}    ${session_name}=books_api

    TRY
        Get Book Via API    ${book_id}    ${session_name}    expected_status=404
        Log    Verified book does not exist: ID ${book_id}
        RETURN    ${True}
    EXCEPT    *
        Log    Unexpected: Book still exists: ID ${book_id}
        RETURN    ${False}
    END

Verify API Response Structure
    [Documentation]    Verify that API response has expected structure
    [Arguments]    ${response_data}    ${expected_fields}    ${response_type}=dict

    IF    "${response_type}" == "list"
        Should Be True    isinstance($response_data, list)    msg=Response should be a list
        FOR    ${item}    IN    @{response_data}
            FOR    ${field}    IN    @{expected_fields}
                Dictionary Should Contain Key    ${item}    ${field}
            END
        END
    ELSE
        Should Be True    isinstance($response_data, dict)    msg=Response should be a dictionary
        FOR    ${field}    IN    @{expected_fields}
            Dictionary Should Contain Key    ${response_data}    ${field}
        END
    END

# Data Management Keywords
Create Test Books Dataset
    [Documentation]    Create a dataset of test books for comprehensive testing
    [Arguments]    ${book_count}=5    ${session_name}=books_api

    @{created_books}    Create List
    @{created_book_ids}    Create List

    FOR    ${index}    IN RANGE    ${book_count}
        &{test_book}    Generate Unique Book Data    Test Book ${index + 1}

        # Vary the data for testing
        IF    ${index} % 2 == 0
            Set To Dictionary    ${test_book}    favorite=${True}
        END

        VAR    ${random_category}    Generate Random Book Category
        Set To Dictionary    ${test_book}    category=${random_category}

        VAR    ${created_book}    Create Book Via API    ${test_book}    ${session_name}
        Append To List    ${created_books}    ${created_book}
        Append To List    ${created_book_ids}    ${created_book}[id]

        Log    Created test book ${index + 1}: ${created_book}[title]
    END

    Log    Created ${book_count} test books for testing
    RETURN    ${created_books}    ${created_book_ids}

Cleanup Test Books Dataset
    [Documentation]    Clean up test books created during testing
    [Arguments]    ${book_ids}    ${session_name}=books_api

    VAR    ${cleanup_count}    ${0}

    FOR    ${book_id}    IN    @{book_ids}
        TRY
            Delete Book Via API    ${book_id}    ${session_name}    expected_status=any
            VAR    ${cleanup_count}    ${cleanup_count + 1}
            Log    Cleaned up test book ID: ${book_id}
        EXCEPT    *    AS    ${error}
            Log    Failed to cleanup book ID ${book_id}: ${error}    WARN
        END
    END

    Log    Cleaned up ${cleanup_count} test books

# API Performance and Monitoring Keywords
Measure API Response Time
    [Documentation]    Measure and validate API response time
    [Arguments]    ${endpoint}    ${method}=GET    ${session_name}=books_api    ${max_response_time}=5s

    VAR    ${start_time}    Get Current Date    result_format=epoch

    IF    "${method}" == "GET"
        VAR    ${response}    GET On Session    ${session_name}    ${endpoint}    expected_status=200
    ELSE IF    "${method}" == "POST"
        &{test_data}    Generate Unique Book Data
        VAR    ${response}    POST On Session    ${session_name}    ${endpoint}    json=&{test_data}    expected_status=200
    ELSE
        Fail    Unsupported HTTP method for performance testing: ${method}
    END

    VAR    ${end_time}    Get Current Date    result_format=epoch
    VAR    ${response_time}    Evaluate    ${end_time} - ${start_time}

    Log    API response time: ${response_time}s for ${method} ${endpoint}

    # Convert max_response_time from string (e.g., "5s") to float
    VAR    ${max_time_seconds}    Convert Time    ${max_response_time}
    Should Be True    ${response_time} <= ${max_time_seconds}
    ...    msg=API response time ${response_time}s exceeded maximum ${max_time_seconds}s

    RETURN    ${response_time}

Validate API Error Response
    [Documentation]    Validate structure and content of API error responses
    [Arguments]    ${error_response}    ${expected_status}    ${expected_error_fields}=@{['detail']}

    Should Be Equal As Numbers    ${error_response.status_code}    ${expected_status}
    VAR    ${error_data}    Set Variable    ${error_response.json()}

    FOR    ${field}    IN    @{expected_error_fields}
        Dictionary Should Contain Key    ${error_data}    ${field}
        Should Not Be Empty    ${error_data}[${field}]
    END

    Log    Validated error response: ${error_data}

# Batch Operations Keywords
Create Multiple Books Via API
    [Documentation]    Create multiple books efficiently through API
    [Arguments]    ${books_data}    ${session_name}=books_api

    @{created_books}    Create List

    FOR    ${book_data}    IN    @{books_data}
        VAR    ${created_book}    Create Book Via API    ${book_data}    ${session_name}
        Append To List    ${created_books}    ${created_book}
    END

    Log    Successfully created ${len($created_books)} books via API
    RETURN    ${created_books}

Update Multiple Books Via API
    [Documentation]    Update multiple books with batch operations
    [Arguments]    ${book_updates}    ${session_name}=books_api

    @{updated_books}    Create List

    FOR    ${book_id}    ${update_data}    IN    @{book_updates}
        VAR    ${updated_book}    Update Book Via API    ${book_id}    ${update_data}    ${session_name}
        Append To List    ${updated_books}    ${updated_book}
    END

    Log    Successfully updated ${len($updated_books)} books via API
    RETURN    ${updated_books}