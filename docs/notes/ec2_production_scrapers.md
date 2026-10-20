---
status: historical-contingency
date: 2026-10
tags: [ec2, tickrake, runbook]
---

# EC2 Tickrake contingency deployment

This records a temporary deployment used while the local workstation was
unavailable. Docker Compose on the local host is the primary runtime; the EC2
host is a contingency, not the normal production target. The deployment-specific
`deploy/ec2-tickrake.yml` existed only on the instance and is not in this repo.

## Retained facts

- Region `us-east-1`; instance name `quant-infra`; ARM64 `t4g.large`.
- Repository `/opt/quant-infra`; persistent Tickrake and Schwab state at
  `/opt/tickrake-home` and `/opt/schwab-home`.
- The instance role `tickrake-ec2-scrapers` supplies AWS credentials. Do not
  install long-lived AWS keys or set `AWS_PROFILE` on the host.
- Use Systems Manager for administration. Keep environment files and Schwab
  state mode `600`; never print token contents. Run only one Schwab streamer
  for the account.
- Stopping the instance retains EBS storage charges; its public IP may change
  after restart. Do not terminate it before confirming all needed data is safe.

## Superseded details

The deployment's S3 archive writes, manifest reconciler, and scheduled
compaction configuration are no longer current. Tickrake disabled those archive
writes and this repository removed the reconciler. Current date-scoped
compaction is documented in the Makefile and script. The former full setup and
command transcript is retained in Git history; verify cloud resources and
Compose targets live before reusing any contingency procedure.
