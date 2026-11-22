@echo off
rem Omnipack server launcher (Windows 10/11).
rem
rem First run: installs Forge, downloads the pack, asks you to accept the EULA.
rem Every run: updates mods/configs from GitHub, then starts the server.
rem The server restarts automatically if it crashes; type "stop" to quit for good.
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "MC_VERSION=1.20.1"
set "FORGE_VERSION=47.4.29"
if not defined PACK_URL set "PACK_URL=https://raw.githubusercontent.com/kunpai/omnipack/master/pack.toml"
if not defined RAM set "RAM=6G"
set "BOOTSTRAP_URL=https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v0.0.3/packwiz-installer-bootstrap.jar"
set "FORGE_URL=https://maven.minecraftforge.net/net/minecraftforge/forge/%MC_VERSION%-%FORGE_VERSION%/forge-%MC_VERSION%-%FORGE_VERSION%-installer.jar"
set "FORGE_ARGS=libraries\net\minecraftforge\forge\%MC_VERSION%-%FORGE_VERSION%\win_args.txt"

rem --- Java 17 ---------------------------------------------------------------
where java >nul 2>nul
if errorlevel 1 (
  echo ERROR: Java 17 not found. Install Temurin 17 from https://adoptium.net and tick "Add to PATH".
  goto fail
)
set "JV="
for /f "tokens=3" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do set "JV=%%~v"
if not "!JV:~0,3!"=="17." (
  echo ERROR: Found Java !JV!, but Forge %MC_VERSION% needs Java 17. Install Temurin 17 from https://adoptium.net
  goto fail
)

rem --- Forge -------------------------------------------------------------------
if exist "%FORGE_ARGS%" goto forge_ok
echo.
echo == Installing Forge %MC_VERSION%-%FORGE_VERSION% (first run only)
curl -fL --retry 3 -o forge-installer.jar "%FORGE_URL%"
if errorlevel 1 ( echo ERROR: could not download Forge. & goto fail )
java -jar forge-installer.jar --installServer
if errorlevel 1 ( echo ERROR: Forge install failed, see forge-installer.jar.log & goto fail )
del /q forge-installer.jar forge-installer.jar.log 2>nul
:forge_ok

rem --- Memory ------------------------------------------------------------------
findstr /b /c:"-Xmx" user_jvm_args.txt >nul 2>nul
if errorlevel 1 (
  rem Forge's file has no trailing newline, so start a fresh line first
  >>user_jvm_args.txt echo.
  >>user_jvm_args.txt echo -Xmx%RAM%
  echo == Server memory set to %RAM% ^(edit user_jvm_args.txt to change^)
)

rem --- Default server settings (only if there is no server.properties) --------
if not exist server.properties (
  >server.properties echo motd=Omnipack
  >>server.properties echo difficulty=normal
  >>server.properties echo allow-flight=true
  >>server.properties echo view-distance=10
  >>server.properties echo simulation-distance=8
  >>server.properties echo spawn-protection=0
  >>server.properties echo max-players=8
  echo == Wrote default server.properties
)

rem --- EULA --------------------------------------------------------------------
findstr /b /c:"eula=true" eula.txt >nul 2>nul
if not errorlevel 1 goto eula_ok
echo.
echo Minecraft servers require accepting the Minecraft EULA: https://aka.ms/MinecraftEULA
set "ANSWER="
set /p "ANSWER=Do you accept the EULA? [y/N] "
if /i not "!ANSWER!"=="y" (
  echo EULA not accepted; the server can't start.
  goto fail
)
>eula.txt echo eula=true
:eula_ok

rem --- Update + run loop -------------------------------------------------------
if not exist packwiz-installer-bootstrap.jar (
  curl -fL --retry 3 -o packwiz-installer-bootstrap.jar "%BOOTSTRAP_URL%"
  if errorlevel 1 ( echo ERROR: could not download packwiz bootstrap. & goto fail )
)

:loop
echo.
echo == Updating Omnipack from %PACK_URL%
java -jar packwiz-installer-bootstrap.jar -g -s server "%PACK_URL%"
if errorlevel 1 echo WARNING: update failed ^(offline?^). Starting with the mods already installed.

echo.
echo == Starting server ^(type 'stop' to shut down^)
java @user_jvm_args.txt @%FORGE_ARGS% nogui
rem Exit code 0 means someone typed "stop": don't restart.
if not errorlevel 1 goto done
echo.
echo Server exited with an error. Restarting in 10 seconds ^(close this window to cancel^)...
timeout /t 10 /nobreak >nul
goto loop

:done
echo Server stopped.
pause
exit /b 0

:fail
pause
exit /b 1
