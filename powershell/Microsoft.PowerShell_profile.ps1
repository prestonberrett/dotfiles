###############################
# Shell Context
###############################

function Test-InteractiveShell {
    try {
        if ($Host.Name -ne 'ConsoleHost' -or
            [Console]::IsInputRedirected -or
            [Console]::IsOutputRedirected) {
            return $false
        }

        # `pwsh -Command ...` / `pwsh -File ...` / `-NonInteractive` run a script and exit,
        # even from a real terminal. -NoExit means the shell stays open, so it still counts.
        $cmdArgs = @([Environment]::GetCommandLineArgs() | Select-Object -Skip 1)
        if ($cmdArgs -match '^[-/]noe\w*$') { return $true }
        if ($cmdArgs -match '^[-/](c|com\w*|f|fil\w*|e|ec|enc\w*|noni\w*)$') { return $false }

        return $true
    } catch {
        return $false
    }
}

$isInteractiveShell = Test-InteractiveShell

function Test-Command {
    param([Parameter(Mandatory)][string]$Name)
    [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
}

function New-CompletionResult {
    param(
        [Parameter(Mandatory)][string]$Text,
        [string]$ToolTip = $Text
    )
    [System.Management.Automation.CompletionResult]::new($Text, $Text, 'ParameterValue', $ToolTip)
}

###############################
# Git Section
###############################

function Invoke-GitAddPatch { & git add --patch @args }
function Invoke-GitAddAll { & git add --all @args }
function Get-GitStatus { & git status -sb @args }
function Get-GitDiff { & git diff @args }
function Invoke-GitCommit { & git commit @args }
function Invoke-GitPush { & git push @args }
function Invoke-GitSwitchNewBranch { & git switch -c @args }
function Invoke-GitRestore { & git restore @args }
function Get-GitBlame { & git blame @args }

# gsw: git switch with branch-name tab completion.
# Extra switches go before the branch, so `gsw -c foo` and `gsw --detach foo` still work.
function Invoke-GitSwitch {
    param([string]$Branch)
    # PowerShell sends -c to $args but binds --long-options positionally, so keep
    # anything that starts with '-' in front.
    if (-not $Branch) { & git switch @args }
    elseif ($Branch.StartsWith('-')) { & git switch $Branch @args }
    else { & git switch @args $Branch }
}

# gra: discard ALL unstaged changes. Shows what will be lost and asks first,
# since `gra` is one letter away from `ga`.
function Invoke-GitRestoreAll {
    $changes = & git diff --stat
    if ($LASTEXITCODE -ne 0) { return }
    if (-not $changes) {
        Write-Host 'No unstaged changes to discard.'
        return
    }
    $changes | Write-Host
    $answer = Read-Host 'Discard ALL of these unstaged changes? [y/N]'
    if ($answer -notmatch '^(y|yes)$') {
        Write-Host 'Cancelled.'
        return
    }
    & git restore . @args
}

function Invoke-GitFetchPull {
    & git fetch --prune
    if ($LASTEXITCODE -eq 0) { & git pull @args }
}

# --oneline is left out on purpose: it would override the custom --pretty format.
function Get-GitLog {
    & git log --graph --abbrev-commit --all `
        --pretty=format:'%C(magenta)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%cr) [%an]' @args
}

function Get-GitBranch {
    & git branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate @args
}

function Get-GitDefaultBranch {
    $ref = & git symbolic-ref --short refs/remotes/origin/HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $ref) {
        return ($ref.Trim() -replace '^origin/', '')
    }
    foreach ($candidate in 'main', 'master') {
        & git show-ref --verify --quiet "refs/heads/$candidate" 2>$null
        if ($LASTEXITCODE -eq 0) { return $candidate }
    }
    return $null
}

# Fetch, then rebase the current branch on origin/<default branch>.
# --autostash parks uncommitted changes during the rebase and restores them after.
function Sync-GitBranch {
    $base = Get-GitDefaultBranch
    if (-not $base) {
        Write-Error 'Could not determine default branch.'
        return
    }
    & git fetch --prune
    if ($LASTEXITCODE -eq 0) { & git rebase --autostash "origin/$base" }
}

# Commit everything as WIP for a quick context switch
function Save-GitWip {
    & git add --all
    & git commit -m 'WIP'
}

function Get-GitBranchName {
    param([string]$Prefix = '')
    git branch --format='%(refname:short)' 2>$null |
        Where-Object { $_ -like "$Prefix*" }
}

# Branch-name completion for `git del`, `git switch`, etc.
Register-ArgumentCompleter -Native -CommandName git -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)

    $elements = $commandAst.CommandElements
    if ($elements.Count -lt 2) { return }

    # Still typing the subcommand itself? Leave it to default completion.
    if ($elements.Count -eq 2 -and $wordToComplete -eq $elements[1].ToString()) { return }

    if ($elements[1].ToString() -in 'del', 'switch', 'sw', 'checkout', 'merge', 'rebase') {
        Get-GitBranchName $wordToComplete | ForEach-Object { New-CompletionResult $_ }
    }
}

# Branch-name completion for gsw (a PowerShell function, so it needs a
# parameter completer rather than a -Native one)
Register-ArgumentCompleter -CommandName Invoke-GitSwitch, gsw -ParameterName Branch -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)
    Get-GitBranchName $wordToComplete | ForEach-Object { New-CompletionResult $_ }
}

# Branch-name completion for `gp -u origin <branch>` (Invoke-GitPush takes
# raw @args, so it needs a native-style completer)
Register-ArgumentCompleter -Native -CommandName gp, Invoke-GitPush -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    if ($wordToComplete -like '-*') { return }
    Get-GitBranchName $wordToComplete | ForEach-Object { New-CompletionResult $_ }
}

###############################
# Git Worktree Section
###############################

# Resolves relative paths against PowerShell's current location (not the
# process working directory, which Set-Location doesn't update).
function ConvertTo-NormalizedPath {
    param([string]$Path)
    try {
        $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        [System.IO.Path]::GetFullPath($resolved).TrimEnd('\', '/')
    } catch {
        $Path
    }
}

# Fast parse of `git worktree list --porcelain` (no per-worktree git calls).
# The first entry git reports is the main worktree (it may be bare, in which
# case it's filtered out and no returned entry is marked IsMain).
function Get-GitWorktreeEntry {
    $lines = & git worktree list --porcelain 2>$null
    if ($LASTEXITCODE -ne 0) { return }

    $entries = [System.Collections.Generic.List[object]]::new()
    $current = $null

    foreach ($line in $lines) {
        if ($line -match '^worktree (.+)$') {
            if ($current) { $entries.Add([pscustomobject]$current) }
            $current = [ordered]@{
                Path   = ConvertTo-NormalizedPath $Matches[1]
                Branch = '(detached)'
                HEAD   = ''
                IsBare = $false
                IsMain = ($entries.Count -eq 0)
            }
        } elseif ($current) {
            if ($line -match '^HEAD ([0-9a-f]+)') { $current.HEAD = $Matches[1] }
            elseif ($line -match '^branch refs/heads/(.+)$') { $current.Branch = $Matches[1] }
            elseif ($line -eq 'bare') { $current.IsBare = $true }
        }
    }
    if ($current) { $entries.Add([pscustomobject]$current) }

    $entries | Where-Object { -not $_.IsBare }
}

# wtl: list worktrees with their last commit message
function Get-GitWorktrees {
    Get-GitWorktreeEntry | ForEach-Object {
        $message = if ($_.HEAD) { & git log -1 --format='%s' $_.HEAD 2>$null } else { '' }
        [pscustomobject]@{
            Path       = $_.Path
            Branch     = $_.Branch
            HEAD       = if ($_.HEAD) { $_.HEAD.Substring(0, [Math]::Min(7, $_.HEAD.Length)) } else { 'unknown' }
            LastCommit = $message
        }
    }
}

# wts: create a worktree (sibling of the repo folder) on a new branch and cd into it.
# Without -ParentBranch, it fetches and branches from origin/<default branch> so the
# new worktree doesn't start from a stale local copy.
function New-GitWorktree {
    param(
        [Parameter(Mandatory)][string]$Branch,
        [string]$ParentBranch
    )

    $repoRoot = & git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
        Write-Error 'Not inside a git repository.'
        return
    }

    $startPoint = $ParentBranch
    if (-not $startPoint) {
        $base = Get-GitDefaultBranch
        if (-not $base) {
            Write-Error 'Could not determine default branch. Please specify -ParentBranch.'
            return
        }

        $startPoint = $base
        & git fetch origin $base 2>$null
        if ($LASTEXITCODE -eq 0) {
            & git show-ref --verify --quiet "refs/remotes/origin/$base" 2>$null
            if ($LASTEXITCODE -eq 0) { $startPoint = "origin/$base" }
        } else {
            Write-Warning "Could not fetch origin/$base; branching from local '$base' instead."
        }
    }

    # Replace characters not allowed in directory names with '-'
    $safeName = $Branch -replace '[\\/:*?"<>|]', '-'
    $path = Join-Path (Split-Path $repoRoot.Trim() -Parent) $safeName

    # --no-track: otherwise a branch made from origin/main would track origin/main,
    # and a plain `git push` would refuse because the names don't match.
    & git worktree add --no-track -b $Branch $path $startPoint
    if ($LASTEXITCODE -eq 0) {
        Set-Location -Path $path
    }
}

# wtr: remove a worktree by branch name, folder name, or full path.
# Safe by default: refuses dirty worktrees, and keeps branches whose changes
# aren't on the default branch yet (merged and squash-merged branches are deleted).
# Use -Force to discard uncommitted work and delete the branch anyway.
function Remove-GitWorktree {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force
    )

    $entries = @(Get-GitWorktreeEntry)
    if (-not $entries) {
        Write-Error 'Not inside a git repository.'
        return
    }

    $target = ConvertTo-NormalizedPath $Path
    $wt = $entries | Where-Object {
        $_.Branch -eq $Path -or
        (Split-Path $_.Path -Leaf) -eq $Path -or
        $_.Path -eq $target
    } | Select-Object -First 1

    if (-not $wt) {
        Write-Error "No worktree found matching '$Path'."
        return
    }
    if ($wt.IsMain) {
        Write-Error 'Refusing to remove the main worktree.'
        return
    }

    # Can't remove a folder we're standing in, so step out first: to the main
    # worktree, or to the worktree's parent folder if the main one is bare.
    $here = ConvertTo-NormalizedPath (Get-Location).Path
    if ($here -eq $wt.Path -or $here.StartsWith($wt.Path + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        $main = $entries | Where-Object IsMain | Select-Object -First 1
        $refuge = if ($main) { $main.Path } else { Split-Path $wt.Path -Parent }
        Set-Location -Path $refuge
    }

    $removeArgs = @('worktree', 'remove')
    if ($Force) { $removeArgs += '--force' }
    & git @removeArgs $wt.Path
    if ($LASTEXITCODE -ne 0) {
        if (-not $Force) { Write-Warning 'Worktree not removed. Use -Force to discard uncommitted changes.' }
        return
    }

    if ($wt.Branch -eq '(detached)') { return }

    if ($Force) {
        & git branch -D $wt.Branch
        return
    }

    # A normal merge passes `git branch -d`. A squash merge doesn't (the squash is
    # a new commit), so check whether its changes already landed upstream.
    & git branch -d $wt.Branch 2>$null
    if ($LASTEXITCODE -eq 0) { return }

    if (Test-GitSquashMerged $wt.Branch) {
        & git branch -D $wt.Branch | Out-Null
        Write-Host "Deleted branch '$($wt.Branch)' (squash-merged into origin/$(Get-GitDefaultBranch))."
    } else {
        Write-Warning "Branch '$($wt.Branch)' was not deleted: its changes aren't on the default branch yet. Use -Force to delete it anyway."
    }
}

# True when <Branch>'s combined changes already exist as a commit on
# origin/<default branch>, i.e. it was squash-merged (or cherry-picked).
# Builds a throwaway commit holding the whole branch as one change, then asks
# `git cherry` whether upstream has an equivalent patch.
function Test-GitSquashMerged {
    param([Parameter(Mandatory)][string]$Branch)

    $base = Get-GitDefaultBranch
    if (-not $base) { return $false }

    # Make sure we can see the squash commit; fine if this fails while offline.
    & git fetch --quiet origin $base 2>$null
    $upstream = "origin/$base"
    & git show-ref --verify --quiet "refs/remotes/$upstream" 2>$null
    if ($LASTEXITCODE -ne 0) { $upstream = $base }

    $mergeBase = & git merge-base $upstream $Branch 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $mergeBase) { return $false }

    $tree = & git rev-parse "$Branch^{tree}" 2>$null
    if ($LASTEXITCODE -ne 0) { return $false }
    $squashed = & git commit-tree $tree -p $mergeBase -m 'squash-merge check' 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $squashed) { return $false }

    $cherry = & git cherry $upstream $squashed 2>$null
    return [bool]($cherry | Where-Object { $_ -like '-*' })
}


# wtcd: cd into a worktree by branch name, or pick one with fzf
function Switch-GitWorktree {
    param([string]$Branch)

    $worktrees = @(Get-GitWorktreeEntry)
    if (-not $worktrees) {
        Write-Error 'No worktrees found.'
        return
    }

    if ($Branch) {
        $match = $worktrees | Where-Object { $_.Branch -eq $Branch } | Select-Object -First 1
        if (-not $match) {
            Write-Error "No worktree found for branch '$Branch'."
            return
        }
        Set-Location -Path $match.Path
        return
    }

    if (Test-Command fzf) {
        $pick = $worktrees |
            ForEach-Object { "$($_.Branch)`t$($_.Path)" } |
            fzf --delimiter '\t' --with-nth '1,2' --height '40%' --reverse
        if ($pick) { Set-Location -Path ($pick -split "`t")[1] }
        return
    }

    # Fallback when fzf isn't installed
    for ($i = 0; $i -lt $worktrees.Count; $i++) {
        Write-Host "[$i] $($worktrees[$i].Branch)  $($worktrees[$i].Path)"
    }
    $choice = Read-Host 'Select worktree index'
    if ($choice -match '^\d+$' -and [int]$choice -lt $worktrees.Count) {
        Set-Location -Path $worktrees[[int]$choice].Path
    } else {
        Write-Error 'Invalid selection.'
    }
}

