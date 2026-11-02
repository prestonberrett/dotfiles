
###############################
# Shell Context
###############################

function Test-InteractiveShell {
    try {
        return $Host.Name -eq 'ConsoleHost' -and
            -not [Console]::IsInputRedirected -and
            -not [Console]::IsOutputRedirected
    } catch {
        return $false
    }
}

$isInteractiveShell = Test-InteractiveShell


###############################
# Git Section
###############################

# Git 'del' branch autocomplete - completes branch names after "git del"
Register-ArgumentCompleter -Native -CommandName 'git' -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    $elements = $commandAst.CommandElements
    if ($elements.Count -ge 2 -and $elements[1].ToString() -eq 'del') {
        git branch --format='%(refname:short)' 2>$null |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object {
                [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
            }
    }
}

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
function Get-GitBlame { & git blame $args }
New-Alias -Name gbl -Value Get-GitBlame -Force -Option AllScope

function New-GitWorktree {
    param(
        [Parameter(Mandatory)][string]$Branch,
        [Parameter()][string]$ParentBranch
    )
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
        Write-Error "Not inside a git repository."
        return
    }
    $repoRoot = $repoRoot.Trim()

    if (-not $ParentBranch) {
        $ParentBranch = git symbolic-ref refs/remotes/origin/HEAD 2>$null | ForEach-Object { $_ -replace '^refs/remotes/origin/', '' }
        if ($LASTEXITCODE -ne 0 -or -not $ParentBranch) {
            Write-Error "Could not determine default branch. Please specify -ParentBranch."
            return
        }
        $ParentBranch = $ParentBranch.Trim()
    }

    # Replace characters not allowed in directory/file names with '-'
    $safeName = $Branch -replace '[\\/:*?"<>|]', '-'
    $Path = Join-Path (Split-Path $repoRoot -Parent) $safeName
    git worktree add -b $Branch $Path $ParentBranch
    if ($LASTEXITCODE -eq 0) {
        Set-Location -Path $Path
    }
}
New-Alias -Name wts -Value New-GitWorktree -Force -Option AllScope

