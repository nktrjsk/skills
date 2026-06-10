---
name: release
description: Set up or execute a software release following the personal release playbook (layered by blast radius, trunk + tags, one-command ship). Use when the user says "/release", asks to cut/ship/tag a release, set up a release process for a project, or asks how to release something.
---

# Release

Thin executor for [PLAYBOOK.md](PLAYBOOK.md) — read it first; it is the source of truth.
This skill only decides which of three modes applies and walks it.

## Mode selection

1. Look for `RELEASE.md` in the project root.
2. **No `RELEASE.md`** → run **Instantiate**.
3. **`RELEASE.md` exists with an unfinished Launch checklist** → run **Launch**.
4. **Otherwise** → run **Cut a release**.

## Instantiate (first contact with a project)

1. Inspect the repo yourself before asking anything: deploy config (netlify/vercel/CI files),
   package.json scripts, test setup, whether it's a library or an app.
2. Ask the user only what can't be inferred (use AskUserQuestion):
   layer (L0/L1/L2 by blast radius — see playbook table), staleness cap if not 3 weeks,
   announce channels.
3. Derive, don't ask: versioning (semver for libraries, CalVer for apps), release command
   (wrap existing scripts), deploy/rollback mechanism.
4. Draft the smoke list (5–10 items) from the app's core flows; mark the golden path; have
   the user confirm it — this is the one part that must be human-approved.
5. Write `RELEASE.md` from the playbook template. If this will be the first public release,
   include the Launch checklist section.
6. If no one-command release script exists, offer to create it (gates → bump → changelog
   prompt → tag → build → deploy).

## Launch (first public release)

Work through the Launch checklist in `RELEASE.md` item by item; verify items by inspection
where possible (license file exists, error reporting wired) rather than taking them on faith.
When the checklist is empty, proceed to Cut a release, then remind the user: soft-launch
audience first, broad announcement only after the listen window.

## Cut a release

Follow the playbook's routine cycle, mapped to actions:

1. **Trigger** — `git log <last-tag>..HEAD --oneline`; summarize what would ship. If it's
   empty, stop. Note if the staleness cap is exceeded.
2. **Gate** — run CI checks locally (tests, lint, build). Then present the smoke list from
   `RELEASE.md` for the user to run on a prod-like build — never claim smoke items passed
   without the user or a verification run confirming them. A failed item blocks; offer fix
   or descope, never waive.
3. **Cut** — draft the `CHANGELOG.md` entry from the git log (user-meaningful wording, not
   commit messages); show it for approval; bump version per the project's scheme; create the
   annotated tag.
4. **Ship** — run the release command. Confirm the previous deploy remains restorable.
5. **Verify** — golden path on production. For a PWA, that includes the installed/offline path.
6. **Listen** — tell the user the listen window for their layer and what to watch; draft the
   user-facing notes/announcement from the changelog entry per the layer's announce tier.

## Hotfix

If the user says hotfix/urgent: skip trigger and changelog ceremony, keep every gate.
Fix on main → CI → smoke only the affected flow + golden path → patch tag → deploy → verify.
Backfill the changelog entry afterwards.
