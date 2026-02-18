#!/bin/bash
# Script to run Robocop audit on Robot Framework tests with timestamped reports
# Usage: ./run_robocop_audit.sh
#
# Generates datestamped file:
#   - robocop_YYYYMMDD.txt  (console output)


set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Define RESULTS_DIR relative to the script location
RESULTS_DIR="${SCRIPT_DIR}/robot_results"

# Generate datestamp for all report filenames
DATESTAMP=$(date +"%Y%m%d")
OUTPUT_TXT="robocop_${DATESTAMP}.txt"

# Container paths (mounted to local robot_results/)
CONTAINER_OUTPUT_TXT="/results/${OUTPUT_TXT}"

# Local paths for report generation
LOCAL_OUTPUT_TXT="${RESULTS_DIR}/${OUTPUT_TXT}"

# Ensure results directory exists
mkdir -p "${RESULTS_DIR}"

# Check if robotframework-mcp container is running
if ! docker ps --format '{{.Names}}' | grep -q "^robotframework-mcp$"; then
    echo "Error: robotframework-mcp container is not running"
    echo "Please start the container first with: docker-compose up -d"
    exit 1
fi

echo "=================================================="
echo "  Robot Framework Robocop Audit"
echo "  Datestamp: ${DATESTAMP}"
echo "=================================================="
echo ""

# Run robocop audit writing directly to mounted /results volume
echo "Running Robocop audit on robot_tests/..."
echo "Output will be written directly to: robot_results/${OUTPUT_TXT}"
echo ""

# Execute robocop with output redirected directly to mounted volume
# Note: Robocop exits with code 1 when issues are found, so we use || true to continue
docker exec robotframework-mcp bash -c "robocop check --persistent /tests/ > ${CONTAINER_OUTPUT_TXT} 2>&1" || true

# Copy cache directory to mounted volume for persistent storage
docker exec robotframework-mcp bash -c "cp -r /app/.robocop_cache /results/ 2>/dev/null || true" || true

echo ""
echo "✓ Audit output written directly to local filesystem via Docker volume mount"

# Extract summary statistics from output
ISSUE_COUNT=$(grep "Found.*issues" "${LOCAL_OUTPUT_TXT}" | head -1 || echo "Unknown")
FILES_PROCESSED=$(grep "Processed.*files" "${LOCAL_OUTPUT_TXT}" | head -1 || echo "Unknown")

echo ""
echo "=================================================="
echo "  Audit Complete!"
echo "=================================================="
echo ""
echo "Generated files (written directly via Docker volume mount):"
echo "  📄 ${LOCAL_OUTPUT_TXT}"
echo ""
echo "Audit Summary:"
echo "  ${ISSUE_COUNT}"
echo "  ${FILES_PROCESSED}"
echo ""

exit 0
