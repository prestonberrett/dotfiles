REM @echo off

REM set tmpfile=%TEMP%\yazi-cwd.%random%

REM yazi %* --cwd-file="%tmpfile%"

REM :: If the file does not exist, then exit
REM if not exist "%tmpfile%" exit /b 0

REM :: If the file exist, then read the content and change the directory
REM set /p cwd=<"%tmpfile%"
REM if not "%cwd%"=="" (
REM     cd /d "%cwd%"
REM )
REM del "%tmpfile%"
