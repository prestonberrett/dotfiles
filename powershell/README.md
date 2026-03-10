#Powershell

This file contains my aliases for powershell, most of them are for git commands, there are a couple for modifying neovim config files, and modifying history.

It also contains a function for opening yazi with just typing 'y' in the terminal.

And then sets up the history, and then sets up the greeting message for when I open powershell. I found the x-wing ascii art at this [link](https://ascii.co.uk/art/xwing). Lastly, it invokes starship to make the terminal look nicer, and invokes zoxide to make it easier to navigate the file system.

The file needs to be placed in the following folder on windows: 'C:\Users\%USERNAME%\Documents\PowerShell\' and then you need to add the following line to your profile script: '. $HOME\Documents\PowerShell\MyProfile.ps1'. You can find your profile script by running '$profile' in powershell.
