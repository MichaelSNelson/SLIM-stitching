/* README
 * - Target the folder with the photon.tif files, all files for all Z slices should be in the same folder
 * - Filenames MUST NOT INCLUDE "_Z" in the file name anywhere other than where the Z position is defined
 * - Limited to Wiscscan FLIM sdt file outputs and setup on SLIM scope with a minimum overlap of  ___ % or ___ pixels
 * - Limited to XYZ stacks with same Z-locations
 * - 
 */
// NOTE v6: removed bioformat ome-reader and gridstitcher-log-reader versions


// GET INPUTS
#@ File (label = "*.asc file folder", style = "directory") input
#@ File (label = "*.xyz file", style = "file") xyzFile
#@ String (label = "File suffix eg: photons, a1[%], a1, color coded value") suffix
#@ Boolean (label = "Make the asc files into tif files for stitching", value=true) make_asc
#@ Boolean (label = "Write out the TileConfiguration_Z.txt files", value =true) write_tileconfig
#@ Boolean (label = "Perform stitching", value=true) stitch_files
#@ Boolean (label = "Crop the top and bottom line of pixels", value=true) crop_pixels
#@ String (visibility=MESSAGE, value="There must be tile configuration tiles for the script to stitch successfully!", required=false) message


// 1. CREATE TIFF FILES FROM ASC
// WILL OVERWRITE TIF EXISTING
	if (make_asc){	
		list = getFileList(input);
		setBatchMode(true);
		list = Array.sort(list);
		for (i = 0; i < list.length; i++) 	{
			if(endsWith(list[i], suffix+".asc")){
				saveastif(input, list[i]);	}
		}
			 	
	}


