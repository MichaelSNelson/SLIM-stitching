# SLIM-stitching
Stitching for FLIM parameter files exported from SPCImage using Fiji's Grid/Collection stitcher and IJM scripts

- Date : Jan 2022

ImageJ Macro to stitch SLIM captured sdt-file exports (*.asc) using the stage locations(*.xyz) file
Extended version (in python) supports reading locations from bioformats ome-xml and textoutput from the Gridstitcher

 * Target the folder with the photon.tif files, all files for all Z slices should be in the same folder
 * Filenames MUST NOT INCLUDE "_Z" in the file name anywhere other than where the Z position is defined
 * Limited to Wiscscan FLIM sdt file outputs and setup on SLIM scope with a minimum overlap of  ___ % or ___ pixels (to be calculated)
 * Limited to XYZ stacks with same Z-locations
 
 NOTE v6: removed bioformat ome-reader and gridstitcher-log-reader versions

