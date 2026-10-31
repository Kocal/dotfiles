Review a pull request by checking it out locally for full access to files and git history.

## Steps

1. **Parse args**: extract the PR number from `$ARGUMENTS` — handle plain number (`3505`) or full URL (`https://github.com/org/repo/pull/3505`).

2. **Save current branch**: run `git branch --show-current` (or `git rev-parse --abbrev-ref HEAD`) to know where to return.

3. **Fetch PR metadata**: run `gh pr view <number> --json title,body,baseRefName,headRefName,author,labels,state` to get the base branch and description.

4. **Checkout PR locally**: run `gh pr checkout <number>`. This creates a local tracking branch for the PR.

5. **Explore commits**: run `git log <baseRefName>..HEAD --oneline` to list all commits in the PR.

6. **Full diff**: run `git diff <baseRefName>...HEAD` for the complete diff — no API truncation.

7. **Analyze**: read critical changed files with the Read tool. Check tests, interfaces, config, docs.

8. **Write review** with these sections:
   - **Overview**: what the PR does and why
   - **Issues**: bugs, security concerns, missing tests — one line each, severity-tagged
   - **Suggestions**: non-blocking improvements
   - **Verdict**: approve / request changes / needs discussion

9. **Restore original branch**: run `git switch <original-branch>` after the review is done.

## Notes

- Always use the `baseRefName` from the PR metadata — never hardcode `main`.
- For large diffs, read the most critical files directly instead of scanning the full diff.
- If the repo has no local remote for the PR's fork, `gh pr checkout` handles it automatically.
