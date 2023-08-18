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
Global $SearchResultsText[0]
Global $LabelPrefix[0]
Global $Imagepath = @ScriptDir &"\Search.ico"
Global $iSearch = TrayCreateItem("Label suchen")
Global $iExit = TrayCreateItem("Beenden")

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
	;_ArrayDisplay($AllLabels)
	;MsgBox(0,"","Alle Labels wurden eingelesen")

    ; Create a tray menu with three items
    ;Local $iSearch = TrayCreateItem("Label suchen")
    ;Local $iExit = TrayCreateItem("Beenden")

	;TrayCreateItem("") ; Create a separator line.

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
		Local $nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE
				GUISetState(@SW_HIDE,$Form1)
				Main()
				;Exit
				;WinClose($Form1)
			Case $SearchButton
				GUICtrlSetData($hListView, "")
				search()
			Case $TakeOverButton
				TakeOver()
				GUISetState(@SW_HIDE,$Form1)
				Main()
		EndSwitch
	WEnd
EndFunc



func search()
		;_ArrayDisplay($SearchResultsLabels)
		_GUICtrlListView_DeleteAllItems($hListView) ; löscht alle Einträge in der ListView

		;ConsoleWrite("Der Größe Index des Arrays ist: " & UBound($SearchResultsLabels)-1&@CRLF)
		Local $counter = 0 ; zählt die gefundenen Treffer
		Local $eingabe = GUICtrlRead($InputField) ;liest das EingabeFeld aus

		For $i = Ubound($SearchResultsLabels)-1 to 0 step -1

			_ArrayDelete($SearchResultsLabels,$i)
			_ArrayDelete($SearchResultsText,$i)

		Next
		;_ArrayDisplay($SearchResultsLabels,"SearchLabels")

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
		;_ArrayDisplay($SearchResultsLabels)

		; ab hier werden die Arrays nicht mehr bearbeitet sondern nur ausgegeben

		;Schreibt die Ergebnisse in die Liste(aktuell noch alle da das Array vorher nicht geleert wurde)
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
		;MsgBox(0,"","Suche ist durchgelaufen ")
EndFunc

Func TakeOver()

	Local $selectedIndex =  _GUICtrlListView_GetSelectionMark($hListView) ;Gibt den Index des Ausgewählten Wertes zurück

	Local $SelectedValue = _GUICtrlListView_GetItemText($hListView, $selectedIndex) ; schreibt den ausgewählten Wert in die ListView
	;MsgBox(0,"SelectedValue",$SelectedValue)

	Local $PrefixLabels[0] ; speichert den Pfad einer Datei mit LabelPrefix
	Local $pathWithPrefix[0]
	Global $prefix = ""

	; Prüfen welche LabelDateien einen Präfix davor haben
	For $i = 0 to UBound($SectionNames)-1

		Local $temp = $SectionNames[$i]

		Local $getPraefix = IniRead($INIFile,$temp,"Labelprefix","wurde nicht gefunden")

		; fügt dem Array das Label dateien mit Prefix enthält werte hinzu
		if $getPraefix <> "" and $getPraefix <> "wurde nicht gefunden" Then

			_ArrayAdd($PrefixLabels,IniRead($INIFile,$temp,"Labelfile",0))

		EndIf
	Next

	;_ArrayDisplay($PrefixLabels,"Dateien die ein Labelprefix haben") ; zeigt das Array an Dateien mit Prefixen enthält

	Local $isFound = false
	;MsgBox(0,"Größe von PrefixLabels",UBound($PrefixLabels))

	For $n = 0 to UBound($PrefixLabels)-1

		Local $temp2 = FileReadToArray($PrefixLabels[$n]) ; zwischenspeicher der
		Local $Labels[0]

		;_ArrayDisplay($temp2,"temp2")

		;den Namen von dem Text trennen
		For $i = 0 to UBound($temp2)-1
			Local $tempValue  = StringSplit($temp2[$i],"=")
			_ArrayAdd($Labels,$tempValue)
		Next

		;_ArrayDisplay($Labels,"zu durchsuchendes Array")
		Local $returnValueSearch = _ArraySearch($Labels,$SelectedValue) ; enthält den Rückgabewert der Suche
		; MsgBox(0,"Rückgabewert",$returnValueSearch)
		if $returnValueSearch  <> -1 Then
			$isFound = True
			;MsgBox(0,"","die Datei konnte gefunden werden")
		else

		EndIf

		; wenn es gefunden wurde soll es an der Stelle

		if $isFound == true then

			;MsgBox(0,"","Prefixlabels: "&$PrefixLabels[$n])

			;Durchgehen in welcher Section der Pfad zu finden ist
			For $i = 1 to UBound($SectionNames)-1

				Local $comparativeValue = IniRead($INIFile,$SectionNames[$i],"Labelfile","")
				if $comparativeValue == $PrefixLabels[$n] Then

						$prefix = IniRead($INIFile,$SectionNames[$i] ,"Labelprefix", "kein Wert gefunden")& ":"
						;MsgBox(0," gefundenener Prefix: ",$prefix)

				EndIf
			Next
			ConsoleWrite("Labelprefix: "&$prefix)
			;MsgBox(0,"","Labelprefix: "& $prefix)

			ExitLoop
		Endif
	Next

			Local $selectedIndex =  _GUICtrlListView_GetSelectionMark($hListView) ;Gibt den Index des Ausgewählten Wertes zurück

			Local $SelectedValue = _GUICtrlListView_GetItemText($hListView, $selectedIndex) ; schsreibt den ausgewählten Wert in die ListView

			_ClipBoard_SetData("" &$prefix & $SelectedValue)

EndFunc

Main()