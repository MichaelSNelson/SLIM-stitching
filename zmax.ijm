/*
 * Macro template to process multiple images in a folder
 * 
 */

#@ File (label = "Input directory", style = "directory") input
//#@ File (label = "Output directory", style = "directory") output
#@ File (label = ".xyz file", style = "file") xyzFile
//
//WARNING: May be formatting issue if slices are 03 instead of 3?
//
////////////////////////////////////////////////


//Array.print(xPos);
//Results in three arrays that are the x, y, and z coordinates from the .xyz file.
//Makes the assumption that the coordinate precision in the file is 5 after the .
////////////////////////////////////////////
//get the number of Z slices
list = getFileList(input);
zFileList = newArray();
//regExMatch = ".*_Z("+zSlice+")_.*";
zMax = 0;
for (i = 0; i < list.length; i++) {
	//Get the names of the files that end in photons.tif
	if(list[i].endsWith("photons.tif")){
		print("list loop "+ list[i]);
		zFileList = Array.concat(zFileList, list[i]);
		zPosition = split(list[i], "(_Z)");
		Array.print(zPosition);
		zPosition = split(zPosition[1], "_");
		if (zPosition>zMax){ zMax = zPosition;}
	}
}
Array.print(zFileList);
