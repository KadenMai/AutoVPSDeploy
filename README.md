# AutoVPSDeploy

Reusable GitHub Issue → VPS Codex → staging PR automation for independent family-app repositories.

## Version 1 scope

This repository provides a coding-host bootstrap, branch/label setup, an issue-driven Actions template, and a deployment helper with image rollback. It does not yet build the family app image, provision DNS/TLS/databases, install/register runners automatically, or enforce dollar spending limits. Those require the test app and new VPS details. Runtime is limited; failed jobs never automatically retry or merge. `agent:done` means a PR was created, not that it was deployed or validated by CI.

## 1. Prepare the NEW coding VPS

Ubuntu 22.04 or 24.04, amd64/arm64. Do not use an existing production VPS for the first trial.

```bash
git clone https://github.com/KadenMai/AutoVPSDeploy.git
cd AutoVPSDeploy
sudo bash scripts/bootstrap.sh
sudo cp -r scripts /opt/autovps/
sudo chmod -R go-w /opt/autovps
```

Bootstrap installs packaged prerequisites and Codex, creates the `autovps` user, and grants no Docker/sudo privileges to it. It does not alter firewall, SSH, containers or reboot the server. Record installed versions before production rollout; npm currently installs the current Codex release.

Choose ONE Codex authentication mode:

```bash
sudo -iu autovps codex login --device-auth
```

Open the displayed URL and enter the code; enable device-code login in your ChatGPT security settings if necessary. Alternatively, securely provision API credentials for the Codex process. Never put credentials into issues, git or command logs. API usage is separately billed. Start with device login for the private trial; isolate API secrets from repository code before production automation.

## 2. Prepare a family repository

Create the test repository with an initial app commit. Authenticate `gh` as the operator, then run:

```bash
bash scripts/prepare-project.sh KadenMai/YOUR_TEST_REPOSITORY
```

Copy `templates/issue-agent.yml` into that repo as `.github/workflows/issue-agent.yml` on its default branch. Set repository Actions variable `AGENT_ALLOWED_USERS` to `KadenMai` (comma-separated operators supported). Enable Actions to create pull requests in repository Settings → Actions → General. Protect staging/main and require the app's real build/test checks. No automatic merges are configured.

In Settings → Actions → Runners → New self-hosted runner, follow GitHub's generated Linux installation/registration commands as `autovps`. Add label `autovps-coding`. Install the runner service using its bundled `svc.sh` with the `autovps` service user. Use a repository-scoped runner for the trial. A runner cannot automatically serve unrelated repositories; for multiple repositories use an organization runner with restricted access or separate runner registrations.

A dedicated coding VPS is recommended: workspace-write is not sufficient isolation for hostile repository code. Only trusted private repositories/operators are supported. The coding runner must not have production files, Docker access or deployment credentials. Different families needing a confidentiality boundary require separate OS/container/VM isolation, not merely separate checkout folders.

## 3. Submit a task

Create an issue in the FAMILY repo containing requirements and acceptance criteria, then apply `agent:ready`. Both the issue author and person applying the label must be authorized. The workflow runs one job per repository at a time, invokes Codex, and creates a unique PR targeting staging. Review Actions logs and app CI before merging. On failure, correct the cause and reapply `agent:ready`; there is no infinite repair loop. Removing a label does not cancel an already-running job; cancel it in Actions.

ChatGPT can create/label issues only when its connected GitHub tool has access to the target repo. The worker continues after the chat closes. There is no dependency on a live chat session.

## 4. Deployment host

Use a separate deployment host/runner with label `autovps-deploy`. Install Docker Engine and Compose using Docker's official Ubuntu instructions. Install `scripts/deploy.sh` under `/opt/autovps/scripts` and register the deployment runner for the family repo. Create GitHub environments `staging` and `production`, restrict allowed branches to staging/main respectively, and configure production reviewers if your plan supports them. Set `FAMILY_PROJECT` in each environment. Copy `templates/deploy.yml` into the family repo.

Provision `/opt/families/PROJECT/staging` and `/opt/families/PROJECT/production` separately. Each needs a trusted `compose.yml` referring to `${APP_IMAGE}`, `runtime.env` with mode 600, and an actual application healthcheck. Use separate ports, databases and volumes. Authenticate the deployment service user to the image registry using noninteractive credentials before deployment; do not run an interactive docker login inside CI.

Dispatch the deployment workflow with a trusted CI-built `registry/image@sha256:DIGEST`. The helper locks each environment, pulls before replacing containers, waits for health, and attempts the previous image on failure. First deployment has no previous image to roll back to. Database migrations are NOT rolled back. This is Compose replacement, not zero-downtime blue/green deployment. Operators must verify image provenance; the helper validates syntax, not whether an image belongs to an approved release.

## Validation

```bash
bash -n scripts/*.sh
python3 -m unittest discover -s tests -v
```

Live login, runner registration, Codex execution and Docker deployment must be tested on the new VPS before calling this production-ready. `config/project.example.json` documents planned project metadata; version 1 uses workflow variables, not that JSON file.

## References

- https://learn.chatgpt.com/docs/auth
- https://learn.chatgpt.com/docs/non-interactive-mode
- https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners
- https://docs.docker.com/engine/install/ubuntu/
