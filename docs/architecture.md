# Architecture

All names, addresses and ports are placeholders. See the conventions table in the [README](../README.md).

## Overview

```mermaid
flowchart TB
    internet([Internet])
    dns[DNS provider<br/>example.com / example.org]

    subgraph edge["Public edge"]
        edgevps["edge-vps<br/>203.0.113.10<br/>reverse proxy, TLS, relay"]
    end

    subgraph site["Private site"]
        router["Site gateway<br/>tunnel endpoint"]
        appvm["app-vm<br/>10.x.y.z<br/>mail, identity, files, monitoring"]
        backupvm["backup-vm<br/>10.x.y.z<br/>backup server"]
    end

    subgraph offsite["Separate backup path"]
        backuphost["backup-host<br/>203.0.113.20<br/>offsite copy"]
    end

    internet -->|"only the ports<br/>the services need"| edgevps
    dns -.->|records| internet
    edgevps <-->|"encrypted tunnel<br/>10.x.y.0/24"| router
    router --- appvm
    router --- backupvm
    appvm -->|backup jobs| backupvm
    backupvm -->|"encrypted, push"| backuphost
    appvm -.->|"heartbeat, alerts"| edgevps
```

## Components

| Role | Placeholder name | Purpose |
|------|------------------|---------|
| Public edge | `edge-vps` | Only host reachable from the internet. Terminates TLS and forwards traffic through the tunnel. |
| Application services | `app-vm` | Runs the application containers: mail, identity, password manager, file sync, monitoring. |
| Backup server | `backup-vm` | Receives VM and file backups from the private site. Accepts connections only from the hosts that need them. |
| Offsite copy | `backup-host` | Holds an encrypted copy of the backups in a different location. |

## Network boundaries

- **Internet to edge:** only the ports the services need. SSH accepts key authentication only.
- **Edge to private site:** one encrypted tunnel. The private site accepts no inbound connections from the internet; access arrives through the tunnel.
- **Private site:** the backup server accepts connections only from the hosts that need them, enforced by a host firewall.
- **Backups:** pushed outward from the backup server, never pulled in.

## Open sections

_Planned: certificate issuance and renewal, mail path (inbound, outbound, authentication records), monitoring and alert routing, and the backup schedule._
