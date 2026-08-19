---
name: sf-blog-post
description: Draft a symfony.com blog post announcing a release of a Symfony project (Reprise, Encore, UX...). Produces the reStructuredText body only, from the GitHub release and the PR diffs, plus a suggested title and excerpt. Never publishes anything.
---

## When to Activate

Use when the user asks to write, draft or prepare a Symfony blog post announcing a release ("un article de blog pour Reprise 0.8.0", "write the blog post for the 3.4 release", "annonce la release sur le blog Symfony"). Not for GitHub release notes (see `sf-webpack-encore-release-notes`) and not for the `CHANGELOG.md`.

## Core Rules

1. **Body only.** symfony.com stores the title and the excerpt in dedicated fields, so the `.rst` file must start with the intro paragraph. Never put a title, a `===` underline or a `.. Excerpt:` line in the body. Print the suggested title and excerpt in the terminal instead.
2. **Never invent a technical fact.** Every claim, number, config snippet and JSON output comes from the release page, the PR body, the actual diff, or the repo's docs. Read the diff before describing a change. If a detail cannot be sourced, drop it or ask.
3. **Never write the prose yourself.** Draft the structure and the facts, then pass the file to the `natural-writing-editor` agent for the wording, with an explicit constraint list (see Workflow step 6). Same for the title and the excerpt.
4. **Hard-wrap the prose at ~76 columns.** Symfony blog RST is hard-wrapped, unlike PR descriptions. Do not wrap inside code blocks or link targets.
5. **One section per notable change,** in the order the user asked for. A section is: a title with a `~~~~` underline of the exact same length, a `.. contributors::` directive, one to two short paragraphs, then a code example when the change is user-facing. Infra and CI changes get no code example.
6. **Cap each section at two paragraphs before the code and one short paragraph after.** A section that does not fit is trying to say too much: cut the backstory, keep the problem and the fix. Anonymize war stories ("meant writing a custom plugin"), do not dump the reporter's metrics into the post.
7. **Every supported target or none.** If the project supports several bundlers, frameworks or backends (Vite *and* Rsbuild for Reprise), show a code example for each one, never just the first.
8. **Always close with a `Full Changelog` section** listing every PR of the release as `` `#NN`_ Title (@author) ``, followed by a short closing paragraph (project status, call for feedback), followed by the link-target block.
9. **Links are named RST targets at the bottom of the file,** never inline URLs.
10. **Verify external claims** (a tool being deprecated, a version dropping a feature, an upstream vote) with `WebSearch`/`WebFetch` before writing them, and link the primary source. Report anything you could not confirm to the user rather than shipping it.
11. **No em dashes, no hype, no exclamation marks.** Use commas, parentheses or `->`.
12. **Never publish.** Do not commit the file, do not push, do not open a PR on symfony/symfony-docs or anywhere else. The output is a file in the scratchpad for the user to paste.

## Guidelines

Voice, matching the author's previous Symfony blog posts: direct and technical, problem stated before the solution, plain concrete sentences, occasionally addresses the reader as "you", candid about limitations and about the project being experimental. Short paragraphs. No marketing.

RST reference:

| Construct | Syntax |
|---|---|
| Section title | title line, then `~~~~` on the next line, exactly as long as the title |
| Contributors | ``.. contributors:: [handle@github(Display Name)|81@symfony/reprise,85@symfony/reprise]`` |
| Code block | ``.. code-block:: javascript`` (also `json`, `css`, `yaml`, `twig`, `php`, `terminal`), blank line, 4-space indented body |
| Link reference | `` `label`_ `` in the prose, ``.. _`label`: https://...`` at the bottom |
| Inline code | double backticks |

The display name in `.. contributors::` is optional; use the handle alone when the real name is unknown. Never guess a contributor's name or pronouns.

Excerpt: one sentence, present tense, naming what the release brings. Title: `<Project> <version> released`, or the project's established pattern.

## Command Reference

```bash
# the release and its PR list
gh release view v0.8.0 --repo symfony/reprise

# the "why" behind a change, straight from the PR body
gh pr view 81 --repo symfony/reprise --json number,title,body,files,additions,deletions

# the real code and the real output, for the examples
git log --oneline v0.7.0..v0.8.0
git show <sha> -- <paths>

# the documented behavior, for wording that matches the docs
grep -n "<option>" doc/index.rst
```

## Workflow

1. Identify the repo and the tag. Run `gh release view` to get the full PR list and the contributors.
2. Ask which PRs deserve their own section if the user did not say. Everything else still lands in `Full Changelog`.
3. For each featured PR: read the PR body for the problem it solves, then `git show` the diff for the actual option names, config snippets and generated output. Prefer a real test fixture over an invented example.
4. Verify every external claim (Core Rule 10) and note the primary source URL.
5. Write the draft `.rst` into the scratchpad directory: intro, one section per PR, `Full Changelog`, closing paragraph, link targets.
6. Hand the file to the `natural-writing-editor` agent with: edit in place, keep valid RST, do not touch `.. contributors::` / code blocks / the changelog list / the link targets, no title or excerpt, keep the section order, hard-wrap at ~76 cols, keep every technical fact, respect the paragraph caps, and the voice description above.
7. Report: the file path, the suggested title, the suggested excerpt, a one-line summary per section, and an explicit list of anything unverified or worth double-checking before publishing.

## Examples

Skeleton of the body (Reprise 0.8.0):

~~~rst
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
~~~

Terminal output at the end, alongside the file path:

> **Title:** `Symfony Reprise 0.8.0 released`
> **Excerpt:** `Reprise 0.8.0 lets copied files keep a stable path and fixes manifest keys under Rsbuild.`
