*** Settings ***
Library          Browser
Resource         resources/common.resource

*** Variables ***
${BOOK_FORM}     #book-form
${TIMEOUT}       10s

*** Test Cases ***
Debug Selector Test
    [Documentation]    Debug empty selector issue
    Log    TIMEOUT value: ${TIMEOUT}
    Log    BOOK_FORM value: ${BOOK_FORM}
    New Browser    chromium    headless=${True}
    New Page    http://books-database-service:8000
    Wait For Load State    networkidle    timeout=${TIMEOUT}
    Wait For Elements State    ${BOOK_FORM}    visible    timeout=${TIMEOUT}