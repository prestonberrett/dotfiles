# Autohotkey

MyScript.ahk contains the script that I find most useful for me. One to open all of the base applications that I use everyday, including outlook, webex, brave, wezterm, and obsidian. Then there is another script for opening the 4D application. A script for 20-20-20, which is a reminder to look away from the screen every 20 minutes for 20 seconds at something 20 feet away. I just have the script in the following folder on windows: 'C:\Users\%USERNAME%\'. I have the script set to run at startup, so it is always running in the background.

## Environment variables

Machine-specific values are read from user environment variables instead of being hardcoded:

- `WORK_EMAIL`: what the `eml` hotstring in AutoCorrectPersonal.ahk types.
- `FOURD_PROJECT`: full path to the `.4DProject` file that Ctrl+Alt+D opens.

Set them once in PowerShell, then restart the script:

```powershell
[Environment]::SetEnvironmentVariable('WORK_EMAIL', 'you@example.com', 'User')
[Environment]::SetEnvironmentVariable('FOURD_PROJECT', 'C:\dev\MyProject\4D\Project\MyProject.4DProject', 'User')
```

## Hotkeys that changed

- Ctrl+Alt+W toggles WezTerm (was Ctrl+Shift+C, which is terminal copy).
- Ctrl+Alt+H shows the shortcut guide (was Alt+Shift+S, which GlazeWM uses).
