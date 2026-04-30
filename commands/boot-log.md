# /boot-log - Boot Analysis

Analyze the boot process for issues:

```bash
echo "=== BOOT TIME ==="
systemd-analyze

echo -e "\n=== SLOW UNITS ==="
systemd-analyze blame | head -15

echo -e "\n=== CRITICAL CHAIN ==="
systemd-analyze critical-chain --no-pager

echo -e "\n=== BOOT ERRORS ==="
journalctl -b -p err --no-pager | head -30
```

Identify any slow services or errors during boot that may indicate problems.
