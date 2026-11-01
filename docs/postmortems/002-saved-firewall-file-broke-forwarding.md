# Postmortem 002: Saved firewall file broke forwarding after a reboot

- **Status:** resolved
- **Severity:** high (all public web services affected)
- **Duration:** not recorded (see Lessons)
- **Hosts:** `edge-vps` (public edge), `app-vm` (application VM)

## Summary

While fixing a failed package update on `app-vm`, the firewall rules on `edge-vps` were saved to the config file with a command that also captured the rules Docker generates for itself. After a reboot the firewall service could not load that file, so the custom forwarding and NAT rules were missing. The reverse proxy could no longer reach the backend VMs through the tunnel, and every public web service returned gateway timeouts. Rewriting the config by hand, with only our own rules, fixed it.

## Impact

- All public web services behind the reverse proxy returned gateway timeouts after the reboot.
- `app-vm` lost its internet access, because the NAT rule for tunnel traffic was missing.
- Only network rules were affected. No application data was changed.
- The duration was not recorded.

## Background

`app-vm` reaches the internet through the tunnel and NAT on `edge-vps`. Its package updates had failed because forwarded packets arrived at the edge host but never left it. Docker's own firewall tables, created through the iptables compatibility layer, were evaluated before the custom forwarding rules. The fix was a small startup unit that adds the needed rules to Docker's user chain once Docker has started.

## Timeline

| When | Event |
|------|-------|
| T+0 | Package updates on `app-vm` fail with network errors. |
| Later | While fixing this, the live ruleset on `edge-vps` is saved to the firewall config file by dumping it. The dump includes the tables Docker generated. |
| Later | `edge-vps` is rebooted as a deliberate reboot test. The firewall service fails to load the file, and the custom forwarding and NAT rules are missing. |
| Later | The reverse proxy cannot reach the backend VMs. All public web services time out, and `app-vm` has no internet. |
| Later | Rules are added and removed during troubleshooting, which makes the situation worse for a while. |
| Later | The config is rewritten by hand with only our own tables. The firewall service and Docker are restarted, and the services recover. |
| Later | Every VM and the edge host are rebooted one by one. All of them come back healthy. |

## Root cause

1. **The saved file contained tables the firewall service cannot load.** Docker creates its tables through the iptables compatibility layer, using targets that the native loader does not understand. One unloadable table made the whole file fail, and the error was only visible in the service log.
2. **The file was generated, not written.** It came from dumping the live state, which mixes in rules owned by another tool. Docker manages its own rules, and they must never end up in our config.

## Detection

The reboot was a planned test, and a manual check afterwards showed that the forwarding table was missing. No automatic check confirmed that the firewall had loaded.

## Resolution

1. Write the config file by hand, with only our own tables: input, forward and NAT.
2. Restart the firewall service and Docker.
3. Reboot every host and confirm that the services survive.

## What went well

- The failure surfaced during a deliberate reboot test and not during a surprise reboot.
- The final fix was proven by rebooting every host.
- The root cause was written down as a rule for the future.

## What went wrong

- The saved file was never checked in a dry run before the reboot.
- Rules were declared working before a reboot had proven that they persist.
- Changes were made faster than they were understood during the outage.
- No timestamps were kept, so the duration is unknown.

## Lessons

- Never create a firewall config by dumping the live ruleset on a host where Docker manages rules. Keep a hand-written file with only your own tables.
- Check a firewall file with a dry run before every reboot.
- During an outage, change one thing at a time and write down the time of each change.
- Reboot-test every host that holds persistent network configuration.

## Action items

| Item | Status |
|------|--------|
| Hand-written config with only our own tables | done |
| Startup unit that adds forwarding rules after Docker starts | done |
| Reboot test on every host | done |
| Dry-run check before every reboot, written into the runbook | planned |
| Record timestamps during incidents | planned |
| Alert when the firewall service fails to start | planned |
