# Infrastructure platform

A privacy-first platform, self-hosted in the EU, for mail, identity, monitoring and backups, designed around defense in depth and least-privilege principles and run as a small SRE-style lab environment. This repository holds the design notes, blameless postmortems and example configurations. **Every value in it is a placeholder.**

> Status: work in progress. Sections marked _planned_ are not written yet.

## Why this exists

I run my own mail, identity, monitoring and backups instead of renting them. I want control over my data and hosting inside the EU, and I want to practice operating real services, because incidents, maintenance and trade-offs only show up in something that actually runs.

I am building toward a site reliability engineering (SRE) role. This repository shows how I work: I write down what broke, find the root cause, fix it, and turn the lesson into a check that runs automatically.

This repository is the public, sanitized side of that work. It holds what I can share without mapping my network: design notes, blameless postmortems, and example configuration that is tested in CI. Everything specific to my setup is replaced by placeholders.

## Architecture

The platform has a public edge, a private site, and a separate backup path. Everything between sites travels over an encrypted tunnel.

See [docs/architecture.md](docs/architecture.md) for the diagram and the role of each component.

## Design decisions

Short decision records, one per file, in `docs/decisions/` (_planned_).

| ID | Decision | Status |
|----|----------|--------|
| 001 | _planned_ | _planned_ |

## Postmortems

Blameless write-ups in `docs/postmortems/`. Each one has a timeline, root cause, fix and prevention.

| ID | Title | Status |
|----|-------|--------|
| 001 | [Resolver lost after a VPN tunnel was removed](docs/postmortems/001-resolver-lost-after-tunnel-removal.md) | written |
| 002 | [Saved firewall file broke forwarding after a reboot](docs/postmortems/002-saved-firewall-file-broke-forwarding.md) | written |

## Reliability targets

_Planned: service level objectives per service, with the error budget and how each is measured. Targets: `<n>`% availability over `<n>` days._

## How to run it

The `ansible/` folder holds two roles. Each one was written after a real incident, and a test for each runs in CI on every push.

| Incident | Role | What the CI checks |
|----------|------|--------------------|
| [Postmortem 001](docs/postmortems/001-resolver-lost-after-tunnel-removal.md) | `resolver` | Applies the role to a temporary file twice. The second run must change nothing. |
| [Postmortem 002](docs/postmortems/002-saved-firewall-file-broke-forwarding.md) | `firewall` | Renders the ruleset, validates it with a dry run, and proves that a Docker-style file is rejected. |

Layout:

    ansible/
      inventory.example/    example inventory, placeholder names only
      playbooks/site.yml    the playbook that uses both roles
      roles/                resolver and firewall
      tests/                test plays, and a bad file used as a negative test
    scripts/check-addresses.sh    fails on any address outside the documentation ranges
    .github/workflows/ci.yml      the pipeline

Run the main checks locally:

    yamllint .
    cd ansible && ansible-lint
    ansible-playbook playbooks/site.yml --syntax-check

Safety rules:

- No real inventory, address or secret is published. The example inventory contains placeholders only.
- The CI never connects to any of my servers, and it has no credentials and no deploy step.
- Tests write to temporary files and never load firewall rules.
- The CI action and the tools are pinned to exact versions, and the one binary download is checksum-verified. Locking the tools' own dependencies as well is planned.
- Running the roles on real hosts is a separate, manual decision: run with `--check` first, and have a rollback ready.

## Threat model

_Planned: assets, trust boundaries, and the main risks with their mitigations._

## What I learned

- **Invisible dependencies fail first.** A host got its DNS settings from a VPN profile, and removing the tunnel removed name resolution ([postmortem 001](docs/postmortems/001-resolver-lost-after-tunnel-removal.md)). Every host should own its resolver configuration, and before removing anything I list what else it provides.
- **Never save a firewall file by dumping the live ruleset.** Docker adds its own tables, the saved file could not be loaded after a reboot, and forwarding stopped ([postmortem 002](docs/postmortems/002-saved-firewall-file-broke-forwarding.md)). The ruleset is now hand-written, checked with a dry run before it is installed, and tested by rebooting.
- **Turn lessons into checks.** Both incidents became Ansible roles with CI tests: one proves that a second run changes nothing, the other proves that a Docker-style file is rejected.
- **Treat the repository like a product.** Pinned tool versions, a checksum-verified download, a read-only CI token, approval for workflows from forks, secret scanning with push protection, a protected `main`, and a full-history scan before it went public.
- **Narrower credentials need testing, not hope.** I evaluated delegating the DNS challenge for certificates to a separate zone with a token limited to challenge records. The pieces worked, but one order that mixed a wildcard and a plain name failed in staging because of DNS publication timing, while two separate orders succeeded. It is not in production yet, and I will not claim it until it has survived a real renewal.

## Placeholder conventions

Nothing here maps a real network. These stand-ins are used throughout:

| Real thing | In this repository |
|------------|--------------------|
| Domains | `example.com`, `example.org` |
| Public addresses | `203.0.113.x` |
| Private and tunnel ranges | `10.x.y.z` |
| Host names | roles: `edge-vps`, `app-vm`, `backup-vm`, `backup-host` |
| SSH and service ports | `<ssh-port>`, `<service-port>` |
| Secrets, tokens, keys | never included |

## License

MIT. See [LICENSE](LICENSE).