# Worktree branch names for wtcd
Register-ArgumentCompleter -CommandName Switch-GitWorktree, wtcd -ParameterName Branch -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    Get-GitWorktreeEntry |
        Where-Object { $_.Branch -like "$wordToComplete*" } |
        ForEach-Object { New-CompletionResult $_.Branch $_.Path }
}

# Worktree folder names for wtr (main worktree excluded)
Register-ArgumentCompleter -CommandName Remove-GitWorktree, wtr -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    Get-GitWorktreeEntry |
        Where-Object { -not $_.IsMain } |
        ForEach-Object { Split-Path $_.Path -Leaf } |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object { New-CompletionResult $_ }
}

###############################
# Terraform and AWS Section
###############################

function Invoke-TerraformInit { & terraform init @args }
function Invoke-TerraformPlan { & terraform plan @args }
function Invoke-TerraformApply { & terraform apply @args }

function Test-Terraform {
    & terraform fmt -check -recursive
    & terraform validate
}

# Switch (or show) the active AWS profile. Production profiles print in red.
function Set-AwsProfile {
    param([string]$Name)

    if ($Name) { $env:AWS_PROFILE = $Name }
    $active = if ($env:AWS_PROFILE) { $env:AWS_PROFILE } else { '(default)' }
    $color = if ($active -match 'prod') { 'Red' } else { 'Green' }
    Write-Host "AWS_PROFILE: $active" -ForegroundColor $color
}

