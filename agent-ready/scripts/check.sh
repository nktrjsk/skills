#!/usr/bin/env bash
# Agent-readiness audit — probes a site for the standards tracked by
# Cloudflare's Agent Readiness score (blog.cloudflare.com/agent-readiness,
# isitagentready.com). Pure HTTP/DNS probes, no external deps beyond curl/dig.
#
# Usage: check.sh <url>
# Exit codes: 0 = ran ok, 2 = bad usage
set -u

URL="${1:-}"
if [ -z "$URL" ]; then
  echo "usage: check.sh <url>" >&2
  exit 2
fi
case "$URL" in
  http://*|https://*) ;;
  *) URL="https://$URL" ;;
esac
URL="${URL%/}"
HOST=$(printf '%s' "$URL" | sed -E 's#^https?://##; s#/.*$##; s#:[0-9]+$##')

UA="agent-readiness-check/1.0"
TIMEOUT=15

PASS=0
TOTAL=0
FAILED_CHECKS=""

# fetch <url> [extra curl args...] -> F_STATUS, F_CTYPE, F_BODY (first 20KB)
fetch() {
  local u="$1" out
  shift
  out=$(curl -sL -m "$TIMEOUT" -A "$UA" "$@" -w '\n__STATUS__%{http_code}\n__CTYPE__%{content_type}' "$u" 2>/dev/null) || out=""
  F_STATUS=$(printf '%s' "$out" | grep '^__STATUS__' | tail -1 | sed 's/^__STATUS__//')
  F_CTYPE=$(printf '%s' "$out" | grep '^__CTYPE__' | tail -1 | sed 's/^__CTYPE__//')
  F_BODY=$(printf '%s' "$out" | sed '/^__STATUS__/d; /^__CTYPE__/d' | head -c 20000)
  : "${F_STATUS:=000}"
  : "${F_CTYPE:=}"
}

body_is_html() {
  printf '%s' "$F_BODY" | head -c 200 | grep -qiE '^[[:space:]]*<(!doctype|html)' && return 0
  printf '%s' "$F_CTYPE" | grep -qi 'text/html'
}

body_is_json() {
  printf '%s' "$F_BODY" | head -c 50 | grep -qE '^[[:space:]]*[{[]'
}

# report <PASS|FAIL|INFO|MISS> <scored:1|0> <name> <detail>
report() {
  local status="$1" scored="$2" name="$3" detail="$4" mark
  case "$status" in
    PASS) mark="✓"; [ "$scored" = 1 ] && PASS=$((PASS + 1)) ;;
    FAIL) mark="✗"; FAILED_CHECKS="${FAILED_CHECKS}  - ${name}\n" ;;
    INFO) mark="○" ;;
    MISS) mark="○" ;;
  esac
  [ "$scored" = 1 ] && TOTAL=$((TOTAL + 1))
  printf '  %s %-34s %s\n' "$mark" "$name" "$detail"
}

echo "Agent-readiness audit: $URL"
echo "=============================================================="

# ---------------------------------------------------------------- Discoverability
echo ""
echo "1. Discoverability"

fetch "$URL/robots.txt"
ROBOTS_BODY=""
if [ "$F_STATUS" = 200 ] && ! body_is_html; then
  ROBOTS_BODY="$F_BODY"
  report PASS 1 "robots.txt" "present"
else
  report FAIL 1 "robots.txt" "missing or HTML (status $F_STATUS)"
fi

SITEMAP_OK=0
if printf '%s' "$ROBOTS_BODY" | grep -qi '^sitemap:'; then
  SITEMAP_OK=1
  report PASS 1 "sitemap" "declared in robots.txt"
else
  fetch "$URL/sitemap.xml"
  if [ "$F_STATUS" = 200 ] && printf '%s' "$F_BODY" | grep -qiE '<(urlset|sitemapindex)'; then
    SITEMAP_OK=1
    report PASS 1 "sitemap" "/sitemap.xml present"
  else
    report FAIL 1 "sitemap" "no Sitemap: directive and no /sitemap.xml"
  fi
fi

LINK_HEADERS=$(curl -sIL -m "$TIMEOUT" -A "$UA" "$URL/" 2>/dev/null | grep -i '^link:')
if printf '%s' "$LINK_HEADERS" | grep -qi 'api-catalog'; then
  report PASS 1 "Link headers (RFC 8288)" "rel=\"api-catalog\" advertised"
elif [ -n "$LINK_HEADERS" ]; then
  report PASS 1 "Link headers (RFC 8288)" "present (no api-catalog rel)"
else
  report FAIL 1 "Link headers (RFC 8288)" "no Link response headers on homepage"
fi

if command -v dig >/dev/null 2>&1; then
  DNS_AID=$(dig +short TXT "_aid.$HOST" 2>/dev/null)
  if [ -n "$DNS_AID" ]; then
    report INFO 0 "DNS-AID (draft, unscored)" "TXT _aid.$HOST found"
  else
    report MISS 0 "DNS-AID (draft, unscored)" "no TXT record at _aid.$HOST"
  fi
else
  report MISS 0 "DNS-AID (draft, unscored)" "skipped (dig not available)"
fi

# ---------------------------------------------------------------- Content accessibility
echo ""
echo "2. Content accessibility"

fetch "$URL/llms.txt"
if [ "$F_STATUS" = 200 ] && ! body_is_html; then
  report PASS 1 "llms.txt" "present"
else
  report FAIL 1 "llms.txt" "missing or HTML (status $F_STATUS)"
fi

