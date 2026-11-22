#!/usr/bin/env bash
# Omnipack server launcher (macOS / Linux).
#
# First run: installs Forge, downloads the pack, asks you to accept the EULA.
# Every run: updates mods/configs from GitHub, then starts the server.
# The server restarts automatically if it crashes; type "stop" to quit for good.
#
# Settings can be overridden with environment variables, e.g.
#   PACK_URL=http://localhost:8080/pack.toml ./start.sh
set -euo pipefail
cd "$(dirname "$0")"

MC_VERSION="1.20.1"
FORGE_VERSION="47.4.29"
PACK_URL="${PACK_URL:-https://raw.githubusercontent.com/kunpai/omnipack/master/pack.toml}"
BOOTSTRAP_URL="https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar"
FORGE_URL="https://maven.minecraftforge.net/net/minecraftforge/forge/${MC_VERSION}-${FORGE_VERSION}/forge-${MC_VERSION}-${FORGE_VERSION}-installer.jar"
RAM="${RAM:-6G}"

log() { printf '\n== %s\n' "$*"; }
die() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

# --- Java 17 -----------------------------------------------------------------
# Prefer Homebrew's openjdk@17, then JAVA_HOME, then whatever is on PATH.
for candidate in /opt/homebrew/opt/openjdk@17/bin /usr/local/opt/openjdk@17/bin "${JAVA_HOME:-}/bin"; do
  if [[ -x "$candidate/java" ]]; then export PATH="$candidate:$PATH"; break; fi
done
command -v java >/dev/null || die "Java 17 not found. Install it: brew install openjdk@17 (Mac) or https://adoptium.net (Temurin 17)."
JAVA_MAJOR=$(java -version 2>&1 | awk -F'"' '/version/ {split($2, v, "."); print v[1]; exit}')
[[ "$JAVA_MAJOR" == "17" ]] || die "Found Java $JAVA_MAJOR, but Forge $MC_VERSION needs Java 17. Install openjdk@17 / Temurin 17."

# --- Forge ---------------------------------------------------------------------
FORGE_ARGS="libraries/net/minecraftforge/forge/${MC_VERSION}-${FORGE_VERSION}/unix_args.txt"
if [[ ! -f "$FORGE_ARGS" ]]; then
  log "Installing Forge $MC_VERSION-$FORGE_VERSION (first run only)"
  curl -fL --retry 3 -o forge-installer.jar "$FORGE_URL"
  java -jar forge-installer.jar --installServer || die "Forge install failed (see forge-installer.jar.log)."
  rm -f forge-installer.jar forge-installer.jar.log
fi

# --- Memory --------------------------------------------------------------------
if ! grep -q '^-Xmx' user_jvm_args.txt 2>/dev/null; then
  # Forge's file has no trailing newline, so start a fresh line first
  printf '\n-Xmx%s\n' "$RAM" >> user_jvm_args.txt
  log "Server memory set to ${RAM} (edit user_jvm_args.txt to change)"
fi

# --- Default server settings (only written if there is no server.properties) --
if [[ ! -f server.properties ]]; then
  cat > server.properties <<'EOF'
motd=Omnipack
difficulty=normal
allow-flight=true
view-distance=10
simulation-distance=8
spawn-protection=0
max-players=8
EOF
  log "Wrote default server.properties"
fi

# --- EULA ----------------------------------------------------------------------
if ! grep -q '^eula=true' eula.txt 2>/dev/null; then
  echo
  echo "Minecraft servers require accepting the Minecraft EULA: https://aka.ms/MinecraftEULA"
  read -r -p "Do you accept the EULA? [y/N] " answer
  [[ "$answer" =~ ^[Yy] ]] || die "EULA not accepted; the server can't start."
  echo "eula=true" > eula.txt
fi

# --- Update + run loop ---------------------------------------------------------
[[ -f packwiz-installer-bootstrap.jar ]] || curl -fL --retry 3 -o packwiz-installer-bootstrap.jar "$BOOTSTRAP_URL"

while true; do
  log "Updating Omnipack from $PACK_URL"
  java -jar packwiz-installer-bootstrap.jar -g -s server "$PACK_URL" \
    || echo "WARNING: update failed (offline?). Starting with the mods already installed."

  log "Starting server (type 'stop' to shut down)"
  set +e
  java @user_jvm_args.txt "@$FORGE_ARGS" nogui
  code=$?
  set -e

  # Exit code 0 means someone typed "stop": don't restart.
  [[ $code -eq 0 ]] && break
  echo
  echo "Server exited with code $code. Restarting in 10 seconds (Ctrl+C to cancel)..."
  sleep 10
done
