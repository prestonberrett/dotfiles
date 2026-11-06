#Requires AutoHotkey v2.0 ; For security
#SingleInstance force

:X:eml::SendText(EnvGet("WORK_EMAIL")) ; set WORK_EMAIL in your user environment
