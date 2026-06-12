# Security Policy & Architecture Guide

As an isolated environment designed to handle untrusted web traffic and potential payloads, maintaining the security boundary between the container and the host system is paramount. This document outlines the structural security posture of the sandbox, known breakout vectors, and the protocol for reporting vulnerabilities.

---

## Security Architecture Overview

The sandbox isolates the execution context of Burp Suite and Chromium using Docker namespaces and control groups (`cgroups`). However, because graphical user interfaces (GUIs) require communication channels with the host display server, specific controlled conduits are established.

```text
+-------------------------------------------------------------+
|                      PARROT OS HOST                         |
|                                                             |
|   +-----------------------------------------------------+   |
|   |                  DOCKER CONTAINER                   |   |
|   |                                                     |   |
|   |   +------------------+     +--------------------+   |   |
|   |   |  Burp Browser    |     |  Malicious Payload |   |   |
|   |   | (Chromium Core)  |     |   (In-Memory/RCE)  |   |   |
|   |   +--------+---------+     +---------+----------+   |   |
|   |            |                         |              |   |
|   +------------|-------------------------|--------------+   |
|                |                         |                  |
|                v                         v                  |
|       X11 Socket Mount          --cap-add=SYS_ADMIN         |
|     (/tmp/.X11-unix:ro)        (Shared Kernel Attack)       |
|                |                         |                  |
|                +------------+------------+                  |
|                             |                               |
|                             v                               |
|                     [ Host Kernel ]                         |
+-------------------------------------------------------------+
```

---

## Known Escape Vectors & Mitigations

### 1. Browser-Based Escape (Chromium Rendering Layer)
Because this setup intercepts Burp Suite's hardcoded browser path and forces execution through a customized rendering profile, the browser itself represents the first line of defense.
+ **The Threat:** A malicious web page executes a browser exploit (such as a V8 engine remote code execution zero-day) that successfully escapes the browser's internal renderer process and achieves local code execution inside the container.
+ **The Vulnerability:** Chromium requires specific kernel features to build its internal sandbox namespaces. Because this environment operates inside a standard Docker container, the ```--cap-add=SYS_ADMIN``` flag must be passed to allow Chromium to create these namespaces. If the browser sandbox is disabled or misconfigured via a ```--no-sandbox wrapper``` fallback during troubleshooting, an attacker gains immediate, unconstrained code execution as the root user inside the container context.
+ **Mitigation Strategy:** I do not bypass or disable the containerized Chromium sandbox during active threat analysis. The workspace uses software rendering (```--disable-gpu```) strictly to avoid mapping host graphics drivers (```/dev/dri```), preventing attackers from exploiting kernel-level vulnerabilities in display drivers to escape the container.

### 2. Shared Kernel Exploitation & Container Breakout
Docker utilizes namespaces and cgroups to isolate processes, but the container shares the underlying Linux kernel directly with the host operating system.
+ **The Threat:** If an automated malware payload or reverse shell is established inside the container, it will attempt to detect the virtualization layer and execute a container escape vulnerability (such as a kernel exploit targeting unpatched system calls).
+ **The Vulnerability:** The script mounts the host's local X11 display socket (/tmp/.X11-unix) to render the browser GUI to the desktop. An attacker who achieves root code execution inside the container can abuse access to the X11 socket to keystroke-inject the host terminal, capture screens, or read host clipboard data.
+ **Mitigation Strategy:** The launcher script restricts the X11 volume mount to read-only (:ro) and uses the automated exit handler to run xhost -local: immediately upon termination. This completely revokes the container's display authorization the moment Burp Suite closes, minimizing the exposure window of the host display server.

## Reporting a Vulnerability

If you discover a security vulnerability, specifically a reproducible method to escape this container or manipulate the host filesystem, please do not open a public GitHub Issue.

**To report a vulnerability responsibly:**
1. Contact me directly at danielhunt1381@gmail.com.
2. Provide a detailed description of the exploit vector, including the specific configuration flaw or script logic being abused.
3. Include step-by-step instructions or proof-of-concept logs to help me reproduce and patch the isolation gap.

## Built-in Auditing & Verification Commands
To track anomalous behavior or unexpected process execution within the sandbox, I leverage Docker's built-in reporting platform and logging engine to audit container events straight from the host terminal:
```bash
# Monitor raw system call anomalies or real-time event logs from the container
docker events --filter 'container=ubuntu-burp'

# Inspect the isolated environment structure for unexpected mount leakage
docker inspect ubuntu-burp | grep -A 10 "Mounts"

# Audit the container process list directly from the host terminal to detect hidden shells
docker top <CONTAINER_ID>
```
