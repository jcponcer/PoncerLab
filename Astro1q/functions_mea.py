"""
Helper functions for the analysis of MEA (Multi Channel Systems) recordings.

- Loading .h5 recordings with SpikeInterface and attaching the MEA geometry
  (probe) built with ProbeInterface.
- Interactive GUI to locate the MEA electrodes on a picture of the slice.
- Utilities to select channels and to interpolate a per-channel feature
  (e.g. signal power) into a 2D map that can be overlaid on the slice picture.
"""

import pickle
import re
import string
from os.path import isfile
from pathlib import Path

import h5py
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.patches as pt
from matplotlib.colors import ListedColormap
from PIL import Image
from scipy.interpolate import griddata
from scipy.ndimage import gaussian_filter

import probeinterface as pi
import spikeinterface.extractors as se
import spikeinterface.preprocessing as spre


# Geometry of the MEA layouts used (pitches in µm)
layouts_meta = {'sparse' : {'n_lines' : 10, 'n_columns' : 12, 'radius' : 30, 'xpitch' : 1500, 'ypitch' : 1000},
                'dense' : {'n_lines' : 12, 'n_columns' : 12, 'radius' : 30, 'xpitch' : 200, 'ypitch' : 200}}


# ---------------------------------------------------------------------------
# Loading recordings
# ---------------------------------------------------------------------------

def get_stream_id(path: str) :
    '''
    Read the metadata of the MCS .h5 file to find the ID of the analog stream.
    '''
    with h5py.File(path, 'r') as rf :
        analog_stream_names = list(rf.require_group('/Data/Recording_0/AnalogStream').keys())
        # Stream names are like 'Stream_0': the ID is the last character
        stream_id = analog_stream_names[0][-1]
    return stream_id


def get_channel_name(path: str, channel_id) :
    '''
    SpikeInterface uses its own channel IDs, which differ from the electrode
    labels of the MEA (e.g. 'B3'). This function returns the electrode label(s)
    corresponding to one channel ID (str) or to a list of channel IDs.
    '''

    # List of electrode labels and corresponding list of SpikeInterface IDs
    rec = se.read_mcsh5(path, get_stream_id(path))
    channels = list(rec._properties['electrode_labels'])
    ids = list(rec._main_ids)

    # Only one channel given: return its label
    if isinstance(channel_id, str) :
        return channels[ids.index(channel_id)]

    # Several channels given: return the list of labels
    elif isinstance(channel_id, list) :
        return [channels[ids.index(chan)] for chan in channel_id]


def define_probe(rec, n_lines = 10, n_columns = 12, radius = 30, xpitch = 1500, ypitch = 1000) :
    '''
    Create a rectangular probe with ProbeInterface matching the MEA layout,
    wire each contact to its channel (using the electrode labels) and attach
    it to the recording.
    '''

    def get_indices(channels: list, n_lines, n_columns) :
        '''
        For each possible electrode of the MEA (from A1 to the last letter/number),
        give its index in the channels list, or -1 if it was not recorded.

        INPUT
        channels: list of electrode labels of the recording
        n_lines: number of lines of the MEA
        n_columns: number of columns of the MEA

        OUTPUT
        indices: list ordered as the probe contacts (letter by letter, and for
        each letter numbers going from n_lines down to 1), containing the index
        of the electrode in `channels` or -1 if absent.
        '''

        # An electrode is named LETTER + NUMBER (e.g. B3): letters go from A to
        # the n_columns-th letter, numbers from 1 to n_lines
        max_number = n_lines
        alphabet = list(string.ascii_uppercase)
        alphabet.remove('I')  # there is no 'I' in MCS electrode names
        alphabet = alphabet[:n_columns]

        # Ordered list of all possible electrodes: A10, A9, ..., A1, B10, B9, ...
        # (same order as the contacts created by generate_multi_columns_probe)
        list_channels_ordered = []
        for l in alphabet :
            for i in range (max_number, 0, -1) :
                list_channels_ordered.append(f'{l}{i}')

        # Index of each possible electrode in the channels list, -1 if missing
        indices = []
        for c in list_channels_ordered :
            if c in channels :
                indices.append(channels.index(c))
            else :
                indices.append(-1)

        return indices

    probe = pi.generate_multi_columns_probe(n_columns, n_lines, xpitch=xpitch, ypitch = ypitch,
            contact_shapes="circle",
            contact_shape_params={"radius": radius})
    channels_real = list(rec._properties['electrode_labels'])
    channel_indices = get_indices(channels_real, n_lines=n_lines, n_columns=n_columns)
    probe.set_device_channel_indices(channel_indices)
    rec = rec.set_probegroup(probe)
    return rec


