# Postmortem 003: Bans did not block traffic to containers, and IPv6 visitors lost their address

- **Status:** resolved
- **Severity:** medium (a protection did not work, no evidence of compromise)
- **Duration:** the gap existed since the ban tool was installed; it was found and closed in one working session
- **Hosts:** `edge-vps` and `edge-vps-2` (public edge hosts that run the reverse proxy in Docker)

## Summary

The intrusion-prevention tool detected attackers, raised alerts and added them to a ban list, but the ban was never applied to traffic going to the reverse proxy. Separately, visitors arriving over IPv6 were all recorded with one internal address, so even a correct ban could not have identified them. Odd alerts for the host's own loopback address led to both findings. Both were fixed on both hosts and checked with tests that simulate a ban and measure the dropped packets.

## Impact

- Banned and community-listed addresses could still reach the service ports behind the reverse proxy.
- Attackers over IPv6 could not be banned at all, because they were recorded as one internal address.
- Per-client limits in the applications had the same blind spot: one noisy IPv6 client could count against every IPv6 user.
- No evidence of compromise: the scanner requests received "not found" or "forbidden" answers, and nothing sensitive was reachable.
- No data was lost and there was no outage.

## Timeline

Times are relative to the first odd alert.

| When | Event |
|------|-------|
| T+0 | Alerts arrive for the host's own loopback address: bursts of scanner-style requests, and no ban that ever took effect. |
| Later | Log analysis: about 7% of all requests are recorded with the loopback address, and fewer than 0.1% as IPv6, although the public names have IPv6 records. |
| Later | Test: a request over IPv4 is recorded with the real address. The same request over IPv6 is recorded with Docker's internal gateway address. |
| Later | Test: a harmless test address is banned for a few minutes. A connection from it to the reverse proxy still succeeds. |
| Later | The firewall chains of the ban tool show only a chain on the input hook. Traffic to containers takes the forward path after Docker's redirect, so that chain never sees it. |
| Later | Fix 1: the proxy's Docker network gets a private IPv6 range, after a rehearsal of the side effects of enabling IPv6 forwarding. |
| Later | Fix 2: a forward-hook chain is added to the ban tool, and made to survive restarts of the tool. |
| Later | A loop test sends a request every 10 seconds while the test address is banned for 60 seconds: answers, then blocked, then answers again, with the drop counter rising. |
| Later | Reboot tests confirm that the network changes persist on both hosts. |

## Root cause

Three conditions came together:

1. **The drop rule was on the wrong hook.** The ban tool attached its rule to the input hook, which only sees traffic addressed to the host itself. Docker redirects traffic for published ports before routing, so it reaches containers over the forward path.
2. **IPv6 connections lost their source address.** On an IPv4-only Docker network, Docker's built-in relay program accepts IPv6 connections to published ports and passes them on from its own side. The proxy then sees an internal address instead of the visitor's.
3. **Alerts looked like protection.** Detection and alerting worked and reached a phone, which hid the fact that enforcement did not.

## Detection

By chance: someone reviewed odd alerts. No automatic check tested whether a ban actually blocks traffic.

## Resolution

1. Before enabling IPv6 forwarding, set the network manager to keep accepting router advertisements. By default it stops accepting them once forwarding is on, and the IPv6 default route would expire. Rehearse it by switching forwarding on by hand and checking that the route survives.
2. Back up, then recreate the proxy's Docker network with a private IPv6 range, using a script that undoes the change by itself if a step fails.
3. Add the forward-hook chain to the ban tool, and make it survive restarts of the tool.
4. Prove it with a self-contained test: ban a test address for 60 seconds, send requests from that address during the ban, and compare the drop counter before and after.
5. Reboot the hosts and repeat the network checks.

## What went well

- The cause was measured before anything was changed: address types counted from the logs, test requests over both IP versions, a test ban with a counter.
- Every change had a backup, an automatic undo and a written rollback, and every step started with a read-only look.
- Test bans expire by themselves, so a mistake could not lock anyone out for long.
- Reboot tests confirmed that the network changes persist.

## What went wrong

- Protection was judged by its alerts and never by trying to get through a ban.
- The first versions of the ban test depended on the order in which commands ran in several terminal windows, and proved nothing. The test had to be made self-contained and independent of order.
- Scripts passed between operating systems picked up an invisible line-ending character. Sending them as encoded text avoids that.

## Lessons

- An alert proves detection, not enforcement. Test enforcement by banning a harmless address and measuring what happens.
- Check which client address the proxy really sees, by type, for both IP versions.
- Enabling forwarding can change how a host learns its IPv6 route. Rehearse it first.
- Give every test a control run and a way to expire.
- Re-check that a protection still enforces after every upgrade or change.

## Action items

| Item | Status |
|------|--------|
| Forward-hook rule on both edge hosts | done |
| IPv6 range on the proxy network of both hosts | done |
| Router-advertisement setting on both hosts | done |
| Reboot tests of the network changes | done |
| Scheduled enforcement test: ban a test address, confirm it is blocked, remove it | planned |
| Alert when most requests are logged with an internal address | planned |
| Ansible role and CI check for the forward rule | planned |
