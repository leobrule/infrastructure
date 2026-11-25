# ansible

In-database configuration for Cloud SQL `mysql-dev`. Terraform builds the
instance, the `training` database and the `dbadmin` user; Ansible creates the
application databases and users listed in
`inventory/group_vars/cloudsql_mysql/app_databases.yml` and grants their access.

```
ansible/
  ansible.cfg
  requirements.yml                      # ansible.mysql collection
  inventory/
    dev.yml                             # mysql-dev: connection name, proxy port, admin secret
    group_vars/cloudsql_mysql/
      app_databases.yml                 # <- edit this: databases, users, access level
  roles/mysql_app_db/                   # create databases, users, grants; passwords in Secret Manager
  playbooks/mysql-app-db.yml
```

## What it creates

| Object | Access | Password |
| --- | --- | --- |
| Database `appdb` (utf8mb4) | — | — |
| User `appdb_admin@%` | `ALL PRIVILEGES` on `appdb.*` (create, alter, drop tables, DML) | Secret Manager `mysql-dev-appdb_admin-password` |
| User `appdb_rw@%` | `SELECT, INSERT, UPDATE, DELETE, EXECUTE, CREATE TEMPORARY TABLES` on `appdb.*` | Secret Manager `mysql-dev-appdb_rw-password` |

Neither user has rights outside `appdb`. Passwords are generated on the first
run, stored in Secret Manager and only read on later runs, so reruns change nothing.

## How it connects

Cloud SQL has no SSH and the instance only accepts the Auth Proxy
(`connector_enforcement = REQUIRED`). So Ansible runs on srv-iac against
`localhost`, and the `ansible.mysql` modules connect to the Cloud SQL Auth
Proxy on `127.0.0.1:3306`, logging in as `dbadmin` with the password read from
Secret Manager. The first tasks of the role double as the Auth Proxy check.

## One-time setup on srv-iac

```bash
# MySQL client library for the modules, and the mysql CLI for manual checks
sudo apt install -y python3-pymysql mysql-client

# Cloud SQL Auth Proxy (v2.28.0 is the latest release as of 23 Nov 2026)
curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.28.0/cloud-sql-proxy.linux.amd64
chmod +x cloud-sql-proxy && sudo mv cloud-sql-proxy /usr/local/bin/

# The collection (into ansible/collections, ignored by Git)
cd ~/infrastructure/ansible
ansible-galaxy collection install -r requirements.yml -p collections
```

Your gcloud login on srv-iac (`gcloud auth login` and
`gcloud auth application-default login`) needs: Cloud SQL Client (proxy),
Secret Manager Secret Accessor (read passwords) and Secret Manager Admin
(create the new user secrets the first time). Project Owner covers all three.

## Run it

1. `mysql-dev` must be running. If it was destroyed, deploy it again through a
   PR (`activation_policy = "ALWAYS"` in `dev.tfvars`), merge, approve `dev`.
2. Terminal 1 on srv-iac — start the proxy and leave it running:
   ```bash
   cloud-sql-proxy mysqlproject-501213:europe-west1:mysql-dev --port 3306
   ```
3. Terminal 2 on srv-iac:
   ```bash
   cd ~/infrastructure/ansible
   git pull
   ansible-playbook playbooks/mysql-app-db.yml --check --diff   # dry run
   ansible-playbook playbooks/mysql-app-db.yml                  # apply
   ```
   The last task prints `SHOW GRANTS` for each user. A second run should end
   with `changed=0`.
4. Try a user by hand (the password is read into a variable, not printed):
   ```bash
   MYSQL_PWD=$(gcloud secrets versions access latest --secret=mysql-dev-appdb_rw-password) \
     mysql -h 127.0.0.1 -P 3306 -u appdb_rw appdb -e "SELECT CURRENT_USER(); SHOW GRANTS;"
   ```
5. Stop the proxy with Ctrl+C when you're done.

## Add or change a database or user

Edit `inventory/group_vars/cloudsql_mysql/app_databases.yml` on an
`ansible-<what>` branch, open a PR, merge, then rerun the playbook. `access` is
`admin`, `write` or `read` (defined in `roles/mysql_app_db/defaults/main.yml`).
Changing a user's `access` replaces its grants on that database.

Don't also list an Ansible database in `dev.tfvars` `databases`: one tool owns each object.

## Notes

- `terraform destroy` removes the databases and users, but not the Secret
  Manager secrets Ansible created (Terraform doesn't know them). A new instance
  plus a rerun reuses the same passwords. To remove them:
  `gcloud secrets delete mysql-dev-appdb_admin-password` (and `..._appdb_rw-password`).
- `community.mysql` is deprecated; its modules moved unchanged to `ansible.mysql`.
- Lint: `ansible-lint playbooks/mysql-app-db.yml` (passes the `production` profile).