Register-ArgumentCompleter -CommandName Set-AwsProfile, awsp -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    if (-not (Test-Command aws)) { return }
    aws configure list-profiles 2>$null |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object { New-CompletionResult $_ }
}

# AWS CLI tab completion (uses the aws_completer that ships with the CLI)
if (Test-Command aws_completer) {
    Register-ArgumentCompleter -Native -CommandName aws -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)

        # The cursor position is relative to the whole input line, and ToString()
        # drops a trailing space; fix both so `aws s3 <Tab>` completes the next word.
        $line  = $commandAst.ToString()
        $point = $cursorPosition - $commandAst.Extent.StartOffset
        if ($line.Length -lt $point) { $line = $line.PadRight($point) }

        $env:COMP_LINE = $line
        $env:COMP_POINT = $point
        try {
            aws_completer | ForEach-Object { New-CompletionResult $_ }
        } finally {
            Remove-Item Env:COMP_LINE, Env:COMP_POINT -ErrorAction SilentlyContinue
        }
    }
}

###############################
# Code Section
###############################

function Set-NeovimConfig {
    Set-Location (Join-Path $env:LOCALAPPDATA 'nvim')
    nvim
}

function Edit-PSReadLineHistory { nvim (Get-PSReadLineOption).HistorySavePath }

