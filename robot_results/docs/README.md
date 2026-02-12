# Robot Framework Library Documentation

This directory contains auto-generated documentation for all installed RF libraries.

## Available Libraries

### Browser Library (Playwright-based)
- **Version**: 19.12.3
- **Purpose**: Web browser automation using Playwright
- **Documentation**: 
  - [Browser.html](Browser.html) - Human-readable HTML
  - [Browser.json](Browser.json) - Machine-readable JSON
  - [Browser.xml](Browser.xml) - Libspec XML format

### RequestsLibrary
- **Version**: 0.9.7
- **Purpose**: HTTP/REST API testing
- **Documentation**: 
  - [RequestsLibrary.html](RequestsLibrary.html) - Human-readable HTML
  - [RequestsLibrary.json](RequestsLibrary.json) - Machine-readable JSON
  - [RequestsLibrary.xml](RequestsLibrary.xml) - Libspec XML format

### Robocop
- **Version**: 7.2.0
- **Purpose**: Static code analysis and linting for Robot Framework
- **Documentation**: 
  - [Robocop_help.txt](Robocop_help.txt) - Command-line help
  - [Robocop_rules.txt](Robocop_rules.txt) - Available linting rules

## Formats Explained

- **HTML**: Open in browser for browsing keywords, arguments, and examples
- **JSON**: Used by MCP tools and IDEs for code completion
- **XML**: Libspec format for Robot Framework tooling integration

## Usage

### View in Browser
```bash
# From host machine (if docs are mounted)
open robot_results/docs/Browser.html

# Or serve from container
python -m http.server 8080 --directory /app/docs
```

### Query via MCP
The rf-docs-mcp server can now query these generated docs for up-to-date library information.

### Use in IDE
IDEs like VS Code with Robot Framework extensions can use the XML libspec files for autocomplete.

## Regenerate Documentation

To regenerate documentation (e.g., after library updates):
```bash
docker exec robotframework-mcp /app/generate_library_docs.sh
```
