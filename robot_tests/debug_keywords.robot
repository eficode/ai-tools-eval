*** Settings ***
Library          Browser
Resource         resources/common.resource

*** Variables ***
${BROWSER_TYPE}       chromium
${HEADLESS_MODE}      ${True}

*** Test Cases ***
Debug Individual Keywords
    [Documentation]    Test each keyword individually

    # Mirror the exact test flow
    Given User Opens Books Library Application
    Then Books Library Page Should Load
    And Page Should Display Main Components

*** Keywords ***
Given User Opens Books Library Application
    [Documentation]    Navigate to the Books Library application homepage
    New Page    http://books-database-service:8000
    Wait For Load State    networkidle    timeout=${TIMEOUT}

Then Books Library Page Should Load
    [Documentation]    Verify the Books Library page loads correctly
    Get Title    contains    Books Library
    Wait For Elements State    selector=id=book-form    state=visible    timeout=${TIMEOUT}

And Page Should Display Main Components
    [Documentation]    Verify main page components are visible
    Wait For Elements State    selector=id=book-form    state=visible    timeout=${TIMEOUT}
    Wait For Elements State    selector=id=books-list    state=visible    timeout=${TIMEOUT}
    Wait For Elements State    selector=id=search-input    state=visible    timeout=${TIMEOUT}

Page Should Display Main Components
    [Documentation]    Verify main page components are visible (duplicate for "And" usage)
    Wait For Elements State    selector=id=book-form    state=visible    timeout=${TIMEOUT}
    Wait For Elements State    selector=id=books-list    state=visible    timeout=${TIMEOUT}
    Wait For Elements State    selector=id=search-input    state=visible    timeout=${TIMEOUT}