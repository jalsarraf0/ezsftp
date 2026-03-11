
[![Regression CI](https://github.com/jalsarraf0/ezsftp/actions/workflows/ci.yml/badge.svg)](https://github.com/jalsarraf0/ezsftp/actions/workflows/ci.yml)
[![Security CI](https://github.com/jalsarraf0/ezsftp/actions/workflows/security.yml/badge.svg)](https://github.com/jalsarraf0/ezsftp/actions/workflows/security.yml)

# 📦 Chroot-SFTP User Manager v1.5

Provision and manage **chrooted SFTP-only users** with ease. This script supports **DRY-RUN** mode for safely previewing changes and automates all required configurations:

- 🧑‍💻 User & group management  
- 📁 Chroot directory setup  
- 🔑 SSH key generation (OpenSSH & PuTTY)  
- 📄 FSTAB bind mounts  
- 🔧 SSH daemon configuration  
- 🔄 Automatic `sshd` reload  

---

## 🚀 Features

- ✅ **Idempotent Design** – Safe to run multiple times; prevents duplicate configurations.  
- 🔐 **Secure Defaults** – Proper directory permissions and SSH key-based authentication.  
- 📄 **Automatic SSHD Config Management** – Creates per-user SSHD configuration fragments.  
- 📂 **Shared Directory Access** – Group-level read/write access to `/shared`.  
- 🧩 **DRY-RUN Mode** – Preview changes before applying them.  
- 📈 **PuTTY Key Export** – Automatically generates `.ppk` keys for Windows clients.  

---

## 📖 Usage

```bash
./ezsftp.sh [OPTIONS]
```

### Options

| Option            | Description             |
|-------------------|-------------------------|
| `-h`, `--help`    | Show help and exit.     |
| `-n`, `--dry-run` | Start in DRY-RUN mode.  |

💡 **Tip:** You can also enable DRY-RUN using an environment variable:

```bash
export DRY_RUN=1
```

---

## 📚 Interactive Menu

```
─── Chroot-SFTP User Manager v1.5 — MODE: [LIVE/DRY-RUN] ───
1) Add user
2) Remove user
3) Toggle dry-run
4) Help / man page
Q) Quit
```

---

## 📂 Directory Structure

| Path                  | Purpose                  |
|-----------------------|--------------------------|
| `/chroot/<user>`      | Chroot jail base         |
| `/shared`             | Shared group access area |
| `/root/created_keys`  | Stores generated SSH keys|

---

## 🛡️ Security Notes

- SSH access is **key-only**; password authentication is disabled.
- Users are jailed using `ChrootDirectory` for secure, restricted environments.
- TCP forwarding and X11 forwarding are **disabled** to limit potential abuse.
- DRY-RUN mode allows administrators to simulate changes before applying them.

---

## 📅 Changelog

- **v1.5**
  - ✅ Enhanced DRY-RUN mode with clear and colorized output.  
  - ✅ Automated PuTTY `.ppk` key generation for Windows users.  
  - ✅ Improved SSHD configuration management using per-user fragments.  
  - ✅ Interactive, colorized terminal menu for intuitive operation.  

---

## 📦 Example: Add a New SFTP User

1. Run the script:

```bash
./ezsftp.sh
```

2. From the menu, select:

```
1) Add user
```

3. Enter the desired username when prompted.

---

## 📦 Example: Remove an SFTP User

1. Run the script:

```bash
./ezsftp.sh
```

2. From the menu, select:

```
2) Remove user
```

3. Enter the username to remove.

---

## 📈 Visual Indicators

| Color  | Meaning        |
|--------|----------------|
| 🟢 Green  | LIVE mode      |
| 🟡 Yellow | DRY-RUN mode   |
| 🔴 Red    | Errors/Issues  |

---

## 👨‍💻 Author

**Jamal Al-Sarraf (Snake)**  
*Elegant system automation and secure user management.*

---

## 📢 Final Notes

- Ensure this script is run with **root privileges**.
- Compatible with modern Linux distributions using OpenSSH.
- Tested on Fedora 41/42 and RHEL-based systems.
- DRY-RUN is highly recommended before applying changes to production environments.

---

🎉 **Happy Automating!**

## Validation Status (2026-03-03)

- Regression status: PASS
- Commands validated:
  - `bash -n ezsftp.sh`
  - `DRY_RUN=1 bash ./ezsftp.sh --non-interactive --action add --user ciuser`
  - `DRY_RUN=1 bash ./ezsftp.sh --non-interactive --action remove --user ciuser`
- CI/CD status: all tests passed on `main` (`Regression CI` run `22643207499`, `Security CI` run `22643207493`, `Regression and Security` run `22643207490`).
- Security hygiene: PASS (no hardcoded secrets or private keys detected in tracked files).