function Remove-GitWorktree {
    param([Parameter(Mandatory)][string]$Path)

    $resolvedPath = (Resolve-Path -Path (Join-Path ("..\") $Path) -ErrorAction SilentlyContinue).Path
    if (-not $resolvedPath) {
        $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    }

    $branch = $null
    $worktrees = & git worktree list --porcelain 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Not inside a git repository."
        return
    }

    for ($i = 0; $i -lt $worktrees.Count; $i++) {
        if ($worktrees[$i] -match '^worktree (.+)$') {
            $wtPath = $Matches[1]
            if ([System.StringComparer]::OrdinalIgnoreCase.Equals($wtPath, $resolvedPath)) {
                for ($j = $i + 1; $j -lt $worktrees.Count -and $worktrees[$j] -notmatch '^worktree '; $j++) {
                    if ($worktrees[$j] -match '^branch refs/heads/(.+)$') {
                        $branch = $Matches[1]
                        break
                    }
                }
                break
            }
        }
    }

    & git worktree remove --force $resolvedPath
    if ($LASTEXITCODE -ne 0) {
        return
    }

    if ($branch) {
        & git branch -D $branch
    }
}
New-Alias -Name wtr -Value Remove-GitWorktree -Force -Option AllScope

function Get-GitWorktrees {
    $worktrees = & git worktree list --porcelain $args
    $entries = @()
    $current = @{}
    foreach ($line in $worktrees) {
        if ($line -match '^worktree (.+)') {
            if ($current.Count) { $entries += $current }
            $current = @{ Path = $Matches[1] }
        } elseif ($line -match '^HEAD ([a-f0-9]+)') {
            $current.HEAD = $Matches[1]
        } elseif ($line -match '^branch refs/heads/(.+)') {
            $current.Branch = $Matches[1]
        } elseif ($line -eq 'bare') {
            $current.Branch = '(bare)'
        }
    }
    if ($current.Count) { $entries += $current }

    foreach ($e in $entries) {
        if ($e.Branch -eq '(bare)') {
            continue
        }
        $shortHash = if ($e.HEAD) { $e.HEAD.Substring(0, 7) } else { 'unknown' }
        $branch = if ($e.Branch) { $e.Branch } else { '(detached)' }
        $commitMsg = if ($e.HEAD) {
            & git -C $e.Path log -1 --format="%s" $e.HEAD 2>$null
        } else { '' }
        [PSCustomObject]@{
            Path        = $e.Path
            Branch      = $branch
            HEAD        = $shortHash
            LastCommit  = $commitMsg
        }
    }
}
New-Alias -Name wtl -Value Get-GitWorktrees -Force -Option AllScope

function Switch-GitWorktree {
    param([Parameter()][string]$Branch)

    $worktrees = Get-GitWorktrees
    if (-not $worktrees) {
        Write-Error "No worktrees found."
        return
    }

    if ($Branch) {
        $match = $worktrees | Where-Object { $_.Branch -eq $Branch }
        if (-not $match) {
            Write-Error "No worktree found for branch '$Branch'."
            return
        }
        Set-Location -Path $match.Path
        return
    }

    # Interactive pick
    $i = 0
    foreach ($wt in $worktrees) {
        Write-Host "[$i] $($wt.Branch)  $($wt.Path)"
        $i++
    }
    $choice = Read-Host "Select worktree index"
    if ($choice -match '^\d+$' -and [int]$choice -lt $worktrees.Count) {
        Set-Location -Path $worktrees[[int]$choice].Path
    } else {
        Write-Error "Invalid selection."
    }
}
New-Alias -Name wtcd -Value Switch-GitWorktree -Force -Option AllScope


###############################
# Code Section
###############################

function Invoke-Profile {
    . $PROFILE
}

function Set-NeovimConfig { Set-Location C:\Users\rpb003\AppData\Local\nvim && nvim }
New-Alias -Name nvc -Value Set-NeovimConfig -Force -Option AllScope

function ChangeHistory { nvim C:\Users\rpb003\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt }
New-Alias -Name hist -Value ChangeHistory -Force -Option AllScope

function Open-4DProject {
    param([string]$Path = ".\")

    $resolved = Resolve-Path $Path -ErrorAction Stop
    $4dExe = "C:\Program Files\4D\4D v20.1\4D\4D.exe"
    $datafile = "C:\dev\Data\AltPro.4DD"

    $searchDirs = @(
        (Join-Path $resolved "4D\Project"),
        (Join-Path $resolved "Project")
    )

    foreach ($dir in $searchDirs) {
        $project = Get-ChildItem -Path $dir -Filter "*.4DProject" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($project) {
            Start-Process -FilePath $4dExe -ArgumentList "`"$($project.FullName)`"", "`"$datafile`""
            return
        }
    }

    Write-Error "No .4DProject file found in '$resolved\4D\Project' or '$resolved\Project'"
}
New-Alias -Name 'open4d' -Value Open-4DProject -Force -Option AllScope

function Invoke-4DCompile {
    param([string]$Path = (Get-Location).Path)
    & "C:\dev\4dCompile.ps1" -Path $Path
}
New-Alias -Name 'compile4d' -Value Invoke-4DCompile -Force -Option AllScope


###############################
# File Section
###############################

function mkcd {
    param ([Parameter(Mandatory)][string]$Path)
    New-Item -Path $Path -ItemType Directory -Force & Out-Null
    Set-Location -Path $Path
}

function ff {
    param([Parameter(Mandatory)][string]$Name)
    Get-ChildItem -Recurse -Filter "*$Name*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
}

function CreateFile { New-Item -ItemType "File" $args }
New-Alias -Name touch -Value CreateFile -Force -Option AllScope

function ll {
    Get-ChildItem -Force | ForEach-Object {
        $color = if ($_.PSIsContainer) { 'Cyan' } else { 'White' }
        Write-Host $_.Name -ForegroundColor $color -NoNewline
        Write-Host "  " -NoNewline
    }
    Write-Host ""
}

function unzip {
    param([Parameter(Mandatory)][string]$File)

    if (-not (Test-Path -Path $File -PathType Leaf)) {
        Write-Error "File not found: $File"
        return
    }

    Expand-Archive -Path $File -DestinationPath (Get-Location) -Force
}

function y {
    $tmp = (New-TemporaryFile).FullName
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -Path $tmp
}


###############################
# System Section
###############################

function sysinfo { Get-ComputerInfo }


###############################
# Prompt Section
###############################

function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
    }
    $host.ui.Write($prompt)
}

# x-wing ascii art
$prompt = "
           __
.-.__      \ .-.  ___  __
|_|  '--.-.-(   \/\;;\_\.-._______.-.
(-)___     \ \ .-\ \;;\(   \       \ \
 Y    '---._\_((Q)) \;;\\ .-\     __(_)
 I           __'-' / .--.((Q))---'    \
 I     ___.-:    \|  |   \'-'_          \
 A  .-'      \ .-.\   \   \ \ '--.__     '\
 |  |____.----((Q))\   \__|--\_      \     '
    ( )        '-'  \_  :  \-' '--.___\
     Y                \  \  \       \(_)
     I                 \  \  \         \
     I                  \  \  \          \
     A                   \  \  \          '\
     |                    \  \__|           '
                           \_:.  \
                             \ \  \
                              \ \  \
                               \_\_|
"
Write-Host $prompt

# Greeting
$prompt = ""
$hourText = Get-Date -Format "HH"
$hour = [int]$hourText
if ( $hour -gt 17 ) { $prompt = "Good evening, Preston. Commands, assemble, and Shell Scripts, roll out!" }
elseif( $hour -gt 11 ) { $prompt = "Good afternoon, Preston. Please feed the CLI some commands.. coffee.. CTRL-ZZzzz.." }
elseif( $hour -gt 05 ) { $prompt = "Good morning, Preston. Early morning commands catches the bugs." }
else { $prompt = "It's kinda late, Preston, but the CLI will be with you. Always. ^_^" }

Write-Host $prompt
$prompt = ""
Write-Host "Use 'Show-Help' to display help"


###############################
# Help Section
###############################

function Show-Help {
    @'
Powershell Profile Help
=======================

Profile:
  nvim $PROFILE     Edit the current user's profile.
  Invoke-Profile    Reload the profile in the current session.

Git:
  gfp                 git fetch && git pull
  ga                  git add .
  gc <message>        git commit < -c message >
  gp                  git push
  gs                  git status
  gd                  git diff
  gl                  git log
  gsw <branch>        git switch <branch>
  gswb <branch>       git switch -c <branch>
  gb                  git branch
  gr </path/to/file>  git restore </path/to/file>
  gra                 git restore .
  wts <branch>        git worktree add at repo-root/../<branch> and cd into it.
  wtr <path>          git worktree remove <path>.
  wtl                 git worktree list.
  wtcd [<branch>]     cd into an existing worktree by branch name, or pick interactively.

Shortcuts:
  ff <name>           Find files recursively by name.
  compile4d [path]    Compile the 4D project of the current (or given) worktree.
  hist                Change PSReadLine History.
  ll                  Linux style `Get-ChildItem`.
  mkcd                Create and enter directory.
  nvc                 cd to neovim config and update neovim config.
  open4d [path]       Open 4D project in current (or given) directory.
  touch <filename>    make a new file.
  unzip <filename>    extract zip archive here.
  y                   Yazi - Terminal file explorer.
'@ | Write-Host
}


###############################
# PSReadLine and FZF Section
###############################

function Set-PSReadLineOptionsCompat {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory)][hashtable]$Options)

    $safeOptions = $Options.Clone()
    if ($PSVersionTable.PSEdition -ne 'Core') {
        $safeOptions.Remove('PredictionSource')
        $safeOptions.Remove('PredictionViewStyle')
    }

    if ($PSCmdlet.ShouldProcess('PSReadLine', 'Set PSReadLine options')) {
        Set-PSReadLineOption @safeOptions
    }
}

