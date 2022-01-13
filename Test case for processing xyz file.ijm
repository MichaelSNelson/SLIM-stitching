/*
 * Macro template to process multiple images in a folder
 * MAKE SURE INPUT AND OUTPUT FOLDERS ARE DIFFERENT
 */

#@ File (label = "Input directory", style = "directory") input
//#@ File (label = "Output directory", style = "directory") output
#@ File (label = ".xyz file", style = "file") xyzFile

filestring = File.openAsString(xyzFile);
//print(filestring);

//Begin parsing the string returned from the xyz file
//First step is to remove the first two lines that contain text.
rows = split(filestring, "\n");
rows = Array.deleteIndex(rows, 0);
rows = Array.deleteIndex(rows, 0);
//Array.print(rows);

xPos = newArray(rows.length);
yPos = newArray(rows.length);
zPos = newArray(rows.length);
for (i = 0; i < rows.length ; i++) {
	periodSplit = split(rows[i], ".");
	Array.print(periodSplit);
	xPos[i] = periodSplit[0]+"."+substring(periodSplit[1], 0, 5);
	yPos[i] = substring(periodSplit[1], 5, periodSplit[1].length)+"."+substring(periodSplit[2], 0, 5);
	zPos[i] = substring(periodSplit[2], 5, periodSplit[2].length)+"."+substring(periodSplit[3], 0, 5);
}
Array.print(xPos);
Array.print(yPos);
Array.print(zPos);
//floatPosition = parseFloat(string);
