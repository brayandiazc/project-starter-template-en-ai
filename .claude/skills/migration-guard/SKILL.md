---
name: migration-guard
description: Reviews a database migration before it ships to make sure it is safe — reversible, non-destructive, and backward-compatible — following the project's database conventions. Use this whenever you create, review, or approve a schema or data migration (e.g. "check this migration", "is this migration safe to deploy?").
---

<!-- Example skill for the template — adapt or delete to fit your project. -->

Review the migration the user points to (or the one in the current diff) for safety.

1. Read [`docs/conventions/database.md`](../../../docs/conventions/database.md) for
   the project's migration rules (naming, reversibility, index strategy, allowed
   column types) and [`docs/architecture/database.md`](../../../docs/architecture/database.md)
   for the current data model it touches.
2. Verify **reversibility**: there is a working `down`/rollback path, or the change
   is explicitly documented as irreversible with justification.
3. Check for **data loss**: dropping columns/tables, narrowing types, or adding a
   `NOT NULL` column without a default/backfill. Flag any destructive step.
4. Check **backward compatibility** for zero-downtime deploys: can old and new code
   run against the new schema during rollout? Prefer expand → migrate → contract
   over a single breaking change.
5. Check **locking / large tables**: operations that rewrite or long-lock big
   tables (e.g. adding a non-null column, certain index builds). Suggest the safe
   variant for the project's database.
6. Confirm a **rollback plan** and that the migration is **idempotent / safe to
   retry** where the tooling allows.

Output: a short verdict (safe / unsafe), the specific risks found, and the minimal
changes to make it safe. If the decision is significant (e.g. an irreversible
migration), recommend recording an ADR in [`docs/decisions/`](../../../docs/decisions/README.md).

Do NOT run the migration. Do NOT loosen the project's database rules to make a
migration pass — fix the migration instead.
