# Postmortem 001: Resolver lost after a VPN tunnel was removed

- **Status:** resolved
- **Severity:** low (internal only, no user-facing impact)
- **Duration:** part of one day, from the tunnel removal until the fix
- **Host:** `pbs` (backup server)

## Summary

During a cleanup, an unused VPN tunnel was removed from the backup server. The tunnel profile turned out to be the host's only DNS setting, so the host lost all name resolution. A package update and a test of the new backup-failure alert both failed to resolve names, which exposed the problem. The fix landed before the next scheduled backup pull.

## Impact

- The backup server could not resolve names from the tunnel removal until the fix, within one day.
- No data was lost and no user-facing service was affected.
- The next scheduled pull jobs would have failed. They were fixed in time.

## Timeline

Times are relative to the change that caused the problem.

| When | Event |
|------|-------|
| T+0 | The unused tunnel is disabled and its profile is removed during a cleanup. |
| T+0 | The host's resolver file loses its only nameserver entries. Nothing alerts. |
| Later | A package update and a test of the new backup-failure alert both fail with name-resolution errors. Investigation starts. |
| Later | First hypothesis: an earlier removal of the container runtime changed the network scripts. It did not explain the symptoms. |
| Later | Nameserver entries are written by hand. Resolution returns. |
| Later | The leftover tunnel profile is found: its DNS line was the only DNS setting. This is the root cause. |
| Later | Explicit nameserver lines are added to the interface configuration. |
| Later | The host is rebooted. The resolver file fills itself, names resolve, and services are active. |

## Root cause

The host never had resolver settings of its own. Its DNS entries came from the VPN profile's DNS directive, which the tunnel tool applied through the resolver helper whenever the tunnel came up. Disabling the tunnel removed those entries, and the resolver file became empty.

The dependency was invisible. Name resolution had worked for months, and nothing recorded where it came from.

## Detection

A person noticed it while testing a new backup-failure alert: the alert call to the notification server and a package update both failed to resolve names. No monitoring covered "this host can resolve names", so the failure went unnoticed until someone ran a command that needed DNS.

## Resolution

1. Write nameserver entries by hand as a stop-gap.
2. Add explicit nameserver lines to the host's interface configuration.
3. Reboot and confirm that the resolver file fills itself, names resolve, and the backup services are active.

## What went well

- The fix was proven with a reboot, not only with a live change.
- The investigation corrected itself when the first hypothesis did not hold.
- No data was lost and the impact stayed internal.

## What went wrong

- The cleanup removed a component without checking what else it provided.
- No health check covered name resolution.
- The first hypothesis was stated early and with more confidence than the evidence supported. It was wrong.

## Lessons

- Every host owns its resolver configuration. It does not borrow it from a VPN profile.
- Before removing a component, list everything else it provides: DNS, routes, firewall rules.
- A change is not finished until it survives a reboot.

## Action items

| Item | Status |
|------|--------|
| Explicit resolver lines in the interface configuration | done |
| Reboot test after the change | done |
| Failure alert for the scheduled backup pulls | done |
| Dedicated health check for name resolution | planned |
| Add "what else does this provide?" to the cleanup checklist | planned |