def get_rec(path, dfs = 10000, layout = 'sparse') :
    '''
    Load an MCS .h5 file as a SpikeInterface recording, with the MEA geometry attached.

    path: path of the .h5 file
    dfs: target sampling frequency (Hz); the recording is resampled if its
         sampling frequency is higher
    layout: MEA layout, key of `layouts_meta` ('sparse' or 'dense')
    '''
    rec = se.read_mcsh5(path, get_stream_id(path))
    rec = define_probe(rec, **layouts_meta[layout])

    # Gains given by the file metadata, so that scaled traces are in µV
    rec.set_channel_gains(rec._properties['gain_to_uV'])
    # TODO: offsets are set to 0, the real offset is not read from the file
    rec.set_channel_offsets(0)

    if dfs < rec.sampling_frequency :
        rec = spre.resample(rec, dfs)

    return rec


# ---------------------------------------------------------------------------
# Interactive positioning of the electrodes on the slice picture
# ---------------------------------------------------------------------------

def show_image_tag_channels(exp_ID, s, path,
                            edgecolor = 'black',
                            facecolor = 'white',
                            folder = '',
                            layout = 'sparse',
                            ) :
    '''
    Interactive GUI (needs an interactive matplotlib backend, e.g. %matplotlib qt)
    to locate the MEA electrodes on the picture of the slice.

    The user clicks on the 4 central electrodes (F5, F6, G5, G6); the position
    of every other electrode is extrapolated from them. The user then clicks
    on the upper left and bottom right corners of the slice; the extreme
    channels are the electrodes inside this rectangle closest to each corner.
    When the window is closed, the electrode positions (in image pixels),
    the extreme channels and the clicked corners are saved in
    `folder`/{exp_ID}_{s}.pkl (keys 'positions', 'min_max_channels', 'slice_corners').

    exp_ID: experiment ID
    s: slice number; the picture must be named slice{s}.bmp and be in the
       same folder as the recording
    path: Path of the .h5 recording
    edgecolor, facecolor: colors of the instruction text box
    folder: folder where the positions are saved
    layout: only 'sparse' is supported
    '''
    exp_ID_s = f'{exp_ID}_{s}'
    positions_file = Path(folder) / f'{exp_ID_s}.pkl'

    # Skip slices that were already positioned
    if isfile(positions_file) :
        print(f'{exp_ID_s} already done')
        return

    if layout != 'sparse' :
        print('Function only works for sparse layout')
        return

    try :
        rec = get_rec(path)
        locations = rec.get_channel_locations(rec.channel_ids)
        # Locations in units of inter-electrode distance (columns, lines)
        locations = locations/np.array((layouts_meta['sparse']['xpitch'], layouts_meta['sparse']['ypitch']))
        channels_all = list(rec._properties['electrode_labels'])
    except Exception as e :
        print(f'{exp_ID} {s} problem rec: {e}')
        return

    image_path = path.parent.absolute() / f'slice{s}.bmp'

    img = np.asarray(Image.open(image_path))

    # --- First window: lets the user look at the picture before starting ---

    fig, ax = plt.subplots(figsize=(20,20))
    fig.set_facecolor('black')
    ax.imshow(img)
    plt.ion()

    # Borders around the picture, where the instructions are written
    border = 100
    xlim = np.array(ax.get_xlim()) + [-border,+border]
    ax.set_xlim(xlim)

    ylim = np.array(ax.get_ylim()) + [-border,+border]
    ax.set_ylim(ylim)

    # Position of the instruction text
    text_space = 10
    xtextleft = xlim[0] - text_space
    ytextup = ylim[1] + text_space

    # Corners of the slice the user will click on
    corners = ['upper left', 'bottom right']

    plt.text(xtextleft, ytextup, f'Click anywhere to start or press the spacebar if hard to see center channels', size=15,
            ha="center", va="center",
            bbox=dict(boxstyle="round",
                    ec=edgecolor,
                    fc=facecolor,
                    ))

    # Class storing the state modified by the GUI callbacks
    class options :
        user = False
        pause = True
        specific = False

        def mouse_event(self, event):
            self.pause = False
            self.user = True

        def on_close(self, event):
            self.pause = False

        def pressed(self, event) :
            self.pause = False
            self.specific = True
            self.user = True

    do = options()
    # Connect the callbacks to the figure events
    fig.canvas.mpl_connect('button_press_event', do.mouse_event)
    fig.canvas.mpl_connect('close_event', do.on_close)
    fig.canvas.mpl_connect('key_press_event', do.pressed)

    # Wait for the user
    while do.pause :
        plt.pause(0.1)

    plt.show()
    plt.close(fig)

    # --- Second window: positioning of the electrodes ---

    fig, ax = plt.subplots(figsize=(20,20))
    fig.set_facecolor('black')
    ax.imshow(img)
    plt.ion()

    border = 100
    xlim = np.array(ax.get_xlim()) + [-border,+border]
    ax.set_xlim(xlim)

    ylim = np.array(ax.get_ylim()) + [-border,+border]
    ax.set_ylim(ylim)

    # Electrodes to click on, in this order
    center_channels = ['F5', 'G5', 'F6', 'G6']

    plt.text(xtextleft, ytextup, f'Click on {center_channels[0]}', size=15,
            ha="center", va="center",
            bbox=dict(boxstyle="round",
                    ec=edgecolor,
                    fc=facecolor,
                    ))

    # Class storing the clicked points and computed positions
    class define_grid :

        def __init__(self) :
            self.points = []   # clicked positions of the central electrodes
            self.limits = []   # clicked corners of the slice
            self.i = 0         # number of clicks
            self.pos_channels = None
            self.min_max_channels = None
            self.pause = True

        def mouse_event(self, event):
            # Coordinates of the click
            self.x = event.xdata
            self.y = event.ydata
            self.i += 1

            # Central electrodes not all clicked yet
            if self.i < len(center_channels)  :

                plt.scatter(self.x, self.y, color = 'white')  # white dot on the clicked electrode
                self.points.append(np.array([self.x,self.y]))

                # Show which electrode to click on next
                plt.text(xtextleft,ytextup,f'Click on {center_channels[self.i]}', size=15,
                ha="center", va="center",
                bbox=dict(boxstyle="round",
                        ec= edgecolor,
                        fc= facecolor,
                        ))

            # Last central electrode: extrapolate the position of all electrodes
            elif self.i == len(center_channels) :

                plt.scatter(self.x, self.y, color = 'white')
                self.points.append(np.array([self.x,self.y]))

                names = center_channels
                points = self.points

                # Indices of the clicked points: a=F5, b=F6, c=G5, d=G6
                a, b, c, d = 0, 1, 2, 3
                x, y = 0, 1
                # Image displacement (averaged over the two pairs) when going
                # from one number to the next (F5 -> F6) ...
                distance_letter = ((points[b][x]-points[a][x] + points[d][x]-points[c][x])/2, (points[b][y]-points[a][y] + points[d][y]-points[c][y])/2)
                # ... and from one letter to the next (F5 -> G5)
                distance_number = ((points[c][x]-points[a][x] + points[d][x]-points[b][x])/2, (points[c][y]-points[a][y] + points[d][y]-points[b][y])/2)

                # Reference electrode (F5): position in the image and on the MEA
                index_point_ref = channels_all.index(names[0])
                pos_ref = points[0]
                loc_ref = locations[index_point_ref]

                # Position in the image of every electrode, from its offset to the reference on the MEA
                positions = []
                for chan, l in zip(channels_all, locations) :
                    dletter = l[0]-loc_ref[0]
                    dnumber = l[1]-loc_ref[1]
                    loc = (pos_ref[0] + dletter*distance_letter[0]-dnumber*distance_number[0],
                        pos_ref[1] + dletter*distance_letter[1]-dnumber*distance_number[1])
                    positions.append({'channel' : chan, 'x' : loc[0], 'y' : loc[1]})

                    plt.text(loc[0], loc[1], chan, size=12,
                        ha="center", va="center",
                        bbox=dict(boxstyle="round",
                                ec='white',
                                fc='white',
                                ))

                self.pos_channels = pd.DataFrame(positions)

                # Ask for the first corner of the slice
                plt.text(xtextleft,ytextup,f'Click on {corners[self.i - len(center_channels)]} corner of the slice', size=15,
                ha="center", va="center",
                bbox=dict(boxstyle="round",
                        ec= edgecolor,
                        fc= facecolor,
                        ))

            # Upper left corner of the slice
            elif self.i == len(center_channels) + 1 :

                plt.scatter(self.x, self.y, color = 'red')  # red dot on the corner
                self.limits.append(np.array([self.x,self.y]))

                # Ask for the second corner
                plt.text(xtextleft,ytextup,f'Click on {corners[self.i - len(center_channels)]} corner of the slice', size=15,
                ha="center", va="center",
                bbox=dict(boxstyle="round",
                        ec= edgecolor,
                        fc= facecolor,
                        ))

            # Bottom right corner of the slice
            else :

                plt.scatter(self.x, self.y, color = 'red')
                self.limits.append(np.array([self.x,self.y]))

                # Draw the slice rectangle
                r = pt.Rectangle((self.limits[0][0], self.limits[1][1]), self.limits[1][0]-self.limits[0][0], self.limits[0][1]-self.limits[1][1], facecolor = 'red', alpha = 0.5)
                ax.add_patch(r)

                # Electrodes inside the clicked rectangle
                xmin, xmax = sorted((self.limits[0][0], self.limits[1][0]))
                ymin, ymax = sorted((self.limits[0][1], self.limits[1][1]))
                in_slice = self.pos_channels[(self.pos_channels.x >= xmin) & (self.pos_channels.x <= xmax) & (self.pos_channels.y >= ymin) & (self.pos_channels.y <= ymax)]

                if len(in_slice) == 0 :
                    print(f'No electrode inside the slice rectangle for {exp_ID_s}, close the window and run again')
                    fig.canvas.draw_idle()
                    return

                # Extreme electrodes: the electrodes inside the rectangle closest to each clicked corner
                def closest_channel(corner) :
                    distances = np.hypot(in_slice.x - corner[0], in_slice.y - corner[1])
                    return in_slice.channel[distances.idxmin()]

                self.min_max_channels = (closest_channel(self.limits[0]), closest_channel(self.limits[1]))

                # Highlight the two extreme electrodes
                for c in self.min_max_channels :
                    ind = list(self.pos_channels.index[self.pos_channels.channel == c])[0]

                    plt.text(self.pos_channels.x[ind], self.pos_channels.y[ind], c, size=12,
                        ha="center", va="center",
                        bbox=dict(boxstyle="round",
                                ec='white',
                                fc='white',
                                ))

            # Refresh the figure
            fig.canvas.draw_idle()

        def on_close(self, event):
            # Save the positions only if the positioning was completed
            if self.pos_channels is not None and self.min_max_channels is not None :
                with open(positions_file, 'wb') as f:
                    pickle.dump({'positions' : self.pos_channels, 'min_max_channels' : self.min_max_channels,
                                 'slice_corners' : self.limits}, f)
                print(f'Channels positions for {exp_ID_s} saved')
            else :
                print(f'Positioning of {exp_ID_s} not completed, nothing saved')

            self.pause = False

    grid = define_grid()

    # Connect the callbacks to the figure events
    fig.canvas.mpl_connect('button_press_event', grid.mouse_event)
    fig.canvas.mpl_connect('close_event', grid.on_close)

    # Wait until the window is closed
    while grid.pause :
        plt.pause(0.1)

    plt.show()


