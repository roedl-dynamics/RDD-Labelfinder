# RDD-Labelfinder
the script enables a faster search of labels from specified label files.<br>

![image](https://github.com/roedl-dynamics/R-dl-Dynamics---Label-Suche/blob/main/LabelfinderBild2.PNG)

<h2> How to Use </h2>

<ul>
  <li>1.place an INI file named "AutoLabelSearch.au3.ini" in the same folder as the script </li>
  <li>2. name the first section "System" add "MaxSearchResults" as key </li>
  <li>3. now you can add the label file to be searched individually as a section with the keys "Labelfile" and "Labelprefix".</li>
  <li>4. When you start the Script it will start in the Background, you can open the GUI in the Tray. </li>
  <li>5. after starting the GUI, you can search labels by typing in the search field and clicking on the Search Button eith the magnifying glass. the results are displayed in the listview.  </li>
  <li>6. Clicking on the label you are looking for in the ListView and clicking on the "Label übernehmen"- button.It will copy the label and the associated prefix into the clipboard.  </li>
</ul>






<h2>Edit the script</h2> 

This program is purely written with the AutoIt script editor SciTE. 
Both are free to download from the following links:
1.  [AutoIt3](https://www.autoitscript.com/site/autoit/downloads/).
2.  [SciTE](https://www.autoitscript.com/site/autoit-script-editor/downloads/).

Once installed, open the D365FOServiceManager.au3 file with SciTE to open and edit the code. By clicking <kbd>F5</kbd>, you can testrun the script.
For further informations have a look at the official AutoIt [website](https://www.autoitscript.com/site/autoit-script-editor/installation/).
