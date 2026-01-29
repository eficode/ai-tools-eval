#!/usr/bin/env python3
"""
MCP server for Robot Framework 7.4.1 Documentation
Fetches and provides searchable access to Robot Framework 7.4.1 documentation.

Tools:
  - fetch_rf_documentation() - Downloads RF 7.4.1 docs (HTML) for all standard libraries
  - search_rf_documentation(query, max_results) - Search the documentation
  - get_library_keywords(library_name, filter_pattern) - List keywords from a specific library
  - get_all_keywords(filter_pattern) - List all keywords from all standard libraries
  - get_builtin_keywords(filter_pattern) - List BuiltIn keywords (backward compat)
  - get_keyword_documentation(keyword_name, library_name) - Get detailed docs for a specific keyword
  - check_keyword_availability(keyword_name) - Check if keyword exists in any standard library
  - get_documentation_url(topic) - Get direct URLs to RF documentation
  - run_rebot(output_files, options) - Reprocess Robot Framework output files
  - run_libdoc(library_or_resource, output_file, options) - Generate keyword documentation
  - run_testdoc(input_file, output_file, options) - Generate test case documentation
  - run_tidy(input_file, options) - Clean and format Robot Framework files
  - get_installed_library_docs(library_name) - Get documentation for installed RF libraries
  - list_installed_library_docs() - List all available library documentation files
"""
import os
import re
import json
import hashlib
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError
from html.parser import HTMLParser

from mcp.server.fastmcp import FastMCP

APP_NAME = "rf-docs-mcp"
RF_VERSION = "7.4.1"
RF_DOCS_URL = f"https://robotframework.org/robotframework/{RF_VERSION}/RobotFrameworkUserGuide.html"
RF_BASE_LIB_URL = f"https://robotframework.org/robotframework/{RF_VERSION}/libraries"

# Standard libraries to fetch
STANDARD_LIBRARIES = [
    "BuiltIn",
    "Collections", 
    "DateTime",
    "OperatingSystem",
    "Process",
    "Screenshot",
    "String",
    "Telnet",
    "XML"
]

# Storage paths
CACHE_DIR = Path(os.getenv("RF_DOCS_CACHE", "/tmp/rf_docs_cache"))
DOCS_FILE = CACHE_DIR / f"RobotFrameworkUserGuide_{RF_VERSION}.html"
INDEX_FILE = CACHE_DIR / f"docs_index_{RF_VERSION}.json"
KEYWORDS_INDEX = CACHE_DIR / f"all_keywords_{RF_VERSION}.json"

# Installed library docs location
LIBRARY_DOCS_DIR = Path("/app/docs")

mcp = FastMCP(APP_NAME)


class DocumentationParser(HTMLParser):
    """Parse Robot Framework documentation HTML to extract structured content."""
    
    def __init__(self):
        super().__init__()
        self.sections = []
        self.current_section = None
        self.current_content = []
        self.in_section = False
        self.section_level = 0
        
    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        
        # Detect section headers (h1, h2, h3, h4)
        if tag in ['h1', 'h2', 'h3', 'h4']:
            # Save previous section
            if self.current_section:
                self.current_section['content'] = ' '.join(self.current_content).strip()
                self.sections.append(self.current_section)
            
            # Start new section
            self.section_level = int(tag[1])
            section_id = attrs_dict.get('id', '')
            self.current_section = {
                'id': section_id,
                'level': self.section_level,
                'title': '',
                'content': ''
            }
            self.current_content = []
            self.in_section = True
            
    def handle_endtag(self, tag):
        if tag in ['h1', 'h2', 'h3', 'h4']:
            self.in_section = False
            
    def handle_data(self, data):
        if self.in_section and self.current_section:
            # This is the section title
            self.current_section['title'] = data.strip()
        elif self.current_section:
            # This is section content
            text = data.strip()
            if text:
                self.current_content.append(text)
    
    def get_sections(self):
        # Save last section
        if self.current_section:
            self.current_section['content'] = ' '.join(self.current_content).strip()
            self.sections.append(self.current_section)
        return self.sections


def _download_file(url: str, target_path: Path, user_agent: str = None) -> Dict:
    """Download a file from URL with proper error handling."""
    try:
        target_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Create request with user agent to avoid 403
        headers = {'User-Agent': user_agent or 'Mozilla/5.0 (compatible; RF-MCP-Docs/1.0)'}
        req = Request(url, headers=headers)
        
        with urlopen(req, timeout=30) as response:
            content = response.read()
            target_path.write_bytes(content)
            
        return {
            "success": True,
            "path": str(target_path),
            "size_bytes": len(content),
            "url": url
        }
    except HTTPError as e:
        return {
            "success": False,
            "error": f"HTTP Error {e.code}: {e.reason}",
            "url": url
        }
    except URLError as e:
        return {
            "success": False,
            "error": f"URL Error: {e.reason}",
            "url": url
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "url": url
        }


