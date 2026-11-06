# Powershell

This file contains my aliases for powershell, most of them are for git commands, there are a couple for modifying neovim config files, and modifying history.

It also contains a function for opening yazi with just typing 'y' in the terminal.

And then sets up the history, and then sets up the greeting message for when I open powershell. I found the x-wing ascii art at this [link](https://ascii.co.uk/art/xwing). Lastly, it invokes starship to make the terminal look nicer, and invokes zoxide to make it easier to navigate the file system.

The file is `Microsoft.PowerShell_profile.ps1`, so it can be used as the profile directly: copy or symlink it to the path that `$PROFILE` prints (for PowerShell 7, usually `Documents\PowerShell\Microsoft.PowerShell_profile.ps1`).

`open4d` opens the project with a data file from `-DataFile` or the `FOURD_DATAFILE` environment variable. Without either, 4D asks you to pick one. To set it once:

```powershell
[Environment]::SetEnvironmentVariable('FOURD_DATAFILE', 'C:\dev\Data\MyProject.4DD', 'User')
```