function Edit-Profile { nvim $PROFILE }

# Set $env:FOURD_EXE (e.g. in your user environment variables) to change the
# default 4D version without editing this file. Deliberately not auto-detected:
# opening a project in a newer 4D can convert it.
# The data file is machine-specific: pass -DataFile or set $env:FOURD_DATAFILE.
function Open-4DProject {
    param(
        [string]$Path = '.\',
        [string]$Exe = $(if ($env:FOURD_EXE) { $env:FOURD_EXE } else { 'C:\Program Files\4D\4D v20.1\4D\4D.exe' }),
        [string]$DataFile = $env:FOURD_DATAFILE
    )

    if (-not $DataFile) {
        Write-Error "No data file given. Pass -DataFile or set the FOURD_DATAFILE environment variable."
        return
    }

    $resolved = Resolve-Path $Path -ErrorAction Stop
    if (-not (Test-Path $Exe)) {
        $installed = Get-ChildItem 'C:\Program Files\4D\*\4D\4D.exe' -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
        $hint = if ($installed) { "Installed: $($installed -join '; ')" } else { 'No 4D installs found under C:\Program Files\4D.' }
        Write-Error "4D executable not found: $Exe. $hint Use -Exe or set `$env:FOURD_EXE."
        return
    }
    if (-not (Test-Path $DataFile)) {
        Write-Warning "Data file not found: $DataFile (4D will ask you to pick or create one)."
    }

    $searchDirs = @(
        (Join-Path $resolved '4D\Project'),
        (Join-Path $resolved 'Project')
    )

    foreach ($dir in $searchDirs) {
        $project = Get-ChildItem -Path $dir -Filter '*.4DProject' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($project) {
            Start-Process -FilePath $Exe -ArgumentList "`"$($project.FullName)`"", "`"$DataFile`""
            return
        }
    }

    Write-Error "No .4DProject file found in '$resolved\4D\Project' or '$resolved\Project'"
}

