# Agent-Readiness Reference & Fix Recipes

Distilled from [Cloudflare: Agent Readiness](https://blog.cloudflare.com/agent-readiness/)
and [isitagentready.com](https://isitagentready.com/) (June 2026). Adoption
figures are from Cloudflare's scan of the 200k most-visited domains.

## 1. Discoverability — can agents find the content?

### robots.txt (78% adoption)
Plain text at `/robots.txt`. Nearly universal, but usually written only for
classic search crawlers. Minimum viable:

```
User-agent: *
Allow: /

Sitemap: https://example.com/sitemap.xml
```

### Sitemap
Declare it in robots.txt (`Sitemap:` directive) or serve `/sitemap.xml`.
Lets agents enumerate all content paths instead of crawling link-by-link.

### Link headers (RFC 8288)
Expose resources in HTTP response headers so agents don't need to parse HTML:

```
Link: </.well-known/api-catalog>; rel="api-catalog"
```

### DNS-AID (IETF draft, bleeding-edge)
DNS-based AI discovery — TXT records advertising agent endpoints at the
domain level. Near-zero adoption; mention only for completeness.

## 2. Content accessibility — can agents read it cheaply?

### llms.txt
Plain text/markdown at `/llms.txt`: what the site is, what's on it, where
the important content lives — a curated reading list for LLMs.

```markdown
# Example Corp

> One-line summary of the site.

## Docs
- [Getting started](https://example.com/docs/start/index.md): setup guide
- [API reference](https://example.com/docs/api/index.md): full API docs

## Optional
- [Changelog](https://example.com/changelog/index.md)
```

**Large sites**: one giant llms.txt blows past context windows. Do what
Cloudflare did — a root `llms.txt` plus per-top-level-directory `llms.txt`
files. Optionally `llms-full.txt` with full inlined content. Also consider
deleting low-value directory-listing pages (Cloudflare cut ~450).

### Markdown content negotiation (3.9% adoption)
Serve `text/markdown` when the request carries `Accept: text/markdown`.
Cuts tokens by up to 80% vs HTML; Cloudflare measured 31% fewer tokens and
66% faster agent responses on their docs.

Two complementary mechanisms:
1. **Header negotiation** — return markdown with `Content-Type: text/markdown`
   when `Accept: text/markdown` is present.
2. **URL fallback** — serve every page's markdown at `<path>/index.md`. On
   Cloudflare this is two rules, no content duplication: a URL-rewrite rule
   strips `/index.md`, a header-transform rule sets `Accept: text/markdown`.

Extra trick: include hidden text in each HTML page telling agents to
re-request the markdown version (append `/index.md` or send
`Accept: text/markdown`) — and strip that directive from the markdown
output to avoid recursion.

## 3. Bot access control — can the owner express policy?

### AI bot rules in robots.txt
Name the AI crawlers explicitly instead of relying on `*`. Common agents:
`GPTBot`, `ChatGPT-User`, `OAI-SearchBot`, `ClaudeBot`, `Claude-User`,
`anthropic-ai`, `Google-Extended`, `CCBot`, `PerplexityBot`, `Bytespider`,
`Amazonbot`, `Applebot-Extended`, `Meta-ExternalAgent`.

```
User-agent: GPTBot
Disallow: /private/

User-agent: ClaudeBot
Allow: /
```

### Content Signals (4% adoption)
`Content-Signal:` directives in robots.txt separate three permissions that
a bare Allow/Disallow can't distinguish:

```
User-agent: *
Content-Signal: search=yes, ai-input=yes, ai-train=no
Allow: /
```

- `search` — may appear in search results
- `ai-input` — may be used for inference/grounding (RAG, answers)
- `ai-train` — may be used to train models

### Web Bot Auth (IETF draft)
Bots authenticate via signed HTTP requests (HTTP Message Signatures); the
site publishes accepted keys at
`/.well-known/http-message-signatures-directory`. Lets you allow verified
agents while filtering impostors. Easiest path today: enable verified-bot
handling at the CDN/WAF layer (Cloudflare supports it natively).

## 4. Protocol discovery — can agents act, not just read?

Only relevant for sites with APIs or services; content-only sites can skip.

### API Catalog (RFC 9727)
Linkset at `/.well-known/api-catalog` listing public APIs, docs, status
endpoints:

```json
{
  "linkset": [{
    "anchor": "https://example.com",
    "service-desc": [{ "href": "https://example.com/api/openapi.json" }],
    "service-doc": [{ "href": "https://example.com/docs/api" }]
  }]
}
```

### MCP server card (<15 sites — huge differentiation opportunity)
JSON at `/.well-known/mcp/server-card.json` describing your Model Context
Protocol server: endpoint URL, transport, tools offered, auth requirements.
Agents that find it can connect and call tools directly.

### Agent Skills
`/.well-known/agent-skills/index.json` — an index of task-specific skill
files telling agents what the site can do and where instructions live.

### OAuth discovery (RFC 8414 + RFC 9728)
- `/.well-known/oauth-authorization-server` — authorization-server metadata
  (endpoints, grant types, PKCE support).
- `/.well-known/oauth-protected-resource` — which resources need auth and
  which server issues tokens.

Together these let an agent route the user through a proper auth flow
instead of riding a logged-in browser session.

### WebMCP
Browser-side protocol (`navigator.modelContext`) letting in-page agents call
site functionality. Early/experimental.

## 5. Commerce (measured, not scored)

For sites that sell things:
- **x402** — revives HTTP `402 Payment Required` for machine-readable,
  per-request payment flows.
- **UCP (Universal Commerce Protocol)** — emerging standard for agent-driven
  purchasing.
- **ACP (Agentic Commerce Protocol)** — agents discover and purchase
  products programmatically.

All are early-stage; recommend only to users explicitly building for
agentic commerce.

## Bonus: ongoing hygiene (from Cloudflare's own playbook)

- **Redirect AI crawlers away from deprecated docs** so LLMs learn current
  APIs while humans keep access to historical pages.
- **Track your score over time** — isitagentready.com for one-off scans,
  Cloudflare URL Scanner (`agentReadiness` option) for programmatic checks,
  Cloudflare Radar for industry adoption trends.
