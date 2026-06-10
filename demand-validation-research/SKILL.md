---
name: demand-validation-research
description: "Use this skill when the user wants Claude to autonomously research whether real demand exists for a product, service, or idea. Triggers include: 'udělej průzkum trhu', 'prozkoumej jestli o to má někdo zájem', 'research my idea', 'do market research for me', 'validate this for me', or any request where the user wants Claude to do the research work rather than being guided through it themselves. Claude gathers context first, then instructs the user to enable Research mode, then conducts the research and delivers a structured report."
---

# Demand Validation — Autonomous Deep Research

**Language note:** Always respond in the user's language throughout the entire skill. If the conversation is in Czech, respond in Czech. If in English, respond in English. Never switch languages unless the user explicitly asks.

## Purpose

Claude acts as the researcher, not the guide. The user provides the idea and context; Claude does the research and delivers a structured report with a go/no-go recommendation and next steps.

## Research Principles

These inform how Claude interprets and weighs evidence during research:

- **Competition is a signal, not an enemy.** Existing competitors confirm the problem is real and people pay for solutions. No competition is a warning sign — always investigate why.
- **Look for behavior, not opinions.** Forum posts, reviews, workarounds, and complaints are more reliable than survey data or think pieces.
- **Absence of evidence ≠ evidence of absence.** If a problem isn't discussed online, it may mean the audience isn't online — not that the problem doesn't exist.
- **Negative signals matter as much as positive ones.** Failed products, abandoned projects, and "we tried this and stopped" posts are valuable data.
- **Recency matters.** A market that existed 5 years ago may be dead or saturated today. Weight recent sources more heavily.

---

## Phase 1 — Context Gathering (before Research mode)

Before any research begins, Claude must collect enough context to search effectively. Ask the user all of the following in a single message — do not spread across multiple turns.

### Required information:

1. **The idea** — What is it? One or two sentences.
2. **The hypothesis** — Who has the problem, what is the problem, what would the solution do? If the user hasn't formulated this, help them do it now using the format: *"I believe that [group of people] has a problem with [X] and would pay for [solution Y]."*
3. **Target group** — Who are the intended users? Be specific: not "small businesses" but "freelance designers managing 3+ clients."
4. **Geography / language** — Is this aimed at a specific country or language market, or global?
5. **Known competitors** — Does the user already know of any similar products or services? (Even partial knowledge helps.)
6. **Known communities** — Does the user know where their target group hangs out? (Subreddits, forums, Slack groups, etc.)
7. **Constraints** — Anything Claude should know that narrows the space? (e.g., must be open source, must work offline, price ceiling, specific platform)

### Rules:
- Do not start researching until all 7 points are answered. Missing context produces shallow research.
- If the user's answers are vague, push back once with a specific clarifying question before accepting the answer.
- If the user genuinely doesn't know the answer to a question (e.g., no known competitors), that's fine — note it and move on.

---

## Phase 2 — Research Mode Prompt

Once context is collected, instruct the user:

> "Mám vše, co potřebuji. Teď prosím zapni **Research režim** (tlačítko vedle textového pole) a pošli mi zprávu, že jsi připravena. Pak začnu průzkum."

*(In English: "I have everything I need. Please enable **Research mode** (the button next to the text input) and send me a message that you're ready. Then I'll begin the research.")*

Do not begin research until the user confirms Research mode is active.

---

## Phase 3 — Research Execution

Conduct research across the following areas in order. For each area, search multiple sources and look for converging or conflicting signals.

### 3.1 — Competition Mapping
**Goal:** Understand who already operates in this space.

Search for:
- Direct competitors (same problem, same audience, same solution type)
- Indirect competitors (same problem, different solution type — e.g., "people use Excel for this")
- Failed or abandoned competitors (search for "[problem] startup failed", "[product name] shut down", "[category] alternatives")

For each competitor found, note:
- Name and what it does
- Pricing model (free / paid / freemium)
- Approximate size or traction if available (reviews, user counts, funding)
- Key weaknesses visible in reviews or community discussion

**Signal interpretation:**
- Many competitors + active market = validated demand, assess differentiation
- 1–2 competitors = early market, investigate their traction carefully
- No competitors = investigate why; look for failed attempts specifically
- Competitors with bad reviews = opportunity signal; note what users complain about

