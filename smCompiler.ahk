#SingleInstance, force
global g_debugMode := false
global sm := {} ; sourcemod information
sm.serverPluginsDir := "D:\Games\SourceServers\l4d2\left4dead2\addons\sourcemod\plugins" ; compiled plugins will be moved into this folder
sm.compilerVersion := "1.9" ; sourcemod compiler version; any version found in ..\res\sourcemod eg: 1.9
sm.customStocksDir := "D:\Github\sourcemod-stocks" ; folder containing include files
sm.compilerDir := A_ScriptDir "\res\sourcemod\" sm.compilerVersion

verifyFolderExist("Server plugins dir", sm.serverPluginsDir)
If (sm.customStocksDir) ; if custom dir specified
    verifyFolderExist("Custom stocks dir", sm.customStocksDir)
verifyFolderExist("Sourcemod compiler dir", sm.compilerDir)

If (g_debugMode) {
    sm.file := "D:\Downloads\speech.sp"
    compileSourcemodScript(sm.file)

    ; msgbox end of script
    return
}
sm.file := selectSourcemodScript()
compileSourcemodScript(sm.file)
return

verifyFolderExist(inputFolderTypeDescription, inputPath) {
    If !InStr(FileExist(inputPath), "D") {
        msgbox %inputFolderTypeDescription% "%inputPath%" is not valid. Set in %A_ScriptFullPath%
        exitapp
    }
}

~^s::
    If (g_debugMode) {
        reload
        return
    }

    compileSourcemodScript(sm.file)
return

~f1::reload

#Include, %A_ScriptDir%\inc
#Include, functions.ahk
#Include, subroutines.ahk