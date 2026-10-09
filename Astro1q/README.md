# astro_1q

Analysis of MEA (Multi Channel Systems) recordings of slices and of the corresponding histology: maps of the electrophysiological power and density maps of astrocytic inclusions and cytomegalic neurons.

## Contents

| File | Description |
| --- | --- |
| `functions_mea.py` | Helper functions: loading of the MCS `.h5` recordings with SpikeInterface, MEA geometry, interactive positioning of the electrodes on the slice picture, interpolation of a per-channel feature into a 2D map. |
| `power_mea.ipynb` | Power (1-40 Hz) of each channel and power maps overlaid on the slice pictures; example traces. |
| `heatmaps_histo.ipynb` | Density maps (cells/mm²) of the cells annotated in QuPath, overlaid on the scans. |
| `info_recordings_astro1q.xlsx` | List of the recordings (path, ID, condition, slice). |
| `power_channels_astro1q.csv` | Power of each channel (output of `power_mea.ipynb`). |
| `mea_rec/` | Pictures of the slices on the MEA (`slice{n}.bmp`). The `.h5` recordings are not included (too large for GitHub). |
| `position_channels/` | Positions of the electrodes on the slice pictures (output of `show_image_tag_channels`). |
| `positions_histo/` | Positions of the annotated cells exported from QuPath. |
| `scans/` | Scans of the slices exported from QuPath (`slice{n}.jpg`). |
| `cmaps_histo/` | Density maps (output of `heatmaps_histo.ipynb`). |


## Installation

Python 3.11:

```bash
pip install -r requirements.txt
```

The interactive positioning of the electrodes (`show_image_tag_channels`) needs a Qt backend for matplotlib (`pip install PyQt5`).
