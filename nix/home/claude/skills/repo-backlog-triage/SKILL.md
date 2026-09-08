---
name: repo-backlog-triage
description: Use when asked to clean up, triage, or "faire le ménage" in a repository's open pull requests and issues — deciding what to merge, rework, or close across a backlog rather than working a single known PR.
---

# Repo Backlog Triage

## Overview

Working a backlog is not the same as working one PR. The failure mode is volume: dozens of items, each looking mergeable at a glance, and a strong pull toward batching decisions or trusting green CI. This skill is the routine that keeps each item honest and keeps the human in control of every irreversible act.

**Core principle: one item at a time, decided by the human, verified by you.**

## The Loop

1. Enumerate open PRs and issues once, up front.
2. Apply the exclusion list the user gave you. Record it — you will be tempted to drift back into excluded areas.
3. Take the next item. Gather its dossier.
4. Present the dossier and **ask the user for a decision on that item alone**.
5. Execute the decision. Prepare everything; stop before anything irreversible.
6. Restate the running state (what is settled, what is left) and move to the next item.

Never present two items in one question. Never decide an item yourself because it "obviously" should be closed.

## Never Merge, Never Push

Merging is the maintainer's act, not yours. This holds even when:

- the CI is green,
- you just verified the branch yourself,
- the user picked an option whose label contained the word "merge".

That last one is the real trap. **Do not put "merge" in an option label** — write "prepare it for merge" instead. Selecting an option is not authorization to perform an irreversible public act on a canonical repository.

Same for `git push`. Prepare the branch, then hand back the two lines and stop.

## Building the Dossier

Before asking for a decision, gather enough that the user does not have to go look:

| Signal | Why it matters |
|---|---|
| Age and last activity | An untouched branch from months ago needs a rebase before anything else |
| Reviews and **unresolved** review threads | Fetch threads via GraphQL `reviewThreads` with `isResolved` — the REST comment list does not tell you what is still open |
| Which CI checks fail, and the actual log line | A red check is often stale or structural, not the contributor's fault |
| Linked issues | They may already be satisfied, or may hold the design debate |
| Whether the layout still matches current conventions | A branch can be correct and still be structurally obsolete |

## Verify the Premise, Not Just the Diff

The expensive mistakes in triage are accepting a premise nobody checked.

- **A red check is a claim, not a verdict.** Read the failing log line. It is routinely a stale run from before a convention changed, a token scope the bot lacks, or a missing PR template on a dependabot PR — none of which are the contributor's problem.
- **A green check is also just a claim.** It proves the code passed the matrix that ran, not the matrix that matters. If a change claims to support several versions of a dependency, install each one and run the suite against each. Deducing compatibility from an API table is how you ship a reversed rotation.
- **"Port of upstream X" deserves an upstream lookup.** Confirm X exists upstream before accepting a component that claims parity with it.
- **A dependency major bump is a consumer-facing break** even when the library's own API is unchanged. Check whether the old major is genuinely dead (last release date, its PHP/Node floor) before agreeing to drop it, and prefer widening the constraint over replacing it.

When you cannot verify something in the environment you have — a port already bound, a browser missing, a service you must not disturb — **say so explicitly and say what it would take**. Never let an environmental failure read as a defect in the contribution, and never let an unrun test read as a passing one.

## Reworking a Contributor's Branch

When the decision is "rework it":

1. Check `maintainerCanModify` first. Without it you can only comment.
2. Worktree under `<repo>/.claude/worktrees/pr<number>`, set up with `gh pr checkout <number>` so the push remote is wired. When the branch starts from an **issue** rather than an existing PR there is no PR to check out, so create it with `git worktree add -b <branch>` and then wire the remote yourself (`git config branch.<branch>.pushremote <fork-url>` plus `git push -u`), otherwise the two-line hand-off has nowhere to push.
3. Rebase onto the current target branch. Resolve conflicts by taking the contributor's side of *their* change and letting the formatter re-apply the target branch's conventions on top.
4. Squash to one commit, **preserving the original author** via `--author`.
5. Strip any `Co-Authored-By` trailer only if asked — it may be the contributor's own, not yours.
6. Run the package's real checks: tests, formatter, linter, and any committed build artefacts.
7. Hand back two lines and stop.

**Re-check the project's own conventions on every branch, not once.** A rule you applied to the previous PR applies to this one too: a forbidden `composer.json` key, a CHANGELOG heading style, a version placeholder. Grep the branch for each of them before handing it back, rather than trusting that you would have noticed.

**`git checkout --ours/--theirs <file>` takes the whole file, not just the conflicting hunks.** Cleanly auto-merged changes in that file are silently discarded. After using it, diff the result against the contributor's original and re-apply what vanished.

## Closing Well

A close is a message to a person who spent their evenings on this. State the verifiable reason first, acknowledge the reviewer who raised it if someone did, and name the nearest thing that *would* be welcome. Route the text through whatever prose-editing process the user has configured.

## Red Flags

| Thought | Reality |
|---|---|
| "CI is green, I can merge this" | You never merge. And green only covers what ran. |
| "They picked the option that said merge" | Option labels are not authorization for irreversible acts. |
| "The failing test proves the PR is broken" | Check whether your environment caused it before blaming the branch. |
| "v3 and v4 look similar, one code path is fine" | Install both and run the suite. Similar is not identical. |
| "I'll present these three together, they're related" | One item, one decision. |
| "The remaining items are obvious, I'll batch them" | The user asked to decide each one. |
| "I'll note the reviewer's points in a reply and move on" | If the decision was to rework, apply them; don't answer on the author's behalf. |

## Keep State Durable

A backlog pass outlives a context window. After each settled item, write the running state somewhere persistent — what is settled with its outcome, what is left in order, and the exclusion rules. Restate the short version to the user each turn so they never have to reconstruct it.
