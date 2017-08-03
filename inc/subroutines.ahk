exitAfterGameClose:
	If (game.path = "") {
		msgbox %A_ThisLabel%: No game path specified
		return
	}
	WinWaitClose, % "ahk_exe " game.path
	Gosub exitRoutine
return

exitRoutine:
	getPos(game)
	getPos(guiConsole)
	Gosub writeSettings
exitapp

loadPlugin:
	loadPlugin()
return

writeSettings:
	FileDelete, % settingsFile
	FileAppend, % json.dump(settings,,2), % settingsFile
return

checkConsoleLog:
	guiConsole()
return

closeTooltip:
	tooltip
return

menuHandler:
return

saveGamePos:
	msgbox % A_ThisLabel
return