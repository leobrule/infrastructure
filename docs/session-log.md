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

## 2026-11-21 — Phase 3 — bootstrap state migrated to GCS

- Done: backed up `bootstrap/terraform.tfstate` to
  `Downloads\bootstrap-terraform.tfstate.2026-11-21.bak`; ran
  `terraform init -migrate-state` in `bootstrap/`. State is now at
  `gs://mysqlproject-501213-tfstate/bootstrap/default.tfstate` (16 resources).
  `terraform plan` in bootstrap: No changes. Old local `terraform.tfstate*`
  moved to Downloads (`bootstrap-terraform.tfstate*`).
- PRs: `bootstrap: store state in GCS (prefix bootstrap)` — open
  (also adds `CLAUDE.md`, this log, `docs/runbook-powershell.md`).
- Plan result: bootstrap 0/0/0; pipeline plan for `envs/dev` see PR comment.
- Cost impact: none (one small object in the existing bucket).
- Open: merge the PR; delete the Downloads backups once comfortable;
  Phase 6 (Ansible) postponed.

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
