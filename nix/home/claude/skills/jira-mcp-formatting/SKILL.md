---
name: jira-mcp-formatting
description: Write Jira descriptions and comments through the mcp-atlassian MCP server. Covers which Markdown actually survives the ADF conversion, the constructs that get mangled, and how to verify what was stored. Load before creating or updating any Jira issue.
---

## When to Activate

Use when about to write or edit Jira content through `mcp__mcp-atlassian__*` tools:

- Creating an issue (`jira_create_issue`) or updating one (`jira_update_issue`)
- Writing or editing a comment (`jira_add_comment`, `jira_edit_comment`)
- The user asks for a panel, callout, `/info`, `/warning`, nested bullets, or a code snippet in a ticket
- Something rendered wrong in Jira and the description has to be republished

## Core Rules

1. **Write Markdown, not wiki markup.** The server converts Markdown to ADF on write. `{panel}`, `{code}` and other wiki macros are only handled on the *read* path.
2. **Never nest list items.** The parser matches bullets with `^[-*]\s+` at line start only; an indented sub-bullet falls through and renders as a separate paragraph with wide spacing. Use a flat list with a bold lead-in per item.
3. **Never put `{{ ... }}` inside an inline code span.** Braces get scrambled (`{{{{ ... }}}}`) by the conversion. Put the snippet in a fenced code block instead.
4. **Use `:::warning` blocks for callouts, not blockquotes.** A blockquote renders as a quote, not as the colored panel the `/info` and `/warning` editor commands produce.
5. **Read the issue back after every write** and compare with what was sent. Do not assume the conversion round-tripped.
6. **Pass `return_fields`** on updates (e.g. `status` or `summary,status`) — the default `*all` returns the whole issue and burns thousands of tokens.

## Supported Syntax

| Construct | Markdown to send | Notes |
|---|---|---|
| Panel / callout | `:::warning` … `:::` | Types: `note`, `info`, `warning`, `success`, `error`. Content is parsed recursively. |
| Bullet list | `- item` | Flat only. |
| Numbered list | `1. item` | Flat only. |
| Task list | `- [ ] item` / `- [x] item` | Becomes an ADF `taskList`. |
| Code block | Triple backticks | The language tag is dropped, the content survives verbatim. |
| Inline code | `` `code` `` | Safe except for `{{ }}` — see rule 3. |
| Bold / italic | `**bold**`, `*italic*` | Renders correctly, see "Reading Artifacts" below. |
| Link | `[text](url)` | |
| Table | `\| a \| b \|` with a `\|---\|` separator row | First row becomes the header. |
| Collapsible | `{expand:Title}` … `{expand}` | |

## Not Supported

| Wanted | What happens | Do instead |
|---|---|---|
| Nested bullets | Indented lines become standalone paragraphs, visually spaced out | Flat list, bold lead-in per item, details after a colon |
| Colored panel via blockquote | Renders as a plain quote | `:::warning` block |
| Twig/Handlebars braces in inline code | `{{ x }}` comes out as `{{{{ x }}}}` | Fenced code block |
| Syntax highlighting | Language tag is dropped | Accept plain code blocks |

## Reading Artifacts

The read path converts ADF back to Markdown and is lossy. Two artifacts are **not** defects in the stored issue:

- Bold comes back as `**text*` (asymmetric marker) — it renders correctly in Jira.
- Paragraphs come back separated by blank lines that were not sent.

Judge structure (nesting, panels, code blocks, links) from the round-trip; judge inline emphasis from the browser, or ask the user for a screenshot.

## Verifying the Converter

The rules above were read from the server source. When the MCP version changes, re-check rather than trusting this file:

```bash
d=$(ls -dt ~/.cache/uv/archive-v0/*/mcp_atlassian | head -1)
sed -n '/--- Panel block ---/,/--- Table ---/p' "$d/models/jira/adf.py"
grep -n "valid_panel_types\|bulletList\|listItem" "$d/models/jira/adf.py"
```

`markdown_to_adf()` in `models/jira/adf.py` is the whole write path; `preprocessing/jira.py` is the read path.

## Workflow

1. Fetch the current issue first (`jira_get_issue` with a narrow `fields` list) — never overwrite a description you have not read.
2. Draft the content, applying the Core Rules.
3. Show the draft to the user and wait for approval before writing.
4. Write with `jira_update_issue` / `jira_create_issue`, passing `return_fields`.
5. Read the issue back, compare against what was sent, and report any construct that did not survive.
6. Never change `status`, assignee or any field the user did not ask about.

## Examples

Callout plus flat list plus code block — the shape that survives intact:

````markdown
:::warning
Blocked until Twig 3.29 and UX TwigComponent 3.5 are released.
:::

- **Package A** : bump to [1.4](https://example.com/releases/v1.4) for the new filter.
- **Package B** : depends on A, ships the merge strategy.

Before:

```
class="{{ ('...' ~ attributes.render('class')) | tailwind_merge }}"
```
````

Same content written the wrong way — sub-bullets collapse into spaced paragraphs and the snippet is scrambled:

```markdown
- **Package A**
    - bump to 1.4
- Replace `class="{{ ('...') | tailwind_merge }}"`
```
