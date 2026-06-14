# Ansible: server hardening

`harden.yml` is the baseline I apply to a fleet before anything runs on it. It is
the manual first-hour security checklist, codified and idempotent, so every box
across staging and prod lands in the same known-good state.

## What it does

- Creates a non-root sudo admin user and installs an SSH public key
- Locks down SSH: no root login, no password auth, configurable port
- Brings up a default-deny firewall (UFW on Debian/Ubuntu, firewalld on RHEL/AlmaLinux)
- Installs and enables fail2ban
- Turns on automatic security updates (unattended-upgrades or dnf-automatic)
- Sets the timezone

It detects `apt` vs `dnf` and branches, so the same playbook hardens both families.

## Run it

The example inventory is a small estate: a web fleet plus database nodes, split
across `staging` and `prod`. Harden everything at once, or scope it.

```bash
cp inventory.example.ini inventory.ini
cp group_vars/all.example.yml group_vars/all.yml
ansible-galaxy collection install community.general ansible.posix

ansible-playbook -i inventory.ini harden.yml                 # whole fleet
ansible-playbook -i inventory.ini harden.yml --limit web     # web tier only
ansible-playbook -i inventory.ini harden.yml --limit staging # staging first
ansible-playbook -i inventory.ini harden.yml --check --diff  # dry run
```

The first run connects as `root`. After it completes, root SSH is closed and you
log in as the admin user on the configured port. Re-run it any time a host drifts.

## Roadmap

- `lemp.yml`, Nginx with PHP-FPM, MariaDB and WordPress
- turn the hardening into a reusable role with molecule tests
