# IsolatedBurp: Ephemeral & State-Controlled Burp Suite Sandbox

IsoBurp is a highly portable, hardware-agnostic Dockerized sandbox built to completely isolate Burp Suite and its embedded browser within an ephemeral container layer. Designed for security analysts, penetration testers, and malware researchers, this architecture prevents malicious payloads, multi-stage scripts, or browser-based zero-day exploits encountered during detonations from interacting with or compromising the host filesystem.

Unlike default containerized graphical configurations, IsoBurp implements a strict **"Gold Copy" Baseline Restoration** model. Every single execution purges the operational workspace entirely and restores it from a trusted snapshot. When the application terminates, the environment is cleanly dismantled, safely storing core configurations while permanently throwing away session contamination.

This is completely open source, download and make your own changes as you see fit!

---

## Key Features

- **Host Isolation:** Restricts the execution boundaries of Burp Suite and Chromium to an isolated Docker container context.
- **Automated State Persistence:** Seamlessly preserves core UI states (e.g., Dark Mode preferences), proxy rules, and user configs across runs without manual data exports.
- **Embedded Browser Hijack:** Securely intercepts Burp's hardcoded, proprietary embedded browser binary path, substituting it transparently with a software-rendered OS-level Chromium engine.
- **Automated Extension Seeding:** Automatically clones, seeds, and maps custom utilities (such as the `RSC_Detector` reverse shell catching tool) into the browser environment at launch.

---

## Host Pre-requisites

IsoBurp is designed to run out-of-the-box on any Debian-based distribution (e.g., Parrot Security OS, Kali Linux, Ubuntu, Debian Core). Before launching, ensure your host machine satisfies the following prerequisites exactly:

1. **Docker Engine Installed & Active:** The standard container runtime package must be installed and running.
```bash
   sudo apt update && sudo apt install docker.io -y
   sudo systemctl enable --now docker
```
2. **Make Sure Podman is Completely Removed and/or Deactivated (if applicable):** With the way that the Dockerfile is built and the scripts are made, by default, nothing will work unless you completely convert your environment over to Docker first. Podman will not cooperate with this build at all unless you manage to go in and make the changes yourself.

   To completely deactivate Podman, execute the following:
```bash
   # Stop and disable any active Podman system and user services/sockets
   sudo systemctl stop podman.socket podman.service 2>/dev/null
   sudo systemctl disable podman.socket podman.service 2>/dev/null
   systemctl --user stop podman.socket podman.service 2>/dev/null
   systemctl --user disable podman.socket podman.service 2>/dev/null
   
   # Completely uninstall the Podman packages and their configuration wrappers
   sudo apt purge -y podman podman-docker containernetworking-plugins
   sudo apt autoremove -y
   
   # Clean up lingering system configuration files and network bridges
   sudo rm -rf /etc/containers /var/lib/containers ~/.local/share/containers
   sudo rm -rf /etc/cni/net.d
   
   # Remove any hardcoded Podman aliases or environment redirections from your shell profile
   # (This unsets variables like DOCKER_HOST if they were pointed to the Podman socket)
   sed -i '/alias docker=/d' ~/.bashrc ~/.zshrc 2>/dev/null
   sed -i '/DOCKER_HOST.*podman/d' ~/.bashrc ~/.zshrc 2>/dev/null
   
   # Reset your active shell environment variables
   unset DOCKER_HOST
   
   # Verify that the 'docker' command now points directly to the real Docker engine
   docker info
```
3. **Make Sure git is Installed:** Do the following:
```bash
   sudo apt install git
```

---

## When Running

Below are a couple of things you should know before you start using the script:

1. **On First Run:** Make sure before you do the following before you run the script for the first time:
```bash
   sudo chmod +x [PATH TO SCRIPT LOCATION]/isolatedBurp.sh
```
2. **Always Run With "sudo" (even if your user is part of Docker group):** When I was making the main script, I ran into quite a few permissions issues, like, a lot. One of the solutions I put into place, was to put a check in the script that makes sure it gets ran with sudo user permissions. Although there were several reasons for this particular feature, the main reason had to do with conflicts between root and the logged in user. This script requires that the Docker container have host-level display permissions, and this temporary change can only be made by root, however, you can't just run the script within a root user shell, because that will result in there being cached files put into the root directory (this creates a huge cascade of problems, both with security, and with state saving).

   So, to summarize, whenever you run the script, you must run:
```bash
   sudo ./isolatedBurp.sh
```

---

## Credits & Attribution

This sandbox setup integrates the **RSC_Detector** browser extension to assist in catching and analyzing reverse shell payloads. 

- **Original Project:** [RSC_Detector](https://github.com/mrknow001/RSC_Detector)
- **Creator:** Developed by [mrknow001](https://github.com/mrknow001)

Please visit the original repository to support the creator, view the source code, or contribute to the extension's development.

