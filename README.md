# POC of Bash and Docker Automation (`poc-bash-docker-automation`)

Proof of concept dummy project for automated deployment using Bash, SSH key authentication, Docker container execution, Vite frontend builds, and passwordless sudo service reloads.

## 📁 Project Structure

```
poc-bash-docker-automation/
├── backend/
│   └── server.py             # Lightweight HTTP API & static asset server
├── frontend/
│   ├── package.json          # Frontend build configuration
│   ├── package-lock.json     # Lockfile for reproducible npm ci builds
│   ├── vite.config.js        # Vite bundler configuration
│   ├── index.html            # Web dashboard interface
│   └── src/
│       ├── main.js           # Live API check & UI logic
│       └── style.css         # Modern responsive styling
├── systemd/
│   └── dummy-app.service     # Systemd service unit for systemctl management
├── deploy                    # Automated Bash deployment pipeline script
├── setup-container.sh        # Container provisioning & environment setup script
├── .gitignore
└── README.md
```

## 🛠️ Architecture & Implemented Plan

| Step | Requirement | Implementation | Status |
|---|---|---|---|
| **1** | **Bash Script** | `./deploy <branch> <ssh-host>` (e.g. `./deploy feat/db-health-check @ubuntu`) | ✅ Verified |
| **2** | **Configure SSH** | SSH key auth & `Host ubuntu` alias in `~/.ssh/config` without password prompt | ✅ Verified |
| **3** | **Connect to Server** | SSH session connecting to server, executing into container via `docker exec -i -u ubuntu` | ✅ Verified |
| **4** | **Git Operations** | `cd /app && git checkout <BRANCH> && git pull origin <BRANCH>` | ✅ Verified |
| **5** | **Build Frontend** | `cd /app/frontend && npm ci && npm run build` producing `/app/frontend/dist` | ✅ Verified |
| **6** | **Passwordless Sudo** | Restricted `/etc/sudoers.d/deploy-service` rule allowing only `systemctl` for `dummy-app.service` | ✅ Verified |
| **7** | **Restart Service** | `sudo -n systemctl restart dummy-app.service` & verified with `systemctl status` + `curl /api/health` | ✅ Verified |

---

## 🚀 How to Run the POC

### 1. Ensure the Target Container is Running
```bash
./setup-container.sh
```

### 2. Run Automated Deployment
Deploy feature branch `feat/db-health-check`:
```bash
./deploy feat/db-health-check @ubuntu
```

Deploy main branch `main`:
```bash
./deploy main @ubuntu
```

---

## 🔒 Security: Restricted Passwordless Sudo Rule

Located inside the container at `/etc/sudoers.d/deploy-service`:
```sudoers
# Restricted sudoers rule allowing only systemctl commands for dummy-app.service
ubuntu ALL=(ALL) NOPASSWD: /bin/systemctl restart dummy-app.service*, /usr/bin/systemctl restart dummy-app.service*, /bin/systemctl status dummy-app.service*, /usr/bin/systemctl status dummy-app.service*, /bin/systemctl is-active dummy-app.service*, /usr/bin/systemctl is-active dummy-app.service*
```
- Validated via `visudo -cf /etc/sudoers.d/deploy-service`.
- Allows `sudo -n systemctl restart dummy-app.service` without password.
- Blocks any other service or unauthorized command (prompts for password / denied).

---

## 🔑 SSH Configuration

Configured in `~/.ssh/config`:
```sshconfig
Host ubuntu
    HostName 127.0.0.1
    User deepak
    IdentityFile ~/.ssh/id_rsa
    StrictHostKeyChecking accept-new
```
Enables daily zero-password connections for the deployment pipeline:
```bash
ssh ubuntu "echo OK"
```

---

## 📦 GitHub Repository Setup

To push to GitHub under `deepakkushwaha9821`:
```bash
git remote add origin https://github.com/deepakkushwaha9821/poc-bash-docker-automation.git
git push -u origin main
git push -u origin feat/db-health-check
```
*(or via SSH: `git remote add origin git@github.com:deepakkushwaha9821/poc-bash-docker-automation.git`)*

