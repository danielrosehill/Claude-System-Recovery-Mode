# /failed - Failed Systemd Units

Show all failed systemd units and provide analysis:

```bash
systemctl --failed --no-pager
```

For each failed unit:
1. Show detailed status: `systemctl status <unit>`
2. Show recent logs: `journalctl -u <unit> -n 20`
3. Suggest how to fix or restart the unit
