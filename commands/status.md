# /status - Quick System Status

Provide a rapid system health overview by running these commands and presenting a summary:

```bash
# System state
echo "=== SYSTEM STATE ==="
systemctl is-system-running

# Failed services
echo -e "\n=== FAILED SERVICES ==="
systemctl --failed --no-pager

# Disk usage
echo -e "\n=== DISK USAGE ==="
df -h / /home /boot 2>/dev/null

# Memory
echo -e "\n=== MEMORY ==="
free -h

# Load average
echo -e "\n=== LOAD ==="
uptime

# Recent errors (last 10)
echo -e "\n=== RECENT ERRORS ==="
journalctl -p err -b --no-pager -n 10
```

Present the output in a clear, organized format highlighting any issues.
