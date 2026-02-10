# Development Workflow

… [Getting Started](getting-started.md) … [Architecture](architecture.md) … [Testing](testing.md) … [Troubleshooting](troubleshooting.md) …

## Scope Constraints

- Do not change application code under `fastapi_demo/`.
- Focus on generating Robot Framework tests (`robot_tests/`) and related documentation under `docs/`.
- Use MCP tools to run and validate tests; store results in `robot_results/`.

## Branching

Create a topic branch from `main` and include your AI tooling details at the end.

 Pattern: `r<Round>_<Tool>_<Model>`

Examples:

```bash
git checkout -b r1_Copilot_Sonnet-4.5
git checkout -b r2_AmazonQ_Sonnet-4.5
```

## Commits

- Keep messages concise: `Add Robot Framework test cases`

## Pull Requests

- Keep PRs focused and small
- Reference related issues (if any)
- Include a brief summary

## Code & Tests

- App code lives under `fastapi_demo/` (unchanged)
- Robot tests go under `robot_tests/` (executed via MCP)
- Unit tests live under `tests/` (optional; do not alter app behavior)

Next: [Architecture](architecture.md)

… [Getting Started](getting-started.md) … [Testing](testing.md) …
