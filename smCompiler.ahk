/*
	This script needs this ingame bind to function:
		bind "arrowdown" "exec commands.cfg"

	ToDo:
		https://wiki.alliedmods.net/Spcomp_switches
			Instead of copying l4d_stock into smComper sourcemod versions folders,
			use the -i switch and a setting in smcompiler.ahk to include them

	Steam appidss
		http://api.steampowered.com/ISteamApps/GetAppList/v0002/
*/

#SingleInstance, force
#Persistent
SetBatchLines -1
OnExit, exitRoutine
global debug := 0	; debug status
global settings	:= []									; settings obj
global settingsFile	:= A_ScriptDir "\settings.json"		; settings file
global appidsFile	:= A_ScriptDir "\res\appids.json"	; settings file
If !FileExist(appidsFile) {
	SplashTextOn, 400, 20, % A_ScriptName, Downloading app id file
	DownloadToFile("http://api.steampowered.com/ISteamApps/GetAppList/v0002/", appidsFile)
	SplashTextOff
}
global guiConsole := []	; vars relevant to guiConsole
global steam := []		; stores steam vars
global plugin := []		; stores notepad plus plus opened file vars
global game := []		; stores game vars
global sm := []			; stores sourcemod vars
sm.Version := "1.9"
loadSettings()
If (debug) {
	Menu, tray, NoStandard
	Menu, tray, add, Save game position, saveGamePos
	Menu, tray, add
	Menu, tray, Standard
	
	; msgbox end of debug section
	return
}
gameRunning := checkRunningGames()
If !(gameRunning)
	guiSelect()
else
	Gosub exitAfterGameClose
return
#Include <JSON>
#Include, %A_ScriptDir%\inc
#Include, functions.ahk
#Include, subroutines.ahk
#Include, Edit.ahk

:*:smtemplate::
smtemplate=
(
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "My First Plugin",
	author = "Me",
	description = "My first plugin ever",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	PrintToServer("Hello world!");
}
)
	pasteText(smtemplate)
return

f5::
	setCompileFile()
return

#IfWinActive, ahk_exe Notepad++.exe

~^s::
	gui msgbox: destroy
	If InStr(getNotepadPlusPlusFile(), "ahk")
		reload
	else If (compile(plugin.path))
		Gosub loadPlugin
return
f1::Gosub loadPlugin

#IfWinActive
