---
description: Run the Go-Barokah task queue one task at a time until no runnable task remains.
agent: task-runner
---

Run the task queue from `docs/tasks.md`.

Process exactly one runnable checkbox at a time, verify it, update its status, rescan the task file, and continue automatically. Do not ask for confirmation. If the current task requires user input, manual verification, or a backend change, record the reason using the task-runner rules, mark it `[s]`, and continue with the next independent task.

Do not modify backend or database code. Report backend requirements in the `Backend Changes Required` section of `docs/tasks.md` and in the final response.