function Set-PredictionSource {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (Get-Command -Name 'Set-PredictionSource_Override' -ErrorAction SilentlyContinue) {
        Set-PredictionSource_Override
        return
    }

    if ($PSCmdlet.ShouldProcess('PSReadLine', 'Set prediction source')) {
        if ($PSVersionTable.PSEdition -eq 'Core') {
            Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        }

        Set-PSReadLineOption -MaximumHistoryCount 10000
    }
}

function Initialize-PSReadLine {
    if (-not $isInteractiveShell -or -not (Get-Module -ListAvailable -Name PSReadLine)) {
        return
    }

    $options = @{
        EditMode = 'Windows'
        HistoryNoDuplicates = $true
        HistorySearchCursorMovesToEnd = $true
        PredictionSource = 'History'
        PredictionViewStyle = 'ListView'
        BellStyle = 'None'
        Colors = @{
            Command = '#87CEEB'
            Parameter = '#98FB98'
            Operator = '#FFB6C1'
            Variable = '#DDA0DD'
            String = '#FFDAB9'
            Number = '#B0E0E6'
            Type = '#F0E68C'
            Comment = '#D3D3D3'
            Keyword = '#8367c7'
            Error = '#FF6347'
        }
    }

    Set-PSReadLineOptionsCompat -Options $options
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
    Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
    Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
    Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

    Set-PSReadLineOption -AddToHistoryHandler {
        param([string]$line)
        $line -notmatch '(?i)(password|secret|token|apikey|connectionstring)'
    }

    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
}

# Fzf (import the fuzzy finder and set a shortcut key to begin searching)
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'

###############################
# Startup Initialization
###############################

Invoke-Expression(&starship init powershell)
Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
Initialize-PSReadLine

if (Get-Command wt -ErrorAction SilentlyContinue) {
    Invoke-Expression (& wt config shell init powershell | Out-String)
}
