function Get-GitAddPatch { & git add --patch $args }
New-Alias -Name gap -Value Get-GitAddPatch -Force -Option AllScope
function Get-GitAddAll { & git add --all $args }
New-Alias -Name ga -Value Get-GitAddAll -Force -Option AllScope
function Get-GitStatus { & git status -sb $args }
New-Alias -Name gs -Value Get-GitStatus -Force -Option AllScope
function Get-GitFetchPull { & git fetch --prune && git pull $args }
New-Alias -Name gfp -Value Get-GitFetchPull -Force -Option AllScope
function Get-GitDiff { & git diff $args }
New-Alias -Name gd -Value Get-GitDiff -Force -Option AllScope
function Get-GitCommit { & git commit $args }
New-Alias -Name gc -Value Get-GitCommit -Force -Option AllScope
function Get-GitPush { & git push $args }
New-Alias -Name gp -Value Get-GitPush -Force -Option AllScope
function Get-GitLog { & git log --pretty=format:\"%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an] " --graph --oneline --all $args }
New-Alias -Name gl -Value Get-GitLog -Force -Option AllScope
function Get-GitSwitch { & git switch $args }
New-Alias -Name gsw -Value Get-GitSwitch -Force -Option AllScope
function Get-GitSwitchNewBranch { & git switch -c $args }
New-Alias -Name gswb -Value Get-GitSwitchNewBranch -Force -Option AllScope
function Get-GitBranch { & git branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate $args }
New-Alias -Name gb -Value Get-GitBranch -Force -Option AllScope
function Get-GitRestoreAll { & git restore . $args }
New-Alias -Name gra -Value Get-GitRestoreAll -Force -Option AllScope
function Get-GitRestore { & git restore $args }
New-Alias -Name gr -Value Get-GitRestore -Force -Option AllScope
function Set-NeovimConfig { cd C:\Users\rpb003\AppData\Local\nvim && nvim }
New-Alias -Name nvc -Value Set-NeovimConfig -Force -Option AllScope
function ChangeHistory { nvim C:\Users\rpb003\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt }
New-Alias -Name hist -Value ChangeHistory -Force -Option AllScope
function Get-GitBlame { & git blame $args }
New-Alias -Name gbl -Value Get-GitBlame -Force -Option AllScope
function CreateFile { New-Item -ItemType "File" $args}
New-Alias -Name touch -Value CreateFile -Force -Option AllScope

function y {
    $tmp = (New-TemporaryFile).FullName
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -Path $tmp
}

# Set Some Options for PSReadLine to show the history of our typed commands
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
#Fzf (Import the fuzzy finder and set a shortcut key to begin searching)
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

# x-wing ascii art
$prompt = "
           __
.-.__      \ .-.  ___  __
|_|  '--.-.-(   \/\;;\_\.-._______.-.
(-)___     \ \ .-\ \;;\(   \       \ \
 Y    '---._\_((Q)) \;;\\ .-\     __(_)
 I           __'-' / .--.((Q))---'    \,
 I     ___.-:    \|  |   \'-'_          \
 A  .-'      \ .-.\   \   \ \ '--.__     '\
 |  |____.----((Q))\   \__|--\_      \     '
    ( )        '-'  \_  :  \-' '--.___\
     Y                \  \  \       \(_)
     I                 \  \  \         \,
     I                  \  \  \          \
     A                   \  \  \          '\
     |                    \  \__|           '
                           \_:.  \
                             \ \  \
                              \ \  \
                               \_\_|
"
Write-Host $prompt

# -- Get our Greeting
$prompt = ""
$hourText = Get-Date -Format "HH"
$hour = [int]$hourText
if ( $hour -gt 17 ) { $prompt = "Good evening, Preston. Commands, assemble, and Shell Scripts, roll out!" }
elseif( $hour -gt 11 ) { $prompt = "Good afternoon, Preston. Please feed the CLI some commands.. coffee.. CTRL-ZZzzz.." }
elseif( $hour -gt 05 ) { $prompt = "Good morning, Preston. Early morning commands catches the bugs." }
else { $prompt = "It's kinda late, Preston, but the CLI will be with you. Always. ^_^" }

Write-Host $prompt

$prompt = ""
function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
    }
    $host.ui.Write($prompt)
}

Invoke-Expression(&starship init powershell)
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
