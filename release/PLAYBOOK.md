# Release Playbook

The spec for releasing software as a solo/indie developer. The `/release` skill executes this
playbook; this file is the source of truth. Update here first, the skill follows.

## Core model

Releases are **discrete versioned events** cut from trunk: gate → cut → ship → verify → listen.
Rigor scales with **blast radius** (what a bad release costs), not with project size or pride.
Everything below is layered on that axis; a project declares its layer once in its `RELEASE.md`
and inherits the matching gates.

## Layers (by blast radius)

| | L0 — personal tool | L1 — free public users | L2 — paid / depended-on |
|---|---|---|---|
| Who's hurt by a bad release | you | strangers' time | people's money or builds |
| Quality gate | CI green | CI green + smoke list (5–10 items) | CI green + smoke list + dogfood soak |
| Pre-release exposure | none — prod is the test | dogfood the prod-candidate build yourself for normal tasks before tagging | + share a preview/staging URL with 1–5 real users |
| Changelog | git log is acceptable | CHANGELOG.md → distilled user-facing notes | same, never skipped |
| Announce | nothing | in-app "what's new" + GitHub release notes | + direct channel (email / Discord / social) |
| Failure path | redeploy previous | one-click rollback kept warm | rollback + error reporting + one health signal |
| Listen window | none | 24h | 48h |

## Decisions (fixed across all layers)

- **Versioning** — semver (`1.4.2`) when consumers depend on your API (libraries, CLIs with
  scriptable interfaces); CalVer (`2026.06` or `2026.06.1`) for end-user apps/PWAs where
  "breaking change" means nothing to users.
- **Trigger** — release when a meaningful chunk of user value is complete, **but** never let
  main sit unshipped longer than the project's staleness cap (default: 3 weeks). The cap exists
  because the solo-dev failure mode is eternal unreleased improvement, not over-shipping.
- **Git** — trunk-based. A release is an annotated tag on a green commit of `main`. No release
  branches, no environment branches. Hotfix = fix on main → patch tag. Only cherry-pick onto a
  tag if main has accumulated unreleasable work.
- **Automation** — one local command (`npm run release` / `make release` / justfile) that runs
  the gates, bumps the version, opens the changelog for editing, tags, builds, deploys.
  Inspectable and debuggable; migrate it into tag-triggered CI only when a collaborator appears
  or reproducibility starts to matter (usually L2).
- **Changelog** — two artifacts from one source. `CHANGELOG.md` (keep-a-changelog style,
  written by a human at release time from `git log <last-tag>..HEAD`) is the source of truth;
  user-facing notes ("what's new", release announcement) are distilled from it, never written
  independently.
- **Hotfix lane** — a defined fast path that skips ceremony but never skips gates: fix → CI →
  patch version → tag → deploy → verify. The smoke list shrinks to the affected flow + the one
  golden-path item.

## The routine cycle

1. **Trigger check** — milestone done, or staleness cap hit? If cap hit with no milestone,
   ship what's on main anyway.
2. **Gate** — CI green on the release commit; run the layer's smoke list against a
   production-like build (for PWAs: the actual built bundle, installed, including offline if
   applicable). A failed item blocks the release — fix or descope, never waive.
3. **Cut** — write the CHANGELOG.md entry; bump version; annotated tag.
4. **Ship** — the one-command script deploys/publishes. Previous deploy stays restorable.
5. **Verify** — run the smoke list's golden path **on production**, not on a local build.
6. **Listen** — for the layer's window, watch errors/feedback before starting new work.
   Retro is written only when something went wrong (what broke, which gate should have
   caught it).

## The launch chapter (first public release only)

One-time work that routine releases never repeat. Done once, checked off in `RELEASE.md`:

- [ ] Name and domain settled; deploy target chosen and rollback verified to actually work
- [ ] License chosen (if source is public)
- [ ] Privacy posture written down (even one sentence: "no data leaves the device")
- [ ] Install/onboarding path tested by someone who isn't you
- [ ] Error reporting wired (L1+) and analytics baseline, if any, captured before announcing
- [ ] "Good enough" bar defined as a finite checklist — launch when it's empty, not when it feels done
- [ ] Soft-launch first: one small community or friend group before any broad announcement

## Per-project instantiation

Each project gets a `RELEASE.md` declaring its parameters. Template:

```markdown
# Release — <project>

- **Layer**: L1 (free public users)
- **Versioning**: CalVer (YYYY.MM.PATCH)
- **Staleness cap**: 3 weeks
- **Release command**: `npm run release`
- **Deploy target / rollback**: Netlify — rollback via deploy history
- **Announce channels**: in-app what's new, GitHub releases

## Smoke list (run on prod-like build before tag; golden path again on prod after deploy)
1. <core flow end-to-end>  ← golden path
2. <fresh install / first-run>
3. <offline behavior, if PWA>
4. ...5–10 items max

## Launch checklist
(copy from playbook on first release; delete this section once done)
```
