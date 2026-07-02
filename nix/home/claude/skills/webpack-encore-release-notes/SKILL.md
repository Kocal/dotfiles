---
name: webpack-encore-release-notes
description: Prepare a Webpack Encore release. Write the terse CHANGELOG.md entry and draft the GitHub release notes (GitHub-alert intro + auto-generated "What's Changed" + footer), then copy them to the clipboard. Never publishes the release. Use when releasing or writing the changelog / release notes for a version or tag.
---

## When to Activate

Use when the user asks to draft, write, or prepare the GitHub release notes for a Webpack Encore version or tag (e.g. "write the release notes for 7.2.0", "prepare the v7.2.0 release", "draft the GitHub release"). Also use when adding or updating the `CHANGELOG.md` entry for a version.

## Core Rules

1. **Never publish the release.** Do not run `gh release create`, `gh release edit`, or anything that creates or edits a GitHub release. The maintainer publishes manually. Your output is text for them to paste into the release form.
2. **Deliver the body via the clipboard, not the terminal.** Printing the block makes it painful to copy (fence indentation, terminal wrapping). Write the assembled body to a temp file, copy it with `pbcopy`, and fire a desktop notification (macOS). In the terminal print only the suggested title and a one-line confirmation. (Fallback when `pbcopy` is unavailable: print the body inside a `~~~markdown` fence.)
3. **The body has these parts, in order:** intro (as a GitHub alert) -> the GitHub auto-generated "What's Changed" -> a `---` separator -> footer. Raw Markdown, no hard line wrapping (long lines are fine).
4. **Get "What's Changed" from GitHub's generator** (`gh api .../generate-notes`); do not hand-write the PR/contributor list. Follow the `github-cli` skill's conventions for `gh` usage.
5. **Draft the intro with the `natural-writing-editor` agent.** Give it the highlights and ask for 2-3 sentences in Encore's house voice (friendly and a little playful, matching the v7.0.0 / v7.1.0 release notes). Do not write the prose yourself, and do not call any external API. Wrap the returned text in the GitHub alert (Core Rule 3): `> [!IMPORTANT]` when the release has breaking changes, otherwise `> [!NOTE]`.
6. **Use the footer verbatim** (see Command Reference); it begins with the `---` separator.
7. **If the release has breaking changes,** end the intro alert with a link to the upgrade guide: `See the [upgrade guide](./UPGRADE.md#<anchor>) before upgrading.` Use a **relative** link: GitHub resolves relative links in release notes against the repo root, so `./UPGRADE.md` points to the file at the repo root (no absolute `https://github.com/...` URL needed, and it stays correct across branches). The anchor is the version with dots removed (e.g. `7.2.0` -> `#720`). The repo's `UPGRADE.md` and `CHANGELOG.md` are the source of truth for what changed.
8. **Propose a release title** (separate from the body), matching the playful naming of past releases (e.g. "The ESM-Only & Async-first Release", "The Wait, We Forgot Some Things Release"). Print it in the terminal above the confirmation.
9. **No em-dashes (`—`)** anywhere in the output. Use commas, parentheses, or `->`. The `natural-writing-editor` agent enforces this for the intro; keep it that way in the title and the rest of the block.

## Command Reference

Fetch the auto-generated "What's Changed" body (the repo is resolved from the git remote):

```bash
# previous_tag_name is optional; GitHub auto-detects it when omitted
gh api --method POST repos/{owner}/{repo}/releases/generate-notes \
  -f tag_name=v7.2.0 \
  -f previous_tag_name=v7.1.0 \
  --jq .body
```

Copy the assembled body to the clipboard and notify (macOS). Write the body to a temp file first (so backticks and `!` survive), then:

```bash
pbcopy < /tmp/encore-release-notes.md
osascript -e 'display notification "Release notes copied to the clipboard" with title "webpack-encore-release-notes" sound name "Glass"'
rm /tmp/encore-release-notes.md
```

Footer (the body ends with this, verbatim, including the leading `---` separator):

~~~markdown
---

Thanks to everyone who contributed to this release! 🙌

Update Encore in your project:

```bash
npm install @symfony/webpack-encore@latest --save-dev
pnpm add --save-dev @symfony/webpack-encore@latest
yarn add --dev @symfony/webpack-encore@latest
```
~~~

## Workflow

1. Determine the tag being released (and the previous tag if it isn't obvious; otherwise let GitHub auto-detect).
2. Run the `generate-notes` command above to get the "What's Changed" body.
3. Ask the `natural-writing-editor` agent for a 2-3 sentence intro (Core Rule 5), then wrap it in the GitHub alert. If the release has breaking changes, add the relative upgrade-guide link inside the alert (Core Rule 7).
4. Pick a release title.
5. Assemble the body: `intro alert` + blank line + `What's Changed` + blank line + `footer` (the footer already starts with the `---` separator).
6. Write the body to a temp file, `pbcopy` it, and send the notification (Command Reference). In the terminal print only the suggested title and a one-line confirmation (where to paste it, and that the release was not created). Do not dump the body into the terminal.

## Examples

For "Draft the release notes for v7.2.0":

1. Run `gh api --method POST repos/{owner}/{repo}/releases/generate-notes -f tag_name=v7.2.0 --jq .body`.
2. Get the intro from the `natural-writing-editor` agent and assemble the body (which looks like):

~~~markdown
> [!IMPORTANT]
> <2-3 sentence intro from the natural-writing-editor agent>. See the [upgrade guide](./UPGRADE.md#720) before upgrading.

## What's Changed
* ... (from generate-notes)

**Full Changelog**: https://github.com/symfony/webpack-encore/compare/v7.1.0...v7.2.0

---

Thanks to everyone who contributed to this release! 🙌

Update Encore in your project:

```bash
npm install @symfony/webpack-encore@latest --save-dev
pnpm add --save-dev @symfony/webpack-encore@latest
yarn add --dev @symfony/webpack-encore@latest
```
~~~

3. Write that body to a temp file, `pbcopy` it, notify, and remove the temp file. In the terminal, print only:

   > **Title:** `7.2.0 - <playful name>`
   > Release notes copied to the clipboard. Paste them into the GitHub release body. The release was not created.

   For a release without breaking changes, use `> [!NOTE]` and drop the upgrade-guide line.