def _parse_documentation() -> Dict:
    """Parse downloaded documentation and create searchable index."""
    if not DOCS_FILE.exists():
        return {"error": "Documentation not downloaded. Call fetch_rf_documentation first."}
    
    try:
        html_content = DOCS_FILE.read_text(encoding='utf-8')
        parser = DocumentationParser()
        parser.feed(html_content)
        sections = parser.get_sections()
        
        # Create searchable index
        index = {
            "version": RF_VERSION,
            "parsed_at": datetime.now().isoformat(),
            "total_sections": len(sections),
            "sections": sections
        }
        
        # Save index
        INDEX_FILE.parent.mkdir(parents=True, exist_ok=True)
        INDEX_FILE.write_text(json.dumps(index, indent=2))
        
        return {
            "success": True,
            "sections_parsed": len(sections),
            "index_path": str(INDEX_FILE)
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Parsing error: {str(e)}"
        }


def _parse_library_keywords(library_name: str) -> Dict:
    """Parse library documentation to extract keywords from embedded JSON."""
    library_file = CACHE_DIR / f"{library_name}_{RF_VERSION}.html"
    
    if not library_file.exists():
        return {"error": f"{library_name} documentation not downloaded."}
    
    try:
        html_content = library_file.read_text(encoding='utf-8')
        
        # The keywords are embedded in JavaScript as: libdoc = {...};
        # Find the start of libdoc object
        start_match = re.search(r'libdoc\s*=\s*\{', html_content)
        
        if not start_match:
            return {
                "success": False,
                "error": "Could not find libdoc in HTML"
            }
        
        # Extract JSON by counting braces
        start_pos = start_match.end() - 1  # Include the opening brace
        depth = 0
        in_string = False
        escape = False
        
        for i in range(start_pos, len(html_content)):
            char = html_content[i]
            
            if escape:
                escape = False
                continue
                
            if char == '\\':
                escape = True
                continue
                
            if char == '"' and not escape:
                in_string = not in_string
                continue
                
            if not in_string:
                if char == '{':
                    depth += 1
                elif char == '}':
                    depth -= 1
                    if depth == 0:
                        end_pos = i + 1
                        libdoc_json = html_content[start_pos:end_pos]
                        break
        else:
            return {
                "success": False,
                "error": "Could not find end of libdoc JSON"
            }
        
        # Parse the JSON
        libdoc_data = json.loads(libdoc_json)
        
        keywords = {}
        for kw_data in libdoc_data.get("keywords", []):
            name = kw_data.get("name", "")
            if not name:
                continue
                
            # Build arguments string from args array
            args_parts = []
            for arg in kw_data.get("args", []):
                arg_repr = arg.get("repr", "")
                if arg_repr:
                    args_parts.append(arg_repr)
            args_str = ", ".join(args_parts)
            
            # Extract short documentation (strip HTML)
            doc = kw_data.get("shortdoc", "")
            doc = re.sub(r'<[^>]+>', '', doc)  # Remove HTML tags
            doc = re.sub(r'``([^`]+)``', r'\1', doc)  # Convert rst code to plain
            
            keywords[name] = {
                "name": name,
                "id": name.replace(" ", "%20"),
                "args": args_str,
                "doc": doc,
                "library": library_name,
                "source": kw_data.get("source", ""),
                "lineno": kw_data.get("lineno", "")
            }
        
        return {
            "success": True,
            "library": library_name,
            "keywords": keywords,
            "total_keywords": len(keywords)
        }
    except json.JSONDecodeError as e:
        return {
            "success": False,
            "error": f"JSON parsing error: {str(e)}"
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Parsing error: {str(e)}"
        }


