# Product Overview

## Purpose
Books Database Service is a stable baseline application designed specifically for QA test generation evaluation using AI tools. This repository serves as a controlled environment where different AI agents generate Robot Framework test suites against a fixed application, enabling comparison of AI-powered test generation capabilities.

## Key Features
- **Stable Application Under Test**: FastAPI-based books management service with CRUD operations
- **Web UI**: Interactive interface for managing books at http://localhost:8000
- **REST API**: OpenAPI-documented endpoints at http://localhost:8000/docs
- **SQLite Database**: Persistent storage with sample data seeding
- **MCP-Powered Testing**: Two specialized Model Context Protocol servers for Robot Framework
  - Robot Framework MCP: Executes Robot tests on demand via MCP
  - RF Docs MCP: Provides Robot Framework keyword/library documentation queries via MCP
- **Containerized Environment**: Docker Compose orchestration for consistent setup
- **One-Step Startup**: `quick-start.sh` script initializes entire environment

## Target Users and Use Cases
- **QA Engineers**: Evaluating AI-assisted test generation tools
- **AI Tool Developers**: Benchmarking test generation capabilities across different AI models
- **Research Teams**: Comparing effectiveness of various AI assistants (Claude Code, Copilot, etc.) in generating Robot Framework tests

## Core Workflow
1. Clone repository and create branch following `<round>/<tool>/<model>` naming convention
2. Run `quick-start.sh` to start all services
3. Use AI tools to generate Robot Framework tests in `robot_tests/` directory
4. Execute tests via Robot Framework MCP server
5. Review results in `robot_results/` directory
6. Application code remains unchanged; focus is entirely on test generation quality

## Value Proposition
Provides a reproducible, controlled environment for objectively evaluating AI-powered test generation tools by keeping the application constant while allowing test suites to evolve across different AI agents and models.
