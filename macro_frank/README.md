# macro_frank

## z_project_from_zstack_tiles.ijm

Max-intensity Z-projects MD ImageXpress z-stack tiles into composite multi-channel TIFs, one per well+site.

### What it does

1. Asks you to select the folder containing the z-stack TIF tiles (e.g. `experiment_z_stack/timepoint0/`)
2. Scans filenames to automatically detect:
   - **Wells** (group keys, e.g. `10527_60x_targets_t0_B09`, `..._B10`, ...)
   - **Channels** (`_w0`, `_w1`, ...)
   - **Z-slices** (`_z0`, `_z1`, ...)
   - **Sites** (`_s0`, `_s1`, ...) if present
3. For each well+site, builds a composite hyperstack and max-intensity Z-projects it
4. Saves each projection as a TIF in `experiment_z_projection/` (created next to `experiment_z_stack/`)

### Expected folder layout

```
<session>/
    experiment_z_stack/
        timepoint0/
            10527_60x_targets_t0_B09_s0_w0_z0.tif
            10527_60x_targets_t0_B09_s0_w0_z1.tif
            ...
    experiment_z_projection/    <-- created by macro
        10527_60x_targets_t0_B09_s0.tif
        10527_60x_targets_t0_B09_s1.tif
        ...
```

### How to run

1. Open Fiji
2. **Plugins > Macros > Run...**
3. Select `z_project_from_zstack_tiles.ijm`
4. Choose the `timepoint0` folder containing the TIF tiles
