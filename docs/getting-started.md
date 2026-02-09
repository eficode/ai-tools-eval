# Getting Started

… [Development Workflow](development-workflow.md) … [Architecture](architecture.md) … [Testing](testing.md) … [Troubleshooting](troubleshooting.md) …

## Prerequisites

- Docker Desktop (includes Docker Compose)
- Git
- Repository cloned locally (see main [README](../README.md) for clone instructions)

## Start Environment (one command)

```bash
./quick-start.sh
```

What starts and why:
- Books API and UI (`books-service`) at http://localhost:8000 — baseline app under test (do not modify)
- Database initialization (`initialization`) for tables, migrations, and sample data
- Robot Framework MCP (`robotframework-mcp`) for test execution via MCP
- RF Docs MCP (`rf-docs-mcp`) for keyword/library docs via MCP

## Verify

```bash
docker ps
curl http://localhost:8000/books/
```

Open:
- Web UI: http://localhost:8000
- API docs: http://localhost:8000/docs

## Generate Tool-Specific and Robot Framework Information Files

The files in the `template/` folder are **templates**, not tests or config files you run directly. You use them as input/prompts for your AI tool to generate a tool-specific Robot Framework instructions file. Based on that generated instructions file, your AI tool can then create Robot Framework test cases when you prompt it.

The `template/` folder contains two key reference files:

- **Instruction Template.txt**: Example Robot Framework test structure with placeholders for Settings, Variables, Test Cases, Keywords, and Comments sections
- **Test Standards.txt**: Example AI generation rules including Page Object pattern, explicit wait strategies, behavioral naming, and library version constraints

Steps to generate tests:

1. Generate a **project-specific instructions file** using your AI tool's built-in function (for example, Copilot's "Generate Chat Instructions" which creates a copilot-instructions.md file, or Claude Code's `/init`). This file describes the project, coding style, and how you want the AI to behave.
2. Prompt your AI assistant to create a **Robot Framework–specific information file** for this project, using the files in the template/ folder (Instruction Template.txt and Test Standards.txt) as examples and guidance. This RF information file should capture the RF structure, libraries, and standards you want the AI to follow.
3. When you want tests, ask your AI assistant to generate Robot Framework test cases/suites for this project. The AI should use the RF-specific information file as its primary rule set, and may also use any other documentation or project files your tool makes available. Review the generated tests and ensure they comply with the standards defined in Test Standards.txt (RF 7.4.1, Browser Library 19.12.3, RequestsLibrary 0.9.7).

## Generate and Run Tests

Place Robot Framework suites under `robot_tests/`. Use your IDE’s MCP integration (configured by `./quick-start.sh`) to list and run tests, or run manually via Docker exec.

After you have generated and executed tests, use your AI assistant to run a **Robocop** audit over the Robot Framework suites (for example, by prompting it to run the project's Robocop command inside the RF container). This lets the AI surface style and best-practice violations for you to review and fix, keeping the suites aligned with the standards defined for this project.

Next: [Development Workflow](development-workflow.md)

## Stop Services

```bash
docker-compose down
```

… [Development Workflow](development-workflow.md) … [Architecture](architecture.md) …
