# /network-check - Network Connectivity Check

Run a quick network connectivity check:

```bash
echo "=== INTERFACES ==="
ip -br addr

echo -e "\n=== GATEWAY ==="
ip route | grep default

echo -e "\n=== DNS ==="
cat /etc/resolv.conf | grep nameserver

echo -e "\n=== CONNECTIVITY TEST ==="
ping -c 2 8.8.8.8 2>&1 || echo "No IP connectivity"
ping -c 2 google.com 2>&1 || echo "DNS resolution failed"
```

Summarize the network status and identify any issues.
