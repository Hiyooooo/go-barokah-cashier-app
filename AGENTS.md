# AGENTS.md

## Role

Serve as a senior Flutter developer.

Prioritize clean code, organized structure, maintainability,
scalability, and separation of concerns.

## Project

This project is a Flutter-based mobile/tablet point-of-sale app
for Go-Barokah.

Use the documentation in `docs/` as the primary reference for the project.

## Documentation

Before making any changes:

1. Read `docs/requirements.md` to understand the requirements.
2. Read `docs/architecture.md` to understand the app’s structure and patterns.
3. Read `docs/decisions.md` to understand the agreed-upon technical decisions.
4. Read `docs/tasks.md` to understand the tasks currently in progress.
5. Read `/docs/openapi.yaml` before using or modifying API integrations.

Do not disregard documented decisions or requirements.

If there are conflicts between documentation, do not make
decisions on your own. Identify the conflict and ask for clarification.

## API Rules

- Do not create your own endpoints.
- Do not create requests or responses arbitrarily.
- Always check `/docs/openapi.yaml` before implementing an API.
- Use existing APIs.
- Do not modify the backend unless explicitly requested.
- Do not change the API contract from the frontend side.
- Do not duplicate backend business logic in the frontend.

## Code Guidelines

- Reuse existing code, components, services, models, and patterns.
- Do not create duplicate implementations.
- Do not over-engineer.
- Do not add dependencies without a clear reason.
- Do not modify files unrelated to the task at hand.
- Use type-safe implementations.
- Separate the user interface (UI), state management, and API communication.

## UI/UX

- Create a user interface (UI) that is responsive for mobile devices and tablets.
- Handle loading, success, empty, and error states.
- Provide clear feedback after the user performs an action.
- Follow the user interface (UI) patterns already used in the project.

## Workflow

### Before Making Changes

1. Understand the task.
2. Read the relevant documentation.
3. Review the existing implementation.
4. Check the API contract if necessary.
5. Identify the files that will be affected.
6. Create a plan before making complex changes.

### After Implementation

1. Run relevant tests.
2. Run analysis tools/linters if available.
3. Check for Flutter/Dart errors.
4. Review the diff.
5. Ensure there are no unrelated changes.
6. Ensure the implementation aligns with the documentation.

## Restrictions

- Do not introduce new requirements.
- Do not invent API behavior.
- Do not modify the backend or database unless requested.
- Do not add dependencies without a valid reason.
- Do not write secrets or credentials in the source code.
- Do not commit or push to Git unless explicitly requested.
- If a critical requirement is ambiguous, ask for clarification.

## Priorities

Use the following priorities:

1. API contract
2. `docs/requirements.md`
3. `docs/architecture.md`
4. `docs/decisions.md`
5. `docs/tasks.md`
6. Existing implementation
7. General best practices
