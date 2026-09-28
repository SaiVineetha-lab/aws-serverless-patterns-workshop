# Jenkins CI and GitHub Projects

Team Trojans: Sai Vineetha Tirumalla, Shivani Naikoti, Mukesh Singh, Ranadhir

Repository: https://github.com/SaiVineetha-lab/aws-serverless-patterns-workshop

This document covers three tasks:

- **A.** Integrating Jenkins with the project repository.
- **B.** Setting up build triggers.
- **C.** Completing the GitHub Projects quickstart.

Screenshots live in [`docs/images/`](images/). Each placeholder below names the file it expects.

---

## A. Jenkins integration

### A1. Installing Jenkins on macOS

Jenkins LTS was installed with Homebrew and runs as a background service on `http://localhost:8080`.
Homebrew also installs OpenJDK 21, which Jenkins runs on.

```bash
brew install jenkins-lts
brew services start jenkins-lts
```

The first-run wizard asks for the one-time unlock key, which is stored in this file:

```bash
cat ~/.jenkins/secrets/initialAdminPassword
```

After unlocking, we chose **Install suggested plugins**. That set includes the plugins this build uses:

- **Git**: clones the repository.
- **GitHub** and **GitHub Branch Source**: receive push notifications from GitHub.
- **Pipeline**: runs the `Jenkinsfile`.
- **JUnit**: publishes test results.
- **Timestamper**: adds a timestamp to each console line.

Finally, we created an admin user.

![Jenkins unlock screen](images/a1-unlock.png)
![Suggested plugins installing](images/a1-plugins.png)
![Jenkins dashboard after setup](images/a1-dashboard.png)

### A2. Connecting the repository

The repository is public, so Jenkins clones it over HTTPS without credentials.
A private repository would need a GitHub personal access token.
That token would be stored under *Manage Jenkins → Credentials* as a *Username with password* entry.

We set up the job like this:

1. *New Item* → name `aws-serverless-patterns-workshop` → **Pipeline**.
2. Under *Pipeline*, choose **Pipeline script from SCM** and fill in:

   | Setting | Value |
   | --- | --- |
   | SCM | Git |
   | Repository URL | `https://github.com/SaiVineetha-lab/aws-serverless-patterns-workshop.git` |
   | Branch | `*/main` |
   | Script path | `Jenkinsfile` |

3. Save, then click **Build Now**.

![Pipeline job SCM configuration](images/a2-job-scm.png)

### A3. The pipeline

The build is defined in [`Jenkinsfile`](../Jenkinsfile) at the root of the repository, so it is versioned with the code.

| Stage | What it does | Why |
| --- | --- | --- |
| Setup | Creates a Python virtualenv and installs Module 3's dependencies, pytest and cfn-lint. | Gives every build a clean environment. |
| Compile | Runs `python -m compileall` on the Lambda sources of modules 1, 3, 4 and 5. | Catches syntax errors in every module, including the ones without unit tests. |
| Lint SAM templates | Runs `cfn-lint` on the module 3, 4 and 5 `template.yaml` files. | Catches invalid CloudFormation/SAM before anyone runs `sam deploy`. |
| Module 3 unit tests | Runs `pytest module-3/tests` and writes a JUnit report. | Checks the order workflow and idempotency against a fake DynamoDB table, with no AWS access needed. |
| Post | Publishes `reports/*.xml` to Jenkins' test results. | Shows test trends on the job page. |

Modules 4 and 5 only have integration tests. Those tests call the deployed API Gateway endpoints, so they need AWS credentials and live stacks.
The pipeline therefore leaves them out. Two issues on the project board track adding offline unit tests for both modules.

![First successful build: stage view](images/a3-stage-view.png)
![Console output showing pytest passing](images/a3-console.png)
![Test results](images/a3-tests.png)

---

## B. Build triggers

The `Jenkinsfile` declares two triggers. Jenkins registers them the first time the pipeline runs.

```groovy
triggers {
    githubPush()
    pollSCM('H/5 * * * *')
}
```

### B1. GitHub webhook (push)

`githubPush()` is the same setting as ticking *GitHub hook trigger for GITScm polling* on the job.
When GitHub sends a push event to `/github-webhook/`, Jenkins checks the repository and builds any new commits.

Jenkins runs on `localhost`, which GitHub can't reach, so we exposed it with an ngrok tunnel:

```bash
brew install ngrok
ngrok config add-authtoken <token-from-ngrok-dashboard>
ngrok http 8080
```

Then the repository admin added the webhook under *Settings → Webhooks → Add webhook*:

| Setting | Value |
| --- | --- |
| Payload URL | `https://<ngrok-subdomain>.ngrok-free.app/github-webhook/` (trailing slash required) |
| Content type | `application/json` |
| Events | Just the `push` event |
| Active | ✓ |

We tested it by pushing a commit to `main`. GitHub showed a green delivery, and Jenkins started a build labelled *Started by GitHub push by &lt;user&gt;*.

