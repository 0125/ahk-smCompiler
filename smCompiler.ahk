#SingleInstance, force
#Persistent

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

FileCopy, % OutDir "\" OutNameNoExt ".smx", g:\GAMES\SourceServers\l4d1\left4dead\addons\sourcemod\plugins, 1

; load plugin in server
If !WinExist("ahk_exe srcds.exe")
{
	run, % serverPath "\serverL4D1.bat"
	WinWait, ahk_exe srcds.exe
}
_activeWindow := WinActive("A")
WinActivate, ahk_exe srcds.exe
SendInput, sm plugins unload_all`; sm plugins load %OutNameNoExt% {enter}
WinActivate, % "ahk_id " _activeWindow


; */
; compile("E:\Downloads\l4d_ff_reverse.sp")	; compile file
return

loadSettings:
	global sm := []
	sm.Version := "1.8"
	sm.Dir := A_ScriptDir "\res\" sm.Version
	sm.CompileDir := A_ScriptDir "\res\" sm.Version "\compiled"
	
	serverPath := "g:\GAMES\SourceServers\l4d1"
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

~^s::reload