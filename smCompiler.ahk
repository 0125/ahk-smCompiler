#SingleInstance, force
#Persistent
hotkey, IfWinActive, ahk_exe Notepad++.exe
hotkey, ~^s, reloadScript

Gosub loadSettings

; /*
; get file from notepad++ title
WinGetTitle, winTitle, ahk_class Notepad++
StringReplace, file, winTitle, - Notepad++
file := Trim(file)

; only compile .sp files
SplitPath, file, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
If !(OutExtension = "sp")
	return
	
compile(file)
hotkey, f1, loadPlugin
return

; */
; compile("E:\Downloads\l4d_ff_reverse.sp")	; compile file
return

loadPlugin:
	Gosub setGameVersion
	
	FileCopy, % OutDir "\" OutNameNoExt ".smx", g:\GAMES\SourceServers\l4d1\left4dead\addons\sourcemod\plugins, 1
	FileCopy, % OutDir "\" OutNameNoExt ".smx", g:\GAMES\SourceServers\l4d2\left4dead2\addons\sourcemod\plugins, 1
		
	If !WinExist("ahk_exe srcds.exe")
	{
		run, % serverPath "\serverL4D" gameVersion ".bat"
		WinWait, ahk_exe srcds.exe
	}
	_activeWindow := WinActive("A")
	WinActivate, ahk_exe srcds.exe
	SendInput, sm plugins unload %OutNameNoExt%`; sm plugins load %OutNameNoExt% {enter}
	WinActivate, % "ahk_id " _activeWindow
	
	If WinExist("ahk_class Valve001")
		WinActivate, ahk_class Valve001
return

loadSettings:
	global sm := []
	sm.Version := "1.8"
	sm.Dir := A_ScriptDir "\res\" sm.Version
	sm.CompileDir := A_ScriptDir "\res\" sm.Version "\compiled"
	
	Gosub setGameVersion
	
	serverPath := "g:\GAMES\SourceServers\l4d" gameVersion
return

setGameVersion:
	gameVersion := 2
	IfWinExist, ahk_exe left4dead.exe
		gameVersion := 1
	IfWinExist, ahk_exe left4dead2.exe
		gameVersion := 2
return

compile(input) {
	DetectHiddenWindows, On
	
	SplitPath, input, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
	
	smDir := sm.Dir
	ErrorFile := "smCompilerErrors.txt"
	run, %comspec% /c "%smDir%\spcomp.exe" %input% -e=%OutDir%\%ErrorFile%, % OutDir, Hide, cmdPID	; silent
	WinWait, ahk_pid%cmdPID%
	WinWaitClose, ahk_pid%cmdPID%
	If FileExist(OutDir "\" ErrorFile)
	{
		FileRead, Error, % OutDir "\" ErrorFile
		FileDelete, % OutDir "\" ErrorFile
		msgbox, % Error
	}
	else
	{
		tooltip Compiled!
		SetTimer, closeTooltip, -250
	}
	
}

closeTooltip:
	tooltip
return

reloadScript:
	reload
return