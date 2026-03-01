# NixOS Config Backup & Recovery

A simple pair of shell scripts to back up and restore your NixOS configuration files (`configuration.nix` and `hardware-configuration.nix`).

---

## 📁 Directory Structure

```
./
├── nixos-backup.sh       ← backup tool
├── nixos-recovery.sh     ← recovery tool
├── README.md             ← this file
└── backups/              ← created automatically on first backup
    ├── 1_14-30-00_01-03-2026/
    │   ├── configuration.nix
    │   └── hardware-configuration.nix
    ├── 2_15-45-12_01-03-2026/
    │   ├── configuration.nix
    │   ├── hardware-configuration.nix
    │   └── README.md     ← present only when -m flag was used
    └── ...
```

---

## ⚙️ Setup

Make both scripts executable:

```bash
chmod +x nixos-backup.sh nixos-recovery.sh
```

---

## 🗂️ nixos-backup.sh

Backs up `/etc/nixos/configuration.nix` and `/etc/nixos/hardware-configuration.nix` into a numbered, timestamped folder inside `./backups/`.

### Usage

```bash
./nixos-backup.sh
```
Creates a plain backup folder with both files.

```bash
./nixos-backup.sh -m "my message"
```
Creates the same backup folder but also adds a `README.md` inside it containing your message.

### Output

Each backup is stored as:
```
./backups/<num>_<HH-MM-SS>_<DD-MM-YYYY>/
├── configuration.nix
├── hardware-configuration.nix
└── README.md              ← only when -m is used
```

The `<num>` prefix auto-increments with every backup (1, 2, 3, ...).

### Examples

```bash
./nixos-backup.sh
# → ./backups/1_14-30-00_01-03-2026/

./nixos-backup.sh -m "added hyprland"
# → ./backups/2_15-00-00_01-03-2026/
#   └── README.md contains: "added hyprland"

./nixos-backup.sh -m "broke everything, reverting soon"
# → ./backups/3_16-22-41_01-03-2026/
```

---

## 🔁 nixos-recovery.sh

Restores backed-up config files back to `/etc/nixos/`. Requires `sudo` for the actual restore since it writes to a root-owned directory.

> **Safety:** Before overwriting any file, the script automatically saves the current live file as a `.bak_<timestamp>` alongside it in `/etc/nixos/` so you never lose what was there.

### Usage

| Command | Description |
|---|---|
| `./nixos-recovery.sh` | Interactive mode — lists backups, prompts you to pick |
| `./nixos-recovery.sh -l` | List all available backups |
| `./nixos-recovery.sh -p <num>` | Preview a colour diff of backup vs current files |
| `sudo ./nixos-recovery.sh -r <num>` | Restore both files from backup `<num>` |
| `sudo ./nixos-recovery.sh -r <num> -f config` | Restore only `configuration.nix` |
| `sudo ./nixos-recovery.sh -r <num> -f hardware` | Restore only `hardware-configuration.nix` |
| `./nixos-recovery.sh -d <num>` | Delete backup `<num>` (asks for confirmation) |

### Examples

```bash
# See all backups
./nixos-recovery.sh -l

# Preview what changed between backup 3 and your current config
./nixos-recovery.sh -p 3

# Restore everything from backup 2
sudo ./nixos-recovery.sh -r 2

# Only restore configuration.nix from backup 5
sudo ./nixos-recovery.sh -r 5 -f config

# Only restore hardware-configuration.nix from backup 1
sudo ./nixos-recovery.sh -r 1 -f hardware

# Delete backup 4 (prompts for confirmation)
./nixos-recovery.sh -d 4

# Interactive mode (no flags)
./nixos-recovery.sh
```

### After restoring

Always rebuild your NixOS system after a restore:

```bash
sudo nixos-rebuild switch
```

---

## 💡 Tips

- Run a backup **before** making changes to your config — treat it like a commit.
- Use `-m` with a short description so you remember what each backup was for, just like a git commit message.
- Use `-p <num>` to preview diffs before restoring so you know exactly what you're rolling back to.
- Backups are just plain folders — you can open, read, or copy files out of them manually at any time.
- The `./backups/` folder is safe to version control with git if you want an extra layer of history.
