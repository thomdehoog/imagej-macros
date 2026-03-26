// Build Hyperstack from w/z TIF tiles
// Infers channels (w), z-slices (z), and sites (s) from filenames
// Supports patterns: *_w{W}_z{Z}.tif or *_s{S}_w{W}_z{Z}.tif

dir = getDirectory("Select folder containing the TIF files");
list = getFileList(dir);

// --- Find position of a tag (e.g. "_s") that is followed by a digit ---
// Skips false matches like "_s" inside "_seeding". Returns -1 if not found.
function findTagPos(filename, tag) {
    from = 0;
    while (from < lengthOf(filename)) {
        idx = indexOf(filename, tag, from);
        if (idx < 0) return -1;
        next = idx + lengthOf(tag);
        if (next < lengthOf(filename) && charCodeAt(filename, next) >= 48 && charCodeAt(filename, next) <= 57)
            return idx;
        from = idx + 1;
    }
    return -1;
}

// --- Extract a numeric index following a tag like "_w", "_z", "_s" ---
// Returns -1 if the tag (followed by a digit) is not found in the filename.
function extractIndex(filename, tag) {
    pos = findTagPos(filename, tag);
    if (pos < 0) return -1;
    start = pos + lengthOf(tag);
    end = start;
    while (end < lengthOf(filename) && charCodeAt(filename, end) >= 48 && charCodeAt(filename, end) <= 57)
        end++;
    return parseInt(substring(filename, start, end));
}

// --- Scan filenames to find prefix, max w/z/s indices, and whether _s is present ---
prefix = "";
maxW = -1;
maxZ = -1;
maxS = -1;
hasSites = false;

for (i = 0; i < list.length; i++) {
    if (!endsWith(list[i], ".tif")) continue;
    w = extractIndex(list[i], "_w");
    z = extractIndex(list[i], "_z");
    if (w < 0 || z < 0) continue;

    // Determine prefix on the first matching file
    if (prefix == "") {
        sIdx = findTagPos(list[i], "_s");
        wIdx = findTagPos(list[i], "_w");
        if (sIdx >= 0 && sIdx < wIdx)
            prefix = substring(list[i], 0, sIdx);
        else
            prefix = substring(list[i], 0, wIdx);
    }

    if (w > maxW) maxW = w;
    if (z > maxZ) maxZ = z;

    s = extractIndex(list[i], "_s");
    if (s >= 0) {
        hasSites = true;
        if (s > maxS) maxS = s;
    }
}

if (prefix == "" || maxW < 0 || maxZ < 0)
    exit("Could not find TIF files matching the expected pattern (*_w*_z*.tif)");

// Indices are 0-based → count = max + 1
numC = maxW + 1;
numZ = maxZ + 1;
numS = 1;
if (hasSites) numS = maxS + 1;

// --- Create output folder: <input folder>_hyperstacks ---
// Strip trailing separator from dir, append _hyperstacks
outDir = substring(dir, 0, lengthOf(dir) - 1) + "_hyperstacks" + File.separator;
if (!File.isDirectory(outDir))
    File.makeDirectory(outDir);

print("Found prefix: " + prefix);
print("Detected: " + numC + " channels, " + numZ + " z-slices, " + numS + " sites");
print("Saving to: " + outDir);

// --- Build one hyperstack per site, save, and close ---
// z varies fastest → xyzct order for hyperstack
setBatchMode(true);

for (s = 0; s < numS; s++) {
    for (w = 0; w < numC; w++) {
        for (z = 0; z < numZ; z++) {
            if (hasSites)
                filename = prefix + "_s" + s + "_w" + w + "_z" + z + ".tif";
            else
                filename = prefix + "_w" + w + "_z" + z + ".tif";
            filepath = dir + filename;
            if (!File.exists(filepath))
                exit("Missing file: " + filename);
            open(filepath);
        }
    }

    run("Images to Stack", "use");

    run("Stack to Hyperstack...",
        "order=xyzct channels=" + numC +
        " slices=" + numZ +
        " frames=1" +
        " display=Composite");

    if (hasSites)
        saveName = prefix + "_s" + s;
    else
        saveName = prefix;

    saveAs("Tiff", outDir + saveName + ".tif");
    close();

    print("Site " + s + " saved and closed.");
}

setBatchMode(false);

print("Done — " + numS + " hyperstack(s) saved to " + outDir);
