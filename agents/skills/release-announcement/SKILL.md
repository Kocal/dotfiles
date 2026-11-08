---
name: release-announcement
description: Draft the social media announcement of one or more software releases, as a copy-paste-ready Markdown file holding a thread for X and Bluesky (one overview post, then one post per project) and a LinkedIn post, each checked against its platform limit. Use whenever the user wants to announce, tweet, post or share releases, pastes GitHub release URLs or tags and asks for "a tweet", "a thread", "a post", "a Bluesky/LinkedIn post", mentions a "release day", or says it in French ("un p'tit tweet pour la release", "annonce la 3.7.2 sur les réseaux", "multi post Twitter et Bluesky"). Not for GitHub release notes or CHANGELOG entries (sf-webpack-encore-release-notes), nor for symfony.com blog posts (sf-blog-post).
---

# Release announcement

Turn a list of releases into posts the user can paste as they are: a thread shared by X and Bluesky, and a LinkedIn post, all in one Markdown file on the Desktop.

## Inputs and defaults

- **Releases**: GitHub release URLs, or a repository and a tag. Keep the order the user gives; it is the order of every list and of the thread.
- **Project names**: write them as the user wrote them, or else as the repository name (`phpstan-symfony-ux`, not "PHPStan Symfony UX"). People search for the name they know.
- **Platforms**: X + Bluesky + LinkedIn unless the user names others. X and Bluesky share the same text, so one thread is enough.
- **Language**: English, unless the user asks for another one.
- **Occasion**: use a special opener only when the user mentions one (a birthday, a conference, a milestone). Hint at it rather than spell it out: for a birthday, the user chose "Today is a special day 🎂 but also a release day 🎉". Without an occasion, a plain "Release day 🎉" opener is fine.
- **Output file**: `~/Desktop/release-day-<YYYY-MM-DD>.md`, so it survives a reboot and is easy to find.

## 1. Gather the facts

Fetch every release instead of trusting memory or the user's summary. A post that misdescribes a release is public and gets quoted.

```bash
gh release view <tag> --repo <owner>/<repo> --json name,publishedAt,body,url
gh repo view <owner>/<repo> --json description --jq .description
```

Then open the pull request of every line you plan to mention (`gh pr view <n> --repo <owner>/<repo> --json title,body`). A changelog line rarely gives the option name users will type or the effect they will see, and a post guessed from a title is the one that turns out wrong.

Only put URLs in the posts that the user gave or that `gh` returned.

## 2. Choose what to say

Readers scroll fast, so each project gets two or three facts, chosen in this order:

1. A change users must act on: a behavior change in production output, a deprecation fixed or introduced, a "low maintenance" or "use X instead" notice. Never drop this one, even when space is short.
2. New features, named by the option, function or command the user will type.
3. Bug fixes, described by their effect ("Autocomplete keeps its value when a field moves"), not by the internal cause.
4. More translations, docs, or a new supported version, when nothing bigger happened.

Say what users gain, not which internal area changed: "3 new rules to catch Symfony UX errors before runtime" tells a reader why to upgrade, "new rules for LiveComponent responses and arguments" does not.

Leave out CI changes, dependency bumps, dev-dependency constraints, refactors and test-only changes: they matter to maintainers, not to the people reading the post. When a release has only those, say "maintenance release" in one line.

Every bullet must trace back to a line of the release or to its pull request. Do not turn a maintainer change into a user promise: "allow Symfony UX 3.x in dev dependencies" says the test suite runs against it, not that the package "works with Symfony UX 3.x".

Write function and option names as plain text. X and Bluesky do not render backticks, so they would show up as stray characters.

## 3. Write

Check the list of subagents your harness offers. If it has a `natural-writing-editor` agent, brief it with the facts per project, the format below and the tone rules, then copy its output verbatim. Give it the facts you chose, not the whole changelog: a full dossier produces condensed sentences that try to say everything.

Tone: upbeat and friendly, never corporate.

- One emoji per line at most. The keycap that numbers a post does not count.
- No hype words ("excited", "thrilled", "game-changer", "revolutionary").
- No em-dashes.
- No hashtags in the thread, and up to three at the end of the LinkedIn post.

## Format

The user reworked dense one-sentence posts into bullet lists with air around the link. Keep that shape from the first draft: one fact per bullet, and a blank line before the URL so the link stands on its own.

### Thread post 1: the overview

No links here. The links go in the replies, one per project.

```text
Today is a special day 🎂 but also a release day 🎉

🚀 Symfony UX 3.7.2
🔁 Symfony Reprise 1.4.0
🧩 Webpack Encore Bundle 2.4.3

Details in the thread 👇
```

Give each project its own emoji that hints at what it is, and use the same emoji for it in the LinkedIn post.

### Thread posts 2 and up: one per project

Number the posts with keycap emojis (1️⃣ to 🔟), following the order of the overview. With more than ten projects, ask the user whether to split the announcement into two threads.

```text
1️⃣ Symfony UX 3.7.2:
- bug fixes for Autocomplete, LiveComponent and Pagination
- more translations

https://github.com/symfony/ux/releases/tag/v3.7.2
```

```text
3️⃣ Webpack Encore Bundle 2.4.3:
- no more deprecation on Symfony 8.2
- the Twig tag functions no longer throw with framework.assets.strict_mode: true

https://github.com/symfony/webpack-encore-bundle/releases/tag/v2.4.3
```

### LinkedIn

The same content as the thread, with room for a full sentence where a bullet would be too terse.

```text
Today is a special day 🎂 but also a release day 🎉

<one line saying how many releases and of what>

🚀 Symfony UX 3.7.2:
- ...
- ...

https://github.com/symfony/ux/releases/tag/v3.7.2

🔁 Symfony Reprise 1.4.0:
- ...

https://github.com/symfony/reprise/releases/tag/v1.4.0

Thank you to everyone who contributed, reported issues and reviewed code.

#Symfony #PHP #OpenSource
```

## 4. Check the limits and deliver

Write the file with exactly this structure, because the checker finds the posts by their headings and their ```` ```text ```` fences:

````markdown
# Release day <YYYY-MM-DD>

## Thread X + Bluesky

### Overview

```text
...
```

### 1️⃣ <project> <version>

```text
...
```

### 2️⃣ <project> <version>
...

## LinkedIn

```text
...
```
````

Then run the checker:

```bash
perl <this skill's directory>/scripts/count.pl ~/Desktop/release-day-<YYYY-MM-DD>.md
```

For each thread post, it checks X (280, a URL counts 23, an emoji 2) and Bluesky (300 graphemes, the URL at its full length, which stays safe even when the client shortens links). For LinkedIn, it checks 3000. It exits 1 when a post is over its limit. Do not hand over a file with an `OVER` line: ask the editor to trim that post, and cut the least important fact first, never the change users must act on.

Copy the overview post to the clipboard (`pbcopy`), then report:

1. the file path,
2. the highest X and Bluesky counts of the thread, and the LinkedIn count,
3. what you left out on purpose, so the user can put it back.

## Revisions

When the user asks for changes ("more upbeat", "add this release", "change the order"), edit the same file, rerun the checker, and copy the overview post again if it changed. When they paste their own rewrite of a post, keep their wording, and carry its shape over to the other posts if it is a style change rather than a one-off.