function Invoke-4DCompile {
    param([string]$Path = (Get-Location).Path)
    & 'C:\dev\4dCompile.ps1' -Path $Path
}

###############################
# File and Navigation Section
###############################

function .. { Set-Location .. }
function ... { Set-Location ..\.. }

function mkcd {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -Path $Path -ItemType Directory -Force | Out-Null
    Set-Location -Path $Path
}

function ff {
    param([Parameter(Mandatory)][string]$Name)
    Get-ChildItem -Recurse -Filter "*$Name*" -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
}

# Create the file, or bump its timestamp if it already exists
function Invoke-Touch {
    param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Path)
    foreach ($p in $Path) {
        if (Test-Path -LiteralPath $p) {
            (Get-Item -LiteralPath $p).LastWriteTime = Get-Date
        } else {
            New-Item -ItemType File -Path $p | Out-Null
        }
    }
}

function ll {
    Get-ChildItem -Force | ForEach-Object {
        $color = if ($_.PSIsContainer) { 'Cyan' } else { 'White' }
        Write-Host $_.Name -ForegroundColor $color -NoNewline
        Write-Host '  ' -NoNewline
    }
    Write-Host ''
}

function unzip {
    param([Parameter(Mandatory)][string]$File)

    if (-not (Test-Path -Path $File -PathType Leaf)) {
        Write-Error "File not found: $File"
        return
    }
    Expand-Archive -Path $File -DestinationPath (Get-Location) -Force
}

function which {
    param([Parameter(Mandatory)][string]$Name)
    Get-Command $Name -All | Select-Object Name, CommandType, Source
}

