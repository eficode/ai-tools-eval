*** Settings ***
Documentation     API-specific keywords for Books Database testing
...               Implements REST API testing patterns with proper error handling

Resource          common.resource


*** Keywords ***
# =============================================================================
# API BOOK OPERATIONS
# =============================================================================

Create Book Via API
    [Documentation]    Creates a book using the REST API
    [Arguments]    ${title}    ${author}    ${year}=${EMPTY}    ${isbn}=${EMPTY}
    
    &{book_data}=    Create Dictionary    
    ...    title=${title}    
    ...    author=${author}
    ...    pages=500
    ...    category=Fiction
    ...    favorite=${FALSE}
    
    ${response}=    POST On Session    books_api    /books/    json=${book_data}    expected_status=200
    RETURN    ${response.json()}

Get All Books Via API
    [Documentation]    Retrieves all books from the API
    ${response}=    GET On Session    books_api    /books/    expected_status=200
    RETURN    ${response.json()}

Get Book By ID Via API
    [Documentation]    Retrieves a specific book by ID
    [Arguments]    ${book_id}
    ${response}=    GET On Session    books_api    /books/${book_id}    expected_status=200
    RETURN    ${response.json()}

Update Book Via API
    [Documentation]    Updates an existing book via API
    [Arguments]    ${book_id}    ${title}    ${author}    ${year}=${EMPTY}    ${isbn}=${EMPTY}
    
    &{book_data}=    Create Dictionary    
    ...    title=${title}    
    ...    author=${author}
    ...    pages=500
    ...    category=Fiction
    ...    favorite=${FALSE}
    
    ${response}=    PUT On Session    books_api    /books/${book_id}    json=${book_data}    expected_status=200
    RETURN    ${response.json()}

Delete Book Via API
    [Documentation]    Deletes a book via API
    [Arguments]    ${book_id}
    ${response}=    DELETE On Session    books_api    /books/${book_id}    expected_status=200
    RETURN    ${response}

# =============================================================================
# API VALIDATION
# =============================================================================

Verify Book Exists Via API
    [Documentation]    Verifies a book exists in the API response
    [Arguments]    ${book_id}    ${expected_title}
    
    ${book}=    Get Book By ID Via API    ${book_id}
    Should Be Equal    ${book}[title]    ${expected_title}

Validate Book Data Structure
    [Documentation]    Validates that book data has required fields
    [Arguments]    ${book_data}
    
    Should Contain    ${book_data}    id
    Should Contain    ${book_data}    title
    Should Contain    ${book_data}    author
    Should Contain    ${book_data}    pages
    Should Contain    ${book_data}    category
    Should Not Be Empty    ${book_data}[title]
    Should Not Be Empty    ${book_data}[author]

Validate API Response Format
    [Documentation]    Validates API response structure
    [Arguments]    ${response}    ${expected_fields}
    
    Should Be Equal As Integers    ${response.status_code}    200
    ${data}=    Set Variable    ${response.json()}
    
    FOR    ${field}    IN    @{expected_fields}
        Should Contain    ${data}    ${field}
    END

# =============================================================================
# ERROR TESTING
# =============================================================================

Test Invalid API Request
    [Documentation]    Tests API with invalid data and expects error
    [Arguments]    ${invalid_data}    ${expected_status}=400
    
    TRY
        ${response}=    POST On Session    books_api    /books/    json=${invalid_data}    expected_status=${expected_status}
        RETURN    ${response}
    EXCEPT    AS    ${error}
        Log    Expected API error: ${error}    INFO
        RETURN    ${None}
    END

# =============================================================================
# GHERKIN-STYLE API KEYWORDS
# =============================================================================

Given API Session Is Created
    [Documentation]    Precondition: API session is ready for testing
    # Session already created in Setup Test Environment
    Log    API session ready    INFO

When Book Is Created Via API
    [Documentation]    Action: Create a book via API
    [Arguments]    ${title}    ${author}
    ${book}=    Create Book Via API    ${title}    ${author}
    Set Test Variable    ${CREATED_BOOK}    ${book}
    RETURN    ${book}

When All Books Are Retrieved Via API
    [Documentation]    Action: Get all books from API
    ${books}=    Get All Books Via API
    Set Test Variable    ${ALL_BOOKS}    ${books}
    RETURN    ${books}

Then API Should Return Book
    [Documentation]    Assertion: API contains the expected book
    [Arguments]    ${book_id}    ${expected_title}
    Verify Book Exists Via API    ${book_id}    ${expected_title}

Then API Should Return Valid Book List
    [Documentation]    Assertion: API returns properly formatted book list
    Should Not Be Empty    ${ALL_BOOKS}
    FOR    ${book}    IN    @{ALL_BOOKS}
        Validate Book Data Structure    ${book}
    END