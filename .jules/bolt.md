## 2026-04-22 - [Optimizing Shell-based User Provisioning]
**Learning:** Significant performance gains in container entrypoint scripts can be achieved by batching operations like `chpasswd` and replacing external command forks (`cut`, `tr`, `printf` in pipes) with native shell parameter expansion. Process forks are particularly expensive in high-density container environments.
**Action:** Always look for loops calling external binaries. Prefer `${var%%:*}` over `cut` and batch inputs to commands that support it.

## 2026-04-22 - [Dante Performance Tuning]
**Learning:** Dante (sockd) has a very low default `internal.backlog` (5), which can cause connection drops under load. Additionally, `libwrap` (TCP wrappers) adds overhead for every connection.
**Action:** Set `internal.backlog: 1024` and `libwrap: no` for better throughput and burst handling in Dante configurations.
