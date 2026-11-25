# Session log

One entry per working session, newest first. Written by Claude Code or by Leo
at the end of a session; read in claude.ai to update the project plan's
progress log. Keep each entry short.

Template:

```
## YYYY-MM-DD — Phase N — <one-line summary>
- Done: ...
- PRs: #n <title> (merged / open)
- Plan result: e.g. 0 to add, 1 to change, 0 to destroy
- Cost impact: none / +X USD/month
- Open: ...
```

---

## 2026-11-25 — Phases 4–5 — mysql_enabled on/off switch

- Done: `mysql_enabled` variable in `envs/dev` (default `true`); the module
  call has `count = var.mysql_enabled ? 1 : 0`, a `moved` block
  (`module.mysql` → `module.mysql[0]`) so a running instance is kept, and
  outputs use `one(module.mysql[*].…)` (null when off). Set `true` in
  `dev.tfvars`, so merging recreates `mysql-dev`. Runbook updated (switch is
  now the usual on/off; manual workflows kept for emergencies).
- PRs: #6 `ansible: create appdb with admin and read-write users` merged by
  Leo; `dev: add mysql_enabled on/off switch` (open).
- Plan result: 9 to add, 0 to change, 0 to destroy (instance absent since
  the 2026-11-21 destroy).
- Cost impact: `db-f1-micro` ≈ 9–14 USD/month while on; turn off after sessions.
- Risk: Cloud SQL blocks reusing a deleted instance name for up to a week
  (last destroy 2026-11-21 23:40 UTC). If the apply fails on the name, wait
  and rerun `terraform-apply`.
- Open: after the apply, run the Ansible playbook from srv-iac (Auth Proxy check).

## 2026-11-23 — Phase 6 — first Ansible playbook: appdb and its users

- Done: `ansible/` scaffold (ansible.cfg, inventory for `mysql-dev`, role
  `mysql_app_db`, playbook `mysql-app-db.yml`, README). Creates database
  `appdb`, user `appdb_admin` (ALL on `appdb.*`) and `appdb_rw` (DML on
  `appdb.*`); passwords generated once and stored in Secret Manager
  (`mysql-dev-appdb_admin-password`, `mysql-dev-appdb_rw-password`).
  Uses the `ansible.mysql` collection (`community.mysql` is deprecated).
- Tested in a sandbox against MySQL 8.0 with a stand-in for gcloud: dry run,
  first run (changed=4), rerun (changed=0), grants checked, `appdb_rw` can't
  CREATE TABLE, `appdb_admin` can. ansible-lint: production profile passes.
  Not yet run against Cloud SQL.
- PRs: `ansible: create appdb with admin and read-write users` (open).
- Plan result: no Terraform change (0/0/0 expected).
- Cost impact: none; 2 Secret Manager secrets (well under 0.01 USD/month).
- Open: deploy `mysql-dev`, start the Auth Proxy on srv-iac, run the playbook
  (also closes the Auth Proxy check). `mysql_enabled` switch still to do.

## 2026-11-21 — Phase 5 — dev tier back to db-f1-micro

- Done: PR #2 merged (no apply: `terraform-apply` only runs on `terraform/**`).
  `dev.tfvars` tier `db-custom-2-7680` → `db-f1-micro`.
- PRs: #3 `dev: set mysql-dev tier to db-f1-micro` — merged and applied.
- Plan result: 9 to add, 0 to change, 0 to destroy (`mysql-dev` recreated at
  `db-f1-micro`).
- Issue: the apply ran **without waiting for approval**: the `dev` environment
  had no protection rules (required reviewer missing). Fixed: Leo set as
  required reviewer on `dev` (self-review allowed; admin bypass and
  any-branch deploy left as they were).
- Then: `terraform-destroy` run (approved by Leo through the restored gate);
  `gcloud sql instances list` shows 0 instances.
- Cost impact: a few cents (instance up ~15 min); now none.
- Open: consider turning off admin bypass on `dev` and limiting deploys to
  `main`; Phase 6 (Ansible) postponed.

## 2026-11-21 — Phase 3 — bootstrap state migrated to GCS

- Done: backed up `bootstrap/terraform.tfstate` to
  `Downloads\bootstrap-terraform.tfstate.2026-11-21.bak`; ran
  `terraform init -migrate-state` in `bootstrap/`. State is now at
  `gs://mysqlproject-501213-tfstate/bootstrap/default.tfstate` (16 resources).
  `terraform plan` in bootstrap: No changes. Old local `terraform.tfstate*`
  moved to Downloads (`bootstrap-terraform.tfstate*`).
- PRs: #2 `bootstrap: store state in GCS (prefix bootstrap)` — merged
  (also adds `CLAUDE.md`, this log, `docs/runbook-powershell.md`).
- Plan result: bootstrap 0/0/0; pipeline plan for `envs/dev` see PR comment.
- Cost impact: none (one small object in the existing bucket).
- Open: delete the Downloads backups once comfortable.

## 2026-11-21 — Phase 3 — main protected, docs for Claude Code

- Done: ruleset `protect-main` created (PR required, `terraform-plan` check required,
  no force push, no deletion, no bypass). Added `CLAUDE.md`, this log and
  `docs/runbook-powershell.md`. `bootstrap/versions.tf` now has the GCS backend
  (prefix `bootstrap`); migration script prepared in Downloads.
- Open: run `terraform init -migrate-state` for bootstrap and merge its PR;
  Phase 6 (Ansible) postponed.

## 2026-11-14 to 2026-11-21 — Phases 4–5 — first deploy and PR flow proven

- Done: bootstrap applied from the laptop; repo variables `GCP_WIF_PROVIDER`,
  `GCP_SA_EMAIL` set; `dev` environment with Leo as required reviewer.
- PRs: #1 `dev: scale mysql-dev to 2 vCPU (db-custom-2-7680)` — merged and applied.
  Same PR fixed the tflint install step (install script URL returned 404).
- Then: `mysql-dev` destroyed to stop costs. Bootstrap kept.

## 2026-11-13 to 2026-11-14 — Phases 2–3 — repo created

- Done: wrote bootstrap, `cloudsql-mysql` module, `envs/dev`, plan/apply/destroy
  workflows; `gh repo create leobrule/infrastructure --public --source . --push`.
- Issue: Windows application control blocked the Google provider exe; fixed on the laptop.
