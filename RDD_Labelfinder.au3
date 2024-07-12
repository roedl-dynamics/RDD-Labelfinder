#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Labelfinder.ico
#AutoIt3Wrapper_Res_Comment=D365 Tool für eine schnelle Labelsuche
#AutoIt3Wrapper_Res_Description=RD Labelfinder
#AutoIt3Wrapper_Res_Fileversion=1.0.0.6
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_ProductName=RD Labelfinder
#AutoIt3Wrapper_Res_CompanyName=Rödl Dynamics GmbH
#AutoIt3Wrapper_Res_LegalCopyright=Rödl Dynamics
#AutoIt3Wrapper_Res_LegalTradeMarks=RödlDynamics
#AutoIt3Wrapper_Res_Language=1031
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; Search Icon Source: https://www.iconarchive.com/show/vista-artistic-icons-by-awicons/search-icon.html
; Link to the Twitter-Account to the Creater of the ICO-File: https://twitter.com/doublejdesign
;#NoTrayIcon

Opt ("MustDeclareVars",1)
#include <AutoItConstants.au3>
#include <StringConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <Array.au3>
#include <TrayConstants.au3>
#include <File.au3>
#include <Clipboard.au3>
#include <GuiListView.au3>

;Opt("MustDeclareVars",1)
Opt("TrayMenuMode", 3) ;
Global $INIFile = @ScriptDir & "\AutoLabelSearch.au3.ini"
Global $MaxSearchResults
;Global $SearchResults[0]
Global $Imagepath = @ScriptDir &"\Search.ico"
Global $iSearch = TrayCreateItem("Label suchen")
Global $iExit = TrayCreateItem("Beenden")
Global $Werte [0][4] ; bleibt umd die Daten aus dem INI File auszulesen

; zum Test
Global $LabelDatei = @ScriptDir& "\Labels.txt" ; Zusätzliche Textdatei die die Werte Zwischenspeichert das das Tool im Launcher verwendbar ist
Global $Labels[0][4] ; 2D Array welches die Labels aus der neuen Textdatei einließt und enthält
Global $openByLauncher ; ermöglicht eine Abfrage wo das Tool gestartet wurde
Global $Labelfail = false

;Array für die Combobox initialisieren
Global $sections = IniReadSectionNames($INIFile)

;_ArrayDisplay($sections)
_ArrayDelete($sections,0)

Global $indicesToDelete = []
For $i = 0 To UBound($sections) - 1
	If $sections[$i] == "Sys" Or $sections[$i] == "SYP" Or $sections[$i] == "General" Or $sections[$i] == "Launcher" Or $sections[$i] == "General" Or $sections[$i] == "System" Then
		_ArrayAdd($indicesToDelete, $i)
	EndIf
Next

; Indizes von hinten nach vorne löschen
For $i = UBound($indicesToDelete) - 1 To 0 Step -1
	_ArrayDelete($sections, $indicesToDelete[$i])
next

ReadIN()

