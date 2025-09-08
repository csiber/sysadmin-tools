# Sysadmin Tools

A collection of **practical scripts and utilities** I use in my daily homelab and sysadmin work.  
These are lightweight, no-nonsense tools designed to automate routine maintenance, backups, and monitoring tasks.  

I treat my homelab as a production-like environment — services run 24/7, data integrity matters, and downtime is unacceptable.  
That mindset is reflected in the way I write and use these tools: **reliable, minimal, and focused**.

---

## ✨ Included Scripts

### 🔄 `backup.sh`
- Rsync-based backup for Docker volumes and application data
- Logs with timestamps for auditability
- Designed for daily cron execution

### 🐳 `docker-cleanup.sh`
- Cleans up unused containers, volumes, and networks
- Ensures disk space is reclaimed regularly
- Runs unattended, safe with `--volumes`

### 📡 `uptime-checker.sh`
- Simple health check for critical services (HTTP/HTTPS endpoints)
- Logs outages, can be extended to send alerts (email/Discord/webhook)
- Ideal for keeping internal apps accountable

### 🌐 `cloudflare-ddns.sh`
- Updates Cloudflare DNS records with current WAN IP
- Replaces the need for insecure port forwarding
- Keeps remote access stable even on dynamic IP connections

### 📊 `monitor.sh`
- Quick system health overview (CPU load, RAM usage, disk space)
- Runs on-demand or via cron, outputs to log for historic data
- Lightweight alternative to heavy monitoring stacks

---

## 🛠️ Philosophy

- **Keep it simple** – minimal dependencies, runs on any Linux box  
- **Automate the boring stuff** – routine tasks should never be manual  
- **Logs or it didn’t happen** – every script writes logs with timestamps  
- **Secure by default** – no plaintext secrets, prefer environment variables  

---

## 🚀 Roadmap

- [ ] Add PowerShell equivalents for Windows environments  
- [ ] Introduce Python-based versions for extensibility (API calls, JSON parsing)  
- [ ] Create systemd unit files for auto-scheduling  
- [ ] Expand with homelab-specific monitoring (Unraid, Unifi API integration)  

---

## 📂 Repository Structure

