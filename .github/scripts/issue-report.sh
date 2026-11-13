#!/usr/bin/env bash
# Posts a report to the issue $ISSUE, or updates the earlier report so that the
# issue has only one. Reports are recognised by their first line, a hidden
# marker such as <!-- bioc-map-bot -->.
#
# Usage: issue-report.sh <report.md>
set -euo pipefail

report="$1"
marker=$(head -n 1 "$report")
id=$(gh api "repos/$GITHUB_REPOSITORY/issues/$ISSUE/comments" --paginate \
  --jq ".[] | select(.user.login == \"github-actions[bot]\" and (.body | startswith(\"$marker\"))) | .id" |
  head -n 1)

if [ -n "$id" ]; then
  gh api --method PATCH "repos/$GITHUB_REPOSITORY/issues/comments/$id" -F "body=@$report" > /dev/null
else
  gh issue comment "$ISSUE" --body-file "$report"
fi