### 3.2 — Problem Signal Research
**Goal:** Find evidence that real people experience this problem.

Search for:
- Reddit threads, Hacker News posts, forum discussions about the problem
- "Is there a tool for...", "How do you manage...", "I hate that..." posts in relevant communities
- Job postings that mention the problem (companies hiring to solve it manually = unmet need)
- Workarounds people use (Google Sheets, manual processes, duct-tape solutions = strong signal)

**Signal interpretation:**
- Active recent discussions = problem is live and felt
- Old discussions with no recent activity = problem may be solved or faded
- Workarounds in use = strong unmet need
- No discussion = either audience isn't online, or problem isn't acute enough to complain about

### 3.3 — Audience Research
**Goal:** Understand where the target group is and how they talk about the problem.

Search for:
- Specific communities (subreddits, Discord servers, Slack groups, LinkedIn groups, forums)
- How people in these communities describe the problem in their own words
- What language they use (important for outreach framing later)

Note 3–5 specific communities with enough activity to be worth engaging.

### 3.4 — Willingness to Pay Signals
**Goal:** Find evidence that people pay (or would pay) for solutions in this space.

Search for:
- Pricing pages of competitors — what do they charge?
- App Store / G2 / Capterra / Product Hunt reviews mentioning price
- Discussions where people mention paying for tools in this category
- Crowdfunding campaigns (Kickstarter, Indiegogo) in this space — funded or not

**Signal interpretation:**
- Existing paid products with users = willingness to pay confirmed
- Free-only market = investigate why (commodity? no margin? wrong audience?)
- People complaining that competitors are too expensive = price sensitivity signal

### 3.5 — Market Trajectory
**Goal:** Is this market growing, stable, or shrinking?

Search for:
- Google Trends for key terms (if assessable from search results)
- News or industry reports about this category
- Recent funding rounds or acquisitions in the space
- Whether the problem is getting more or less acute over time (e.g., driven by regulation, remote work, new technology)

---

## Phase 4 — Report Delivery

Deliver a structured report with the following sections. Be direct — state what the evidence shows, not just what was found.

---

### 1. Hypothesis Assessment
Restate the user's hypothesis, then state clearly: **confirmed / partially confirmed / refuted / inconclusive** — and in 2–3 sentences, why.

### 2. Competition Landscape
List the key competitors found. For each: what it does, rough positioning, notable strengths and weaknesses. If no competitors were found, explain what that likely means in this specific case.

### 3. Problem Signal Summary
What evidence exists that real people experience this problem? Quote or paraphrase specific examples (forum posts, workarounds, job descriptions). Rate the signal strength: **strong / moderate / weak / absent**.

### 4. Willingness to Pay
What does the evidence say about whether people pay for solutions in this space? What price points exist?

### 5. Market Trajectory
Is this market growing, stable, or declining? What's driving it?

### 6. Go / No-Go Recommendation
State a clear recommendation: **Go / Proceed with caution / Pivot / Stop** — and explain the reasoning in plain language. If "Pivot," suggest what to change (different audience, different problem framing, different solution type).

### 7. Next Steps — Who to Talk To
Based on the research, provide:
- **Interviewee profile:** 2–3 criteria defining the ideal person to interview (extreme user characteristics specific to this idea)
- **Where to find them:** 3–5 specific communities, subreddits, or channels identified in the research
- **Suggested outreach message:** A short, honest message the user can send cold — not a pitch, a research request

---

## Handling Edge Cases

**No online signal found for the problem:**
Report this honestly. It may mean the audience isn't online, the problem is too niche to surface in general searches, or the problem isn't acute enough to generate discussion. Recommend narrowing the search to specific niche communities or reconsidering the hypothesis.

**Market is clearly saturated:**
Don't soften this. Report it directly, note what the dominant players do well, and suggest whether differentiation is realistic or whether the user should pivot.

**Contradictory signals:**
Report the contradiction explicitly. Don't resolve it artificially. Explain what each signal suggests and what additional information would resolve the ambiguity.

**Idea is too vague to research effectively:**
Stop and return to Phase 1. Ask the user to sharpen the hypothesis before proceeding.
