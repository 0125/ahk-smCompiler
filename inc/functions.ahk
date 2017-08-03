
guiSelect() {
	btnWidth := 65
	gui select: Default
	gui select: +LabelguiSelect_ +Hwnd_guiSelect
	gui select: margin, 5, 5
	gui select: add, listview, w500 r10 gguiSelect_lv AltSubmit, Game|Path
	gui select: add, button, w%btnWidth% gguiSelect_add, Add
	gui select: add, button, x+5 w%btnWidth% gguiSelect_remove Disabled, Remove
	gui select: add, button, x+5 w%btnWidth% gguiSelect_run Disabled, Run
	gui select: show
	Gosub guiSelect_lvRefresh
	return
	
	guiSelect_lv:
		If (A_GuiEvent = "Normal") {
			LV_GetText(selectedGame, A_EventInfo)
			Gosub setGame
		}
		If (A_GuiEvent = "DoubleClick")	{
			LV_GetText(selectedGame, A_EventInfo)
			Gosub setGame
			Gosub guiSelect_run
		}
		Gosub guiSelect_refresh
	return
	
	setGame:
		setGameObj(selectedGame)
	return
	
	guiSelect_refresh:
		If !(selectedGame) or (selectedGame = "game") {
			GuiControl select: Disable, Button2
			GuiControl select: Disable, Button3
		}
		else {
			GuiControl select: Enable, Button2
			GuiControl select: Enable, Button3
		}
	return
	
	guiSelect_lvRefresh:
		gui select: default
		GuiControl, -Redraw, SysListView321
		LV_Delete()
		
		for loopGame in settings["games"]
			LV_Add(, settings["games", loopGame, "title"], settings["games", loopGame, "Path"])

		LV_ModifyCol(1, "AutoHDR")
		LV_ModifyCol(2, "AutoHDR")
		LV_ModifyCol(3, "AutoHDR")
			
		GuiControl, +Redraw, SysListView321
	return
	
	guiSelect_add:
		FileSelectFile, newExe, 3, % steam.dir "\steamapps\common\" , Select source game executable, Executable (*.exe)
		If !(newExe)
			return
		SplitPath, newExe, ExeName, ExeDir, ExeExtension, ExeNameNoExt, ExeDrive
		settings["games", ExeNameNoExt, "path"] := newExe
		settings["games", ExeNameNoExt, "title"] := ExeNameNoExt
		settings["games", ExeNameNoExt, "dir"] := ExeDir
		settings["games", ExeNameNoExt, "exe"] := ExeName
		
		loop, % ExeDir "\steam_appid.txt", 0, 1
		{
			FileRead, appid, % A_LoopFileFullPath
			break
		}
			
		settings["games", ExeNameNoExt, "appid"] := appid
		
		Gosub guiSelect_lvRefresh
	return
	
	guiSelect_remove:
		settings["games"].Delete(selectedGame)
		Gosub guiSelect_lvRefresh
	return
	
	guiSelect_run:
		Gosub guiSelect_close
		runGame()
		Gosub exitAfterGameClose
	return
	
	guiSelect_close:
		gui select: destroy
	return
}

guiMsgBox(input) {
	gui msgbox: new
	gui msgbox: +Hwnd_msgbox +Labelmsgbox_
	
	gui msgbox: add, edit, hwnd_editControl, % input
	ControlGetPos, eX, eY, eW, eH, , ahk_id %_editControl%
	gui msgbox: add, button, % " w" eW " hwnd_buttonOk Default gMsgBox_Ok", Ok
	gui msgbox: show, AutoSize, % plugin

	SendMessage, 0xB1, start, end,, ahk_id %_editControl% ; deselect text
	ControlFocus, , ahk_id %_buttonOk%
	return
	
	MsgBox_Ok:
		gui msgbox: destroy
	return
}

