; Search Icon Source: https://www.iconarchive.com/show/vista-artistic-icons-by-awicons/search-icon.html
;#NoTrayIcon
;Test2
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
Global $INIFile = "AutoLabelSearch.au3.ini"
Global $MaxSearchResults
Global $AllLabels[0]
Global $SearchResultsLabels[0]
Global $SearchResultsText[0]
Global $Imagepath = @ScriptDir &"\Search.ico"
Global $iSearch = TrayCreateItem("Label suchen")
Global $iExit = TrayCreateItem("Beenden")
Global $prefix = ""
Global $PrefixLabels[0] ; speichert den Pfad einer Datei mit LabelPrefix

ReadIN()

Func ReadIN()
	Global  $SectionNames = IniReadSectionNames(@ScriptDir & "\" & $INIFile)

			For $i = 1 to UBound($SectionNames)-1
			Global $SectionName = $SectionNames[$i]
				ConsoleWrite("Sectionname: "&$SectionName&@CRLF)
				if $SectionName == "System" Then

					$MaxSearchResults = IniRead($INIFile,$SectionName,"MaxSearchResults",0)

				ElseIf $SectionName == "General " Then
					; hier soll nichts passieren
				Else
					; hier wird das Array befüllt
					Global $tmpLabelFile = IniRead($INIFile,$SectionName,"Labelfile","") ; enthält die Pfade zu den Dateien aus der INI
					Global $LabelPrefix = IniRead($INIFile,$SectionName,"Labelprefix","nichts gefunden") ; enthält dem Prefix der aktuellen SectionName

					if FileExists($tmpLabelFile) then ; wenn das File existiert
						Global $CurrentLabelFile = FileReadToArray($tmpLabelFile)
						_ArrayAdd($AllLabels,$CurrentLabelFile)
					else
						MsgBox(1,@ScriptName,"FileNotFound")
					EndIf
				EndIf
			next
			Main()
EndFunc

Func Main()

	TraySetState($TRAY_ICONSTATE_SHOW)

    While 1
        Switch TrayGetMsg()
            Case  $iExit
				Exit
			Case $iSearch
				openGUI()
        EndSwitch
    WEnd
EndFunc

Func openGUI()
	#Region ### START Koda GUI section ### Form=
		Local $minWidth = 350
		Local $minHeigt = 460
		Global $Form1 = GUICreate("Rödl Dynamics - Label Suche",350, 460, 190, 151,BitOR($WS_SIZEBOX, $WS_SYSMENU, $WS_MINIMIZEBOX)) ;BitOR($WS_SIZEBOX, $WS_SYSMENU, $WS_MINIMIZEBOX)
		GUICtrlSetResizing($Form1,$GUI_DOCKAUTO)
		Global $Group1 = GUICtrlCreateGroup("Suche", 16, 24, 318, 65)
		GUICtrlSetResizing($Group1,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKHCENTER+$GUI_DOCKVCENTER+$GUI_DOCKHEIGHT)

		Global $SearchButton = GUICtrlCreateButton("", 270, 45, 60, 20,$BS_ICON)
		GUICtrlSetResizing($SearchButton,$GUI_DOCKRIGHT+$GUI_DOCKHCENTER+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT+$GUI_DOCKTOP)
		GUICtrlSetImage($SearchButton, $Imagepath, 169, 0)

		Global $InputField = GUICtrlCreateInput("", 26, 45, 230, 20)
		GUICtrlSetResizing($InputField,$GUI_DOCKHEIGHT+ $GUI_DOCKRIGHT+$GUI_DOCKLEFT+$GUI_DOCKTOP+$GUI_DOCKWIDTH)

		Global $hListView = GUICtrlCreateListView("Label|Text|Kommentar", 16, 100, 318, 295)
		GUICtrlSetResizing($hListView ,$GUI_DOCKAUTO+$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKTOP+$GUI_DOCKBOTTOM)

		Global $TakeOverButton = GUICtrlCreateButton("Label übernehmen", 16, 400, 318, 27)
		GUICtrlSetResizing(-1 ,$GUI_DOCKLEFT+$GUI_DOCKRIGHT+$GUI_DOCKBOTTOM+$GUI_DOCKWIDTH+$GUI_DOCKHEIGHT)

		GUISetState(@SW_SHOW)

		ControlFocus($Form1, "", $InputField)
	#EndRegion ### END Koda GUI section ##

	While 1
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				;GUISetState(@SW_HIDE,$Form1)
				GUIDelete($Form1)
				Main()
			Case $SearchButton
				GUICtrlSetData($hListView, "")
				;ConsoleWrite("Start Searchfunktion: "& @MIN &":"&@SEC& @CRLF)
				search()
				;ConsoleWrite("Ende Searchfunktion: "& @MIN &":"&@SEC&@CRLF)
			Case $TakeOverButton
				;ConsoleWrite("Start:  " & @MIN &":"&@SEC&@CRLF)
				TakeOver()
				GUIDelete($Form1)
				;ConsoleWrite("Ende:  " & @MIN &":" &@SEC&@CRLF)
				;ConsoleWrite("---------------------------------"&@CRLF)
				Main()
			Case $GUI_EVENT_RESIZED
				Local $NewSize = WinGetPos($Form1)
				if $NewSize[2] < $minWidth OR $NewSize[3] < $minHeigt Then

					WinMove($Form1,"",$NewSize[0],$NewSize[1],$minWidth,$minHeigt)

				EndIf
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
		ConsoleWrite("gesuchter Wert: " & $eingabe& @CRLF)

		; leert die Resultate der alten Suche (läuft Rückwärts da das Array immer kleiner wird)
		For $i = Ubound($SearchResultsLabels)-1 to 0 step -1

			_ArrayDelete($SearchResultsLabels,$i)
			_ArrayDelete($SearchResultsText,$i)

		Next

		For $i = 0 to UBound($AllLabels)-1
			If StringRegExp($AllLabels[$i],";") Then
				; passiert nichts

				else
					If StringRegExp($AllLabels[$i],$eingabe) Then

							Local $tempArray = StringSplit($AllLabels[$i],"=")

							_ArrayAdd($SearchResultsLabels,$tempArray[1]) ; Fügt dem Array mit dem den Gefundenen Labels das Label hinzu

							_ArrayAdd($SearchResultsText,$tempArray[UBound($tempArray)-1]) ;Fügt dem Array mit den Gefundenen Text ein Text hinzu

							$counter = $counter+1

					EndIf
			EndIf
		Next

		If UBound($SearchResultsLabels) >  $MaxSearchResults Then

			Local $returnValue = MsgBox($MB_YESNO,"Mehr als "&$MaxSearchResults,"möchten sie mehr anzeigen ?",15)
			if $returnValue == $IDYES  or $returnValue == -1 Then
				For $i = 0 to UBound($SearchResultsLabels)-1

					GUICtrlCreateListViewItem($SearchResultsLabels[$i] & "|"&$SearchResultsText[$i]& "|", $hListView)

				Next
			ElseIf $returnValue == $IDNO Then
				for $i = 0 to $MaxSearchResults

					GUICtrlCreateListViewItem($SearchResultsLabels[$i] & "|"&$SearchResultsText[$i]& "|", $hListView)

				Next
			EndIf
		EndIf

		if $counter == 0 Then

			GUICtrlCreateListViewItem("kein Treffer gefunden" & "|"&""& "|", $hListView)

		EndIf
EndFunc


Func TakeOver()

	Local $selectedIndex =  _GUICtrlListView_GetSelectionMark($hListView) ;Gibt den Index des Ausgewählten Wertes zurück

	Local $SelectedValue = _GUICtrlListView_GetItemText($hListView, $selectedIndex) ; ermittelt welcher Wert zu dem Index gehört.

	Local $PrefixLabels[0] ; speichert den Pfad einer Datei mit LabelPrefix

	; Prüfen welche LabelDateien einen Präfix davor haben
	ConsoleWrite("Start: "&@MIN&":"&@SEC&@CRLF)
	For $i = 0 to UBound($SectionNames)-1

		Local $temp = $SectionNames[$i]

		Local $getPraefix = IniRead($INIFile,$temp,"Labelprefix","wurde nicht gefunden")

		; fügt dem Array das Label dateien mit Prefix enthält werte hinzu
		if $getPraefix <> "" and $getPraefix <> "wurde nicht gefunden" Then

			_ArrayAdd($PrefixLabels,IniRead($INIFile,$temp,"Labelfile",0))

		EndIf
	Next
	;ConsoleWrite("Ende einlesen welche Dateinen einen Prefix davor haben: "&@MIN&":"&@SEC&@CRLF)

	ConsoleWrite("Start(Prüfen ob ein Präfix davor muss ):"&@MIN&":"&@SEC&@CRLF)
	Local $isFound = false

	For $n = 0 to UBound($PrefixLabels)-1

		; hier nur die relevanten Teile aus dem File
		Local $Labels[0]

		Local $FileOpen = FileOpen($PrefixLabels[$n],$Fo_Read)
		Local $FileRead

		while 1
			$FileRead = FileReadLine($FileOpen)
			If @error then ExitLoop
			if StringLeft($FileRead,1) <> " " Then
				Local $tmp = StringSplit($FileRead,"=")
				_ArrayAdd($Labels,$tmp[1])
			EndIf
		WEnd


		Local $returnSearchValue = _ArraySearch($Labels,$SelectedValue) ; variable enthält den Rückgabewert der Suche

		if $returnSearchValue  <> -1 Then

			$isFound = True

		EndIf

		if $isFound == True then

			;Durchgehen in welcher Section der Pfad zu finden ist
			For $i = 1 to UBound($SectionNames)-1

				Local $comparativeValue = IniRead($INIFile,$SectionNames[$i],"Labelfile","")

				if $comparativeValue == $PrefixLabels[$n] Then

						$prefix = IniRead($INIFile,$SectionNames[$i] ,"Labelprefix", "kein Wert gefunden")& ":"

				EndIf
			Next

			ExitLoop
		Endif
	Next
	ConsoleWrite("Ende: suchen ob ein Präfix davor muss: " &@MIN&":"&@SEC&@CRLF)
	ConsoleWrite("Ende: "&@MIN&":"&@SEC&@CRLF)
	ConsoleWrite("----------------------------------------------------------------------------")

	_ClipBoard_SetData("" &$prefix & $SelectedValue)

	$prefix = ""

EndFunc