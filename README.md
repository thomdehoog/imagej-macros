# ImageJ Macros

Collection of ImageJ/Fiji macros for microscopy image processing.

## macro_ruchi/build_hyperstack.ijm

Assembles individual TIF tiles exported by LAS X into multi-channel, z-stack hyperstacks.

### What it does

1. Asks you to select a folder containing TIF tiles
2. Scans filenames to automatically detect:
   - Number of **channels** (`_w0`, `_w1`, ...)
   - Number of **z-slices** (`_z0`, `_z1`, ...)
   - Number of **sites** (`_s0`, `_s1`, ...) if present
3. Builds one composite hyperstack per site
4. Saves each hyperstack as a TIF in a new folder next to the input folder (e.g. `E10/` -> `E10_hyperstacks/`)
5. Closes each hyperstack after saving to keep memory usage low

### Expected filename patterns

```
<prefix>_w{channel}_z{slice}.tif
<prefix>_s{site}_w{channel}_z{slice}.tif
```

Examples:
```
Ngn2_seeding resistance_p62_t0_E10_s0_w0_z0.tif
10527_60x_targets_t0_B09_s4_w3_z5.tif
```

Tags like `_w`, `_z`, `_s` must be followed by a digit. Occurrences within words (e.g. `_s` in `_seeding`) are ignored.

Non-TIF files in the folder (e.g. `.json`) are ignored.

### How to run

1. Open Fiji
2. Go to **Plugins > Macros > Run...**
3. Select `build_hyperstack.ijm`
4. Choose the folder containing the TIF tiles

### Output

Hyperstacks are saved as TIF files in `<input_folder>_hyperstacks/`:

```
E10_hyperstacks/
  Ngn2_seeding resistance_p62_t0_E10_s0.tif
```

If there are no sites, the output filename matches the prefix:

```
experiment_hyperstacks/
  experiment_name.tif
```
