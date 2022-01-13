

import re
import os
import glob


sdt_loc = r'C:\temp\img'
xml_loc = r'C:\temp'

read_grid_log = False
read_xml = True


## reading grid-logger-output and writing a 2D stitching TileConfiguration file
## ??Only works if all tiles are in a 2D plane?
if read_grid_log:  
    ## read the grid stitcher log from imageJ-exported text file
    grid_log = os.path.join(xml_loc,'gridstitcher_log.txt')
    with open(grid_log) as f:
        txt = f.read()        
    ## find the locations
    locx = re.findall(r'(\d*\.\d*,\d*\.\d*,\d*\.\d*)',txt)

    ## find the lifetime SPCImage-exported *.tif files

    fl  = glob.glob(os.path.join(sdt_loc,r'*.tif'))
    #print(re.split(r'SP(\d*)[._]',fl[0])[1])
    fl = sorted(fl, key = lambda x:int(re.split(r'SP(\d*)[._]',x)[1]))

    #print(fl)

    ## output file
    output_file = os.path.join(sdt_loc,'TileConfiguration_x.txt')
    with open(output_file,'w') as f:
        f.write("""# Define the number of dimensions we are working on
dim = 2

# Define the image coordinates
""")

    ## iterate over locations,tif file: assuming they are numerically sorted
    for i,j in zip(locx[:len(locx)//2],fl):
        x = float(i.split(",")[0]) /2
        y = float(i.split(",")[1]) /2
        config_statement = f'{os.path.split(j)[-1]} ; ; ({x:.2f},{y:.2f})'
        with open(output_file,'a') as f:
            f.write(config_statement+'\n')

## standard use case, pulling from the ome.xml file for the intensity images?
## NOT the scanSettings.xml
if read_xml:
    
    xml_file= glob.glob(os.path.join(xml_loc,'*.ome.xml'))
    assert len(xml_file)==1
    xml_file = xml_file[0]
    
    with open(xml_file) as f:
        txt = f.read()

    info ={}
    for expr in [
        (r'SizeZ="(\d*)"','size_z'),
        (r'PhysicalSizeX="(\d*\.\d*)"','physical_size_x'),
        (r'PhysicalSizeY="(\d*\.\d*)"','physical_size_y'),
        (r'PhysicalSizeZ="(\d*\.\d*)"','physical_size_z')  ]:
        z = re.findall(expr[0],txt)
        z= list(set(z))
        assert len(z) == 1
        val = float(z[0])
        info.update({expr[1]:val})
        print(expr[1], val)


    ## find positions
    expr = r'(Position #\d*")'

    ## extract coordinates into a list
    x_coords = []
    for i in re.split(expr,txt)[2::2]:
    #print(i.split("/")[0], i.split("PhysicalSizeX")[1].split('"')[1])
        x_coords.append(float(i.split("X=")[1].split('"')[1]))
    x_coords = [(x-x_coords[0])/info['physical_size_x'] for x in x_coords]


    y_coords = []
    for i in re.split(expr,txt)[2::2]:
        y_coords.append(float(i.split("Y=")[1].split('"')[1]))

    y_coords = [(y-y_coords[0])/info['physical_size_y'] for y in y_coords]


    expr = r'FirstZ="(\d*)"'
    z_coords = []
    for i in re.findall(expr,txt):
        z_coords.append(float(i))

    locs= []
    for i in zip(x_coords,y_coords,z_coords):
        x,y,first_z = i
        for z_index in range(int(info['size_z'])):
            current_z = first_z  + (z_index)*info['physical_size_z']
            locs.append((x,y,current_z))



    fl  = glob.glob(os.path.join(sdt_loc,r'*photons.tif'))
    #print(len(fl))
    #for sdt_exported_filename in fl:
    #    fl.append(re.split(r'SP(\d*)[._]',sdt_exported_filename)[1])
    fl = sorted(fl, key = lambda x:int(re.split(r'SP(\d*)[._]',x)[1]))

    ##06012022 modified need the number of Z positions to know how many TileConfiguration text files are needed
    z_list = []
    for z in fl:
        z_list.append(re.split(r'Z(\d*)[._]',z)[1])
    z_list = unique(z_list)
    ##ideally at this point z_list should contain 0-8 or whatever the number of Z positions are.
    ##potentially use a set.
    
    ## HEADER
    ## 06012022 modified to output each Z set as its own configuration file
    for layer_number in z_list:
        output_file = os.path.join(sdt_loc,'TileConfiguration'+n+'.txt')
        
##        if int(info['size_z'])==1:
##            dim =2
##        if int(info['size_z'])>1:
##            dim =3

        tile_config_text = """# Define the number of dimensions we are working on
dim = 2

# Define the image coordinates
"""

        with open(output_file,'w') as f:
            f.write(tile_config_text)


        ## LOCATIONS
        ## iterate over locations,tif file: assuming they are numerically sorted
        for i,j in zip(locs,fl):
            x,y,z = i
            
            ## 06012022 modified check the file name for the presence of the Z# before adding it to the current TileCOnfigurationX.txt
            file_name = os.path.split(j)[-1]
            if  layer_number in re.split(r'Z(\d*)[._]',file_name)[1]

            ########the conversion seems weird. We convert and then convert back? Maybe I am doing the wrong conversion.
                config_statement = f'{os.path.split(j)[-1]} ; ; ({x:.2f}/2,{y:.2f}/2)'
                with open(output_file,'a') as f:
                    f.write(config_statement+'\n')
                #print(config_statement)
    


# next cycle through tile configs using a loop in Fiji?
#run("Grid/Collection stitching", "type=[Positions from file] order=[Defined by TileConfiguration] directory=[G:/Eliceiri lab/03062021 Stitching in Fiji/temp/temp/img - Copy] layout_file=TileConfiguration.txt fusion_method=[Max. Intensity] regression_threshold=0.30 max/avg_displacement_threshold=2.50 absolute_displacement_threshold=3.50 computation_parameters=[Save computation time (but use more RAM)] image_output=[Write to disk] output_directory=[G:/Eliceiri lab/03062021 Stitching in Fiji/temp/temp/img - Copy]");
    

