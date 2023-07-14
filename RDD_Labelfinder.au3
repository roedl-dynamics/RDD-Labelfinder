; Search Icon Source: https://www.iconarchive.com/show/vista-artistic-icons-by-awicons/search-icon.html
;#NoTrayIcon
#include <StringConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <WindowsConstants.au3>
#include <MsgBoxConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <Array.au3>
#include <TrayConstants.au3> ; benötigt um das Tool im Hintergrund laufen zu lassen
#include <File.au3>
#include <Clipboard.au3>
#include <GuiListView.au3>

;Opt("MustDeclareVars",1)
Opt("TrayMenuMode", 3) ;
Local $INIFile = @ScriptName & ".ini"
Global $MaxSearchResults = 0
Global $AllLabels
Global $SearchResultsLabels[0]
;Global $SectionNames[0]
Global $SearchResultsText[0]
Global $LabelPrefix[0]
Global $Imagepath = @ScriptDir &"\Search.ico"

Func Main()
	;einlesen der Konfigurationsdatei
	$INIFile = "AutoLabelSearch.au3.ini"

	Global $MaxSearchResults
	Global $AllLabels[0]
	Global  $SectionNames = IniReadSectionNames(@ScriptDir & "\" & $INIFile)
	ConsoleWrite(@ScriptDir & "\" & $INIFile&@CRLF)

	For $i = 1 to UBound($SectionNames)-1
			Local $SectionName = $SectionNames[$i]

				if $SectionName == "System" Then
					$MaxSearchResults = IniRead($INIFile,$SectionName,"MaxSearchResults",0)
					ConsoleWrite("$MaxSearchResults=" & $MaxSearchResults & @CRLF)

				ElseIf $SectionName == "General " Then
					; hier soll nichts passieren
				Else
					;hier die prefixe auslesen und das Array befüllen
					Local $tmpLabelFile = IniRead($INIFile,$SectionName,"Labelfile","")
					if FileExists($tmpLabelFile) then
						Local $CurrentLabelFile = FileReadToArray($tmpLabelFile)
						; zu dem anderen Array hinzugfügen
						_ArrayAdd($AllLabels,$CurrentLabelFile)
					else
						MsgBox(1,@ScriptName,"FileNotFound")
					EndIf
				EndIf
	next

	MsgBox(0,"","Alle Labels wurden eingelesen")

    ; Create a tray menu with three items
    Local $iSearch = TrayCreateItem("Label suchen")
    Local $iExit = TrayCreateItem("Beenden")


    TrayCreateItem("") ; Create a separator line.

    ; Show the tray menu
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
	Global $Form1 = GUICreate("Rödl Dynamics - Label Suche",396, 460, 190, 151,BitOR($WS_SIZEBOX, $WS_SYSMENU, $WS_MINIMIZEBOX)) ;BitOR($WS_SIZEBOX, $WS_SYSMENU, $WS_MINIMIZEBOX)
	Global $Group1 = GUICtrlCreateGroup("Suche", 32, 24, 337, 65)
	Global $SearchButton = GUICtrlCreateButton("", 300, 45, 60, 27,$BS_ICON)
	GUICtrlSetImage(-1, $Imagepath, 169, 0)
	Global $InputField = GUICtrlCreateInput("", 40, 45, 200, 20)
	Global $hListView = GUICtrlCreateListView("Label|Text|Kommentar", 32, 113, 337, 280)
	Global $TakeOverButton = GUICtrlCreateButton("Label übernehmen", 32, 400, 337, 27)
	GUISetState(@SW_SHOW)
	ControlFocus($Form1, "", $InputField)
	GUICtrlSetResizing($TakeOverButton,$GUI_DOCKAUTO)
	GUICtrlSetResizing($Group1,$GUI_DOCKAUTO)
	GUICtrlSetResizing($SearchButton,$GUI_DOCKAUTO)
	GUICtrlSetResizing($InputField,$GUI_DOCKAUTO)
	GUICtrlSetResizing($hListView ,$GUI_DOCKAUTO)
	#EndRegion ### END Koda GUI section ###

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				Exit
			Case $SearchButton
				search()
			Case $TakeOverButton
				TakeOver2()
				;$selectedIndex =  _GUICtrlListView_GetSelectionMark($hListView) ;Gibt den Index des Ausgewählten Wertes zurück

				;Local $SelectedValue = _GUICtrlListView_GetItemText($hListView, $selectedIndex)

				;_ClipBoard_SetData("" & $SelectedValue)
		EndSwitch
	WEnd
EndFunc


func search()
		Local $eingabe = GUICtrlRead($InputField) ;liest das EingabeFeld aus
		For $i = 0 to UBound($AllLabels)-1
			If StringRegExp($AllLabels[$i],";") Then
				; passiert nichts

				else
					If StringRegExp($AllLabels[$i],$eingabe) Then

							Local $tempArray = StringSplit($AllLabels[$i],"=")

							_ArrayAdd($SearchResultsLabels,$tempArray[1]) ; Fügt dem Array mit dem den Gefundenen Labels das Label hinzu

							_ArrayAdd($SearchResultsText,$tempArray[UBound($tempArray)-1]) ;Fügt dem Array mit den Gefundenen Text ein Text hinzu

					EndIf
			EndIf
		Next

		;Schreibt die Ergebnisse in die Liste
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
EndFunc

Func TakeOver()
	$selectedIndex =  _GUICtrlListView_GetSelectionMark($hListView) ;Gibt den Index des Ausgewählten Wertes zurück

	Local $SelectedValue = _GUICtrlListView_GetItemText($hListView, $selectedIndex) ; schsreibt den ausgewählten Wert in die ListView

	_ClipBoard_SetData("" & $SelectedValue)
EndFunc

; Takeover mit Labelprefix (noch nicht fertig)
Func TakeOver2()

	$selectedIndex =  _GUICtrlListView_GetSelectionMark($hListView) ;Gibt den Index des Ausgewählten Wertes zurück

	Local $SelectedValue = _GUICtrlListView_GetItemText($hListView, $selectedIndex) ; schreibt den ausgewählten Wert in die ListView
	MsgBox(0,"SelectedValue",$SelectedValue)

	Local $PrefixLabels[0] ; speichert den Pfad einer Datei mit LabelPrefix
	Local $pathWithPrefix[0]
	Global $key = "Labelprefix"
	Local $prefix

	; Prüfen welche LabelDateien einen Präfix davor haben
	For $i = 0 to UBound($SectionNames)-1

		Local $temp = $SectionNames[$i]

		Local $getPraefix = IniRead($INIFile,$temp,"Labelprefix","wurde nicht gefunden")

		; fügt dem Array das Label dateien mit Prefix enthält werte hinzu
		if $getPraefix <> "" and $getPraefix <> "wurde nicht gefunden" Then

			_ArrayAdd($PrefixLabels,IniRead($INIFile,$temp,"Labelfile",0))

		EndIf
	Next

	_ArrayDisplay($PrefixLabels,"Array mit dem Pfad") ; zeigt das Array an Dateien mit Prefixen enthält

	; nur die Labeldateien durchsuchen die einen Präfix haben
	; Dateien einzeln durchsuchen
	; Labelpräfix hinzufügen falls nötig
	Local $isFound = false


	For $i = 0 to UBound($PrefixLabels)-1
		Local $temp2 = FileReadToArray($PrefixLabels[$i])
		Local $Labels[0]

		_ArrayDisplay($temp2,"temp2")

		;den Namen von dem Text trennen
		For $i = 0 to UBound($temp2)-1
			$tempValue  = StringSplit($temp2[$i],"=")
			;_ArrayDisplay($Labels)
			_ArrayAdd($Labels,$tempValue)
		Next

		_ArrayDisplay($Labels,"zu durchsuchendes Array")
		Local $z = _ArraySearch($Labels,$SelectedValue)
		;MsgBox(0,"Rückgabewert",$z)
		if $z <> -1 Then
			$isFound = True
		else
			; bleibt so wie es ist
		EndIf

		; wenn es gefunden wurde soll es an der Stelle


		; hier noch mal prüfen
		if $isFound == true then
			; hier muss das Labelprefix bestimmt werden
			;IniRead($PrefixLabels[$i],$prefixLabel[$i],$key)
			ExitLoop
		Endif

	Next

EndFunc

Main()