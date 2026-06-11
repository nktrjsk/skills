# skills

Agent skills for [Claude Code](https://code.claude.com). Each skill lives in its own
directory as `<skill-name>/SKILL.md` (with optional bundled resources), installable by
copying the directory into `~/.claude/skills/`.

| Skill | Description |
|---|---|
| [agent-ready](agent-ready/SKILL.md) | Audit whether a website is agent-ready — probes robots.txt, llms.txt, markdown content negotiation, Content Signals, MCP/OAuth discovery and more, then scores the site and reports prioritized fixes. Distilled from [Cloudflare's Agent Readiness](https://blog.cloudflare.com/agent-readiness/) and [isitagentready.com](https://isitagentready.com/). |
| [demand-validation](demand-validation/SKILL.md) | Guided, ADHD-friendly workflow for validating demand for an idea yourself — timeboxed steps from hypothesis to interviews to synthesis. |
| [demand-validation-research](demand-validation-research/SKILL.md) | Claude does the market research autonomously: gathers context, researches competition / problem signals / willingness to pay, delivers a go/no-go report. |
| [release](release/SKILL.md) | Set up or execute a software release following a layered release playbook (rigor scales with blast radius; trunk + tags; one-command ship). |