# Yazi: cd to wherever you quit
function y {
    $tmp = (New-TemporaryFile).FullName
    yazi @args --cwd-file="$tmp"
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

function Get-ListeningPorts {
    Get-NetTCPConnection -State Listen | Sort-Object LocalPort |
        Select-Object LocalAddress, LocalPort, OwningProcess,
            @{ Name = 'Process'; Expression = { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName } }
}

function Stop-PortProcess {
    param([Parameter(Mandatory)][int]$Port)

    $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
    if (-not $connections) {
        Write-Warning "Nothing is listening on port $Port."
        return
    }
    $connections | Select-Object -ExpandProperty OwningProcess -Unique |
        ForEach-Object { Stop-Process -Id $_ -Confirm }
}

###############################
# Aliases
###############################

# Note: gc, gp and gl replace PowerShell's built-in aliases for Get-Content,
# Get-ItemProperty and Get-Location in this session. Pasted snippets that use
# `gc file.txt` will run git instead; use the full cmdlet names there.
$profileAliases = @{
    # Git
    gap    = 'Invoke-GitAddPatch'
    ga     = 'Invoke-GitAddAll'
    gs     = 'Get-GitStatus'
    gfp    = 'Invoke-GitFetchPull'
    gd     = 'Get-GitDiff'
    gc     = 'Invoke-GitCommit'
    gp     = 'Invoke-GitPush'
    gl     = 'Get-GitLog'
    gsw    = 'Invoke-GitSwitch'
    gswb   = 'Invoke-GitSwitchNewBranch'
    gb     = 'Get-GitBranch'
    gra    = 'Invoke-GitRestoreAll'
    gr     = 'Invoke-GitRestore'
    gbl    = 'Get-GitBlame'
    gsync  = 'Sync-GitBranch'
    gwip   = 'Save-GitWip'
    # Worktrees
    wts    = 'New-GitWorktree'
    wtr    = 'Remove-GitWorktree'
    wtl    = 'Get-GitWorktrees'
    wtcd   = 'Switch-GitWorktree'
    # Terraform / AWS
    tfi    = 'Invoke-TerraformInit'
    tfp    = 'Invoke-TerraformPlan'
    tfa    = 'Invoke-TerraformApply'
    tfv    = 'Test-Terraform'
    awsp   = 'Set-AwsProfile'
    # Code
    nvc    = 'Set-NeovimConfig'
    hist   = 'Edit-PSReadLineHistory'
    ep     = 'Edit-Profile'
    open4d = 'Open-4DProject'
    compile4d = 'Invoke-4DCompile'
    # Files / system
    touch  = 'Invoke-Touch'
    ports  = 'Get-ListeningPorts'
    killport = 'Stop-PortProcess'
}

foreach ($name in $profileAliases.Keys) {
    New-Alias -Name $name -Value $profileAliases[$name] -Force -Option AllScope -Scope Global
}

###############################
# Prompt Section
###############################

# Called by starship before each prompt: tells the terminal (WezTerm) the cwd
function Invoke-Starship-PreCommand {
    $location = $executionContext.SessionState.Path.CurrentLocation
    if ($location.Provider.Name -eq 'FileSystem') {
        $esc = [char]27
        $providerPath = $location.ProviderPath -replace '\\', '/'
        $host.UI.Write("$esc]7;file://${env:COMPUTERNAME}/$providerPath$esc\")
    }
}

function Show-Greeting {
    # Optional ASCII-art banner: paste it between the @' and '@ lines.
    # Nothing is printed while it's empty.
    $banner = @'
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
'@
    if ($banner.Trim()) { Write-Host $banner }

    $hour = [int](Get-Date -Format 'HH')
    $greeting = if ($hour -gt 17) { 'Good evening, Preston. Commands, assemble, and Shell Scripts, roll out!' }
                elseif ($hour -gt 11) { 'Good afternoon, Preston. Please feed the CLI some commands.. coffee.. CTRL-ZZzzz..' }
                elseif ($hour -gt 5) { 'Good morning, Preston. Early morning commands catches the bugs.' }
                else { "It's kinda late, Preston, but the CLI will be with you. Always. ^_^" }
    Write-Host $greeting
    Write-Host "Use 'Show-Help' to display help"
}

###############################
# Help Section
###############################

function Show-Help {
    @'
Powershell Profile Help
=======================

Profile:
  ep                    Edit this profile in nvim.
  . $PROFILE            Reload the profile (type it directly; it won't work from inside a function).

Git:
  gfp                   git fetch --prune, then pull
  ga                    git add --all
  gap                   git add --patch
  gc                    git commit (opens editor; or gc -m "<message>")
  gp                    git push
  gs                    git status -sb
  gd                    git diff
  gl                    git log graph
  gsw <branch>          git switch <branch>   (tab completes branches)
  gswb <branch>         git switch -c <branch>
  gb                    git branch, newest first
  gr <file>             git restore <file>
  gra                   git restore . (shows changes and asks first)
  gbl <file>            git blame
  gsync                 fetch, then rebase on origin/<default branch> (autostash)
  gwip                  commit everything as "WIP"

Worktrees:
  wts <branch> [-ParentBranch <b>]
                        New worktree at <repo>/../<branch>, cd into it.
                        Defaults to a fresh origin/<default branch>.
  wtr <name> [-Force]   Remove a worktree by branch/folder name or path. Safe unless -Force.
  wtl                   List worktrees.
  wtcd [<branch>]       cd into a worktree by branch, or pick with fzf.

Terraform / AWS:
  tfi, tfp, tfa         terraform init / plan / apply
  tfv                   terraform fmt -check, then validate
  awsp [<profile>]      Show or set AWS_PROFILE (prod shows in red).

Shortcuts:
  ff <name>             Find files recursively by name.
  compile4d [path]      Compile the 4D project of the current (or given) worktree.
  open4d [path]         Open 4D project in current (or given) directory ($env:FOURD_EXE overrides the 4D version; data file from -DataFile or $env:FOURD_DATAFILE).
  hist                  Edit PSReadLine history.
  ll                    Compact colored directory listing.
  mkcd <dir>            Create and enter directory.
  nvc                   cd to the neovim config and open it.
  touch <file>          Create a file or bump its timestamp.
  unzip <file>          Extract zip archive here.
  which <cmd>           Show where a command comes from.
  ports                 List listening TCP ports.
  killport <port>       Stop the process listening on a port (asks first).
  sysinfo               Show computer info.
  y                     Yazi terminal file explorer.
  .. / ...              Up one / two directories.
'@ | Write-Host
}

###############################
# PSReadLine and FZF Section
###############################

function Initialize-PSReadLine {
    if (-not $isInteractiveShell -or -not (Get-Module -ListAvailable -Name PSReadLine)) {
        return
    }

    $isCore = $PSVersionTable.PSEdition -eq 'Core'

    # CompletionPredictor adds argument-aware suggestions (PowerShell 7+):
    #   Install-Module CompletionPredictor
    $hasPredictor = $isCore -and (Get-Module -ListAvailable -Name CompletionPredictor)
    if ($hasPredictor) { Import-Module CompletionPredictor }

    $options = @{
        EditMode                      = 'Windows'
        HistoryNoDuplicates           = $true
        HistorySearchCursorMovesToEnd = $true
        MaximumHistoryCount           = 10000
        PredictionSource              = if ($hasPredictor) { 'HistoryAndPlugin' } else { 'History' }
        PredictionViewStyle           = 'ListView'
        BellStyle                     = 'None'
        Colors                        = @{
            Command   = '#87CEEB'
            Parameter = '#98FB98'
            Operator  = '#FFB6C1'
            Variable  = '#DDA0DD'
            String    = '#FFDAB9'
            Number    = '#B0E0E6'
            Type      = '#F0E68C'
            Comment   = '#D3D3D3'
            Keyword   = '#8367c7'
            Error     = '#FF6347'
        }
    }

    # Windows PowerShell 5.1 doesn't support the prediction options
    if (-not $isCore) {
        $options.Remove('PredictionSource')
        $options.Remove('PredictionViewStyle')
    }

    Set-PSReadLineOption @options

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

    # Keep anything that looks like a secret out of the saved history file.
    # On PSReadLine 2.2+ such lines stay in this session's history (so UpArrow
    # still finds them) but are never written to disk; PSReadLine's own default
    # check still runs for everything else. Older PSReadLine (e.g. the 2.0 that
    # ships with Windows PowerShell 5.1) can only drop the line entirely.
    $secretPattern = '(?i)(password|secret|token|apikey|connectionstring)'
    $psReadLine = Get-Module -Name PSReadLine
    if ($psReadLine -and $psReadLine.Version -ge [version]'2.2.0') {
        Set-PSReadLineOption -AddToHistoryHandler {
            param([string]$line)
            if ($line -match $secretPattern) {
                return [Microsoft.PowerShell.AddToHistoryOption]::MemoryOnly
            }
            [Microsoft.PowerShell.PSConsoleReadLine]::GetDefaultAddToHistoryOption($line)
        }.GetNewClosure()
    } else {
        Set-PSReadLineOption -AddToHistoryHandler {
            param([string]$line)
            $line -notmatch $secretPattern
        }.GetNewClosure()
    }
}

###############################
# Startup Initialization
###############################

if ($isInteractiveShell) {
    Show-Greeting

    if (Get-Module -ListAvailable -Name PSFzf) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
    }

    if (Test-Command starship) {
        Invoke-Expression (& starship init powershell)
    }
    if (Test-Command zoxide) {
        Invoke-Expression (& { (zoxide init --cmd cd powershell | Out-String) })
    }

    Initialize-PSReadLine
}
