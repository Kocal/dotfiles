---
name: github-security-advisory
description: Draft the content of a GitHub Security Advisory (title, Description/Resolution/Credits, CVSS 3.1 vector) from a repo, issue, and PR URL. Use when the user wants to create a CVE/GHSA.
---

## When to Activate

Use when the user wants to publish a security advisory or request a CVE, typically signalled by:

- "create a CVE", "GitHub advisory", "GHSA", "report a vulnerability", "security advisory"
- A security issue + its fixing PR provided together
- A request to fill GitHub's "Report a vulnerability" form

This skill produces **content only** (text to paste into the GitHub form). It never creates the advisory and never makes write API calls.

## Inputs

The skill needs three inputs:

1. **Repo URL** — derive `owner/repo` and the advisories tab `https://github.com/<owner>/<repo>/security/advisories` (read existing advisories for tone/structure inspiration).
2. **Issue URL** — describes the vulnerability.
3. **PR URL** — the fix.

**STOP and ask for any missing input before doing anything else.** Do not start working. In particular:

- **Never infer the inputs from local context** — current branch, recent commits, working directory, or open files. A security branch checked out locally is not the inputs.
- The user must provide the three URLs explicitly. If only some are given, ask for the rest.
- Only after you have all three URLs do you run any `gh` command or fetch anything.

## Core Rules

1. **Gather the three inputs first (see Inputs).** Ask the user for the repo, issue, and PR URLs before any other action. Never infer them from the current branch, commits, or working directory.
2. **Always fetch real data with `gh`** (issue, PR, diff, existing advisories). Never guess or fabricate content.
3. **Delegate all prose to the `natural-writing-editor` agent** via the Agent tool — the title and the Description/Resolution/Credits body. Never write that prose yourself. Feed the agent the raw facts you collected.
4. **All advisory content is in English**, regardless of conversation language.
5. **CVSS is an estimate.** Show the per-metric reasoning and mark the result as "to validate". Point to the official calculator for the exact score.
6. **Never create the advisory or call a write API.** Output is text to copy-paste.
7. **Credits**: extract reporter (issue author) and fixer (PR author) from `gh`. Confirm handles/names with the user before finalizing.

## Workflow

1. **Collect the three input URLs from the user** (repo, issue, PR). If any is missing, ask and wait — do not proceed or infer from local git state. Then parse them → `owner/repo`, issue number, PR number.
2. **Fetch data:**
   ```bash
   gh issue view <n> --repo owner/repo --comments
   gh pr view <n> --repo owner/repo --comments
   gh pr diff <n> --repo owner/repo            # understand the nature of the fix
   gh api /repos/{owner}/{repo}/security-advisories   # published advisories, for tone/style
   ```
   If the API returns nothing usable, fall back to WebFetch on `https://github.com/<owner>/<repo>/security/advisories`.
3. **Analyze:** attack surface and impact → CVSS metrics.
4. **Draft prose:** call the `natural-writing-editor` agent with the collected facts to produce the title and the Description/Resolution/Credits body (English), respecting the section format below.
5. **Assemble** the final block (see Output format) and present it for copy-paste, flagging the CVSS vector as an estimate to validate.

## Description format

The body uses three `###` (h3) headings, in this order:

- `### Description` — 1 to 2 paragraphs (~100 words): what the vulnerability is, where it lives, how it is triggered, and its impact.
- `### Resolution` — 1 paragraph (~75 words): what the fix does, in prose. **Do not mention or link the fixing PR or issue**, and **do not state the patched/fixed version(s)** — the GitHub advisory form already lists vulnerable and patched versions, so repeating them here is redundant. At advisory-drafting time the fix is not yet public; linking it would disclose the vulnerability early. After the release, the user edits the published advisory to add a link to the fix commit on the public repo.
- `### Credits` — exactly one sentence, this template:

  > We would like to thank \<REPORTER first and last names> for reporting the issue and \<FIXER first and last names> for providing the fix.

  If reporter and fixer are the same person, adapt naturally (e.g. "for reporting the issue and providing the fix").

## CVSS 3.1 Reference

Build the vector string `CVSS:3.1/AV:?/AC:?/PR:?/UI:?/S:?/C:?/I:?/A:?` from the base metrics:

| Metric | Values | Note |
|---|---|---|
| AV — Attack Vector | N / A / L / P | Network is most common for web |
| AC — Attack Complexity | L / H | H only if a special condition beyond attacker control is required |
| PR — Privileges Required | N / L / H | N = no auth needed |
| UI — User Interaction | N / R | Reflected/stored XSS is often R |
| S — Scope | U / C | C when the impact crosses a security boundary (e.g. XSS hits other users) |
| C — Confidentiality | N / L / H | |
| I — Integrity | N / L / H | |
| A — Availability | N / L / H | |

Qualitative score bands: None 0.0 / Low 0.1–3.9 / Medium 4.0–6.9 / High 7.0–8.9 / Critical 9.0–10.0.

Get the exact score from the official FIRST calculator: `https://www.first.org/cvss/calculator/3.1`.

## Output format

Present a single block ready to paste:

```
## Title
<concise title: component + weakness>

## Description
### Description
<1–2 paragraphs>

### Resolution
<1 paragraph; no PR/issue link, no version numbers — added after release / already in the form>

### Credits
We would like to thank <REPORTER first and last names> for reporting the issue and <FIXER first and last names> for providing the fix.

## Severity
CVSS:3.1/AV:.../...   (Score X.Y — <band>) — estimate, validate on the FIRST calculator
Per-metric reasoning: AV ... / AC ... / PR ... / UI ... / S ... / C ... / I ... / A ...
```

## Examples

### User says: "Create a CVE for this. Repo https://github.com/symfony/ux, issue .../issues/593, PR .../pull/595"

1. `gh issue view 593 --repo symfony/ux --comments`, `gh pr view 595 --repo symfony/ux --comments`, `gh pr diff 595 --repo symfony/ux`, `gh api /repos/symfony/ux/security-advisories`.
2. Fix sanitizes SVG output → stored XSS via unsanitized SVG markup.
3. Plausible vector for SVG rendered into other users' pages: `CVSS:3.1/AV:N/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:N` (≈ Medium) — flag as estimate to validate.
4. Delegate title + Description/Resolution/Credits to `natural-writing-editor`; credits sentence names the issue author (reporter) and the PR author (fixer), confirmed with the user.
5. Output the assembled block.