fetch "$URL/llms-full.txt"
if [ "$F_STATUS" = 200 ] && ! body_is_html; then
  report INFO 0 "llms-full.txt (bonus)" "present"
else
  report MISS 0 "llms-full.txt (bonus)" "not present"
fi

fetch "$URL/" -H "Accept: text/markdown"
if printf '%s' "$F_CTYPE" | grep -qi 'markdown'; then
  report PASS 1 "Markdown content negotiation" "Accept: text/markdown honored"
else
  report FAIL 1 "Markdown content negotiation" "homepage ignores Accept: text/markdown (got ${F_CTYPE:-nothing})"
fi

fetch "$URL/index.md"
if [ "$F_STATUS" = 200 ] && ! body_is_html; then
  report PASS 1 "/index.md fallback" "markdown served at /index.md"
else
  report FAIL 1 "/index.md fallback" "no markdown at /index.md (status $F_STATUS)"
fi

# ---------------------------------------------------------------- Bot access control
echo ""
echo "3. Bot access control"

AI_BOTS='GPTBot|ChatGPT-User|OAI-SearchBot|ClaudeBot|Claude-Web|Claude-User|anthropic-ai|Google-Extended|CCBot|PerplexityBot|Perplexity-User|Bytespider|Amazonbot|Applebot-Extended|Meta-External|cohere|DuckAssistBot|MistralAI'
if printf '%s' "$ROBOTS_BODY" | grep -qiE "user-agent:.*($AI_BOTS)"; then
  MATCHED=$(printf '%s' "$ROBOTS_BODY" | grep -ioE "user-agent:[[:space:]]*($AI_BOTS)" | sed 's/.*:[[:space:]]*//' | sort -u | head -5 | tr '\n' ',' | sed 's/,$//; s/,/, /g')
  report PASS 1 "AI bot rules in robots.txt" "rules for: $MATCHED"
else
  report FAIL 1 "AI bot rules in robots.txt" "no AI-crawler-specific user-agent rules"
fi

if printf '%s' "$ROBOTS_BODY" | grep -qiE '^[[:space:]]*content-signal:'; then
  SIGNALS=$(printf '%s' "$ROBOTS_BODY" | grep -iE '^[[:space:]]*content-signal:' | head -1 | tr -d '\r')
  report PASS 1 "Content Signals" "$SIGNALS"
else
  report FAIL 1 "Content Signals" "no Content-Signal directive in robots.txt"
fi

fetch "$URL/.well-known/http-message-signatures-directory"
if [ "$F_STATUS" = 200 ] && body_is_json; then
  report PASS 1 "Web Bot Auth" "signature directory published"
else
  report FAIL 1 "Web Bot Auth" "no /.well-known/http-message-signatures-directory"
fi

# ---------------------------------------------------------------- Protocol discovery
echo ""
echo "4. Protocol discovery (capabilities)"

fetch "$URL/.well-known/api-catalog"
if [ "$F_STATUS" = 200 ] && ! body_is_html; then
  report PASS 1 "API Catalog (RFC 9727)" "present"
else
  report FAIL 1 "API Catalog (RFC 9727)" "no /.well-known/api-catalog"
fi

fetch "$URL/.well-known/mcp/server-card.json"
if [ "$F_STATUS" = 200 ] && body_is_json; then
  report PASS 1 "MCP server card" "present"
else
  report FAIL 1 "MCP server card" "no /.well-known/mcp/server-card.json"
fi

fetch "$URL/.well-known/agent-skills/index.json"
if [ "$F_STATUS" = 200 ] && body_is_json; then
  report PASS 1 "Agent Skills" "present"
else
  report FAIL 1 "Agent Skills" "no /.well-known/agent-skills/index.json"
fi

fetch "$URL/.well-known/oauth-authorization-server"
if [ "$F_STATUS" = 200 ] && body_is_json; then
  report PASS 1 "OAuth server metadata (RFC 8414)" "present"
else
  report FAIL 1 "OAuth server metadata (RFC 8414)" "no /.well-known/oauth-authorization-server"
fi

fetch "$URL/.well-known/oauth-protected-resource"
if [ "$F_STATUS" = 200 ] && body_is_json; then
  report PASS 1 "OAuth protected resource (RFC 9728)" "present"
else
  report FAIL 1 "OAuth protected resource (RFC 9728)" "no /.well-known/oauth-protected-resource"
fi

fetch "$URL/"
if printf '%s' "$F_BODY" | grep -qiE 'webmcp|navigator\.modelContext'; then
  report INFO 0 "WebMCP (unscored)" "homepage references WebMCP"
else
  report MISS 0 "WebMCP (unscored)" "no WebMCP reference detected on homepage"
fi

# ---------------------------------------------------------------- Commerce
echo ""
echo "5. Commerce (informational, not scored)"
report MISS 0 "x402 / UCP / ACP" "not auto-probed; see REFERENCE.md if the site sells things"

# ---------------------------------------------------------------- Score
echo ""
echo "=============================================================="
PCT=$((PASS * 100 / TOTAL))
if [ "$PCT" -ge 80 ]; then
  VERDICT="AGENT-READY"
elif [ "$PCT" -ge 50 ]; then
  VERDICT="PARTIALLY AGENT-READY"
else
  VERDICT="NOT AGENT-READY"
fi
echo "Score: $PASS/$TOTAL scored checks ($PCT%) — $VERDICT"
if [ -n "$FAILED_CHECKS" ]; then
  echo ""
  echo "Failed checks (fix recipes in REFERENCE.md):"
  printf '%b' "$FAILED_CHECKS"
fi
