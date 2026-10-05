# Pi for Windows installer

An interactive PowerShell bootstrapper for installing Pi on Windows. It offers
native Windows with Git Bash or Pi inside WSL, and lets you select the language
Pi should use for its initial assistant instructions.

## Run

Open PowerShell and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
./Install-Pi.ps1
```

The installer checks and installs Node.js (LTS) and Pi via npm. Native mode
installs Git for Windows when needed. WSL mode enables/installs WSL and Ubuntu
when needed; Windows may require a reboot, after which rerun this script.
Review the prompts before allowing software installation. No administrator
rights are required unless Windows needs to enable/install WSL or Git/Node
installers request elevation.

Languages offered: English, Mandarin Chinese, Hindi, Spanish, and French.
The selection is saved to `~/.pi/agent/INSTALL_LANGUAGE.md`; it does not claim
to translate Pi's interface or automatically configure a model-specific system
prompt.

## Script

`Install-Pi.ps1` is interactive and supports `-Help`. Native mode uses Git Bash
as Pi's Bash environment. WSL mode configures Pi inside Ubuntu, leaving WSL's
own Bash as the shell. See Pi's Windows documentation at https://pi.dev/docs/
for shell resolution and authentication details.