guiConsole() {
	static _guiConsole, _editControl, oldConsoleLastModified, oldConsoleOutput
	
	If !WinExist("ahk_id " _guiConsole) {
		gui console: new
		gui console: margin, 5, 5
		gui console: +Hwnd_guiConsole +LabelguiConsole_ +Resize
		gui console: add, edit, w400 h200 hwnd_editControl -wrap +hscroll, % input
		If (settings["pos", "guiConsole", "x"])
			Gui, show, % " x" settings["pos", "guiConsole", "x"] " y" settings["pos", "guiConsole", "y"] " w" settings["pos", "guiConsole", "w"] " h" settings["pos", "guiConsole", "h"], Console
		else
			Gui, show, , Console
		SendMessage, 0xB1, start, end,, ahk_id %_editControl% ; deselect text
		guiConsole.hwnd := "ahk_id " _guiConsole
		guiConsole.title := "guiConsole"
		guiOffScreenCheck(_guiConsole)
		SetTimer, checkConsoleLog, 250
	}
	
	Gosub guiConsole_refresh
	return
	
	guiConsole_size:
		if ErrorLevel = 1  ; The window has been minimized.  No action needed.
			return
		GuiControl console: Move, % _editControl, % " w" A_GuiWidth - 10 " h" A_GuiHeight - 10
	return
	
	guiConsole_refresh:
		FileGetTime, consoleLastModified, % game.dir "\console.log", M
		If (consoleLastModified = oldConsoleLastModified)
			return
		FileRead, consoleOutput, % game.dir "\console.log"
		
		StringReplace, newLine, consoleOutput, % oldConsoleOutput, , UseErrorLevel
		
		If !(ErrorLevel) { ; stringreplace no errorlevel = actual error
			gui console: Default
			
			Edit_SetText(_editControl, "")
			Edit_SetText(_editControl, consoleOutput)
			
			; ControlSetText, , % consoleOutput, % "ahk_id " _editControl	
			; ControlSend, , {Control down}{end}{Control up}, % "ahk_id " _editControl
		}
		else {
			Edit_SetSel(_editControl, Edit_GetTextLength(_editControl))
			Edit_ReplaceSel(_editControl, newLine)
		}
		
		oldConsoleLastModified := consoleLastModified
		oldConsoleOutput := consoleOutput
	return
}

loadSettings() {
	FileRead, settingsFileContents, % settingsFile
	If (settingsFileContents)
		settings := JSON.Load(settingsFileContents)
		
	sm.Dir := A_ScriptDir "\res\" sm.Version
	sm.CompileDir := A_ScriptDir "\res\" sm.Version "\compiled"
		
	If (steamDir = "")
		RegRead, steamDir, HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Valve\Steam, InstallPath
	If (steamDir = "")
		RegRead, steamDir, HKEY_LOCAL_MACHINE\SOFTWARE\Valve\Steam, InstallPath
	steam.dir := steamDir
}

loadPlugin() {
	If (plugin.dir = "") and !(debug) {
		msgbox %A_ThisLabel%: Plugin directory not set. Set file for compiling using f5 while the file is opened in notepad++
		return
	}

	FileCopy, % plugin.dir "\" plugin.name ".smx", % game.Dir "\addons\sourcemod\plugins", 1
	runCommand("sm plugins unload_all; sm plugins refresh")
}

getPos(object) {
	If !(WinExist(object.hwnd))
		return
	If !(object.title) {
		msgbox %A_ThisFunc%: No title specified!
		return
	}
	WinGetPos(WinExist(object.hwnd), x, y, w, h, 1)
	
	settings["pos", object.title, "x"] := x
	settings["pos", object.title, "y"] := y
	settings["pos", object.title, "w"] := w
	settings["pos", object.title, "h"] := h
	
	If (x = "")
		msgbox %A_ThisFunc%: X coordinate was empty!
}

setCompileFile() {
	file := getNotepadPlusPlusFile()
	SplitPath, file, pluginFileName, pluginDir, pluginExtension, pluginNameNoExt, pluginDrive	
	If !(file) {
		msgbox %A_ThisFunc%: Could not retrieve opened notepad++ file
		return
	}
	If !(pluginExtension = "sp") {
		msgbox %A_ThisFunc%: %pluginFileName% is not a sourcemod script
		return
	}
	
	plugin.fileName := pluginFileName,plugin.dir := pluginDir,plugin.ext := pluginExtension,plugin.name := pluginNameNoExt,plugin.drive := pluginDrive, plugin.path := file
	tooltip % "Set for compiling: " plugin.fileName
	SetTimer, closeTooltip, -500
}

getNotepadPlusPlusFile() {
	WinGetTitle, winTitle, ahk_class Notepad++
	StringReplace, nppFile, winTitle, % " - Notepad++"
	StringReplace, nppFile, nppFile, * ; npp adds * when file has unsaved changes
	return nppFile
}

getAppId(input) {
	static appids
	
	; search app id in settings json
	appid := settings["appids", input]
	If (appid)
		return appid
	
	; search app id in appid json
	If !(IsObject(appids)) {
		SplashTextOn, 400, 20, % A_ScriptName, Loading app id file
		FileRead, appidsFileContents, % appidsFile
		If (appidsFileContents)
			appids := JSON.Load(appidsFileContents)
		SplashTextOff
	}
	
	loop, % appids["applist", "apps"].length() {
		If (appids["applist", "apps", A_Index, "Name"] = input) {
			appid := appids["applist", "apps", A_Index, "appid"]
			break
		}
	}
	
	settings["appids", input] := appid
	
	If !(appid)
		msgbox %A_ThisFunc%: Could not find appid for input: %input%
	return appid
}

