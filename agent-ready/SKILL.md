---
name: agent-ready
description: Audit whether a website or app is agent-ready — probes robots.txt, sitemap, llms.txt, markdown content negotiation, Content Signals, Web Bot Auth, MCP server card, Agent Skills, API catalog, OAuth discovery and commerce protocols, then scores the site and reports prioritized fixes. Use when the user asks to check/audit agent readiness or AI-agent/LLM friendliness of a site, asks how agents see their site, or mentions llms.txt, isitagentready, or MCP discovery.
---

# Agent-Ready Audit

Checks a site against the agent-readiness standards tracked by Cloudflare
(blog.cloudflare.com/agent-readiness) and isitagentready.com: can AI agents
discover, read, respect, and interact with the site?

## Quick start

```bash
scripts/check.sh <url>   # e.g. scripts/check.sh developers.cloudflare.com
```

Prints ✓/✗ per check across 5 categories, a score out of 14, and a verdict
(≥80% agent-ready, 50–79% partially, <50% not ready).

## Workflow

1. **Run the script** against the user's URL. If they gave a bare domain or a
   deep link, audit the site root (the standards live at the root and
   `/.well-known/`).
2. **Spot-check quality, not just presence**, for anything that passed:
   - `llms.txt` — is it a real curated index (title, summary, links to key
     content) or a stub?
   - Markdown negotiation — fetch a real content page with
     `curl -H "Accept: text/markdown"` and confirm it returns clean markdown,
     not HTML. Markdown cuts agent token cost up to ~80% vs HTML.
   - robots.txt — do the AI bot rules express what the owner actually wants
     (allow vs block training/inference crawlers)?
3. **Report**: lead with the verdict and score, then a short category
   breakdown, then **prioritized fixes** — easy wins first:
   1. robots.txt with AI bot rules + `Sitemap:` directive
   2. `llms.txt` (and per-section `llms.txt` for large sites)
   3. Markdown content negotiation / `/index.md` fallbacks
   4. Content Signals (`ai-train` / `ai-input` / `search`)
   5. `/.well-known/` capability endpoints (API catalog, MCP server card,
      Agent Skills, OAuth discovery) — only if the site has APIs/services
4. For each failed check the user wants to fix, use the exact recipe in
   [REFERENCE.md](REFERENCE.md) — it has the file formats, header syntax, and
   RFC references.

## Interpreting context

- **Content sites** (blogs, docs, marketing): categories 1–3 matter most;
  failing OAuth/API-catalog checks is normal and shouldn't be presented as a
  problem.
- **Apps with APIs/services**: category 4 (protocol discovery) is the
  differentiator — an MCP server card and API catalog let agents act, not
  just read.
- **E-commerce**: also discuss commerce protocols (x402, UCP, ACP) from
  REFERENCE.md; the script doesn't auto-probe them.
- Some checks (Web Bot Auth, DNS-AID, WebMCP) have <5% adoption — frame them
  as ahead-of-the-curve, not table stakes.

## Auditing a local/unreleased app

If the user wants their own codebase audited before deploy, skip the script
and instead check the repo for: a robots.txt with AI bot rules, generated
llms.txt, markdown routes or `Accept: text/markdown` handling, and
`/.well-known/` routes — then map findings to the same categories and
recipes in REFERENCE.md.
