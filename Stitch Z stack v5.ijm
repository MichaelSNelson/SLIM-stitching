/*
 * Target the folder with the photon.tif files, all files for all Z slices should be in the same folder
 * Assumptions made: 
 * *****
 * File names MUST NOT INCLUDE "_Z" in the file name anywhere other than where the Z position is defined
 * *****
 * All file names are similar except for _Z and _SP values
 * All files end in the string placed in file name suffix
 * Assumes coordinate precision in .xyz file is 5 decimal places exactly
 */
 //To Do: Include file metadata - pixel size, Z distances?

#@ File (label = "Input directory", style = "directory") input
//#@ File (label = "Output directory", style = "directory") output
#@ File (label = ".xyz file", style = "file") xyzFile
#@ String (label = "File name suffix, e.g. photons (not extensions like .tif)") imageType
//
////////////////////////////////////////////////
//Create new output sub-directory to selected Input directory - if one already exists
if (File.exists(input+File.separator+"output")) {
	tm = gettimestring();
	//print(tm);
	File.rename(input+File.separator+"output",input+File.separator+"output_renamed_"+tm);
} 

output = input+File.separator+"output" ;
File.makeDirectory(output);

//Create the TileConfiguration_Z.txt file for Grid/Collection stitching to use
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
for (i = 0; i < rows.length ; i++) {
	periodSplit = split(rows[i], ".");
	//Array.print(periodSplit);
	xPos[i] = parseFloat(periodSplit[0]+"."+substring(periodSplit[1], 0, 5))/0.81; //works better with /1.23713338989675
	yPos[i] = parseFloat(substring(periodSplit[1], 5/*, periodSplit[1].length*/)+"."+substring(periodSplit[2], 0, 5))/0.81; //vs /0.416666650109821/2
}
//Array.print(xPos);
//Results in three arrays that are the x, y, and z coordinates from the .xyz file.
//Makes the assumption that the coordinate precision in the file is 5 decimal places
////////////////////////////////////////////
//get the number of Z slices
list = getFileList(input);
zMax = 0;
//
//***************************************************//
//Requires that there be no other _Zs in the file name.
//******************************************************//
for (i = 0; i < list.length; i++) {
	//Get the names of the files that end in photons.tif
	if(list[i].endsWith(imageType+".tif")){
		//zFileList = Array.concat(zFileList, list[i]);
		zPosition = split(list[i], "(_Z)");
		Array.print(zPosition);
		zPosition = split(zPosition[1], "_");
		if (zPosition[0] > zMax){ 
			zMax = zPosition[0];
		}
	}
}
print("Z max: "+ zMax);
print("N rows = ",rows.length);
//zMax should now be the max number of Z slices (0 base)
//waitForUser("Draw ROI, then hit OK");   
//Now cycle through each Z, and create a TileConfiguration_Z.txt
for (i = 0; i < zMax+1; i++) {
	regExMatch = ".*_Z"+i+"_.*";
	//print(regExMatch);
	zFileList = returnFileListCurrentZ(list, regExMatch);
	Array.print(zFileList);
	//Get the names of the files that end in requiredString.tif
	tileConfigurationFileName = "TileConfiguration_"+i+".txt";
	f = File.open(input+File.separator + tileConfigurationFileName);
	print(f, "# Define the number of dimensions we are working on\ndim = 2\n\n# Define the image coordinates\n");
	//For each row L, add a line indicating the file name and positions from the .xyz file.
	for (l = 0; l < rows.length; l++) {
		//print(l);
		print(f, zFileList[l]+" ; ; ("+xPos[l]+","+yPos[l]+")\n");
	}
	File.close(f);

}

 
//At this point we should have a set of text files written that are in a format Grid/Collection stitcher can use
/////////////////////////////////////////////


//File.makeDirectory()
// See also Process_Folder.py for a version of this code
// in the Python scripting language.
processFolder(input, zMax);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input, zMax) {
	list = getFileList(input);
	list = Array.sort(list);
	//Array.show(list);
	Array.print(list);
	estimatedName = estimateName(input);

	for (i = 0; i < zMax+1; i++) {
		//
		tileConfigFile = "TileConfiguration_"+i+".txt";
		print("filename "+ tileConfigFile);
		processFile(input, output, tileConfigFile);

	}

	//Grab all images and convert to stack. Need to be grabbed in order.
	//run("Image Sequence...", "dir=["+output+"] filter=tif sort");
	//saveAs("TIFF", output+File.separator +"CurrentZStack.tif");
	//close();
	run("Image Sequence...", "dir=["+output+"] filter=tif sort");
	
	saveAs("TIFF", output+File.separator +estimatedName+"_zStack");
	close();
}

//Perform grid/collection stitching on the contents of the selected directory.
//each call of the function will be on a specific TileConfiguration_#.txt file. 
function processFile(input, output, file) {
	// Figure out which N is being passed
	dotIndex = indexOf( file, ".txt" );
	n = replace(substring( file, 0, dotIndex ), "TileConfiguration_", "");
	print(n);
	run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by TileConfiguration] directory=["+input+"] layout_file=TileConfiguration_"+n+".txt fusion_method=[Max. Intensity] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Write to disk] output_directory=["+output+"]");
	//may need to rename file as it is created
	File.rename(output+File.separator +"img_t1_z1_c1", output+File.separator +"Z"+n+".tif");
	//print("Processed: " + input + File.separator + file);

}


function gettimestring(){
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	//MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
	// MonthNames[month]
	//DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
	 //"Date: "+DayNames[dayOfWeek]+" ";
	 
	 TimeString =""+year+"_" ;
	 if (month<10) {TimeString = TimeString+"0";}
	 TimeString = TimeString+d2s(month+1,0)+"_";
	 if (dayOfMonth<10) {TimeString = TimeString+"0";}
	 TimeString = TimeString+dayOfMonth+"-"; 
	 if (hour<10) {TimeString = TimeString+"0";}
	 TimeString = TimeString+hour+"_";
	 if (minute<10) {TimeString = TimeString+"0";}
	 TimeString = TimeString+minute+"_";
	 if (second<10) {TimeString = TimeString+"0";}
	 TimeString = TimeString+second;
	 //showMessage(TimeString);
	return TimeString;
}

//Attempt to get a base name to call the Z-stack from the file name.
//Assumes there are only time point 0 files. 
function estimateName(input){
	imageFiles = getFileList(input);
	for (i = 0; i < imageFiles.length; i++) {
		if(endsWith(imageFiles[i], ".tif")){
			nameIndex = indexOf(imageFiles[i], "_TP0");
			estimatedName = substring( imageFiles[i], 0, nameIndex );
			return estimatedName;
		}
	}
}

function returnFileListCurrentZ(list, regExMatch){
	zFileList = newArray(list.length); //keep the list of Z slice file names
	k = 0; //keep track of how many useful files, not the total number of files
	for (j = 0; j < list.length; j++) {
	
		//Get the names of the files that end in requiredString.tif
		if(list[j].endsWith(imageType+".tif") && list[j].matches(regExMatch)){
			zFileList[k] = list[j];
			k=k+1;
		}
	}
	return zFileList;
}