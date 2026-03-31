# macro_frank

## z_project_from_md_hcs_tiles.ijm

Max-intensity Z-projects MD ImageXpress z-stack tiles into composite multi-channel TIFs, one per timepoint + well + site.

### What it does

1. Asks you to select the `experiment_z_stack` folder
2. Finds all `timepoint*` subfolders inside it
3. For each timepoint, scans filenames to detect wells, channels, z-slices, and sites
4. Builds a composite hyperstack per well+site, max-intensity Z-projects it
5. Saves each projection as a TIF in `experiment_z_projection/` (created next to `experiment_z_stack/`)

### Expected folder layout

```
<session>/
    experiment_z_stack/          <-- select this folder
        timepoint0/
            10527_60x_targets_t0_B09_s0_w0_z0.tif
            ...
        timepoint1/
            ...
    experiment_z_projection/     <-- created by macro
        10527_60x_targets_t0_B09_s0.tif
        10527_60x_targets_t0_B09_s1.tif
        ...
```

### How to run

1. Open Fiji
2. **Plugins > Macros > Run...**
3. Select `z_project_from_md_hcs_tiles.ijm`
4. Choose the `experiment_z_stack` folder
