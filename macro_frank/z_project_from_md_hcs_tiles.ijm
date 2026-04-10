// ------------------------------------------------------------------------------
// ImageJ Macro: Z-Project MD ImageXpress Z-Stack Tiles
// Created: 2026-03-31 | Updated: 2026-03-31
// Author: thom.dehoog@zmb.uzh.ch | ZMB Center for Microscopy and Image Analysis, UZH
//
// If you publish a paper using this macro, please acknowledge.
//
// Description: Batch max-intensity Z-projects multi-well, multi-timepoint
//   z-stack tiles exported by Molecular Devices ImageXpress (MD HCS).
//   - Discovers timepoint subfolders automatically
//   - Groups tiles by well and site from filename tags (_w, _z, _s)
//   - Builds a temporary hyperstack per group, then max-intensity projects
//   - Saves one composite MIP per timepoint, well, and site
//   - Runs in batch mode to minimise memory overhead
//
// Input:  experiment_z_stack/ folder containing timepoint subfolders
// Output: experiment_z_projection/ created alongside the input folder
// ------------------------------------------------------------------------------

experimentDir = getDirectory("Select the experiment_z_stack folder");

// --- Output folder: ../experiment_z_projection/ ---
expTrimmed = substring(experimentDir, 0, lengthOf(experimentDir) - 1);
sessionPath = File.getParent(expTrimmed);
outDir = sessionPath + File.separator + "experiment_z_projection" + File.separator;
if (!File.isDirectory(outDir))
    File.makeDirectory(outDir);

// --- Helpers ---

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

function extractIndex(filename, tag) {
    pos = findTagPos(filename, tag);
    if (pos < 0) return -1;
    start = pos + lengthOf(tag);
    end = start;
    while (end < lengthOf(filename) && charCodeAt(filename, end) >= 48 && charCodeAt(filename, end) <= 57)
        end++;
    return parseInt(substring(filename, start, end));
}

var _groupKey = "";

function extractGroupKey(filename) {
    sPos = findTagPos(filename, "_s");
    wPos = findTagPos(filename, "_w");
    if (sPos >= 0 && (wPos < 0 || sPos < wPos)) {
        _groupKey = substring(filename, 0, sPos);
        return 1;
    }
    if (wPos >= 0) {
        _groupKey = substring(filename, 0, wPos);
        return 1;
    }
    _groupKey = "";
    return 0;
}

// --- Find timepoint subfolders ---
expContents = getFileList(experimentDir);
numTP = 0;
tpDirs = newArray(1000);
tpNames = newArray(1000);
for (i = 0; i < expContents.length; i++) {
    if (startsWith(expContents[i], "timepoint") && endsWith(expContents[i], "/")) {
        tpNames[numTP] = replace(expContents[i], "/", "");
        tpDirs[numTP] = experimentDir + expContents[i];
        numTP++;
    }
}

if (numTP == 0)
    exit("No timepoint folders found in " + experimentDir);

tpDirs = Array.trim(tpDirs, numTP);
tpNames = Array.trim(tpNames, numTP);
Array.sort(tpNames);
Array.sort(tpDirs);

print("Found " + numTP + " timepoint(s)");
print("Output: " + outDir);

// --- Process each timepoint ---
setBatchMode(true);

for (tp = 0; tp < numTP; tp++) {
    dir = tpDirs[tp];
    list = getFileList(dir);
    print("Processing " + tpNames[tp] + " (" + list.length + " files)...");

    // Collect unique group keys (one per well)
    maxKeys = 0;
    tempKeys = newArray(1000);
    for (i = 0; i < list.length; i++) {
        if (!endsWith(list[i], ".tif")) continue;
        if (extractIndex(list[i], "_w") < 0) continue;
        if (extractIndex(list[i], "_z") < 0) continue;
        extractGroupKey(list[i]);
        key = _groupKey;
        if (key == "") continue;
        found = false;
        for (g = 0; g < maxKeys; g++) {
            if (tempKeys[g] == key) found = true;
        }
        if (!found) {
            tempKeys[maxKeys] = key;
            maxKeys++;
        }
    }

    if (maxKeys == 0) {
        print("  No matching TIF files, skipping.");
        continue;
    }

    keys = Array.trim(tempKeys, maxKeys);
    Array.sort(keys);

    // Process each well
    for (k = 0; k < keys.length; k++) {
        key = keys[k];
        maxW = -1;
        maxZ = -1;
        maxS = -1;
        hasSites = false;

        for (i = 0; i < list.length; i++) {
            if (!endsWith(list[i], ".tif")) continue;
            extractGroupKey(list[i]);
            if (_groupKey != key) continue;
            w = extractIndex(list[i], "_w");
            z = extractIndex(list[i], "_z");
            if (w < 0 || z < 0) continue;
            if (w > maxW) maxW = w;
            if (z > maxZ) maxZ = z;
            s = extractIndex(list[i], "_s");
            if (s >= 0) {
                hasSites = true;
                if (s > maxS) maxS = s;
            }
        }

        numC = maxW + 1;
        numZ = maxZ + 1;
        numS = 1;
        if (hasSites) numS = maxS + 1;

        // Process each site
        for (s = 0; s < numS; s++) {
            for (w = 0; w < numC; w++) {
                for (z = 0; z < numZ; z++) {
                    if (hasSites)
                        filename = key + "_s" + s + "_w" + w + "_z" + z + ".tif";
                    else
                        filename = key + "_w" + w + "_z" + z + ".tif";
                    if (!File.exists(dir + filename))
                        exit("Missing file: " + filename + " in " + tpNames[tp]);
                    open(dir + filename);
                }
            }

            run("Images to Stack", "use");
            run("Stack to Hyperstack...",
                "order=xyzct channels=" + numC +
                " slices=" + numZ +
                " frames=1 display=Composite");
            hsID = getImageID();

            run("Z Project...", "projection=[Max Intensity]");

            if (hasSites)
                saveName = key + "_s" + s;
            else
                saveName = key;
            saveAs("Tiff", outDir + saveName + ".tif");
            close();

            selectImage(hsID);
            close();

            print("  " + saveName + ".tif");
        }
    }
}

setBatchMode(false);
print("Done — projections saved to " + outDir);
