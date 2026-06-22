---
name: webpack-encore-release-notes
description: Prepare a Webpack Encore release. Write the terse CHANGELOG.md entry and draft the GitHub release notes (intro + auto-generated "What's Changed" + footer, output to paste, never published). Use when releasing or writing the changelog / release notes for a version or tag.
---

## When to Activate

Use when the user asks to draft, write, or prepare the GitHub release notes for a Webpack Encore version or tag (e.g. "write the release notes for 7.2.0", "prepare the v7.2.0 release", "draft the GitHub release"). Also use when adding or updating the `CHANGELOG.md` entry for a version.

## Core Rules

1. **Never publish the release.** Do not run `gh release create`, `gh release edit`, or anything that creates or edits a GitHub release. The maintainer publishes manually. Your output is text for them to paste into the release form.
2. **Output one raw Markdown block** the user can copy straight into the GitHub release body. No surrounding commentary inside the block, no hard line wrapping (long lines are fine).
3. **The body has three parts, in order:** intro paragraph -> the GitHub auto-generated "What's Changed" -> footer.
4. **Get "What's Changed" from GitHub's generator** (`gh api .../generate-notes`) — do not hand-write the PR/contributor list. Follow the `github-cli` skill's conventions for `gh` usage.
5. **Write the intro yourself** in Encore's house voice — do not call any external API. Keep it to 2-3 sentences, friendly and a little playful, summarizing the highlights. Match the tone of past releases (see the v7.0.0 / v7.1.0 release notes for reference).
6. **Use the footer verbatim** (see Command Reference).
7. **If the release has breaking changes,** add a line in the intro pointing to the upgrade guide: `See the [upgrade guide](https://github.com/symfony/webpack-encore/blob/main/UPGRADE.md#<anchor>) before upgrading.` The anchor is the version with dots removed (e.g. `7.2.0` -> `#720`). Keep [UPGRADE.md](../../../UPGRADE.md) and [CHANGELOG.md](../../../CHANGELOG.md) as the source of truth for what changed.
8. **Also propose a release title** (separate from the body), matching the playful naming of past releases (e.g. "The ESM-Only & Async-first Release", "The Wait, We Forgot Some Things Release"). Present it above the body block.

## Command Reference

Fetch the auto-generated "What's Changed" body (the repo is resolved from the git remote):

```bash
# previous_tag_name is optional; GitHub auto-detects it when omitted
gh api --method POST repos/{owner}/{repo}/releases/generate-notes \
  -f tag_name=v7.2.0 \
  -f previous_tag_name=v7.1.0 \
  --jq .body
```

Footer (paste verbatim, after the "What's Changed" section):

```markdown
Thanks to everyone who contributed to this release! 🙌

Update Encore in your project:

\`\`\`bash
npm install @symfony/webpack-encore@latest --save-dev
pnpm add --save-dev @symfony/webpack-encore@latest
yarn add --dev @symfony/webpack-encore@latest
\`\`\`
```

## Workflow

1. Determine the tag being released (and the previous tag if it isn't obvious; otherwise let GitHub auto-detect).
2. Run the `generate-notes` command above to get the "What's Changed" body.
3. Draft a 2-3 sentence intro in Encore's voice. If the release has breaking changes, add the upgrade-guide link (Core Rule 7).
4. Propose a release title.
5. Assemble the body: `intro` + blank line + `What's Changed` + blank line + `footer`.
6. Output the title, then the full body as a single fenced or clearly-delimited Markdown block ready to copy/paste. Remind the user you have not created the release.

## Examples

User: "Draft the release notes for v7.2.0."

1. Run:
    ```bash
    gh api --method POST repos/{owner}/{repo}/releases/generate-notes -f tag_name=v7.2.0 --jq .body
    ```
2. Produce:

    > **Suggested title:** `7.2.0 - <playful name>`
    >
    > ```markdown
    > <2-3 sentence intro in Encore's voice>
    >
    > ## What's Changed
    >
    > - ... (from generate-notes)
    >
    > **Full Changelog**: https://github.com/symfony/webpack-encore/compare/v7.1.0...v7.2.0
    >
    > Thanks to everyone who contributed to this release! 🙌
    >
    > Update Encore in your project:
    > ... (footer)
    > ```

3. Tell the user to paste this into the GitHub release form, and that the release was not created.
