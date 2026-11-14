# infrastructure

Terraform + Ansible for the training project. This first version deploys the
cheapest possible **Cloud SQL for MySQL** instance in `mysqlproject-501213`
and changes its settings through pull requests.

```
bootstrap/                      # state bucket, deploy SA, WIF — applied once, locally
terraform/
  modules/cloudsql-mysql/       # instance, databases, admin user, passwords in Secret Manager
  envs/dev/                     # backend + module call; dev.tfvars holds the settings
.github/workflows/
  terraform-plan.yml            # PR: fmt, tflint, checkov, validate, plan -> PR comment
  terraform-apply.yml           # merge to main: plan + apply after "dev" environment approval
  terraform-destroy.yml         # manual, type "destroy"
ansible/                        # Phase 6
docs/adr/
```

## What gets deployed

| Setting | Value | Why |
| --- | --- | --- |
| Engine | MySQL 8.4 (`MYSQL_8_4`) | Current LTS; 8.0 starts paid extended support on 2027-01-01 |
| Edition | `ENTERPRISE` | Set explicitly: for 8.4 the API defaults to Enterprise Plus |
| Tier | `db-f1-micro` | Cheapest: shared core, 0.6 GB RAM (no SLA) |
| Availability | `ZONAL` | HA would double the cost |
| Disk | 10 GB `PD_HDD`, no autoresize | Cheapest storage; type can't be changed later |
| Network | Public IP, no authorized networks, `connector_enforcement = REQUIRED` | Only the Cloud SQL Auth Proxy can connect |
| Backups | Daily at 02:00 UTC, keep 7 | |
| Passwords | `random_password` → Secret Manager (`mysql-dev-root-password`, `mysql-dev-dbadmin-password`) | Nothing secret in Git |

Rough cost: about 8 USD/month for the instance (us-central1 list price; europe-west1 is a little higher) plus ~1–2 USD for disk and backups.
That is close to the 10 EUR budget. Set `activation_policy = "NEVER"` in `dev.tfvars` to stop the instance when you're not using it. Storage is still billed while it's stopped.

## First-time setup (Windows laptop, PowerShell)

### 1. Create the repo and push

```powershell
cd $HOME\source          # or wherever you keep repos
gh repo create leobrule/infrastructure --public --clone
cd infrastructure
# copy the contents of this folder here, then:
git add .
git commit -m "Initial Terraform: bootstrap, cloudsql-mysql module, dev env, workflows"
git push -u origin main
```

`main` isn't protected yet, so this first push goes straight in.

### 2. Apply bootstrap (local state)

```powershell
gcloud config set project mysqlproject-501213
cd bootstrap
terraform init
terraform plan
terraform apply
terraform output
```

Keep `bootstrap\terraform.tfstate` safe (it's git-ignored). Optionally move it to the bucket afterwards. Uncomment the `backend "gcs"` block in `bootstrap/versions.tf`, then run `terraform init -migrate-state`.

### 3. Give GitHub the WIF values (they're not secrets)

```powershell
gh variable set GCP_WIF_PROVIDER --body (terraform output -raw workload_identity_provider)
gh variable set GCP_SA_EMAIL     --body (terraform output -raw deployer_service_account)
cd ..
```

### 4. Create the `dev` environment with yourself as approver

GitHub → repo **Settings → Environments → New environment** → `dev` → tick **Required reviewers**, add `leobrule` → Save.
Leave "Prevent self-review" off so you can approve your own deployments.

### 5. Lock providers for both Windows and Linux, then first apply locally

The pipeline runs `init -lockfile=readonly`, so the lock file must contain hashes for the Linux runner too.

```powershell
cd terraform\envs\dev
terraform init
terraform providers lock -platform=windows_amd64 -platform=linux_amd64
terraform plan  -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars      # ~10-15 min for a new instance
cd ..\..\..
git add terraform/envs/dev/.terraform.lock.hcl
git commit -m "Add provider lock file"
git push
```

(Pushing the lock file triggers `terraform-apply`. It waits for your approval, and once approved it should report "No changes".)

### 6. Check the connection through the Auth Proxy

```powershell
# download cloud-sql-proxy.exe from https://github.com/GoogleCloudPlatform/cloud-sql-proxy/releases
.\cloud-sql-proxy.exe --port 3306 mysqlproject-501213:europe-west1:mysql-dev
# in another window:
gcloud secrets versions access latest --secret=mysql-dev-dbadmin-password
mysql -h 127.0.0.1 -P 3306 -u dbadmin -p
```

No MySQL client on the laptop? Run the same from srv-iac. On Ubuntu use the Linux proxy binary and `sudo apt install mysql-client`.

### 7. Protect `main`

GitHub → **Settings → Rules → Rulesets → New branch ruleset**:

- Target: default branch
- Enable: **Require a pull request before merging** (required approvals: **0** — GitHub doesn't let you approve your own PR)
- Enable: **Require status checks to pass** → add `terraform-plan`
- Enable: **Block force pushes**, **Restrict deletions**

From now on every change goes through a PR.

## Changing settings through a PR

```powershell
git switch -c enable-slow-log
# edit terraform/envs/dev/dev.tfvars, e.g.
#   database_flags = { slow_query_log = "on", long_query_time = "2" }
terraform fmt -recursive terraform
git commit -am "dev: enable slow query log"
git push -u origin enable-slow-log
gh pr create --fill
```

1. `terraform-plan` runs and comments the plan on the PR, for example `Plan: 0 to add, 1 to change, 0 to destroy`.
2. Read it. Watch for **`must be replaced`**: that means the instance would be recreated and its data lost.
3. Merge. Then `terraform-apply` waits at the `dev` environment. Approve it under **Actions → the run → Review deployments**.
4. The apply re-plans against current state and applies that plan.

Good first PRs to try: `maintenance_hour`, `retained_backups`, `database_flags`, `query_insights_enabled`, adding a database to `databases`, or `activation_policy = "NEVER"` to stop the instance.

Changes that **restart** the instance: `tier`, most `database_flags`, `activation_policy`.
Changes that **replace** it: `name`, `disk_type`, `region`.

## Notes

- The repo is public, so plan comments and Action logs are public. Sensitive values (passwords) show as `(sensitive value)`. Instance names and IPs are visible.
- Only workflows from `leobrule/infrastructure` can impersonate `tf-deployer` (WIF `attribute_condition`). Fork PRs get no OIDC token and the plan job is skipped for them.
- Checkov runs in report-only mode (`--soft-fail`). Read its findings, then decide which ones to fix or suppress.