# ---------------------------------------------------------------------------
# Plotting utilities
# ---------------------------------------------------------------------------

def add_linear_transparency(cmap, max_alpha = 1) :
    '''
    Return a copy of the colormap whose transparency increases linearly
    (alpha from 0 for the lowest values to max_alpha for the highest values).
    '''
    my_cmap = cmap(np.arange(cmap.N))
    my_cmap[:, -1] = np.linspace(0, max_alpha, cmap.N)
    my_cmap = ListedColormap(my_cmap)
    return my_cmap


def channels_in(channels_all, channel1, channel2) :
    '''
    Return the channels of `channels_all` inside the rectangle of the MEA
    defined by two corner electrodes, i.e. with a letter between the letters
    of channel1 and channel2 and a number between their numbers.

    The two corners can be given in any order (e.g. 'B5' and 'D2').

    Example: channels_in(channels, 'B2', 'D5') keeps B2...B5, C2...C5, D2...D5
    '''
    min_letter, max_letter = sorted((re.findall("[a-zA-Z]+", channel1)[0], re.findall("[a-zA-Z]+", channel2)[0]))
    min_number, max_number = sorted((int(re.findall(r'\d+', channel1)[0]), int(re.findall(r'\d+', channel2)[0])))

    channels_do = []

    for channel in channels_all :
        letter = re.findall("[a-zA-Z]+", channel)[0]
        number = int(re.findall(r'\d+', channel)[0])
        if letter >= min_letter and letter <= max_letter and number >= min_number and number <= max_number :
            channels_do.append(channel)

    return channels_do


