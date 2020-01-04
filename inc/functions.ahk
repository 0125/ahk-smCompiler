; input = full path to sourcemod script file
compileSourcemodScript(input) {
    verifySourcemodScriptFile(input)
    DetectHiddenWindows, On

    spcompErrorFile := A_ScriptDir "\" A_Now
    smcompilerDir := sm.compilerDir
    smCustomStocksDir := sm.customStocksDir

    ; compile script
    run, %comspec% /c "%smcompilerDir%\spcomp.exe" %input% -e=%spcompErrorFile% -i=%smCustomStocksDir%, % smcompilerDir, Hide, PID	; /c = silent /k = keep window open
	WinWait, ahk_pid%PID%
	WinWaitClose, ahk_pid%PID%

    ; check for error file
    FileRead, spcompError, % spcompErrorFile
    FileDelete, % spcompErrorFile
    If (spcompError) {
        msgbox % spcompError
        return
    }
    
    ; move compiled file to server & source file folder
    SplitPath, input , OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
    FileCopy, % smcompilerDir "\" OutNameNoExt ".smx", % OutDir, 1 ; overwrite into source script dir
    FileMove, % smcompilerDir "\" OutNameNoExt ".smx", % sm.serverPluginsDir, 1 ; overwrite into server sourcemod plugins dir

    serverCommand("sm plugins unload_all; sm plugins refresh {enter}") ; reload server plugins
}

serverCommand(input) {
    If !WinExist("ahk_exe srcds.exe") {
        msgbox Could not find srcds.exe (source server console) using "ahk_exe srcds.exe"
        return
    }
    
    WinGet, _activeWin, ID, A
    WinActivate, ahk_exe srcds.exe
    SendInput % input
    WinMinimize, ahk_exe srcds.exe
    WinActivate, % "ahk_id " _activeWin
}

selectSourcemodScript() {
    FileSelectFile, output, 3, , Open, Sourcepawn script (*.sp)
    verifySourcemodScriptFile(output)
    return output
}

verifySourcemodScriptFile(input) {
    SplitPath, input, OutFileName, OutDir, OutExtension, OutNameNoExt, OutDrive
    If !(OutExtension = "sp") {
        msgbox Specified file "%input%" is not a sourcepawn script
        exitapp
    }
}