# Omnipack server

Runs on Windows or macOS. The script installs Forge, downloads the pack from
GitHub, and re-checks for pack updates every time it starts, so the server
always matches what players have.

## Setup

1. Install **Java 17**
   - Windows: [Temurin 17](https://adoptium.net/temurin/releases/?version=17) (.msi, tick "Add to PATH")
   - macOS: `brew install openjdk@17`
2. Make an empty folder for the server (e.g. `Omnipack Server`) and put the
   start script in it: `start.bat` on Windows, `start.sh` on macOS.
3. Run it: double-click `start.bat`, or `./start.sh` in Terminal.
   The first run takes a few minutes and asks you to accept the
   [Minecraft EULA](https://aka.ms/MinecraftEULA).
4. Wait for `Done (...)! For help, type "help"`. Connect from Minecraft with
   `localhost` (same PC) or the playit.gg address (friends).

Type `stop` in the server window to shut down. If the server crashes, it
restarts by itself after 10 seconds.

## Settings

| What | Where |
|---|---|
| Server RAM (default 6G) | `user_jvm_args.txt` (`-Xmx6G`) |
| Difficulty, flight, view distance | `server.properties` |
| Ports | game `25565` (TCP), voice chat `24454` (UDP) |

`allow-flight=true` is on by default so Ben 10 aliens, jetpacks and space suits
don't get players kicked for "flying".
