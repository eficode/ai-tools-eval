*** Settings ***
Library          Browser

*** Test Cases ***
Super Simple Test
    [Documentation]    Test with hardcoded values
    New Browser    chromium    headless=${True}
    New Page    http://books-database-service:8000
    Wait For Load State    networkidle    timeout=10s
    Wait For Elements State    selector=#book-form    state=visible