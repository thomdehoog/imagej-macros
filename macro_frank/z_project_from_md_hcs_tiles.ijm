// Z-Project from MD ImageXpress z-stack tiles (multi-well)
// Builds hyperstack per well+site, max-intensity z-projects, saves projection
// Input:  select the timepoint folder (e.g. experiment_z_stack/timepoint0/)
// Output: experiment_z_projection/ created next to experiment_z_stack/

dir = getDirectory("Select the folder containing the z-stack TIF tiles");
list = getFileList(dir);

// --- Output folder: ../../experiment_z_projection/ ---
dirTrimmed = substring(dir, 0, lengthOf(dir) - 1);
parentPath = File.getParent(dirTrimmed);
sessionPath = File.getParent(parentPath);
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

function extractGroupKey(filename) {
    sPos = findTagPos(filename, "_s");
    wPos = findTagPos(filename, "_w");
    if (sPos >= 0 && (wPos < 0 || sPos < wPos))
        return substring(filename, 0, sPos);
    if (wPos >= 0)
        return substring(filename, 0, wPos);
    return "";
}

// --- Collect unique group keys (one per well) ---
maxKeys = 0;
tempKeys = newArray(1000);
for (i = 0; i < list.length; i++) {
    if (!endsWith(list[i], ".tif")) continue;
    if (extractIndex(list[i], "_w") < 0) continue;
    if (extractIndex(list[i], "_z") < 0) continue;
    key = extractGroupKey(list[i]);
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

if (maxKeys == 0)
    exit("No TIF files matching the expected pattern (*_w*_z*.tif) found.");

keys = Array.trim(tempKeys, maxKeys);
Array.sort(keys);

print("Found " + keys.length + " group(s):");
for (k = 0; k < keys.length; k++)
    print("  " + keys[k]);
print("Output: " + outDir);

// --- Process each group: build hyperstack, z-project, save ---
setBatchMode(true);

for (k = 0; k < keys.length; k++) {
    key = keys[k];
    maxW = -1;
    maxZ = -1;
    maxS = -1;
    hasSites = false;

    for (i = 0; i < list.length; i++) {
        if (!endsWith(list[i], ".tif")) continue;
        if (extractGroupKey(list[i]) != key) continue;
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

    for (s = 0; s < numS; s++) {
        for (w = 0; w < numC; w++) {
            for (z = 0; z < numZ; z++) {
                if (hasSites)
                    filename = key + "_s" + s + "_w" + w + "_z" + z + ".tif";
                else
                    filename = key + "_w" + w + "_z" + z + ".tif";
                if (!File.exists(dir + filename))
                    exit("Missing file: " + filename);
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

setBatchMode(false);
print("Done — " + keys.length + " group(s) projected to " + outDir);