Func ReadIn()
	Local $FileSize = FileGetSize($LabelDatei)
	$openByLauncher = IniRead($INIFile,"Launcher","openedByLauncher","Konnte nicht gefunden werden")
	ConsoleWrite("OpendedBylauncher: " & $openByLauncher & @CRLF)
	ConsoleWrite("Start: " & @HOUR & ":"& @MIN&":"&@SEC & @CRLF)
	;Global $SectionNames = IniReadSectionNames(@ScriptDir & "\" & $INIFile)
	Global $SectionNames = IniReadSectionNames($INIFile)
	ConsoleWrite("Dateigröße: "& $FileSize & @CRLF)

	Local $z
	For $z = 4 to UBound($SectionNames)-1
		ConsoleWrite("Springt in die Schleife nach dem $z")
		Local $path = IniRead($INIFile,$SectionNames[$z],"Labelfile","")
		if $path == "" then
			MsgBox(16, @ScriptName,"bitte Dateipfad für " &$SectionNames[$z]&" angeben")
			$Labelfail = True
			Main()
		EndIf
	next

	if UBound($SectionNames)-1 < 4 then
		MsgBox(16,"Warnung","sie haben keine Labeldateien angegeben")
		$Labelfail = true
		Main()
	EndIf

	if $FileSize == 0 then
		; hier muss das Tool die Labels in die neue Textdatei einlesen
		ConsoleWrite("Die Labeldatei ist leer" & @CRLF)
		For $i = 1 to Ubound($SectionNames)-1
			Local $SectionName = $SectionNames[$i]
			if $SectionName <> "System" and $SectionName <> "General" and $SectionName <> "Launcher" then
				Local $SectionContent = _ReadInSection($SectionNames[$i])
				_ArrayAdd($Werte,$SectionContent)
				_FileWriteFromArray($LabelDatei,$Werte) ; schreibt das Array in das neue Dokument Labels.txt
			elseIf $SectionName == "Launcher" then
				$openByLauncher  = IniRead($INIFile,"Launcher","openedByLauncher","")
			EndIf
		next
		ConsoleWrite("Größe des Arrays(Labels): " & UBound($Labels)&","& UBound($Labels,2) & @CRLF)
		ConsoleWrite("Größe des Arrays(Werte): " & UBound($Werte) & ","&Ubound($Werte,2)& @CRLF)

		; mit der Funktion readLabelFile_Intog_2DArray in das 2D-Array einlesen
		$Labels = readLabelFile_Into_2DArray($LabelDatei)
	else
		; hier muss das Tool nur auf die bereits eingelesenen Werte in der neuen Textdatei zugreifen
		ConsoleWrite("Die Labeldatei ist nicht leer"& @CRLF)
		;MsgBox(0,"","Die Labeldatei ist nicht leer")
		;_FileReadToArray($LabelDatei,$Labels) würde unnötiger weise Doppelt dafür sorgen das die werte in einem Array sind
		; mit String Split n ein neues 2D Array einlesen ähnlich der Funktion _ReadInSection eigene Methode dafür unten
		$Labels = readLabelFile_Into_2DArray($LabelDatei) ; methode zum einlesen der Datei in das 2D Array
		;_ArrayDisplay($Labels,"Labels am Ende der ReadIn Funktion ")
		If $openByLauncher == "True" then
			openGUI()
		EndIf

	EndIf

	ConsoleWrite("Ende: " & @HOUR & ":" &@MIN&":"&@SEC&@CRLF)
	;_ArrayDisplay($Werte)
	Main()
EndFunc

Func _ReadInSection($pSectionName)

	Local $tmpFilePath = IniRead($INIFile,$pSectionName, "Labelfile","")
	Local $LabelPrefix = IniRead($INIFile,$pSectionName,"Labelprefix","")

#cs
	if $tmpFilePath == "" then
		MsgBox(16, @ScriptName,"bitte Dateipfad für " &$pSectionName&" angeben")
	EndIf
#ce

	if Not FileExists($tmpFilePath) Then
		MsgBox(16,@ScriptName, "Datei " & $tmpFilePath & " wurde nicht gefunden")
	endif

	Local $FileContent = FileReadToArray($tmpFilePath)

	;_ArrayDisplay($FileContent,"$FileContent");

	Local $FileContent_Rows = Ubound($FileContent)-1
	ConsoleWrite("$FileContent_Rows="  & $FileContent_Rows & @CRLF)
	Local $ValuesCurrentFile[$FileContent_Rows][4]
	;_ArrayDisplay($ValuesCurrentFile)

	Local $n
	Local $CurrentPos = 0

	;_ArrayDisplay($FileContent_Rows)

	For $n = 0 to $FileContent_Rows-1

		Local $FileContentLine = $FileContent[$n]


		; String left um herauszufinden womit die Zeile beginnt
		If StringLeft($FileContentLine,1) <> " " Then
			local $tmpArray = StringSplit($FileContentLine,"=")
			;_ArrayDisplay($tmpArray)

			Local $label = $tmpArray[1]
			Local $text = $tmpArray[2]
			Local $comment = ""

			$ValuesCurrentFile[$CurrentPos][0]=$label
			; ConsoleWrite("Label: "&$label&@CRLF)
			$ValuesCurrentFile[$CurrentPos][1]=$text
			; ConsoleWrite("Text: "&$text&@CRLF)
			$ValuesCurrentFile[$CurrentPos][2]=$comment
			; ConsoleWrite("Kommentar: "&$comment&@CRLF)
			$ValuesCurrentFile[$CurrentPos][3]=$LabelPrefix
			; ConsoleWrite("Prefix: "&$LabelPrefix& @CRLF)

			$CurrentPos += 1
		EndIf

	next

	 $ValuesCurrentFile = _ArrayExtract($ValuesCurrentFile, 0, $CurrentPos-1)

	;_ArrayDisplay($ValuesCurrentFile)
	Return $ValuesCurrentFile

EndFunc


Func readLabelFile_Into_2DArray($pFile)
	; Prüft ob das File Existiert
	if Not FileExists($pFile) then
		MsgBox(16,@ScriptName,"Datei " & $pFile & " wurde nicht gefunden")
	EndIf

	Local $FileContent = FileReadToArray($pFile)
	;_ArrayDisplay($FileContent,"Filecontent:")

	Local $FileContent_Rows = UBound($FileContent)-1
	ConsoleWrite("$FileContent_Rows=" & $FileContent_Rows & @CRLF)
	Local $ValuesCurrentFile[$FileContent_Rows][4]

	Local $n
	Local $CurrentPos = 0

	For $n = 0 to $FileContent_Rows-1
		Local $FileContentLine = $FileContent[$n]

		If StringLeft($FileContentLine,1) <> " " Then
			Local $tmpArray = StringSplit($FileContentLine,"|")
			ConsoleWrite("CurrentPos "& $CurrentPos & @CRLF)
			;_ArrayDisplay($tmpArray,"Das richtige Array")

			Local $label = $tmpArray[1]
			Local $text = $tmpArray[2]
			Local $comment = ""
			Local $prefix = $tmpArray[4]

			;_ArrayDisplay($ValuesCurrentFile,"valuesCurrentFile")

			$ValuesCurrentFile[$CurrentPos][0] = $label
			$ValuesCurrentFile[$CurrentPos][1] = $text
			$ValuesCurrentFile[$CurrentPos][2] = $comment
			$ValuesCurrentFile[$CurrentPos][3] = $prefix

			$CurrentPos += 1

		EndIf

	next


		Return $ValuesCurrentFile
EndFunc


Func Main()

	TraySetState($TRAY_ICONSTATE_SHOW)

    While 1
        Switch TrayGetMsg()
			Case  $iExit
				clearFile()
				Exit
			Case $iSearch
					if $Labelfail == true then
						MsgBox(16,"Error","die Labeldateien konnten nicht korrekt eingelesen werden")
						Exit
					Else
						openGUI()
					EndIf
        EndSwitch
    WEnd
EndFunc

Func openGUI()
	#Region ### START Koda GUI section ### Form=
		Local $minWidth = 350 ; an die neue Größe anpassen
		Local $minHeigt = 460 ; an die neue Größe anpassen

		Global $Form1 = GUICreate("Rödl Dynamics - Label Suche",350, 480, 190, 201,BitOR($WS_SIZEBOX, $WS_SYSMENU, $WS_MINIMIZEBOX)) ;BitOR($WS_SIZEBOX, $WS_SYSMENU, $WS_MINIMIZEBOX)
		GUICtrlSetResizing($Form1,$GUI_DOCKAUTO)

		Local $Tab = GUICtrlCreateTab(0, 0, 350, 20)

		Global $TabSearch = GUICtrlCreateTabItem("Suche")
		Global $Group1 = GUICtrlCreateGroup("Suche", 16, 44, 318, 65)
		GUICtrlSetResizing($Group1,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHCENTER+$GUI_DOCKVCENTER+$GUI_DOCKHEIGHT)

		Global $openIniFileButton = GUICtrlCreateButton("Open INI",270,25,60,20)
		GUICtrlSetResizing($openIniFileButton,$GUI_DOCKRIGHT+$GUI_DOCKHCENTER+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT+$GUI_DOCKTOP)

		Global $SearchButton = GUICtrlCreateButton("", 270, 65, 60, 20,$BS_ICON)
		GUICtrlSetResizing($SearchButton,$GUI_DOCKRIGHT+$GUI_DOCKHCENTER+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT+$GUI_DOCKTOP)
		GUICtrlSetImage($SearchButton, $Imagepath, 169, 0)

		Global $InputField = GUICtrlCreateInput("", 26, 65, 230, 20)
		GUICtrlSetResizing($InputField,$GUI_DOCKHEIGHT+ $GUI_DOCKRIGHT+$GUI_DOCKLEFT+$GUI_DOCKTOP+$GUI_DOCKWIDTH)

		Global $hListView = GUICtrlCreateListView("Label|Text|Kommentar", 16, 120, 318, 295)
		GUICtrlSetResizing($hListView ,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKBOTTOM)

		Global $TakeOverButton = GUICtrlCreateButton("Label übernehmen", 16, 420, 318, 27)
		GUICtrlSetResizing(-1 ,$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKBOTTOM+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT)
		GUICtrlCreateTabItem("")

		Global $TabEdit = GUICtrlCreateTabItem("Edit")
		Global $InputMaxResults = GUICtrlCreateInput("", 128, 33, 153, 21)
		;GUICtrlSetResizing($InputMaxResults,$GUI_DOCKHEIGHT+ $GUI_DOCKRIGHT+$GUI_DOCKLEFT+$GUI_DOCKTOP+$GUI_DOCKWIDTH)

		Global $LabelMaxResults = GUICtrlCreateLabel("MaxSearchResults: ", 16, 33, 100, 17)
		GUICtrlSetResizing(-1,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHCENTER+$GUI_DOCKVCENTER+$GUI_DOCKHEIGHT)

		Global $SectionNameLabel = GUICtrlCreateLabel("Sectionname: ",16,66,100,17)
		GUICtrlSetResizing(-1,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHCENTER+$GUI_DOCKVCENTER+$GUI_DOCKHEIGHT)

		Global $SectionNameInput = GUICtrlCreateCombo("", 128, 66, 153, 21)
		GUICtrlSetData($SectionNameInput, _ArrayToString($sections, "|"))

		Global $LabelLabelFile = GUICtrlCreateLabel("Labeldatei: ", 16, 99, 100, 17)
		GUICtrlSetResizing(-1,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHCENTER+$GUI_DOCKVCENTER+$GUI_DOCKHEIGHT)

		Global $InputLabelFile = GUICtrlCreateInput("", 128, 99, 153, 21)
		;GUICtrlSetResizing($InputLabelFile,$GUI_DOCKHEIGHT+ $GUI_DOCKRIGHT+$GUI_DOCKLEFT+$GUI_DOCKTOP+$GUI_DOCKWIDTH)

		Global $PrefixLabel = GUICtrlCreateLabel("Prefix: ", 16, 132, 100, 17)
		GUICtrlSetResizing(-1,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHCENTER+$GUI_DOCKVCENTER+$GUI_DOCKHEIGHT)

		Global $InputPrefix = GUICtrlCreateInput("", 128, 132, 153, 21)
		;GUICtrlSetResizing($InputPrefix,$GUI_DOCKHEIGHT+ $GUI_DOCKRIGHT+$GUI_DOCKLEFT+$GUI_DOCKTOP+$GUI_DOCKWIDTH)

		Global $FileOpenButton = GUICtrlCreateButton("...", 288, 99, 41, 21)
		GUICtrlSetResizing(-1,$GUI_DOCKRIGHT+$GUI_DOCKHCENTER+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT+$GUI_DOCKTOP)

		Global $SafeButton = GUICtrlCreateButton("Speichern",80,205,100,25)
		GUICtrlSetResizing(-1,$GUI_DOCKRIGHT+$GUI_DOCKHCENTER+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT+$GUI_DOCKTOP)

		Global $DeleteButton = GUICtrlCreateButton("Löschen",180,205,100,25)
		GUICtrlSetResizing(-1,$GUI_DOCKRIGHT+$GUI_DOCKHCENTER+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT+$GUI_DOCKTOP)

		GUICtrlCreateTabItem("")

		Global $TabCreate = GUICtrlCreateTabItem("Create")

		Global $CreateTabSectionNameLabel = GUICtrlCreateLabel("Sectionname: ",16,66,100,17)
		GUICtrlSetResizing(-1,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHCENTER+$GUI_DOCKVCENTER+$GUI_DOCKHEIGHT)

		Global $CreateTabSectionNameInput = GUICtrlCreateInput("", 128, 66, 153, 21)

		Global $CreateTabLabelFileLabel = GUICtrlCreateLabel("Labeldatei: ", 16, 99, 100, 17)
		GUICtrlSetResizing(-1,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHCENTER+$GUI_DOCKVCENTER+$GUI_DOCKHEIGHT)

		Global $CreateTabLabelFileInput = GUICtrlCreateInput("", 128, 99, 153, 21)

		Global $CreateTabFileOpenButton = GUICtrlCreateButton("...", 288, 99, 41, 21)
		GUICtrlSetResizing(-1,$GUI_DOCKRIGHT+$GUI_DOCKHCENTER+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT+$GUI_DOCKTOP)

		Global $CreateTabPrefixLabel =  GUICtrlCreateLabel("Prefix: ", 16, 132, 100, 17)
		GUICtrlSetResizing(-1,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHCENTER+$GUI_DOCKVCENTER+$GUI_DOCKHEIGHT)

		Global $CreateTabPrefixInput =  GUICtrlCreateInput("", 128, 132, 153, 21)

		Global $CreateButton = GUICtrlCreateButton("Create",128,205,100,25)
		GUICtrlSetResizing(-1,$GUI_DOCKRIGHT+$GUI_DOCKHCENTER+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT+$GUI_DOCKTOP)

		GUICtrlCreateTabItem("")

		GUISetState(@SW_SHOW)

		ControlFocus($Form1, "", $InputField)

	#EndRegion ### END Koda GUI section ##

	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				if $openByLauncher == "True" then
					Exit
				else
					GUIDelete($Form1)
					Main()
				EndIf
			Case $SearchButton
				GUICtrlSetData($hListView, "")
				search()
			Case $TakeOverButton
				TakeOver()
				if $openByLauncher == "True" then
					Exit
				else
					GUIDelete($Form1)
					Main()
				EndIf
			Case $GUI_EVENT_RESIZED
				Local $NewSize = WinGetPos($Form1)
				if $NewSize[2] < $minWidth OR $NewSize[3] < $minHeigt Then

					WinMove($Form1,"",$NewSize[0],$NewSize[1],$minWidth,$minHeigt)

				EndIf
			Case $openIniFileButton
				;Local $filePath = @ScriptDir &"\" & $INIFile
				Local $filePath = $INIFile
				Run("notepad.exe " & $filePath)
			Case $FileOpenButton
				local $file =  FileOpenDialog("Wählen sie eine Labeldatei aus", @DesktopDir & "\", "All (*.*)", $FD_FILEMUSTEXIST)
				GUICtrlSetData($InputLabelFile,$file)

			Case $CreateTabFileOpenButton
				local $file =  FileOpenDialog("Wählen sie eine Labeldatei aus", @DesktopDir & "\", "All (*.*)", $FD_FILEMUSTEXIST)
				GUICtrlSetData($CreateTabLabelFileInput,$file)
			Case $CreateButton
				createINISection()
			Case $SafeButton
				editINI()
			Case $DeleteButton
				local $Section = GUICtrlRead($SectionNameInput)
				IniDelete($INIFile,$Section)
		EndSwitch
	WEnd
EndFunc

func search()
	_GUICtrlListView_DeleteAllItems($hListView) ; löscht alle Einträge in der ListView

	Local $counter = 0 ; zählt die gefundenen Treffer

	Local $eingabe = GUICtrlRead($InputField)

	if $eingabe == "" then
		MsgBox(48,"Achtung","leeres Suchfeld")

	EndIf

	; leert die Resultate der alten Suche (läuft Rückwärts da das Array immer kleiner wird)

	; hier die Labels durchgehen
	Local $col = 1


	For $Row = 0 to UBound($Labels,1)-1
		If $counter == $MaxSearchResults Then
			 Local $returnValue = MsgBox($MB_YESNO, "Achtung", "Möchten sie mehr als "&$MaxSearchResults&"anzeigen lassen ?")
			 if $returnValue == $IDYES or $returnValue == 6 Then
				; hier passiert nichts
				$counter = $counter+1
			 Else
				 ExitLoop

			EndIf
		EndIf

		ConsoleWrite("Größe des Arrays: "& Ubound($Labels) & " Row-Wert: "& $Row & " col-Wert: " & $col & @CRLF)

		If StringRegExp($Labels[$Row][$col], $eingabe) then
				$counter = $counter +1
				GUICtrlCreateListViewItem($Labels[$Row][0]&"|"&$Labels[$Row][1]&"|"&"" , $hListView)
		EndIf

	next
	if $counter = 0 then
		GUICtrlCreateListViewItem("kein Treffer gefunden",$hListView)
	EndIf

EndFunc

Func TakeOver()
	Local $selectedIndex =  _GUICtrlListView_GetSelectionMark($hListView)

	Local $SelectedValue = _GUICtrlListView_GetItemText($hListView, $selectedIndex)

	Local $index = _ArraySearch($Labels,$SelectedValue)

	if $Labels[$index][3] <> "" then

		_ClipBoard_SetData($Labels[$index][3]&":"& $Labels[$index][0])

	Else
		_ClipBoard_SetData($Labels[$index][0])
	EndIf
EndFunc

Func clearFile()
	Local $oFile  = FileOpen($LabelDatei,2)
	FileWrite($oFile,"")
	FileClose($oFile)
EndFunc

Func createINISection()
	local $SectionNameValue = GUICtrlRead($CreateTabSectionNameInput)
	local $LabelFileValue = GUICtrlRead($CreateTabLabelFileInput)
	local $PrefixValue = GUICtrlRead($CreateTabPrefixInput)

	;local $Keys = "Labelfile= " & @CRLF & _
     ;            "Labelprefix ="

	local $Keys = "Labelfile=" & @CRLF &  "Labelprefix="
	IniWriteSection($INIFile,$SectionNameValue,$Keys,1)
	IniWrite($INIFile,$SectionNameValue,"Labelfile",$LabelFileValue)
	IniWrite($INIFile,$SectionNameValue,"Labelprefix",$PrefixValue)

EndFunc

Func editINI()
	local $MaxSearchInputValue = GUICtrlRead($InputMaxResults)
	local $InputLabelFileValue = GUICtrlRead($InputLabelFile)
	local $SectionNameInputValue = GUICtrlRead($SectionNameInput)
	local $PrefixLabelValue = GUICtrlRead($InputPrefix)

	If FileExists($INIFile) Then
		if $MaxSearchInputValue <> "" Then
        IniWrite($INIFile, "System", "MaxSearchResults", $MaxSearchInputValue)
		EndIf
		if $SectionNameInputValue <> "" then
			IniWrite($INIFile,$SectionNameInputValue,"","")
		EndIf
		if $InputLabelFileValue <> "" then
        IniWrite($INIFile,$SectionNameInputValue, "Labelfile", $InputLabelFileValue)
		EndIf
		if $PrefixLabelValue <> "" then
        IniWrite($INIFile,$SectionNameInputValue, "Labelprefix", $PrefixLabelValue)
		EndIf
    Else
        MsgBox(16, "Fehler", "Die INI-Datei existiert nicht: " & $INIFile)
    EndIf
EndFunc