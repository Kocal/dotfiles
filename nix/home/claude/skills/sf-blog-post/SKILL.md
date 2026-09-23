---
name: sf-blog-post
description: Draft the body of a symfony.com blog post announcing a release of a Symfony project (Reprise, Encore, UX, and the rest). Use whenever someone asks to write, draft or prepare a release announcement for the Symfony blog, in English or in French: "write the blog post for the 3.4 release", "un article de blog pour Reprise 0.8.0", "annonce la release sur le blog Symfony", or simply "the blog post" once a release is on the table. Produces reStructuredText body only, sourced from the GitHub release and the real PR diffs, plus a suggested title and excerpt. Not for GitHub release notes, which belong to `sf-webpack-encore-release-notes`, and not for `CHANGELOG.md`. Never publishes anything.
---

# Symfony release blog post

A release page lists what changed. The blog post is the only place where someone explains why it changed and what it means for the reader, so every sentence in it is a claim the author gets held to. That is why this skill keeps sending you back to the diff instead of the PR title: one plausible sentence about an option that does not exist costs more than a missing section.

## What you deliver

An `.rst` file in the scratchpad, plus two lines printed in the terminal.

The file holds **the body only**, starting at the intro paragraph. symfony.com keeps the title and the excerpt in their own fields, so a title line, a `===` underline or a `.. Excerpt:` line inside the body ends up rendered twice. Print the suggested title and excerpt in the terminal instead, for the user to paste into those fields.

## Hard constraints

**Do not invent a technical fact.** Every claim, number, option name, config snippet and JSON output comes from the release page, the PR body, the actual diff, or the repo's docs. When a detail cannot be sourced, drop it or ask. Same for anything outside the repo (a tool being deprecated, an upstream vote, a version dropping a feature): confirm it with `WebSearch` or `WebFetch`, link the primary source, and tell the user what you could not confirm rather than shipping it.

**Do not write the prose yourself.** Build the structure and the facts, then hand the file to the `natural-writing-editor` agent, which holds the style rules and the author's voice. Same for the title and the excerpt.

**Do not publish.** No commit, no branch, no PR, anywhere. The output is a file the user pastes themselves.

## Workflow

1. Identify the repo and the tag, then run `gh release view` for the PR list and the contributors.
2. Ask which PRs deserve their own section, unless the user already said. Everything else still lands in `Full Changelog`.
3. For each featured PR: read the PR body for the problem it solves, then read the **diff** for the real option names, config keys and generated output. A real test fixture beats an invented example.
4. Verify the external claims and note each primary source URL.
5. Write the draft into the scratchpad: intro, one section per featured PR, `Full Changelog`, closing paragraph, link targets.
6. Hand the file to `natural-writing-editor` with an explicit constraint list: edit in place, keep valid RST, leave `.. contributors::`, the code blocks, the changelog list and the link targets untouched, no title and no excerpt, keep the section order, hard-wrap at ~80 columns, keep every technical fact, respect the paragraph caps, and the voice below.
7. Report: the file path, the suggested title, the suggested excerpt, one line per section, and an explicit list of everything unverified or worth a second look before publishing.

### Getting the facts

`gh` needs no clone, which is the usual situation since the release is rarely the repo you are sitting in:

```bash
gh release view v0.8.0 --repo symfony/reprise
gh pr view 81 --repo symfony/reprise --json number,title,body,author,files
gh pr diff 81 --repo symfony/reprise
gh api repos/symfony/reprise/compare/v0.7.0...v0.8.0 --jq '.commits[].commit.message | split("\n")[0]'
```

A local clone adds `git log v0.7.0..v0.8.0`, `git show <sha> -- <paths>`, and `grep -n "<option>" doc/index.rst` for wording that matches the project's own docs.

## Shape of the body

Intro paragraph, then one section per notable change in the order the user asked for, then `Full Changelog`, then a closing paragraph, then the link targets.

A section is: a title, a `~~~~` underline exactly as long as the title, a `.. contributors::` directive, one or two short paragraphs, a code example when the change is user-facing, and at most one short paragraph after it. Infra and CI changes get no code example.

Those caps are the point rather than a formality. A section that will not fit is usually smuggling in backstory: cut it, keep the problem and the fix. Anonymize the war stories ("meant writing a custom plugin") instead of naming a reporter or dumping their metrics into the post.

