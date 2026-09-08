#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo"
  exit 1
fi

REAL_USER=$(logname || echo $SUDO_USER)
REAL_UID=$(id -u "$REAL_USER")
REAL_GID=$(id -g "$REAL_USER")

BURP_DIR="/opt/BurpSuite"
PROFILE_DIR="/home/$REAL_USER/.config/burp_docker_profile"
SAFE_COPY_DIR="/home/$REAL_USER/.config/SAFE_DOCKERCACHE_COPY"

mkdir -p "$PROFILE_DIR"
mkdir -p "$SAFE_COPY_DIR"

if [ -d "$SAFE_COPY_DIR/.BurpSuite" ]; then
    echo "[Security] Purging active workspace and enforcing trusted Gold Copy..."
    find "$PROFILE_DIR" -mindepth 1 -delete
    cp -a "$SAFE_COPY_DIR"/. "$PROFILE_DIR/"
fi

# --- EXTENSION SEEDING BLOCK ---
# Ensure the extension exists in the host profile so it survives the volume mount
if [ ! -d "$PROFILE_DIR/RSC_Detector" ]; then
    echo "[Security] Fetching RSC_Detector extension for the sandbox..."
    git clone https://github.com/mrknow001/RSC_Detector.git "$PROFILE_DIR/RSC_Detector"
    rm -rf "$PROFILE_DIR/RSC_Detector/.git"
fi
# -----------------------------------

# --- THE EXECUTION HIJACK ---
BURP_CHROME_PATH=$(find "$BURP_DIR/burpbrowser" -name chrome -type f 2>/dev/null | head -n 1)
BROWSER_MOUNT=""

if [ -n "$BURP_CHROME_PATH" ]; then
    echo "[Security] Hijacking Burp's embedded browser at: $BURP_CHROME_PATH"
    WRAPPER_PATH="$PROFILE_DIR/chrome_wrapper.sh"
    echo '#!/bin/bash' > "$WRAPPER_PATH"
    echo 'echo "--- BROWSER INTERCEPTED ---" >> /home/ubuntu/chrome_debug.log' >> "$WRAPPER_PATH"
    echo 'export DCONF_USER_CONFIG_DIR=/home/ubuntu/.config/dconf' >> "$WRAPPER_PATH"
    echo 'export XDG_RUNTIME_DIR=/home/ubuntu/.runtime' >> "$WRAPPER_PATH"
    echo 'export NO_AT_BRIDGE=1' >> "$WRAPPER_PATH"
	echo 'exec /usr/bin/chromium --no-sandbox --test-type --disable-dev-shm-usage --disable-background-networking --disable-gpu --load-extension=/home/ubuntu/RSC_Detector "$@" >> /home/ubuntu/chrome_debug.log 2>&1' >> "$WRAPPER_PATH"
    chmod +x "$WRAPPER_PATH"

    # mount the wrapper directly over the official binary
    BROWSER_MOUNT="-v $WRAPPER_PATH:$BURP_CHROME_PATH:ro"
else
    echo "Warning: Could not find Burp's embedded browser in $BURP_DIR. Hijack may fail."
fi

chown -R "$REAL_UID:$REAL_GID" "$PROFILE_DIR"

# --- PROXY CONFIGURATION INJECTION ---
# This block is mostly to ensure the listening port doesn't default to 8080, since that port is the default for a lot of programs.
BURP_CONFIG_FILE="$PROFILE_DIR/custom_proxy.json"
if [ ! -f "$BURP_CONFIG_FILE" ]; then
    echo "[Config] Generating custom Burp config to shift proxy port to 8085..."
    cat << 'EOF' > "$BURP_CONFIG_FILE"
{
    "proxy": {
        "request_listeners": [
            {
                "certificate_mode": "per_host",
                "listen_mode": "loopback_only",
                "listener_port": 8085,
                "running": true
            }
        ]
    }
}
EOF
    # Ensure the user retains ownership of the file
    chown "$REAL_UID:$REAL_GID" "$BURP_CONFIG_FILE"
fi
# -------------------------------------

echo "Launching Burp Suite..."
sudo -u "$REAL_USER" xhost +local:

trap "
    echo 'Burp closed. Saving container state...';
    if [ -z \"\$(find \"$SAFE_COPY_DIR\" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)\" ]; then
        echo 'Locking in this session as your permanent Safe Gold Image...';
        cp -a \"$PROFILE_DIR\"/. \"$SAFE_COPY_DIR/\";
    fi
    chown -R \"$REAL_UID:$REAL_GID\" \"$PROFILE_DIR\";
    chmod -R 700 \"$PROFILE_DIR\";
    echo 'State saved securely.';
    sudo -u \"$REAL_USER\" xhost -local:;
    echo 'X11 privileges revoked.'
" EXIT

# Added some DNS sinkhole rules for added telemetry filtering.
# Added some DNS sinkhole rules for added telemetry filtering below starting at the "--add-host" line.
docker run --rm -it \
  --shm-size="2g" \
  --ipc=host \
  -e DISPLAY="$DISPLAY" \
  -e XDG_RUNTIME_DIR=/home/ubuntu/.runtime \
  -e HOME=/home/ubuntu \
  --add-host clients2.google.com:0.0.0.0 \
  --add-host accounts.google.com:0.0.0.0 \
  --add-host android.clients.google.com:0.0.0.0 \
  --add-host optimizationguide-pa.googleapis.com:0.0.0.0 \
  --add-host redirector.gvt1.com:0.0.0.0 \
  --add-host beacons.gvt2.com:0.0.0.0 \
  --add-host content-autofill.googleapis.com:0.0.0.0 \
  --add-host update.googleapis.com:0.0.0.0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -v "$BURP_DIR:/opt/BurpSuite:ro" \
  -v "$PROFILE_DIR:/home/ubuntu" \
  $BROWSER_MOUNT \
  --cap-add=SYS_ADMIN \
  ubuntu-burp:latest \
  bash -c "
    mkdir -p /home/ubuntu/.runtime
    java -jar /opt/BurpSuite/burpsuite.jar --config-file=/home/ubuntu/custom_proxy.json
  "

###	This script took a suprisingly large amount of time to make, and I had to do an absurd amount of debugging and troubleshooting.
### If you see things that seem poorly made or pointless, it's probably because I was up at 4 AM working on this and was losing my mind.