@mcp.tool()
def fetch_rf_documentation(force_refresh: bool = False) -> Dict:
    """
    Download Robot Framework 7.4.1 documentation for all standard libraries.
    
    Parameters:
      - force_refresh: If True, re-download even if cached (default: False)
    
    Returns:
      - success: Boolean indicating if download succeeded
      - version: RF version (always 7.4.1)
      - files_downloaded: List of downloaded files
      - cache_location: Where files are stored
      - libraries: Dictionary of library parsing results
    """
    results = {
        "version": RF_VERSION,
        "cache_location": str(CACHE_DIR),
        "files_downloaded": [],
        "libraries": {}
    }
    
    # Download User Guide
    if force_refresh or not DOCS_FILE.exists():
        result = _download_file(RF_DOCS_URL, DOCS_FILE)
        results["user_guide"] = result
        if result["success"]:
            results["files_downloaded"].append("RobotFrameworkUserGuide.html")
    else:
        results["user_guide"] = {
            "success": True,
            "cached": True,
            "path": str(DOCS_FILE)
        }
    
    # Parse and index User Guide documentation
    if DOCS_FILE.exists():
        parse_result = _parse_documentation()
        results["indexing"] = parse_result
    
    # Download and parse all standard libraries
    all_keywords = {}
    total_keywords = 0
    
    for library_name in STANDARD_LIBRARIES:
        library_file = CACHE_DIR / f"{library_name}_{RF_VERSION}.html"
        library_url = f"{RF_BASE_LIB_URL}/{library_name}.html"
        
        # Download library docs
        if force_refresh or not library_file.exists():
            result = _download_file(library_url, library_file)
            if result["success"]:
                results["files_downloaded"].append(f"{library_name}.html")
        
        # Parse keywords
        if library_file.exists():
            keywords_result = _parse_library_keywords(library_name)
            results["libraries"][library_name] = {
                "success": keywords_result.get("success", False),
                "total_keywords": keywords_result.get("total_keywords", 0)
            }
            
            if keywords_result.get("success"):
                all_keywords[library_name] = keywords_result.get("keywords", {})
                total_keywords += keywords_result.get("total_keywords", 0)
    
    # Save combined keywords index
    if all_keywords:
        keywords_index = {
            "version": RF_VERSION,
            "parsed_at": datetime.now().isoformat(),
            "total_libraries": len(all_keywords),
            "total_keywords": total_keywords,
            "libraries": all_keywords
        }
        KEYWORDS_INDEX.write_text(json.dumps(keywords_index, indent=2))
        results["keywords_index"] = {
            "success": True,
            "path": str(KEYWORDS_INDEX),
            "total_libraries": len(all_keywords),
            "total_keywords": total_keywords
        }
    
    results["success"] = results.get("user_guide", {}).get("success", False)
    
    return results


@mcp.tool()
def search_rf_documentation(query: str, max_results: int = 10) -> Dict:
    """
    Search Robot Framework 7.4.1 documentation.
    
    Parameters:
      - query: Search term or phrase
      - max_results: Maximum number of results to return (default: 10)
    
    Returns:
      - results: List of matching sections with relevance scores
      - total_matches: Total number of matches found
    """
    if not INDEX_FILE.exists():
        return {
            "error": "Documentation index not found. Call fetch_rf_documentation first.",
            "hint": "Run fetch_rf_documentation() to download and index docs"
        }
    
    try:
        index_data = json.loads(INDEX_FILE.read_text())
        sections = index_data.get("sections", [])
        
        query_lower = query.lower()
        results = []
        
        for section in sections:
            title = section.get("title", "").lower()
            content = section.get("content", "").lower()
            
            # Simple relevance scoring
            title_matches = title.count(query_lower)
            content_matches = content.count(query_lower)
            
            if title_matches > 0 or content_matches > 0:
                relevance = (title_matches * 10) + content_matches
                
                results.append({
                    "title": section.get("title", ""),
                    "id": section.get("id", ""),
                    "level": section.get("level", 0),
                    "relevance": relevance,
                    "content_preview": section.get("content", "")[:300] + "...",
                    "url": f"{RF_DOCS_URL}#{section.get('id', '')}"
                })
        
        # Sort by relevance
        results.sort(key=lambda x: x["relevance"], reverse=True)
        
        return {
            "version": RF_VERSION,
            "query": query,
            "total_matches": len(results),
            "results": results[:max_results]
        }
    except Exception as e:
        return {"error": f"Search failed: {str(e)}"}


@mcp.tool()
def get_library_keywords(library_name: str = "BuiltIn", filter_pattern: Optional[str] = None) -> Dict:
    """
    Get list of keywords from a specific Robot Framework 7.4.1 library.
    
    Parameters:
      - library_name: Library name (BuiltIn, Collections, String, etc.) (default: BuiltIn)
      - filter_pattern: Optional regex pattern to filter keyword names
    
    Returns:
      - version: RF version (7.4.1)
      - library: Library name
      - total_keywords: Total number of keywords
      - keywords: List of keyword names and brief descriptions
    """
    if library_name not in STANDARD_LIBRARIES:
        return {
            "error": f"Unknown library: {library_name}",
            "available_libraries": STANDARD_LIBRARIES
        }
    
    # Ensure we have the data
    library_file = CACHE_DIR / f"{library_name}_{RF_VERSION}.html"
    if not library_file.exists():
        fetch_result = fetch_rf_documentation()
        if not fetch_result.get("success"):
            return {"error": f"Failed to fetch {library_name} documentation"}
    
    keywords_result = _parse_library_keywords(library_name)
    
    if not keywords_result.get("success"):
        return keywords_result
    
    keywords = keywords_result["keywords"]
    
    # Apply filter if provided
    if filter_pattern:
        try:
            pattern = re.compile(filter_pattern, re.IGNORECASE)
            keywords = {k: v for k, v in keywords.items() if pattern.search(k)}
        except re.error as e:
            return {"error": f"Invalid regex pattern: {str(e)}"}
    
    # Format for output
    keyword_list = [
        {
            "name": k,
            "library": library_name,
            "args": v["args"],
            "description": v["doc"][:200]
        }
        for k, v in sorted(keywords.items())
    ]
    
    return {
        "version": RF_VERSION,
        "library": library_name,
        "total_keywords": len(keyword_list),
        "keywords": keyword_list
    }


