#!/usr/bin/env bash
#
# PreToolUse hook for Bash: enforce the Bash(...) entries of permissions.deny
# against the *whole* command string.
#
# Claude Code matches a deny rule against the start of the command, so wrapping
# a denied command in a loop, a subshell, a pipe or an && chain slips past it:
#
#     git push origin main                  -> denied by the rule
#     for b in x; do git push origin $b; done -> not denied, same effect
#
# This reads the same deny list, so there is nothing to keep in sync, and looks
# for each denied command at any point where a command can actually start:
# beginning of string, or after ; & | ( { newline, or after do/then/else.
# A denied string merely quoted or echoed is left alone.

set -uo pipefail

SETTINGS="${CLAUDE_DENY_GUARD_SETTINGS:-$HOME/.claude/settings.json}"

command_json=$(cat)
command=$(printf '%s' "$command_json" | jq -r '.tool_input.command // ""')

[ -z "$command" ] && exit 0
[ -r "$SETTINGS" ] || exit 0

# `Bash(rm -rf *)` -> `rm -rf *`, one per line.
patterns=$(jq -r '
    (.permissions.deny // [])[]
    | select(startswith("Bash(") and endswith(")"))
    | .[5:-1]
' "$SETTINGS" 2>/dev/null)

[ -z "$patterns" ] && exit 0

deny() {
    printf '%s' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Blocked by permissions.deny (\`$1\`). The rule only matches the start of a command, so this hook also catches it inside loops, subshells and pipes. Print the command and let the user run it.\"}}"
    exit 0
}

# Where a command can begin: start of string, or after a shell separator or keyword.
boundary='(^|[;&|(){}]|^[[:space:]]*|[[:space:]](do|then|else)[[:space:]]+)[[:space:]]*'

while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue

    # Escape regex metacharacters, then let the rule's own `*` mean "anything
    # but a command separator" so `curl * | sh` keeps its shape.
    escaped=$(printf '%s' "$pattern" | sed -e 's/[][\.^$+?(){}|/]/\\&/g' -e 's/\*/[^;\&|]*/g')

    # A trailing wildcard should also match the bare command with no arguments.
    escaped=$(printf '%s' "$escaped" | sed -e 's/[[:space:]]\[\^;\&|\]\*$/([[:space:]].*)?/')

    if printf '%s' "$command" | grep -qE "${boundary}${escaped}"; then
        deny "$pattern"
    fi
done <<< "$patterns"

exit 0
