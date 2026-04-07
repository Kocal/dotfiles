---
name: skill-generation
description: Generate new agent skills following the project's conventions. Covers file structure, frontmatter format, section layout, and the generation workflow.
---

## When to Activate

Use this skill whenever the user asks to create, generate, or scaffold a new skill (or "agent skill").

## Skill File Structure

A skill is a single Markdown file located at:

```
~/workspace/kocal/dotfiles/agents/skills/<skill-name>/SKILL.md
```

Where `<skill-name>` is a short, lowercase, hyphenated identifier (e.g. `github-cli`, `natural-writing`, `skill-generation`).

## Frontmatter

Every `SKILL.md` starts with a YAML frontmatter block containing exactly two fields:

```yaml
---
name: <skill-name>
description: <One sentence describing when and why this skill should be loaded. Keep it under 200 characters.>
---
```

The `description` is what the agent sees in the skill list to decide whether to load it, so it must be precise and self-explanatory.

## Section Layout

After the frontmatter, use the following sections. Not all sections are mandatory for every skill, but this is the preferred order:

| Section | Required | Purpose |
|---------|----------|---------|
| `## When to Activate` | Yes | Conditions that trigger this skill (user keywords, patterns, contexts). |
| `## Core Rules` | Yes | Numbered list of mandatory behaviors and prohibitions when the skill is active. |
| `## Command Reference` or `## Guidelines` | Depends | Technical reference: commands, patterns, tables. Use "Command Reference" for tool-oriented skills, "Guidelines" for writing/style skills. |
| `## Workflow` | Recommended | Step-by-step process to follow when the skill is active. |
| `## Examples` | Recommended | Concrete examples showing input, commands run, and expected behavior. |

## Writing Conventions

- Write in English (all existing skills are in English).
- Be concise and actionnable. Every sentence should either instruct or constrain.
- Use numbered lists for ordered rules and steps.
- Use tables for "Bad / Good" comparisons or reference lookups.
- Include code blocks with real commands or code when relevant.
- Do not pad content. A short skill that covers everything is better than a long one with filler.

## Generation Workflow

When the user asks for a new skill:

1. **Clarify the scope.** Understand what the skill should cover. Ask if unclear.
2. **Propose a plan.** Before writing, outline: the skill name, the sections you will include, and the key rules. Let the user validate or adjust.
3. **Generate the skill.** Create the directory and `SKILL.md` file following the structure above.
4. **Summarize.** Tell the user what was created and list the key rules/behaviors of the new skill.

## Examples

### User says: "Generate a skill for Docker"

1. Ask what aspects of Docker the skill should cover (Compose, image builds, deployment, etc.).
2. Propose a plan with the skill name (`docker`), sections, and key rules.
3. After validation, create `~/workspace/kocal/dotfiles/dotfiles/agents/skills/docker/SKILL.md`.
4. Summarize the result.

### User says: "Create a skill to always use pnpm instead of npm"

The scope is already clear. Propose a quick plan:

- Name: `pnpm`
- When to Activate: any task involving package management
- Core Rules: use `pnpm` everywhere, never run `npm` or `yarn`, translate commands accordingly
- Command Reference: mapping table of npm commands to pnpm equivalents

After validation, generate the file.