@mcp.tool()
def get_all_keywords(filter_pattern: Optional[str] = None) -> Dict:
    """
    Get list of all keywords from all Robot Framework 7.4.1 standard libraries.
    
    Parameters:
      - filter_pattern: Optional regex pattern to filter keyword names
    
    Returns:
      - version: RF version (7.4.1)
      - total_keywords: Total number of keywords across all libraries
      - libraries: Dictionary of libraries with their keywords
    """
    if not KEYWORDS_INDEX.exists():
        fetch_result = fetch_rf_documentation()
        if not fetch_result.get("success"):
            return {"error": "Failed to fetch documentation"}
    
    try:
        index_data = json.loads(KEYWORDS_INDEX.read_text())
        all_libraries = index_data.get("libraries", {})
        
        # Apply filter if provided
        if filter_pattern:
            try:
                pattern = re.compile(filter_pattern, re.IGNORECASE)
                filtered_libraries = {}
                for lib_name, keywords in all_libraries.items():
                    filtered_kw = {k: v for k, v in keywords.items() if pattern.search(k)}
                    if filtered_kw:
                        filtered_libraries[lib_name] = filtered_kw
                all_libraries = filtered_libraries
            except re.error as e:
                return {"error": f"Invalid regex pattern: {str(e)}"}
        
        # Format for output
        result_libraries = {}
        total_keywords = 0
        
        for lib_name, keywords in all_libraries.items():
            keyword_list = [
                {
                    "name": k,
                    "library": lib_name,
                    "args": v["args"],
                    "description": v["doc"][:200]
                }
                for k, v in sorted(keywords.items())
            ]
            result_libraries[lib_name] = keyword_list
            total_keywords += len(keyword_list)
        
        return {
            "version": RF_VERSION,
            "total_keywords": total_keywords,
            "total_libraries": len(result_libraries),
            "libraries": result_libraries
        }
    except Exception as e:
        return {"error": f"Failed to read keywords index: {str(e)}"}


@mcp.tool()
def get_builtin_keywords(filter_pattern: Optional[str] = None) -> Dict:
    """
    Get list of all BuiltIn keywords in Robot Framework 7.4.1.
    (Shortcut for get_library_keywords with library_name="BuiltIn")
    
    Parameters:
      - filter_pattern: Optional regex pattern to filter keyword names
    
    Returns:
      - version: RF version (7.4.1)
      - total_keywords: Total number of keywords
      - keywords: List of keyword names and brief descriptions
    """
    return get_library_keywords("BuiltIn", filter_pattern)


@mcp.tool()
def get_keyword_documentation(keyword_name: str, library_name: Optional[str] = None) -> Dict:
    """
    Get detailed documentation for a specific keyword.
    
    Parameters:
      - keyword_name: Name of the keyword (case-insensitive)
      - library_name: Optional library name (if None, searches all libraries)
    
    Returns:
      - keyword: Keyword name
      - library: Library containing the keyword
      - available: Whether keyword exists in RF 7.4.1
      - documentation: Full keyword documentation
      - arguments: Keyword arguments
    """
    if not KEYWORDS_INDEX.exists():
        fetch_result = fetch_rf_documentation()
        if not fetch_result.get("success"):
            return {"error": "Failed to fetch documentation"}
    
    try:
        index_data = json.loads(KEYWORDS_INDEX.read_text())
        all_libraries = index_data.get("libraries", {})
        
        # Filter libraries if specified
        if library_name:
            if library_name not in all_libraries:
                return {
                    "error": f"Library '{library_name}' not found",
                    "available_libraries": list(all_libraries.keys())
                }
            libraries_to_search = {library_name: all_libraries[library_name]}
        else:
            libraries_to_search = all_libraries
        
        # Case-insensitive search
        keyword_name_lower = keyword_name.lower().replace("_", " ").replace("-", " ")
        
        for lib_name, keywords in libraries_to_search.items():
            for k, v in keywords.items():
                if k.lower().replace("_", " ").replace("-", " ") == keyword_name_lower:
                    lib_url = f"{RF_BASE_LIB_URL}/{lib_name}.html"
                    return {
                        "version": RF_VERSION,
                        "keyword": k,
                        "library": lib_name,
                        "available": True,
                        "arguments": v["args"],
                        "documentation": v["doc"],
                        "url": f"{lib_url}#{v['id']}"
                    }
        
        return {
            "version": RF_VERSION,
            "keyword": keyword_name,
            "available": False,
            "message": f"Keyword '{keyword_name}' not found in any standard library for RF {RF_VERSION}",
            "hint": "Use get_all_keywords() to see all available keywords"
        }
    except Exception as e:
        return {"error": f"Failed to search keyword: {str(e)}"}


