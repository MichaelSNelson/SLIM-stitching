/*
 * Macro template to process multiple images in a folder
 * MAKE SURE INPUT AND OUTPUT FOLDERS ARE DIFFERENT
 */

#@ File (label = "Input directory", style = "directory") input
//#@ File (label = "Output directory", style = "directory") output


if (File.exists(input+File.separator+"output"))
	{
	tm = gettimestring();
	//print(tm);
	File.rename(input+File.separator+"output",input+File.separator+"output_renamed_"+tm);
	
	} 
output = input+File.separator+"output" ;
File.makeDirectory(output);



//File.makeDirectory()
// See also Process_Folder.py for a version of this code
// in the Python scripting language.
processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	//Array.show(list);
	Array.print(list);
	estimatedName = estimateName(input);
	for (i = 0; i < list.length; i++) {

		//if(File.isDirectory(input + File.separator + list[i]))
		//	processFolder(input + File.separator + list[i]);
		//print(endsWith(list[i], ".txt"));
		//
		if(endsWith(list[i], ".txt") && startsWith(list[i], "TileConfiguration_"))
		{
			print("filename"+ list[i]);
			processFile(input, output, list[i]);

		}
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

