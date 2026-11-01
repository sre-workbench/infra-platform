# Infrastructure platform

A privacy-first platform, self-hosted in the EU, for mail, identity, monitoring and backups, designed around least-privilege and zero-trust principles and run as a small SRE-style lab environment. This repository holds the design notes, blameless postmortems and example configurations. **Every value in it is a placeholder.**

> Status: work in progress. Sections marked _planned_ are not written yet.

## Why this exists

_Planned: two or three sentences on the problem. Who the platform serves, which services it runs, and why it is self-hosted instead of rented._

## Architecture

The platform has a public edge, a private site, and a separate backup path. Everything between sites travels over an encrypted tunnel.

See [docs/architecture.md](docs/architecture.md) for the diagram and the role of each component.

## Design decisions

Short decision records, one per file, in `docs/decisions/` (_planned_).

| ID | Decision | Status |
|----|----------|--------|
| 001 | _planned_ | _planned_ |

## Postmortems

Blameless write-ups in `docs/postmortems/` (_planned_). Each one has a timeline, root cause, fix and prevention.

| ID | Title | Status |
|----|-------|--------|
| 001 | [Resolver lost after a VPN tunnel was removed](docs/postmortems/001-resolver-lost-after-tunnel-removal.md) | written |
| 002 | [Saved firewall file broke forwarding after a reboot](docs/postmortems/002-saved-firewall-file-broke-forwarding.md) | written |

## Reliability targets

_Planned: service level objectives per service, with the error budget and how each is measured. Targets: `<n>`% availability over `<n>` days._

## How to run it

_Planned: Ansible roles for provisioning, and a CI pipeline that lints and validates them. No real inventory is published; an `inventory.example` file will show the shape._

## Threat model

_Planned: assets, trust boundaries, and the main risks with their mitigations._

## What I learned

_Planned._

## Placeholder conventions

Nothing here maps a real network. These stand-ins are used throughout:

| Real thing | In this repository |
|------------|--------------------|
| Domains | `example.com`, `example.org` |
| Public addresses | `203.0.113.x` |
| Private and tunnel ranges | `10.x.y.z` |
| Host names | roles: `edge-vps`, `app-vm`, `pbs`, `backup-host` |
| SSH and service ports | `<ssh-port>`, `<service-port>` |
| Secrets, tokens, keys | never included |

## License

MIT. See [LICENSE](LICENSE).