@mcp.tool()
def check_keyword_availability(keyword_name: str) -> Dict:
    """
    Quick check if a keyword exists in Robot Framework 7.4.1 (searches all standard libraries).
    
    Parameters:
      - keyword_name: Name of the keyword to check
    
    Returns:
      - available: Boolean indicating if keyword exists
      - version: RF version checked (7.4.1)
      - library: Library containing the keyword (if found)
      - keyword: The keyword name as found in docs (if available)
    """
    result = get_keyword_documentation(keyword_name)
    
    return {
        "version": RF_VERSION,
        "keyword_searched": keyword_name,
        "available": result.get("available", False),
        "library": result.get("library") if result.get("available") else None,
        "keyword_actual_name": result.get("keyword") if result.get("available") else None,
        "message": result.get("message", f"Keyword '{result.get('keyword')}' is available in {result.get('library')} library")
    }


@mcp.tool()
def get_documentation_url(topic: Optional[str] = None) -> Dict:
    """
    Get direct URLs to Robot Framework 7.4.1 documentation.
    
    Parameters:
      - topic: Optional topic (user_guide, builtin, releases)
    
    Returns:
      - version: RF version
      - urls: Dictionary of documentation URLs
    """
    urls = {
        "user_guide": RF_DOCS_URL,
        "builtin_library": f"{RF_BASE_LIB_URL}/BuiltIn.html",
        "release_notes": f"https://github.com/robotframework/robotframework/blob/master/doc/releasenotes/rf-{RF_VERSION}.rst",
        "all_libraries": f"https://robotframework.org/robotframework/{RF_VERSION}/libraries/",
        "standard_libraries": {
            "BuiltIn": f"{RF_BASE_LIB_URL}/BuiltIn.html",
            "Collections": f"{RF_BASE_LIB_URL}/Collections.html",
            "DateTime": f"{RF_BASE_LIB_URL}/DateTime.html",
            "OperatingSystem": f"{RF_BASE_LIB_URL}/OperatingSystem.html",
            "Process": f"{RF_BASE_LIB_URL}/Process.html",
            "Screenshot": f"{RF_BASE_LIB_URL}/Screenshot.html",
            "String": f"{RF_BASE_LIB_URL}/String.html",
            "Telnet": f"{RF_BASE_LIB_URL}/Telnet.html",
            "XML": f"{RF_BASE_LIB_URL}/XML.html"
        }
    }
    
    return {
        "version": RF_VERSION,
        "urls": urls if not topic else {topic: urls.get(topic, "Topic not found")}
    }


@mcp.tool()
def run_rebot(
    output_files: List[str],
    output_dir: Optional[str] = None,
    name: Optional[str] = None,
    merge: bool = False,
    options: Optional[str] = None
) -> Dict:
    """
    Run Rebot tool from RF 7.4.1 to reprocess Robot Framework output files.
    Rebot can merge multiple outputs, generate new reports, or filter results.
    
    Parameters:
      - output_files: List of output.xml file paths to process
      - output_dir: Directory for output files (default: current directory)
      - name: Custom name for the test suite/report
      - merge: If True, merges multiple output files (default: False)
      - options: Additional rebot options as string (e.g., "--include smoke --exclude wip")
    
    Returns:
      - success: Boolean indicating if command succeeded
      - command: The rebot command that was executed
      - stdout: Standard output from rebot
      - stderr: Standard error from rebot
      - output_files: List of generated files
    
    Examples:
      - Merge outputs: run_rebot(["output1.xml", "output2.xml"], merge=True)
      - Filter by tags: run_rebot(["output.xml"], options="--include smoke")
      - Custom name: run_rebot(["output.xml"], name="Regression Tests")
    """
    try:
        if not output_files:
            return {"success": False, "error": "No output files specified"}
        
        # Build rebot command
        cmd = ["rebot"]
        
        if output_dir:
            cmd.extend(["--outputdir", output_dir])
        
        if name:
            cmd.extend(["--name", name])
        
        if merge:
            cmd.append("--merge")
        
        # Add custom options
        if options:
            cmd.extend(options.split())
        
        # Add output files
        cmd.extend(output_files)
        
        # Execute rebot
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300
        )
        
        # Collect generated files
        generated_files = []
        out_dir = Path(output_dir) if output_dir else Path.cwd()
        for fname in ["output.xml", "log.html", "report.html"]:
            fpath = out_dir / fname
            if fpath.exists():
                generated_files.append(str(fpath))
        
        return {
            "success": result.returncode == 0,
            "version": RF_VERSION,
            "command": " ".join(cmd),
            "return_code": result.returncode,
            "stdout": result.stdout,
            "stderr": result.stderr if result.stderr else None,
            "output_files": generated_files
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "Rebot command timed out after 300 seconds"
        }
    except FileNotFoundError:
        return {
            "success": False,
            "error": "Rebot command not found. Ensure Robot Framework 7.4.1 is installed."
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Failed to run rebot: {str(e)}"
        }


