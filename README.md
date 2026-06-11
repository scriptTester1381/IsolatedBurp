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

## Credits & Attribution

This sandbox setup integrates the **RSC_Detector** browser extension to assist in catching and analyzing reverse shell payloads. 

- **Original Project:** [RSC_Detector](https://github.com/mrknow001/RSC_Detector)
- **Creator:** Developed by [mrknow001](https://github.com/mrknow001)

Please visit the original repository to support the creator, view the source code, or contribute to the extension's development.