runCommand(input) {
	static firstRun
	
	If (game.dir = "") {
		msgbox %A_ThisFunc%: Game directory not set. Reload script
		return
	}
	
	FileDelete, % game.dir "\console.log"
	execFile := game.dir "\cfg\commands.cfg"
	FileDelete, % execFile
	
	If (firstRun = "") {
		FileAppend, % "bind f1 ""exec commands.cfg""; sv_cheats 1; director_stop; nb_delete_all; ", % execFile
		firstRun := false
	}
	
	FileAppend, % "clear; " input, % execFile
	
	activeWindow("save")
	WinActivate, ahk_class Valve001
	Send {F1}
	activeWindow("restore")
}

runGame() {
	DetectHiddenWindows, On

	gameTitle := game.title
	
	If !(IsObject(game)) {
		msgbox %A_ThisFunc%: Game object is not set
		return
	}
	
	If WinExist("ahk_exe " game.exe) {
		MsgBox, 68, % A_ScriptName, %A_ThisFunc%: %gameTitle% is already running`n`nRestart it?
		IfMsgBox No
		{
			guiConsole()
			return
		}
		Process, Close, % game.exe
		WinWaitClose, % game.exe
	}
	
	launchOptions := "-console -condebug -window -w 640 -h 480"
	If (game.exe = "left4dead.exe")
		launchOptions .= "+map l4d_airport05_runway"
	If (game.exe = "left4dead2.exe")
		launchOptions .= "+map c11m5_runway"
	gamePos := "-x " game.x " -y " game.y
	
	game.hwnd := "ahk_id " WinExist("ahk_exe " game.exe)
	
	run, % steam.dir "\steam.exe -silent -applaunch " game.appid A_Space gamePos A_Space launchOptions, % steam.dir
	WinWait, % "ahk_exe " game.exe
	
	guiConsole()
}

checkRunningGames() {
	WinGet, gamePath, ProcessPath, ahk_class Valve001
	If !(gamePath)
		return false

	SplitPath, gamePath, gameFileName, gameDir, gameExtension, gameNameNoExt, gameDrive
	gameVarsLoaded := setGameObj(gameNameNoExt)
	
	If !(gameVarsLoaded) {
		msgbox %A_ThisFunc%: Could not load vars for %gameNameNoExt%.`n`nThis is currently unhandled so the program will close
		exitapp
	}
	
	game.hwnd := "ahk_id " WinExist("ahk_exe " game.exe)
	
	guiConsole()
	return true
}

setGameObj(input) {
	game.appid := settings["games", input, "appid"]
	game.dir := settings["games", input, "dir"] "\" settings["games", input, "title"]
	game.exe := settings["games", input, "exe"]
	game.path := settings["games", input, "path"]
	game.title := settings["games", input, "title"]
	
	game.x := settings["pos", game.title, "x"]
	If !(game.x)
		game.x := 0
	game.y := settings["pos", game.title, "y"]
	If !(game.y)
		game.y := 0

	
	If !(game.path)
		return false
		
	FileDelete, % game.dir "\console.log"
	return true
}

compile(input) {
	DetectHiddenWindows, On
	isCompiled := true ; default isCompiled value
	
	SplitPath, input, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
	If !(OutExtension = "sp") {
		msgbox %A_ThisFunc%: Invalid file specified:`n`n"%input%"`n`nSet file for compiling using f5 while the file is opened in notepad++
		return
	}
	smDir := sm.Dir
	ErrorFile := OutDir "\smCompilerErrors.txt"
	
	run, %comspec% /c "%smDir%\spcomp.exe" %input% -e=%ErrorFile%, % OutDir, Hide, cmdPID	; silent
	WinWait, ahk_pid%cmdPID%
	WinWaitClose, ahk_pid%cmdPID%
	
	If FileExist(ErrorFile) {
		FileRead, Error, % ErrorFile
		FileDelete, % ErrorFile
		
		loop, parse, error, `n ; error in error file = not compiled, warning in error file = compiled
		{
			loopedError := StringBetween(A_LoopField, A_Space ":" A_Space, ":")
			If InStr(loopedError, "error")
				isCompiled := false
		}
		
		Error := "Compiled = " isCompiled "`n`n" Error
		
		guiMsgBox(Error)
	}
	else {
		tooltip % "Compiled " plugin.fileName "!"
		SetTimer, closeTooltip, -250
	}
	return isCompiled
}

activeWindow(action) {
	static ActiveWindowHwnd, mX, mY
	
	If (action = "save")
	{
		WinGetActiveTitle, ActiveWindowTitle
		WinGet, ActiveWindowHwnd, ID, % ActiveWindowTitle
		MouseGetPos, mX, mY
	}
	
	If (action = "restore")
	{
		WinActivate % "ahk_id " ActiveWindowHwnd
		MouseMove, % mX, % mY, 0
		MouseMove, % mX, % mY+1, 0
	}
}

pasteText(input) {
	oldClipboard:=clipboard
	clipboard:=input
	Send ^v
	clipboard:=oldClipboard
}