#!/usr/bin/env python3
"""
MCP server to run Robot Framework tests (Browser/Chromium + Requests) - TEST VERSION
Tools:
  - run_suite(suite_path="/tests", include_tags=None, exclude_tags=None, variables=None)
  - run_test_by_name(test_name, suite_path="/tests", variables=None)
  - list_tests(suite_path="/tests")  - Mount your repo tests at /tests (read-only) and results at /results.
  - run_robocop_audit(target_path="/tests") - Code quality audit with Robocop
"""
import os
import shlex
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, List

from mcp.server.fastmcp import FastMCP  # official python-sdk FastMCP

APP_NAME = "rf-mcp-test"
DEFAULT_TESTS = os.getenv("RF_TESTS_DIR", "/tests")
DEFAULT_RESULTS = os.getenv("ROBOT_OUTPUT_DIR", "/results")

mcp = FastMCP(APP_NAME)


def _robot_cmd(
    suite_path: str,
    test_name: Optional[str] = None,
    include_tags: Optional[str] = None,
    exclude_tags: Optional[str] = None,
    variables: Optional[Dict[str, str]] = None,
) -> List[str]:
    Path(DEFAULT_RESULTS).mkdir(parents=True, exist_ok=True)
    cmd = ["robot", "--outputdir", DEFAULT_RESULTS]
    merged_vars = {"BROWSER": "chromium", "HEADLESS": "true", **(variables or {})}
    for k, v in merged_vars.items():
        cmd += ["-v", f"{k}:{v}"]
    if include_tags:
        cmd += ["-i", include_tags]
    if exclude_tags:
        cmd += ["-e", exclude_tags]
    if test_name:
        cmd += ["-t", test_name]
    cmd += [suite_path]
    return cmd


def _run(cmd: List[str]) -> Dict:
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return {
        "returncode": p.returncode,
        "command": " ".join(shlex.quote(c) for c in cmd),
        "stdout": p.stdout[-10000:],  # tail to keep responses small
        "stderr": p.stderr[-10000:],
        "artifacts": {
            "output_xml": str(Path(DEFAULT_RESULTS) / "output.xml"),
            "log_html": str(Path(DEFAULT_RESULTS) / "log.html"),
            "report_html": str(Path(DEFAULT_RESULTS) / "report.html"),
        },
    }


@mcp.tool()
def run_suite(
    suite_path: str = DEFAULT_TESTS,
    include_tags: Optional[str] = None,
    exclude_tags: Optional[str] = None,
    variables: Optional[Dict[str, str]] = None,
) -> Dict:
    """Run an entire Robot Framework suite/folder."""
    return _run(
        _robot_cmd(
            suite_path=suite_path,
            include_tags=include_tags,
            exclude_tags=exclude_tags,
            variables=variables,
        )
    )


@mcp.tool()
def run_test_by_name(
    test_name: str,
    suite_path: str = DEFAULT_TESTS,
    variables: Optional[Dict[str, str]] = None,
) -> Dict:
    """Run a single test by name (or pattern)."""
    return _run(
        _robot_cmd(
            suite_path=suite_path,
            test_name=test_name,
            variables=variables,
        )
    )


@mcp.tool()
def list_tests(suite_path: str = DEFAULT_TESTS) -> Dict:
    """List test case long names under suite_path."""
    try:
        from robot.api import TestSuiteBuilder
        suite = TestSuiteBuilder().build(suite_path)
        names: List[str] = []
        def walk(s):
            for t in s.tests:
                names.append(t.longname)
            for child in s.suites:
                walk(child)
        walk(suite)
        return {"count": len(names), "tests": names}
    except Exception as e:
        return {"error": str(e), "hint": "Check suite_path and Robot syntax."}

@mcp.tool()
def run_robocop_audit(target_path: str = DEFAULT_TESTS, report_format: str = "text") -> Dict:
    """
    Scan Robot Framework files for code quality issues using Robocop.
    Automatically generates timestamped reports in specified format.
    
    Parameters:
      - target_path: Path to scan (default: /tests). Scans recursively for .robot files.
      - report_format: Report format - "text" (default), "json", or "all"
    
    Returns:
      - returncode: 0 = no issues, >0 = issues found
      - stdout: Robocop output with findings
      - stderr: Any error messages
      - artifacts: Paths to timestamped robocop report file(s)
    """
    
    # Security: Ensure we are scanning inside the default tests directory
    # If target_path is absolute and starts with DEFAULT_TESTS, use it directly
    # Otherwise, treat it as relative to DEFAULT_TESTS
    if target_path.startswith(DEFAULT_TESTS):
        safe_path = os.path.abspath(target_path)
    else:
        safe_path = os.path.abspath(os.path.join(DEFAULT_TESTS, target_path.lstrip("./")))
    
    # Verify path is within DEFAULT_TESTS
    if not safe_path.startswith(os.path.abspath(DEFAULT_TESTS)):
        return {
            "returncode": 1,
            "error": f"Invalid path: {target_path}",
            "hint": f"Path must be within {DEFAULT_TESTS}"
        }

    # Create results directory
    Path(DEFAULT_RESULTS).mkdir(parents=True, exist_ok=True)
    
    # Generate timestamp for report filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    artifacts = {}
    output_text = []
    combined_returncode = 0
    
    try:
        # Determine report types to generate
        generate_text = report_format in ["text", "all"]
        generate_json = report_format in ["json", "all"]
        
        # Generate text report (default and most readable)
        if generate_text:
            text_report = Path(DEFAULT_RESULTS) / f"robocop_report_{timestamp}.txt"
            command_text = [
                "robocop",
                "check",
                "--reports", "all",
                safe_path
            ]
            result_text = subprocess.run(
                command_text,
                capture_output=True,
                text=True,
                check=False
            )
            # Save full output to timestamped text file
            text_report.write_text(result_text.stdout + result_text.stderr)
            artifacts["robocop_text_report"] = str(text_report)
            output_text.append(result_text.stdout[-2000:])  # Last 2000 chars for summary
            combined_returncode = result_text.returncode
        
        # Generate JSON report for programmatic analysis
        if generate_json:
            json_report = Path(DEFAULT_RESULTS) / f"robocop_report_{timestamp}.json"
            command_json = [
                "robocop",
                "check",
                "--reports", "json_report",
                safe_path
            ]
            result_json = subprocess.run(
                command_json,
                capture_output=True,
                text=True,
                check=False,
                cwd=str(DEFAULT_RESULTS)
            )
            # Rename default output to timestamped file
            default_json = Path(DEFAULT_RESULTS) / "robocop.json"
            if default_json.exists():
                default_json.rename(json_report)
                artifacts["robocop_json_report"] = str(json_report)
            
            if not generate_text:  # Use JSON result if text wasn't generated
                output_text.append(result_json.stdout[-2000:])
                combined_returncode = result_json.returncode
        
        artifacts["local_path"] = "robot_results/"
        artifacts["timestamp"] = timestamp
        
        # Robocop exit codes:
        # 0 = No issues found
        # 1 = Issues found
        return {
            "returncode": combined_returncode,
            "stdout": "\n".join(output_text),
            "stderr": "",
            "artifacts": artifacts,
            "message": f"Robocop audit completed. Report(s) saved with timestamp: {timestamp}"
        }

    except Exception as e:
        return {
            "returncode": 1,
            "error": str(e),
            "hint": "Check if Robocop is installed and target_path is valid"
        }

if __name__ == "__main__":
    # STDIO is the default transport for FastMCP; just run()
    mcp.run()