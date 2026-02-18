*** Settings ***
Library          Browser

*** Test Cases ***
List Browser Keywords
    [Documentation]    List available Browser keywords
    ${keywords}    Get Library Instance    Browser
    Log    Available Browser keywords listed in test execution log