@mcp.tool()
def run_libdoc(
    library_or_resource: str,
    output_file: str,
    format: str = "html",
    name: Optional[str] = None,
    version: Optional[str] = None,
    options: Optional[str] = None
) -> Dict:
    """
    Run Libdoc tool from RF 7.4.1 to generate keyword documentation.
    Creates documentation for libraries, resources, or test suites.
    
    Parameters:
      - library_or_resource: Path to library/resource file or library name
      - output_file: Output file path for generated documentation
      - format: Output format - html, xml, json, libspec (default: html)
      - name: Custom name for the documented library
      - version: Custom version for the documented library
      - options: Additional libdoc options as string
    
    Returns:
      - success: Boolean indicating if command succeeded
      - command: The libdoc command that was executed
      - output_file: Path to generated documentation file
      - stdout: Standard output from libdoc
      - stderr: Standard error from libdoc
    
    Examples:
      - Document library: run_libdoc("SeleniumLibrary", "selenium_docs.html")
      - Document resource: run_libdoc("keywords.robot", "keywords_docs.html")
      - JSON format: run_libdoc("BuiltIn", "builtin.json", format="json")
    """
    try:
        if not library_or_resource:
            return {"success": False, "error": "No library or resource specified"}
        
        # Build libdoc command
        cmd = ["libdoc"]
        
        if name:
            cmd.extend(["--name", name])
        
        if version:
            cmd.extend(["--version", version])
        
        # Add format
        cmd.extend(["--format", format])
        
        # Add custom options
        if options:
            cmd.extend(options.split())
        
        # Add library/resource and output file
        cmd.extend([library_or_resource, output_file])
        
        # Execute libdoc
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        output_path = Path(output_file)
        
        return {
            "success": result.returncode == 0 and output_path.exists(),
            "version": RF_VERSION,
            "command": " ".join(cmd),
            "return_code": result.returncode,
            "output_file": str(output_path) if output_path.exists() else None,
            "file_size": output_path.stat().st_size if output_path.exists() else 0,
            "stdout": result.stdout,
            "stderr": result.stderr if result.stderr else None
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "Libdoc command timed out after 60 seconds"
        }
    except FileNotFoundError:
        return {
            "success": False,
            "error": "Libdoc command not found. Ensure Robot Framework 7.4.1 is installed."
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Failed to run libdoc: {str(e)}"
        }


@mcp.tool()
def run_testdoc(
    input_file: str,
    output_file: str,
    title: Optional[str] = None,
    name: Optional[str] = None,
    doc: Optional[str] = None,
    options: Optional[str] = None
) -> Dict:
    """
    Run Testdoc tool from RF 7.4.1 to generate test case documentation.
    Creates high-level HTML documentation from Robot Framework test files.
    
    Parameters:
      - input_file: Path to test file, suite directory, or output.xml
      - output_file: Output HTML file path
      - title: Custom title for the documentation
      - name: Override suite name in documentation
      - doc: Override suite documentation
      - options: Additional testdoc options as string
    
    Returns:
      - success: Boolean indicating if command succeeded
      - command: The testdoc command that was executed
      - output_file: Path to generated HTML documentation
      - stdout: Standard output from testdoc
      - stderr: Standard error from testdoc
    
    Examples:
      - Document suite: run_testdoc("tests/", "test_docs.html", title="API Tests")
      - Single file: run_testdoc("login_tests.robot", "login_docs.html")
      - From output: run_testdoc("output.xml", "test_report_docs.html")
    """
    try:
        if not input_file:
            return {"success": False, "error": "No input file specified"}
        
        # Build testdoc command
        cmd = ["testdoc"]
        
        if title:
            cmd.extend(["--title", title])
        
        if name:
            cmd.extend(["--name", name])
        
        if doc:
            cmd.extend(["--doc", doc])
        
        # Add custom options
        if options:
            cmd.extend(options.split())
        
        # Add input and output files
        cmd.extend([input_file, output_file])
        
        # Execute testdoc
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        output_path = Path(output_file)
        
        return {
            "success": result.returncode == 0 and output_path.exists(),
            "version": RF_VERSION,
            "command": " ".join(cmd),
            "return_code": result.returncode,
            "output_file": str(output_path) if output_path.exists() else None,
            "file_size": output_path.stat().st_size if output_path.exists() else 0,
            "stdout": result.stdout,
            "stderr": result.stderr if result.stderr else None
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "Testdoc command timed out after 60 seconds"
        }
    except FileNotFoundError:
        return {
            "success": False,
            "error": "Testdoc command not found. Ensure Robot Framework 7.4.1 is installed."
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Failed to run testdoc: {str(e)}"
        }


