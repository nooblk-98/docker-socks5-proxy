## 2026-04-25 - [Dante Optimization Patterns]
**Learning:** Dante's performance in high-throughput SOCKS5 environments is significantly improved by increasing the listener's `backlog` and disabling `libwrap` checks in the rules. The `backlog` prevents connection drops during bursts, while disabling `libwrap` reduces per-connection CPU overhead and latency.
**Action:** Always tune `internal.backlog` and set `libwrap: no` in `danted.conf` for production-ready Dante deployments.
