# Bash System Health Dashboard

## Group Members

- Rose Thomas
- Alfonso Sanchez

## Project Description

This project is a Bash-based Linux system health dashboard. The script
displays important system information in one readable view and is designed
to run on both Fedora Linux and Ubuntu Server.

The dashboard includes system information, CPU and memory usage, disk usage,
top processes, network information, service status, logged-in users, recent
login activity, and recent system errors.

## Requirements

- Bash shell
- Fedora Linux or Ubuntu Server
- systemd-based Linux system
- Standard Linux commands such as:
  - hostname
  - uname
  - uptime
  - free
  - df
  - ps
  - ip
  - ss
  - systemctl
  - who
  - last
  - journalctl

The script checks whether required commands are available before using them.
If a command is missing, the dashboard displays a message instead of
terminating.

## Setup

Navigate to the project directory:

```bash
cd ~/bash-dashboard