@mcp.tool()
def run_tidy(
    input_file: str,
    output_file: Optional[str] = None,
    format: str = "robot",
    inplace: bool = False,
    options: Optional[str] = None
) -> Dict:
    """
    Run Tidy tool from RF 7.4.1 to clean and format Robot Framework files.
    Normalizes formatting, converts between formats, and applies best practices.
    
    Parameters:
      - input_file: Path to Robot Framework file or directory to format
      - output_file: Output file path (if not inplace)
      - format: Output format - robot, txt, tsv, html (default: robot)
      - inplace: If True, modifies file in place (default: False)
      - options: Additional tidy options (e.g., "--indent 4 --spacecount 2")
    
    Returns:
      - success: Boolean indicating if command succeeded
      - command: The tidy command that was executed
      - output_file: Path to formatted file
      - changes_made: Boolean indicating if file was modified
      - stdout: Standard output from tidy
      - stderr: Standard error from tidy
    
    Examples:
      - Format in place: run_tidy("tests.robot", inplace=True)
      - Convert format: run_tidy("tests.robot", "tests.txt", format="txt")
      - Custom spacing: run_tidy("suite.robot", options="--spacecount 4")
    """
    try:
        if not input_file:
            return {"success": False, "error": "No input file specified"}
        
        input_path = Path(input_file)
        if not input_path.exists():
            return {"success": False, "error": f"Input file not found: {input_file}"}
        
        # Build tidy command
        cmd = ["robot.tidy"]
        
        # Add format
        cmd.extend(["--format", format])
        
        # Handle inplace or output file
        if inplace:
            cmd.append("--inplace")
            target_file = input_file
        elif output_file:
            target_file = output_file
        else:
            return {"success": False, "error": "Must specify either output_file or inplace=True"}
        
        # Add custom options
        if options:
            cmd.extend(options.split())
        
        # Add input file
        cmd.append(input_file)
        
        # Add output file if not inplace
        if not inplace and output_file:
            cmd.append(output_file)
        
        # Get original content hash for change detection
        original_hash = None
        if inplace:
            original_hash = hashlib.md5(input_path.read_bytes()).hexdigest()
        
        # Execute tidy
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60
        )
        
        # Check if changes were made
        changes_made = False
        if inplace and original_hash:
            new_hash = hashlib.md5(input_path.read_bytes()).hexdigest()
            changes_made = original_hash != new_hash
        elif output_file:
            changes_made = Path(output_file).exists()
        
        output_path = Path(target_file)
        
        return {
            "success": result.returncode == 0,
            "version": RF_VERSION,
            "command": " ".join(cmd),
            "return_code": result.returncode,
            "output_file": str(output_path) if output_path.exists() else None,
            "file_size": output_path.stat().st_size if output_path.exists() else 0,
            "changes_made": changes_made,
            "inplace": inplace,
            "stdout": result.stdout,
            "stderr": result.stderr if result.stderr else None
        }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "Tidy command timed out after 60 seconds"
        }
    except FileNotFoundError:
        return {
            "success": False,
            "error": "Tidy command not found. Ensure Robot Framework 7.4.1 is installed."
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Failed to run tidy: {str(e)}"
        }


@mcp.tool()
def list_installed_library_docs() -> Dict:
    """
    List all available library documentation files generated in the container.
    
    Returns:
      - success: Boolean indicating if docs directory exists
      - docs_directory: Path to documentation directory
      - available_libraries: List of libraries with available documentation
      - files: Detailed list of all documentation files with metadata
    """
    try:
        if not LIBRARY_DOCS_DIR.exists():
            return {
                "success": False,
                "error": f"Documentation directory not found: {LIBRARY_DOCS_DIR}",
                "hint": "Run: docker exec robotframework-mcp /app/generate_library_docs.sh"
            }
        
        # Scan directory for documentation files
        doc_files = list(LIBRARY_DOCS_DIR.glob("*.*"))
        
        if not doc_files:
            return {
                "success": False,
                "docs_directory": str(LIBRARY_DOCS_DIR),
                "error": "No documentation files found",
                "hint": "Run: docker exec robotframework-mcp /app/generate_library_docs.sh"
            }
        
        # Organize by library
        libraries = {}
        all_files = []
        
        for doc_file in doc_files:
            file_stat = doc_file.stat()
            file_info = {
                "name": doc_file.name,
                "path": str(doc_file),
                "size_bytes": file_stat.st_size,
                "size_human": f"{file_stat.st_size / 1024:.1f} KB" if file_stat.st_size < 1024*1024 else f"{file_stat.st_size / (1024*1024):.1f} MB",
                "modified": datetime.fromtimestamp(file_stat.st_mtime).isoformat(),
                "format": doc_file.suffix.lstrip('.')
            }
            all_files.append(file_info)
            
            # Extract library name
            lib_name = doc_file.stem.split('_')[0]  # Handle Browser, RequestsLibrary, Robocop_help, etc.
            
            if lib_name not in libraries:
                libraries[lib_name] = {
                    "library": lib_name,
                    "formats": []
                }
            
            libraries[lib_name]["formats"].append({
                "format": file_info["format"],
                "file": doc_file.name,
                "size": file_info["size_human"]
            })
        
        return {
            "success": True,
            "docs_directory": str(LIBRARY_DOCS_DIR),
            "total_files": len(all_files),
            "available_libraries": list(libraries.keys()),
            "libraries": list(libraries.values()),
            "files": all_files
        }
    except Exception as e:
        return {
            "success": False,
            "error": f"Failed to list library docs: {str(e)}"
        }


