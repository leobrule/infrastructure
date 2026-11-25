# CLAUDE.md — infrastructure

Instructions for Claude Code working in this repo. Read this before doing anything.

## What this repo is

Leo's Terraform + Ansible training project (he is a DBRE: Cloud SQL focus).
It deploys a Cloud SQL for MySQL instance in GCP project `mysqlproject-501213`
(region `europe-west1`) and changes it only through pull requests.
Later phases add Ansible (users, grants, schemas), Azure SQL, and a monitoring
VM (srv-mon). The full plan and progress log live in a claude.ai Project doc
that you cannot see — record your work in `docs/session-log.md` instead.

## Layout

| Path | What | How it is applied |
| --- | --- | --- |
| `bootstrap/` | State bucket `mysqlproject-501213-tfstate`, service account `tf-deployer`, WIF pool `github-pool` | Locally, by Leo, only when he asks. Never from the pipeline |
| `terraform/modules/cloudsql-mysql/` | Cloud SQL module | Through `envs/dev` |
| `terraform/envs/dev/` | Dev environment; **all settings in `dev.tfvars`** | PR → `terraform-plan` → merge → `dev` approval → `terraform-apply` |
| `.github/workflows/` | `terraform-plan.yml` (PR), `terraform-apply.yml` (merge), `terraform-destroy.yml` (manual) | GitHub Actions |
| `ansible/` | Phase 6: in-database config (app databases, users, grants) for `mysql-dev`; see `ansible/README.md` | Leo runs it from srv-iac through the Cloud SQL Auth Proxy, after the PR is merged |
| `docs/session-log.md` | One entry per working session | You update it |
| `docs/runbook-powershell.md` | Everyday commands for Leo | Keep in sync when workflows change |

State is remote in GCS: `envs/dev` under prefix `envs/dev`, bootstrap under
prefix `bootstrap` (once migrated). Never commit `*.tfstate`, plans or secrets.

## Rules — always

1. **Every change goes through a PR.** `main` is protected by the `protect-main`
   ruleset (PR required, `terraform-plan` check required, no force push, no bypass).
   Work on a branch, push it, open the PR with `gh pr create`. Never try to push to `main`.
2. **Never run `terraform apply` or `terraform destroy` in `terraform/envs/dev`.**
   The pipeline applies after Leo approves the `dev` environment. You may run
   `terraform init`, `fmt`, `validate` and `plan`.
3. **Never touch `bootstrap/` state** (`apply`, `destroy`, `import`, `state` commands,
   `-migrate-state`) unless Leo explicitly asks in this session, and show him the
   plan first.
4. **Never approve deployments, merge PRs, or change repo settings, rulesets,
   variables or GCP IAM** unless Leo explicitly asks. Approving `dev` is always his.
5. **Secrets:** passwords come from `random_password` and live in Secret Manager.
   Never print them, never write them to files, never put them in tfvars or commits.
6. **Costs:** the budget is 10 EUR/month. Before proposing a change that adds cost,
   say what it costs per month. Reference: `db-f1-micro` ≈ 9–14 USD/month,
   `db-custom-2-7680` ≈ 99 USD/month, REGIONAL (HA) doubles the cost.
7. **Read every plan.** Stop and tell Leo if a plan says `must be replaced`
   (instance recreated, data lost) or destroys anything he didn't ask to remove.
   Changes that restart the instance: `tier`, most `database_flags`, `activation_policy`.
   Changes that replace it: `name`, `disk_type`, `region`.

## Before every push

```powershell
terraform fmt -recursive terraform bootstrap
cd terraform\envs\dev
terraform init -input=false
terraform validate
terraform plan -var-file="dev.tfvars" -input=false
cd ..\..\..
git status
```

If providers change, refresh the lock file for both platforms (the pipeline runs
`init -lockfile=readonly` on Linux):

```powershell
terraform providers lock -platform=windows_amd64 -platform=linux_amd64
```

## Branches, commits, PRs

- Branch names: `dev-<what>` for dev settings, `ci-<what>` for workflows,
  `bootstrap-<what>`, `docs-<what>`, `ansible-<what>`.
- Commit messages: `<area>: <what changed>` — e.g. `dev: enable slow query log`.
- One change per PR. PR description: what, why, expected plan summary, cost impact.
- After opening a PR: `gh pr checks --watch`, then read the plan comment and
  summarise it for Leo. Leave the merge to him unless he says otherwise.

## Environment (Windows laptop)

- Repo clone: `D:\github-repos\infrastructure`. Shell: PowerShell.
- Logged in: `gcloud` (user + application-default credentials) and `gh` as `leobrule`.
- Tools: Terraform 1.16.x, gcloud, git, gh, pre-commit.
- Known issue: Windows application control once blocked the Google provider
  executable in `.terraform\providers`. If `init`/`plan` fails with
  "An Application Control policy has blocked this file", stop and tell Leo;
  do not try to work around it. srv-iac (Ubuntu VM) is the fallback.

## VMs (Oracle VirtualBox on the laptop)

`VBoxManage` is on Leo's user PATH (`C:\Program Files\Oracle\VirtualBox`).
If it isn't found, use the full path: `& "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"`.

| VirtualBox name | Role in this project | Notes |
| --- | --- | --- |
| `UbuntuTerraformAnsible` | **srv-iac**: Ubuntu 26.04, runs Ansible (Phases 6–7) | Terraform, gcloud, gh, Ansible installed. SSH: `ssh srv-iac` |
| `UbuntuPostgreSQL` | **srv-mon**: monitoring VM with the Postgres metrics repository (Phase 9) | SSH: `ssh srv-mon` |
| `UbuntuMySQL` | Not part of the plan | Leo's own lab VM |
| `Win22MongoDB` | Not part of the plan | Leo's own lab VM |

Both hostnames resolve through the Windows hosts file
(`C:\Windows\System32\drivers\etc\hosts`). Use the hostname, never a hard-coded IP.

```powershell
VBoxManage list vms                                         # all VMs
VBoxManage list runningvms                                  # running now
VBoxManage startvm "UbuntuTerraformAnsible" --type headless # start, no window
VBoxManage controlvm "UbuntuTerraformAnsible" acpipowerbutton  # clean shutdown
VBoxManage showvminfo "UbuntuTerraformAnsible" --machinereadable | Select-String VMState
```

Rules for VMs:
- Start or stop a VM only when Leo asks. Never touch the two lab VMs (`UbuntuMySQL`, `Win22MongoDB`) unless he names them.
- Shut down with `acpipowerbutton` (clean). Use `controlvm <name> poweroff` only if
  Leo agrees, after a clean shutdown hasn't worked within 2 minutes.
- Never delete, unregister, snapshot-restore or reconfigure a VM (`unregistervm`,
  `modifyvm`, `snapshot ... restore`) without Leo's explicit request.
- After starting a VM, wait until it answers on SSH before running anything on it:
  `ssh -o ConnectTimeout=5 srv-iac "uptime"` (retry every 15 s, give up after 3 minutes and tell Leo).
- On the VMs, only run what the task needs. No package upgrades, reboots or service
  changes unless Leo asks.

## End of every session

Add an entry at the top of `docs/session-log.md` (date, phase, what was done,
PRs, open items) and include it in the session's PR, or in a small `docs-` PR.
Leo uses it to update the project plan in claude.ai.
