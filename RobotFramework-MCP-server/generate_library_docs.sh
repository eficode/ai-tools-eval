#!/bin/bash
################################################################################
# Generate Library Documentation for Robot Framework Libraries
# 
# This script generates documentation for all installed RF libraries:
# - Browser Library (Playwright-based web testing)
# - RequestsLibrary (HTTP API testing)
# - Robocop (RF code quality static analyzer)
#
# Documentation is generated in multiple formats:
# - JSON: Machine-readable format for MCP tools
# - HTML: Human-readable format for browsers
# - XML: Libspec format for tooling integration
################################################################################

set -euo pipefail

DOCS_DIR="/app/docs"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo "=================================="
echo "RF Library Documentation Generator"
echo "=================================="
echo "Started: ${TIMESTAMP}"
echo ""

# Create docs directory if it doesn't exist
mkdir -p "${DOCS_DIR}"

# Function to generate documentation for a library
generate_docs() {
    local library_name="$1"
    local display_name="$2"
    
    echo "📚 Generating documentation for ${display_name}..."
    
    # Generate JSON format (machine-readable for MCP)
    if python -m robot.libdoc "${library_name}" "${DOCS_DIR}/${library_name}.json" 2>/dev/null; then
        echo "   ✅ JSON: ${DOCS_DIR}/${library_name}.json"
    else
        echo "   ⚠️  JSON generation failed for ${library_name}"
    fi
    
    # Generate HTML format (human-readable)
    if python -m robot.libdoc "${library_name}" "${DOCS_DIR}/${library_name}.html" 2>/dev/null; then
        echo "   ✅ HTML: ${DOCS_DIR}/${library_name}.html"
    else
        echo "   ⚠️  HTML generation failed for ${library_name}"
    fi
    
    # Generate XML/Libspec format (tooling integration)
    if python -m robot.libdoc "${library_name}" "${DOCS_DIR}/${library_name}.xml" 2>/dev/null; then
        echo "   ✅ XML:  ${DOCS_DIR}/${library_name}.xml"
    else
        echo "   ⚠️  XML generation failed for ${library_name}"
    fi
    
    echo ""
}

# Generate documentation for each library
generate_docs "Browser" "Browser Library (Playwright)"
generate_docs "RequestsLibrary" "Requests Library (HTTP/REST)"

# Robocop is a linter/analyzer, not a keyword library, so it doesn't have libdoc
# Instead, we'll capture its help output
echo "📚 Generating documentation for Robocop..."
if python -m robocop --help > "${DOCS_DIR}/Robocop_help.txt" 2>/dev/null; then
    echo "   ✅ Help: ${DOCS_DIR}/Robocop_help.txt"
else
    echo "   ⚠️  Robocop help generation failed"
fi

# List available rules
if python -m robocop --list > "${DOCS_DIR}/Robocop_rules.txt" 2>/dev/null; then
    echo "   ✅ Rules: ${DOCS_DIR}/Robocop_rules.txt"
else
    echo "   ⚠️  Robocop rules listing failed"
fi
echo ""

# Generate summary file
cat > "${DOCS_DIR}/README.md" << 'EOF'
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
EOF

# List all generated files with sizes
echo "📦 Generated Documentation Files:"
echo ""
ls -lh "${DOCS_DIR}" | tail -n +2 | awk '{printf "   %s  %s\n", $5, $9}'
echo ""
echo "=================================="
echo "Documentation generation complete!"
echo "Location: ${DOCS_DIR}"
echo "=================================="
