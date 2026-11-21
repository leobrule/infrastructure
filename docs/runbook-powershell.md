# Runbook — everyday commands (PowerShell)

For working in `D:\github-repos\infrastructure` by hand. `main` is protected:
every change is branch → PR → `terraform-plan` → merge → approve `dev` → apply.

## Start of a session

```powershell
cd D:\github-repos\infrastructure
git switch main
git pull
git status            # should be clean
```

## Change a Cloud SQL setting

```powershell
git switch -c dev-<what>                 # e.g. dev-slow-log
# edit terraform\envs\dev\dev.tfvars
terraform fmt -recursive terraform
git add terraform/envs/dev/dev.tfvars
git commit -m "dev: <what changed>"
git push -u origin dev-<what>
gh pr create --fill --base main
gh pr checks --watch
gh pr view --web                         # read the plan comment
```

In the plan comment check:

- `Plan: 0 to add, 1 to change, 0 to destroy` (or what you expect)
- **no** `must be replaced` — that means the instance is recreated and data is lost

Then:

```powershell
gh pr merge --squash --delete-branch
gh run list --workflow terraform-apply.yml --limit 1
gh run view --web                        # Review deployments → dev → Approve and deploy
git switch main
git pull
git branch -d dev-<what>
```

| Change | Effect |
| --- | --- |
| `tier`, most `database_flags`, `activation_policy` | Instance restarts (a few minutes) |
| `name`, `disk_type`, `region` | Instance **replaced** — data lost |
| `maintenance_*`, `backup_*`, `retained_backups`, `databases` | Online, no restart |

## Check the instance

```powershell
gcloud sql instances list
gcloud sql instances describe mysql-dev --format="value(settings.tier,state)"
```

## Connect with the Auth Proxy

```powershell
.\cloud-sql-proxy.exe --port 3306 mysqlproject-501213:europe-west1:mysql-dev
# second window:
gcloud secrets versions access latest --secret=mysql-dev-dbadmin-password
mysql -h 127.0.0.1 -P 3306 -u dbadmin -p
```

## Recreate or destroy the instance

```powershell
gh workflow run terraform-apply.yml                       # recreate from main
gh workflow run terraform-destroy.yml -f confirm=destroy  # destroy
gh run view --web                                         # approve dev in both cases
```

The name `mysql-dev` can't be reused for about a week after a destroy.

## Bootstrap (rare, local only)

Only when the pipeline's own permissions change (new role for `tf-deployer`,
another repo in WIF, a new API). Never through the pipeline.

```powershell
cd D:\github-repos\infrastructure\bootstrap
terraform init
terraform plan
terraform apply
```

The `bootstrap/` code change itself still goes through a PR.

## When something fails

| Symptom | Fix |
| --- | --- |
| `git push` to `main` rejected | Expected — use a branch and PR |
| `terraform-plan` ❌ on fmt | `terraform fmt -recursive terraform`, commit, push |
| `init -lockfile=readonly` fails in Actions | `terraform providers lock -platform=windows_amd64 -platform=linux_amd64`, commit the lock file |
| "Application Control policy has blocked this file" | Windows blocked a provider exe; fix on the laptop or use srv-iac |
| Apply waiting forever | Approve the `dev` environment on the run page |

## End of a session

Add an entry to `docs/session-log.md` (template at its top), then commit it in
the session's PR or a small `docs-<date>` PR.
