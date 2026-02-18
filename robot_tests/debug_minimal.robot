*** Settings ***
Library          Browser
Resource         resources/common.resource

*** Variables ***
${BOOK_FORM}     #book-form

*** Test Cases ***
Debug Minimal Test
    [Documentation]    Debug the Browser library issue
    Log    BOOK_FORM value: ${BOOK_FORM}
    Log    TIMEOUT value: ${TIMEOUT}
    New Browser    chromium    headless=${True}
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    http://books-database-service:8000
    Wait For Load State    networkidle    timeout=10s
    Wait For Elements State    selector=#book-form    state=visible    timeout=10s