// 2. WRITE TILE CONFIG
// FIND XY LOCATIONS and PIXEL SIZE AND WRITE TILE CONFIG
// WILL OVERWRITE EXISTING TILECONFIG
	
	if (write_tileconfig){


		filestring = File.openAsString(xyzFile);
		
		//Begin parsing the string returned from the xyz file
		//remove the first two lines that contain text.
		rows = split(filestring, "\n");
		rows = Array.deleteIndex(rows, 0);
		rows = Array.deleteIndex(rows, 0);
		// Read the positions as floats
		xPos = newArray(rows.length);
		yPos = newArray(rows.length);
		arr_for_calc_minimum_img_size = newArray(rows.length);
		for (i = 0; i < rows.length ; i++) {
			periodSplit = split(rows[i], ".");
			x = parseFloat(periodSplit[0]+"."+substring(periodSplit[1], 0, 5));
			y = parseFloat(substring(periodSplit[1], 5)+"."+substring(periodSplit[2], 0, 5)); 
			xPos[i] = x;
			yPos[i] = y;	
			arr_for_calc_minimum_img_size[i] = x;
		}
		// find the stage-stepsize
		stage_stepsize = calculate_step_size(arr_for_calc_minimum_img_size);
		image_size = 256.0 ; // WISCSCAN FIXED FLIM SIZE
		pixel_size =  stage_stepsize / image_size ; 
		pixel_size = parseFloat(d2s(pixel_size, 1));
		print('PixelSize = ',pixel_size);
		//Array.show(xPos);
		// make pixels for Tile config
		for (i = 0; i < rows.length ; i++) {
			xPos[i] = xPos[i]/pixel_size; 
			yPos[i] = yPos[i]/pixel_size;
		}
	
		// FIND Number of Z positions by reading filename _Z in sdt exported files
		
		n_zpos = get_number_of_z_slices(input,suffix);  // number of Z slices (0 base)
		print("Number of Z", n_zpos);
				
		//Now cycle through each Z, and create a TileConfiguration_Z.txt
		for (i = 0; i < n_zpos+1; i++) {
			regExMatch = ".*_Z"+i+"_.*";
			list = getFileList(input);

			//Get the names of the files that end in requiredString.tif
			zFileList = returnFileListCurrentZ(list, regExMatch);	
			print("#files matching string " +regExMatch + " = ", n_zpos);
			
			// WRITE FILE
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
	}


// 3. MAKE OUTPUT FOLDER AND STITCH FILES
//  USE TILE CONFIG AND STITCH SEQUENTIAL OVER Z-SET OF TIFS

	if(stitch_files) {
	// CREATE OUTPUT FOLDER WITHOUT OVERWRITING:
			tm = gettimestring();

	output = input+File.separator+"output_"+ suffix+ "_" + tm;
	File.makeDirectory(output);	
	StitchFiles(input, output, n_zpos);
	print("Processing completed, results in "+output);
 }



////////////////////methods defined below //////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////

// FUNCTION TO CHANGE ASC TO TIF
function saveastif(input, file) {
	if(crop_pixels){
		run("Text Image... ", "open=["+ input + File.separator  +file+"]");
		//height = getHeight;
		//width = getWidth;
		//run("Specify...", "width="+width+" height="+height-2);
		run("Specify...", "width=256 height=254 x=0 y=1");
		run("Crop");
		saveAs("Tiff", input  + File.separator+file );
	}else{
		run("Text Image... ", "open=["+ input + File.separator  +file+"]");
		saveAs("Tiff", input + File.separator +file );
	}
}



// FUNCTION TO GET THE CURRENT TIME AS A STRING
function gettimestring(){
	 getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
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
	return TimeString;
}


// FUNCTION TO CALCULATE STEPSIZE
function calculate_step_size(arr_for_calc_minimum_img_size)
{
	arr_for_calc_minimum_img_size = Array.sort(arr_for_calc_minimum_img_size);
	i=1;
	stepsize=0;
	while (stepsize==0){ 
		stepsize = (arr_for_calc_minimum_img_size[i]-arr_for_calc_minimum_img_size[i-1]);
		i = i+1;
		}
	print("stepsize = ",stepsize);
	return stepsize;
}


// FIND NUMBER OF Z FILES PER SINGLE SDT
function get_number_of_z_slices(input,suffix){
	list = getFileList(input);
	zMax = 0;
	for (i = 0; i < list.length; i++) {
		//Get the names of the files that end in photons.tif
		if(list[i].endsWith(suffix+".tif")){
			//zFileList = Array.concat(zFileList, list[i]);
			zPosition = split(list[i], "(_Z)");
			//Array.print(zPosition);
			zPosition = split(zPosition[1], "_");
			if (zPosition[0] > zMax){ 
				zMax = zPosition[0];
				}
			}
		}
	return zMax;
	}

// FUNCTION TO FIND LIST WITH SPECIFIC STRING
function returnFileListCurrentZ(list, regExMatch){
	zFileList = newArray(list.length); //keep the list of Z slice file names
	k = 0; //keep track of how many useful files, not the total number of files
	for (j = 0; j < list.length; j++) {
	
		//Get the names of the files that end in requiredString.tif
		if(list[j].endsWith(suffix+".tif") && list[j].matches(regExMatch)){
			zFileList[k] = list[j];
			k=k+1;
		}
	}
	return zFileList;
}


// FUNCTION TO SEQUENTIAL STITCHING 
function StitchFiles(input, output, zMax) {

	list = getFileList(input);
	list = Array.sort(list);
	//Array.show(list);
	//Array.print(list);
	estimatedName = estimateName(input);
	print("Final Stitched File", estimatedName);
	for (i = 0; i < zMax+1; i++) {
		//
		tileConfigFile = "TileConfiguration_"+i+".txt";
		//print("filename "+ tileConfigFile);
		stitch_file(input, output, tileConfigFile);

	}

	//Grab all images and convert to stack. Need to be grabbed in order.
	//run("Image Sequence...", "dir=["+output+"] filter=tif sort");
	//saveAs("TIFF", output+File.separator +"CurrentZStack.tif");
	//close();
	run("Image Sequence...", "dir=["+output+"] filter=tif sort");
	
	saveAs("TIFF", output+File.separator +estimatedName+"_zStack");
	close();
}

// FUNCTION TO ESTIMATE STITCHED OUTPUT FILE NAME
function estimateName(input){
	//Attempt to get a base name to call the Z-stack from the file name.
	//Assumes there are only time point 0 files. 	
	imageFiles = getFileList(input);
	for (i = 0; i < imageFiles.length; i++) {
		if(endsWith(imageFiles[i], ".tif")){
			nameIndex = indexOf(imageFiles[i], "_TP0");
			estimatedName = substring( imageFiles[i], 0, nameIndex );
			return estimatedName;
		}
	}
}


// STITCH SINGLE SET OF Z-TIFs
function stitch_file(input, output, file) {
	//Perform grid/collection stitching on the contents of the selected directory.
	//each call of the function will be on a specific TileConfiguration_#.txt file. 
	// Figure out which N is being passed
	dotIndex = indexOf( file, ".txt" );
	n = replace(substring( file, 0, dotIndex ), "TileConfiguration_", "");
	//print(n);
	run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by TileConfiguration] directory=["+input+"] layout_file=TileConfiguration_"+n+".txt fusion_method=[Max. Intensity] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Write to disk] output_directory=["+output+"]");
	//may need to rename file as it is created
	File.rename(output+File.separator +"img_t1_z1_c1", output+File.separator +"Z"+n+".tif");
	//print("Processed: " + input + File.separator + file);
	// open the fused image (grid stitcher wont save and display AFAIK
	open(output+File.separator +"Z"+n+".tif");
	run("Enhance Contrast", "saturated=0.35");
	
}

