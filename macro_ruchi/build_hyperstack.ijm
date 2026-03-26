// Build Hyperstack from w/z TIF tiles
// Expects filenames like: *_w{W}_z{Z}.tif
// Stacks as: 4 channels (w0-w3), 6 z-slices (z0-z5), 1 timepoint

numC = 4;
numZ = 6;
numT = 1;

dir = getDirectory("Select folder containing the TIF files");

// Get a file list and find the common prefix (everything before _w)
list = getFileList(dir);
prefix = "";
for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif")) {
        idx = indexOf(list[i], "_w");
        if (idx > 0) {
            prefix = substring(list[i], 0, idx);
            break;
        }
    }
}

if (prefix == "") {
    exit("Could not find TIF files matching the expected pattern (*_w*_z*.tif)");
}

print("Found prefix: " + prefix);
print("Building hyperstack: " + numC + "C x " + numZ + "Z x " + numT + "T");

// Open images: w outer, z inner — matches alphabetical sort by filename
// Stack order: w0z0, w0z1, ..., w0z5, w1z0, ..., w3z5
// z (slice) varies fastest → use xyzct order for hyperstack
setBatchMode(true);

for (w = 0; w < numC; w++) {
    for (z = 0; z < numZ; z++) {
        filename = prefix + "_w" + w + "_z" + z + ".tif";
        filepath = dir + filename;
        if (!File.exists(filepath)) {
            exit("Missing file: " + filename);
        }
        open(filepath);
    }
}

// Combine all open images into a single stack
run("Images to Stack", "use");

// Convert to hyperstack — xyzct because slices vary fastest in our stack
run("Stack to Hyperstack...", 
    "order=xyzct channels=" + numC + 
    " slices=" + numZ + 
    " frames=" + numT + 
    " display=Composite");

setBatchMode(false);

print("Done — hyperstack created.");
