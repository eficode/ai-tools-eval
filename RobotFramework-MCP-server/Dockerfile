FROM mcr.microsoft.com/playwright/python:v1.48.0-jammy

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    TZ=Europe/Helsinki

WORKDIR /app

# Node.js is required by robotframework-browser (Playwright via Node)
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs=20.19.6-1nodesource1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Robot Framework + Browser + Requests + MCP SDK
RUN pip install --no-cache-dir \
    robotframework==7.4.1 \
    robotframework-browser==19.12.3 \
    robotframework-requests==0.9.7 \
    robotframework-robocop==7.2.0 \
    "mcp[cli]" \
    && rfbrowser init

COPY server.py /app/server.py
COPY generate_library_docs.sh /app/generate_library_docs.sh

# Make the scripts executable
RUN chmod +x /app/generate_library_docs.sh

# Safer browser execution
RUN useradd -m -u 10001 appuser && chown -R appuser:appuser /app

# Create results and docs directories with proper permissions
RUN mkdir -p /results /app/docs && chown -R appuser:appuser /results /app/docs

ENV ROBOT_OUTPUT_DIR=/results
ENV RF_TESTS_DIR=/tests

# Playwright configuration for Docker containers
# PLAYWRIGHT_BROWSERS_PATH: Location of installed Playwright browsers
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

# Switch to appuser AFTER all root operations are done
USER appuser

ENTRYPOINT ["python", "-u", "/app/server.py"]