@mcp.tool()
def get_installed_library_docs(
    library_name: str,
    format: str = "json"
) -> Dict:
    """
    Get documentation content for a specific installed RF library.
    
    Parameters:
      - library_name: Name of the library (Browser, RequestsLibrary, Robocop)
      - format: Documentation format to retrieve - json, html, xml, txt (default: json)
    
    Returns:
      - success: Boolean indicating if documentation was found
      - library: Library name
      - format: Documentation format
      - content: Documentation content (JSON parsed if format=json, raw text otherwise)
      - file_path: Full path to documentation file
      - metadata: File size and modification time
    
    Examples:
      - Get Browser keywords: get_installed_library_docs("Browser", "json")
      - Get HTML docs: get_installed_library_docs("RequestsLibrary", "html")
      - Get Robocop help: get_installed_library_docs("Robocop", "txt")
    """
    try:
        if not LIBRARY_DOCS_DIR.exists():
            return {
                "success": False,
                "error": f"Documentation directory not found: {LIBRARY_DOCS_DIR}",
                "hint": "Run: docker exec robotframework-mcp /app/generate_library_docs.sh"
            }
        
        # Handle different file naming patterns
        if library_name.lower() == "robocop" and format == "txt":
            # Robocop has special txt files
            possible_files = [
                LIBRARY_DOCS_DIR / "Robocop_help.txt",
                LIBRARY_DOCS_DIR / "Robocop_rules.txt"
            ]
            doc_file = None
            for f in possible_files:
                if f.exists():
                    doc_file = f
                    break
        else:
            # Standard library documentation
            doc_file = LIBRARY_DOCS_DIR / f"{library_name}.{format}"
        
        if not doc_file or not doc_file.exists():
            # Try to find any file matching the library name
            matches = list(LIBRARY_DOCS_DIR.glob(f"{library_name}*"))
            available = [f.name for f in matches] if matches else []
            
            return {
                "success": False,
                "library": library_name,
                "format": format,
                "error": f"Documentation file not found: {library_name}.{format}",
                "available_formats": available,
                "hint": f"Available files: {', '.join(available) if available else 'none'}"
            }
        
        # Read the documentation file
        file_stat = doc_file.stat()
        
        if format == "json":
            # Parse JSON content
            content = json.loads(doc_file.read_text(encoding='utf-8'))
            
            # Extract summary information
            keywords_count = len(content.get("keywords", []))
            library_version = content.get("version", "unknown")
            library_scope = content.get("scope", "unknown")
            library_doc = content.get("doc", "")
            
            return {
                "success": True,
                "library": library_name,
                "format": format,
                "file_path": str(doc_file),
                "metadata": {
                    "version": library_version,
                    "scope": library_scope,
                    "keywords_count": keywords_count,
                    "file_size": file_stat.st_size,
                    "modified": datetime.fromtimestamp(file_stat.st_mtime).isoformat()
                },
                "documentation": library_doc[:500] + "..." if len(library_doc) > 500 else library_doc,
                "keywords": content.get("keywords", [])[:10],  # First 10 keywords as sample
                "full_content_available": True,
                "hint": "Full JSON content available, showing first 10 keywords. Parse the file for complete data."
            }
        else:
            # Return raw content for other formats
            content = doc_file.read_text(encoding='utf-8')
            
            # Truncate if too large
            truncated = len(content) > 5000
            display_content = content[:5000] + "\n\n... (truncated)" if truncated else content
            
            return {
                "success": True,
                "library": library_name,
                "format": format,
                "file_path": str(doc_file),
                "metadata": {
                    "file_size": file_stat.st_size,
                    "modified": datetime.fromtimestamp(file_stat.st_mtime).isoformat(),
                    "truncated": truncated
                },
                "content": display_content
            }
    except json.JSONDecodeError as e:
        return {
            "success": False,
            "library": library_name,
            "format": format,
            "error": f"Failed to parse JSON: {str(e)}"
        }
    except Exception as e:
        return {
            "success": False,
            "library": library_name,
            "format": format,
            "error": f"Failed to read library docs: {str(e)}"
        }


if __name__ == "__main__":
    mcp.run()
