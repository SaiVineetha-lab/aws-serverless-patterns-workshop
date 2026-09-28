#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-SaiVineetha-lab/aws-serverless-patterns-workshop}"
OWNER="${OWNER:-@me}"
TITLE="${TITLE:-Trojans - Serverless Patterns Workshop}"
SPRINT1_START="${SPRINT1_START:-2026-09-28}"
SPRINT2_START="${SPRINT2_START:-2026-10-05}"

if ! gh auth status 2>&1 | grep -q "'project'"; then
  echo "Missing the 'project' scope. Run: gh auth refresh -s project" >&2
  exit 1
fi

new_issue() {
  gh issue create -R "$REPO" --title "$1" --body "$2"
}

echo "Creating issues in $REPO"
I_CI=$(new_issue "Set up Jenkins CI pipeline for the repository" \
"Add a declarative \`Jenkinsfile\` that installs Python dependencies, compiles all Lambda sources, lints the SAM templates with cfn-lint, and runs the Module 3 unit tests with JUnit reporting.")
I_HOOK=$(new_issue "Add a GitHub webhook build trigger for Jenkins" \
"Add a repository webhook (push events, \`application/json\`) pointing at \`<jenkins-url>/github-webhook/\` so pushes start a Jenkins build. Needs repo admin. Poll SCM (\`H/5 * * * *\`) is the fallback trigger.")
I_M4=$(new_issue "Add unit tests for Module 4 address and favorites handlers" \
"Module 4 only has integration tests, which need a deployed stack. Add offline unit tests with a fake DynamoDB table (same approach as \`module-3/tests\`) for \`src/api/address\` and \`src/api/favorites\`, and run them in Jenkins.")
I_M5=$(new_issue "Add unit tests for Module 5 update_order_status" \
"Add an offline unit test for \`module-5/orderstatus/src/api/update_order_status.py\` using \`events/event-update-order.json\`, and run it in Jenkins.")
I_DUP=$(new_issue "Remove duplicate unused handlers in module-4/userprofile/src/api" \
"The handler files at the top of \`module-4/userprofile/src/api\` are identical copies that \`template.yaml\` never references; it deploys from \`src/api/address\` and \`src/api/favorites\`. Remove the stale copies.")
I_UTC=$(new_issue "Replace deprecated datetime.utcnow() in Module 3 create_order" \
"\`module-3/src/api/order/create/create_order.py\` calls \`datetime.utcnow()\`, which raises a DeprecationWarning in the unit tests. Switch to \`datetime.now(timezone.utc)\`.")
I_DOC=$(new_issue "Document Jenkins CI and GitHub Projects setup" \
"Complete \`docs/jenkins-github-projects.md\` with screenshots of the Jenkins setup, build trigger, and each GitHub Projects quickstart step.")

echo "Creating project '$TITLE' for $OWNER"
NUM=$(gh project create --owner "$OWNER" --title "$TITLE" --format json --jq .number)
PID=$(gh project view "$NUM" --owner "$OWNER" --format json --jq .id)

gh project edit "$NUM" --owner "$OWNER" \
  --description "Planning board for Team Trojans' AWS Serverless Patterns Workshop repo: CI, tests, cleanup and docs." \
  --readme "$(cat <<'MD'
# Trojans - AWS Serverless Patterns Workshop

Tracks the remaining work on https://github.com/SaiVineetha-lab/aws-serverless-patterns-workshop.

- **Iteration**: one-week sprints
- **Priority**: High / Medium / Low
- **Status**: Todo -> In Progress -> Done, moved automatically when issues close or PRs merge

Views: **Table** (everything), **Priority** (grouped by priority), **Board** (by status).
MD
)" >/dev/null

echo "Adding issues"
add_item() { gh project item-add "$NUM" --owner "$OWNER" --url "$1" --format json --jq .id; }
T_CI=$(add_item "$I_CI")
T_HOOK=$(add_item "$I_HOOK")
T_M4=$(add_item "$I_M4")
T_M5=$(add_item "$I_M5")
T_DUP=$(add_item "$I_DUP")
T_UTC=$(add_item "$I_UTC")
T_DOC=$(add_item "$I_DOC")

echo "Adding draft issues"
gh project item-create "$NUM" --owner "$OWNER" --title "Decide whether to add Module 2 to the repo" \
  --body "Check with the instructor whether Module 2 is required; the repo currently has modules 1, 3, 4 and 5." >/dev/null
gh project item-create "$NUM" --owner "$OWNER" --title "Tear down deployed stacks after grading" \
  --body "Delete the module 3, 4 and 5 CloudFormation stacks and the module 1 console resources in us-east-2." >/dev/null

echo "Creating Priority field"
gh project field-create "$NUM" --owner "$OWNER" --name "Priority" \
  --data-type SINGLE_SELECT --single-select-options "High,Medium,Low" >/dev/null

set_priority() { gh project item-edit "$NUM" --owner "$OWNER" --url "$1" --field Priority --value "$2" >/dev/null; }
set_priority "$I_CI" High
set_priority "$I_HOOK" High
set_priority "$I_DOC" High
set_priority "$I_M4" Medium
set_priority "$I_M5" Medium
set_priority "$I_DUP" Low
set_priority "$I_UTC" Low

gh project item-edit "$NUM" --owner "$OWNER" --url "$I_CI" --field Status --value "In Progress" >/dev/null
for url in "$I_HOOK" "$I_M4" "$I_M5" "$I_DUP" "$I_UTC" "$I_DOC"; do
  gh project item-edit "$NUM" --owner "$OWNER" --url "$url" --field Status --value "Todo" >/dev/null
done

echo "Creating Iteration field"
ITER_JSON=$(gh api graphql -f query='
mutation($p: ID!, $s1: Date!, $s2: Date!) {
  createProjectV2Field(input: {
    projectId: $p, dataType: ITERATION, name: "Iteration",
    iterationConfiguration: {
      startDate: $s1, duration: 7,
      iterations: [
        {title: "Sprint 1", startDate: $s1, duration: 7},
        {title: "Sprint 2", startDate: $s2, duration: 7}
      ]
    }
  }) {
    projectV2Field { ... on ProjectV2IterationField { id configuration { iterations { id title } } } }
  }
}' -f p="$PID" -f s1="$SPRINT1_START" -f s2="$SPRINT2_START" 2>/dev/null || true)

FID=$(jq -r '.data.createProjectV2Field.projectV2Field.id // empty' <<<"$ITER_JSON")
if [[ -n "$FID" ]]; then
  S1=$(jq -r '.data.createProjectV2Field.projectV2Field.configuration.iterations[] | select(.title=="Sprint 1") | .id' <<<"$ITER_JSON")
  S2=$(jq -r '.data.createProjectV2Field.projectV2Field.configuration.iterations[] | select(.title=="Sprint 2") | .id' <<<"$ITER_JSON")
  set_iter() { gh project item-edit --id "$1" --project-id "$PID" --field-id "$FID" --iteration-id "$2" >/dev/null; }
  for id in "$T_CI" "$T_HOOK" "$T_DOC"; do set_iter "$id" "$S1"; done
  for id in "$T_M4" "$T_M5" "$T_DUP" "$T_UTC"; do set_iter "$id" "$S2"; done
else
  echo "Could not create the Iteration field through the API; add it in the UI (docs step C6)." >&2
fi

URL=$(gh project view "$NUM" --owner "$OWNER" --format json --jq .url)
echo
echo "Done: $URL"
echo "Finish in the browser: Priority view (group by Priority, save), Board view, and Workflows."
