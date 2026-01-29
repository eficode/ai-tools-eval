# Testing

… [Getting Started](getting-started.md) … [Development Workflow](development-workflow.md) … [Architecture](architecture.md) … [Troubleshooting](troubleshooting.md) …

## Robot Framework via MCP

- Add your `.robot` suites to `robot_tests/`
- Use your IDE’s MCP integration (configured by `./quick-start.sh`) to:
  - List tests
  - Run a suite
  - Run a single test
  - Run Robocop audits

Results are saved under `robot_results/` (mapped from container `/results`).

## Python Unit Tests

Run unit tests inside the running app container:

```bash
docker exec -it books-database-service pytest -q
```

Run a specific test:

```bash
docker exec -it books-database-service pytest tests/test_books.py::test_create_book -q -vv
```

## API Docs

OpenAPI docs are available at http://localhost:8000/docs once the service is up.

… [Troubleshooting](troubleshooting.md) … [Architecture](architecture.md) …

Next: [Troubleshooting](troubleshooting.md)
