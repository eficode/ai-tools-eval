*** Settings ***
Library          Browser
Resource         resources/common.resource

*** Test Cases ***
Debug Form Structure
    [Documentation]    Inspect the actual HTML form structure

    # Setup
    New Browser    chromium    headless=${True}
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page    http://books-database-service:8000
    Wait For Load State    networkidle    timeout=10s

    # Get the form HTML structure
    ${form_html}    Get Property    id=book-form    outerHTML
    Log    Form HTML: ${form_html}

    # Check if form has action and method attributes
    ${has_action}    Run Keyword And Return Status    Get Attribute    id=book-form    action
    ${has_method}    Run Keyword And Return Status    Get Attribute    id=book-form    method
    Log    Form has action attribute: ${has_action}
    Log    Form has method attribute: ${has_method}

    IF    ${has_action}
        ${form_action}    Get Attribute    id=book-form    action
        Log    Form action: ${form_action}
    END

    IF    ${has_method}
        ${form_method}    Get Attribute    id=book-form    method
        Log    Form method: ${form_method}
    END

    # Check submit button details
    ${submit_html}    Get Property    css=#book-form [type="submit"]    outerHTML
    Log    Submit button HTML: ${submit_html}

    # Check if form fields have proper name attributes
    ${title_name}    Get Attribute    id=title    name
    ${author_name}    Get Attribute    id=author    name
    ${pages_name}    Get Attribute    id=pages    name
    ${category_name}    Get Attribute    id=category    name
    Log    Field names - title: ${title_name}, author: ${author_name}, pages: ${pages_name}, category: ${category_name}