When the project supports several targets (Vite *and* Rsbuild for Reprise, several bundlers or backends elsewhere), show a code example for **each** one. Showing only the first reads as the others being second-class.

`Full Changelog` lists every PR of the release as `` `#NN`_ Title (@author) ``. Links are named RST targets at the bottom of the file, never inline URLs.

## The `.. contributors::` trap

The directive takes **one** `[...]` group: the contributors, comma-separated, then a `|`, then the PRs, comma-separated, each carrying its repo. Two `[...]` groups in a single directive do not work. The renderer keeps the first bracket and dumps the rest into the body as plain text.

Everyone before the `|` is credited jointly for the whole PR list ("Contributed by Simon André and Hugo Alliaume in #2985, #2993"). There is no per-person split inside one directive. To credit people who worked on different PRs, either accept the shared list or emit one directive per person.

```
.. contributors:: [handle@github(Display Name)|52487@symfony/symfony,52501@symfony/symfony]
.. contributors:: [smnandre@github(Simon André),Kocal@github(Hugo Alliaume)|2985@symfony/ux,2993@symfony/ux]
```

**Several directives in one section render in reverse source order.** The last one in the file is shown first, leftmost. So the person whose work carries the section has to be written *last*, which is the opposite of what the source reads like. Inside a single directive the order is untouched: first in the list is first on the page.

```
.. contributors:: [Amoifr@github(Pascal CESCON)|3798@symfony/ux]

.. contributors:: [Kocal@github(Hugo Alliaume)|3887@symfony/ux]
```

That renders as "Contributed by Hugo Alliaume", then "Contributed by Pascal CESCON".

Prefer **one merged directive** whenever the people can share a PR list, because the order then matches the source and nobody has to remember this rule. Split into several directives only when the credit really must be per-person, and remember to write them bottom-up.

The display name is optional; use the handle alone when the real name is unknown. Never guess a contributor's name or pronouns.

## RST reference

| Construct | Syntax |
| --- | --- |
| Section title | title line, then `~~~~` on the next line, exactly as long as the title |
| Contributors | ``.. contributors:: [handle@github(Name)\|81@symfony/reprise]`` |
| Code block | ``.. code-block:: javascript`` (also `json`, `css`, `yaml`, `twig`, `php`, `terminal`), blank line, 4-space indented body |
| Link reference | `` `label`_ `` in the prose, ``.. _`label`: https://...`` at the bottom |
| Inline code | double backticks |

## Voice

Direct and technical, matching the author's previous Symfony blog posts: the problem stated before the solution, plain concrete sentences, short paragraphs, occasionally addressing the reader as "you", candid about limitations and about a project being experimental. No marketing, no hype, no exclamation marks, no em dashes (commas, parentheses or `->` instead).

Excerpt: one sentence, present tense, naming what the release brings. Title: `<Project> <version> released`, or the project's established pattern.

## Skeleton

````rst
Reprise 0.8.0 is out, a few weeks after the project was `introduced on this
blog`_. This release brings back an Encore behavior that some codebases
depend on: copied files that keep a stable path on disk.

Copied Files Can Keep Their Path
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. contributors:: [pyrech@github(Loïck Piera)|81@symfony/reprise]

<problem: what the old tool did, who relies on it, why it broke>

<fix: the new option, its default>

.. code-block:: javascript

    // vite.config.ts
    ...

.. code-block:: javascript

    // rsbuild.config.ts
    ...

<one short paragraph: trade-off, caveat, related change>

Full Changelog
~~~~~~~~~~~~~~

* `#81`_ Add a per-entry opt-out of copied filenames hashing (@pyrech)
* `#82`_ [Manifest] Strip ``url()`` query and fragment from Rspack keys (@Kocal)

<closing paragraph: project status, call for feedback>

.. _`introduced on this blog`: https://symfony.com/blog/...
.. _`#81`: https://github.com/symfony/reprise/pull/81
.. _`#82`: https://github.com/symfony/reprise/pull/82
````

Terminal output at the end, alongside the file path:

> **Title:** `Symfony Reprise 0.8.0 released`
> **Excerpt:** `Reprise 0.8.0 lets copied files keep a stable path and fixes manifest keys under Rsbuild.`