def channels_grid(df_channels, feature = "power", fill_missing = True) :
    '''
    Arrange the channels as the 2D grid of the MEA (letters x numbers), with
    the position of each electrode on the picture. The output can be given
    directly to plt.contourf(X, Y, Z), which uses a marching squares algorithm
    with linear interpolation between neighbouring channels. Since X and Y are
    2D, the grid can be rotated / not exactly straight on the picture.

    df_channels : dataframe with columns 'channel', 'x', 'y' and the feature;
                  x, y are needed for every channel of the grid, the feature
                  can be NaN (e.g. noisy channels)
    feature : name of the column to use (e.g. 'power')
    fill_missing : if True, the missing values (NaN) are replaced by a linear
                   interpolation between the other channels; outside their
                   convex hull, they stay NaN (masked by contourf)

    Returns X, Y, Z: 2D arrays (numbers x letters), Z is a masked array
    '''
    df = df_channels.copy()
    df['letter'] = [re.findall("[a-zA-Z]+", c)[0] for c in df.channel]
    df['number'] = [int(re.findall(r'\d+', c)[0]) for c in df.channel]

    # Rows = numbers, columns = letters
    X = df.pivot(index='number', columns='letter', values='x').sort_index().sort_index(axis=1)
    Y = df.pivot(index='number', columns='letter', values='y').reindex_like(X)
    Z = df.pivot(index='number', columns='letter', values=feature).reindex_like(X)
    X, Y, Z = X.values.astype(float), Y.values.astype(float), Z.values.astype(float)

    if np.isnan(X).any() or np.isnan(Y).any() :
        raise ValueError('x and y positions are needed for all the channels of the grid')

    # Missing channels: linear interpolation (Delaunay) between the valid channels
    missing = np.isnan(Z)
    if fill_missing and missing.any() and (~missing).sum() >= 3 :
        Z[missing] = griddata((X[~missing], Y[~missing]), Z[~missing], (X[missing], Y[missing]), method='linear')

    return X, Y, np.ma.masked_invalid(Z)