![Webhook configuration](images/b1-webhook.png)
![Successful webhook delivery (200)](images/b1-delivery.png)
![Build started by GitHub push](images/b1-push-build.png)

### B2. Poll SCM (fallback)

`pollSCM('H/5 * * * *')` checks the repository about every five minutes and builds only when there are new commits.
It keeps CI working without inbound network access, for example when the ngrok tunnel is down.
The polling log is under *Job → Git Polling Log*.

![Git polling log](images/b2-polling-log.png)

---

## C. GitHub Projects quickstart

Project: `<paste project URL>`

Most of the setup was scripted with the GitHub CLI in [`docs/scripts/setup-github-project.sh`](scripts/setup-github-project.sh).
GitHub has no API for views or workflows, so those steps were done in the web UI.

```bash
gh auth refresh -s project
./docs/scripts/setup-github-project.sh
```

### C1. Introduction

A GitHub Project is a table or board that lists issues, pull requests and draft notes.
Each item can have custom fields such as priority or sprint.
The project stays in sync with the repository: closing an issue or merging a PR updates the item.

### C2. Prerequisites

- An existing repository with issues. We created seven issues for real remaining work:

  | Issue | Priority | Iteration |
  | --- | --- | --- |
  | Set up Jenkins CI pipeline | High | Sprint 1 |
  | GitHub webhook build trigger | High | Sprint 1 |
  | Document Jenkins CI and GitHub Projects setup | High | Sprint 1 |
  | Module 4 unit tests | Medium | Sprint 2 |
  | Module 5 unit tests | Medium | Sprint 2 |
  | Remove duplicate Module 4 handlers | Low | Sprint 2 |
  | Replace `utcnow()` in Module 3 | Low | Sprint 2 |

- Write access to the repository.
- A GitHub CLI token with the `project` scope.

![Repository issues](images/c2-issues.png)

### C3. Creating a project

We created a project named *Trojans - Serverless Patterns Workshop* from the **Table** layout.

![New project](images/c3-create.png)

### C4. Setting the project description and README

In *Project settings*, we added a short description and a README.
The README explains the Iteration, Priority and Status fields and the three views.

![Project settings: description and README](images/c4-readme.png)

### C5. Adding issues to the project

We added the seven repository issues to the project.
In the UI, you type `#` in a new row, pick the repository, and select the issue.

![Issues added to the table](images/c5-issues.png)

### C6. Adding draft issues

We added two draft issues, which exist only in the project until they are converted to real issues:

- *Decide whether to add Module 2 to the repo*
- *Tear down deployed stacks after grading*

![Draft issues](images/c6-drafts.png)

### C7. Adding an iteration field

We added an **Iteration** field with one-week sprints:

- **Sprint 1** (Sep 28): CI, webhook and docs.
- **Sprint 2** (Oct 5): tests and cleanup.

![Iteration field](images/c7-iteration.png)

### C8. Creating a field to track priority

We added a **Priority** single-select field with the options High, Medium and Low, and gave every issue a priority.

![Priority field](images/c8-priority.png)

### C9. Grouping issues by priority

In the view menu we chose *Group by → Priority*.

![Grouped by priority](images/c9-group.png)

### C10. Saving the priority view

We clicked **Save changes** and renamed the view to *Priority*.

![Saved Priority view](images/c10-saved-view.png)

### C11. Adding a board layout

We added a new view with the **Board** layout, named *Board*. Its columns come from the Status field: Todo, In Progress and Done.

![Board view](images/c11-board.png)

### C12. Configuring built-in automation

Under *⋯ → Workflows* we turned on these workflows:

| Workflow | Action |
| --- | --- |
| Item added to project | Set Status to **Todo** |
| Item closed | Set Status to **Done** |
| Pull request merged | Set Status to **Done** |
| Item reopened | Set Status to **In Progress** |

We tested the automation by closing the Jenkins CI issue once the pipeline was green; the item moved to *Done* on the board automatically.

![Workflows](images/c12-workflows.png)
![Item auto-moved to Done](images/c12-auto-done.png)

---

## Contributions

| Member | Work |
| --- | --- |
| Sai Vineetha Tirumalla | |
| Shivani Naikoti | |
| Mukesh Singh | |
| Ranadhir | Jenkinsfile, Jenkins setup, build triggers, GitHub Projects script |

## Problems and fixes

- **GitHub can't reach `localhost:8080`.** We tunnelled with ngrok for the webhook and kept Poll SCM as a fallback.
- **Only repository admins can add webhooks.** The repository owner configured the webhook.
- **The Homebrew Jenkins service has a minimal `PATH`.** The `Jenkinsfile` prepends `/opt/homebrew/bin` so builds use Homebrew's `python3`.
- **Modules 4 and 5 only have integration tests, which need live AWS stacks.** CI runs Module 3's offline unit tests plus compile and lint checks for all modules.
