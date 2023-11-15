function [LFP,Mode,Channels,Units,Sweeps] = LoadHDF5(filename,varargin)

%  LoadHDF5 - Load HDF5 file (obtained from MultiChannel System recordings).
%
%  USAGE
%
%    [LFP,Mode,Channels,Units,Sweeps] = LoadHDF5(filename,varargin)
%
%    This function calls the McsHDF5 Toolbox and reorganizes data for convenience
%
%    filename       path + filename of file to load.
%    <options>      optional list of property-value pairs (see table below)
%
%    =========================================================================
%     Properties    Values
%     
%     channel       IDs of channels you want to import.
%                   (default = manually entered by user)
%     time          for gap-free recordings, timing you want to import.
%                   (default = manually entered by user)
%     sweep         for length-fixed episodic recordings, ID of sweeps to import
%     time_unit     specify in which unit you want to import the timestamps
%                   's', 'ms' or 'min' (default = 's')
%     data_unit     specify in which unit you want to import the data
%                   'V', 'mV', 'µV' or 'nV' (default = 'mV')
%     export        export LFP into Excel File 'yes' or 'no' 
%                   (default = manually entered by user)
%    -------------------------------------------------------------------------
%    =========================================================================
%
%  OUTPUT
%
%    LFP            for gap-free recordings :
%		    Mx(N+1) matrix [Time Signal1 ... SignalN]
%		    for fixed-length episodic recordings :
%		    [Time Sweep1 ... SweepN] x ChannelID 3-D matrix
%    Mode	    Mode of recording : 'gapfree' or 'sweep'
%    Channels	    List of channels that were imported
%    Units	    structure Units.Time and Units.Data
%    Sweeps	    in case of fixed-length episodic recordings, 
%		    ID of imported sweeps
%
%  SEE
%
%    See also McsHDF5 Toolbox from MultiChannel Systems.

% Copyright (C) 2017 by Marie Goutierre
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.



%-----------------------------------------------------------------------------------------------------------------
% Initialize parameters
%-----------------------------------------------------------------------------------------------------------------

% Default values
Channels = [];
Timing = [];
Sweeps = [];
Units.Time = 's';
Units.Data = 'mV';
LFP = [];
Export = [];
LoadingCriteria = struct;

% Parse parameter list
for i = 1:2:length(varargin),
	if ~ischar(varargin{i}),
		error(['Parameter ' num2str(i) ' is not a property (type ''help <a href="matlab:help LoadHDF5">LoadHDF5</a>'' for details).']);
	end
	switch(lower(varargin{i})),
		case 'channel',
			Channels = varargin{i+1};
			if ~iscell(Channels)
				error('Incorrect value for ''channel'' (type ''help <a href="matlab:help LoadHDF5">LoadHDF5</a>'' for details).');
			end
		case 'time',
			Timing = varargin{i+1};
            if ~isempty(Timing)
                if ~isdmatrix(Timing,'>=0') | size(Timing,2) ~= 2,
                    error('Incorrect value for ''time'' (type ''help <a href="matlab:help LoadHDF5">LoadHDF5</a>'' for details).');
                end
            end
		case 'sweep',
			Sweeps = varargin{i+1};
			if ~isdmatrix(Timing,'>=0') | size(Timing,2) ~= 2,
				error('Incorrect value for ''sweep'' (type ''help <a href="matlab:help LoadHDF5">LoadHDF5</a>'' for details).');
			end
		case 'time_unit',
			Units.Time = varargin{i+1};
			if ~isstringFMA(Units.Time,'s','ms','min'),
				error('Incorrect value for ''time_unit'' (type ''help <a href="matlab:help LoadHDF5">LoadHDF5</a>'' for details).');
			end
		case 'data_unit',
			Units.Data = varargin{i+1};
			if ~isstringFMA(Units.Data,'V','mV','µV','nV'),
				error('Incorrect value for ''data_unit'' (type ''help <a href="matlab:help LoadHDF5">LoadHDF5</a>'' for details).');
			end
		case 'export',
			Export = varargin{i+1};
			if ~isstringFMA(Export,'yes','no'),
				error('Incorrect value for ''export'' (type ''help <a href="matlab:help LoadHDF5">LoadHDF5</a>'' for details).');
			end
		otherwise,
			error(['Unknown property ''' num2str(varargin{i}) ''' (type ''help <a href="matlab:help LoadHDF5">LoadHDF5</a>'' for details).']);
	end
end

% Retrieve multiplication factor according to units
if strcmp(Units.Time,'s'),
	TimeFactor = 1;
elseif strcmp(Units.Time,'ms'),
	TimeFactor = 1000;
elseif strcmp(Units.Time,'min'),
	TimeFactor = 1/60;
end

if strcmp(Units.Data,'V'),
	DataFactor = 1;
elseif strcmp(Units.Data,'mV'),
	DataFactor = 1000;
elseif strcmp(Units.Data,'µV'),
	DataFactor = 1000000;
elseif strcmp(Units.Data,'nV'),
	DataFactor = 1000000000;
end


%-----------------------------------------------------------------------------------------------------------------
%   Preliminary loading and infos
%-----------------------------------------------------------------------------------------------------------------

% Pre-load the data using McsHDF5 Toolbox
DataSet = McsHDF5.McsData(filename);

% Identify the mode of recording
if ~isempty(DataSet.Recording{1,1}.SegmentStream),
	Mode = 'sweep';
	disp('Data were acquired in fixed-length episodic mode');
elseif ~isempty(DataSet.Recording{1,1}.AnalogStream),
	Mode = 'gapfree';
	disp('Data were acquired in gap-free mode');
else
	error('Data were not acquired in gap-free or in fixed-length episodic mode. Unable to import the data');
end

% Determine which channels to import
if isempty(Channels),
	Channels = inputdlg(sprintf([' Enter the ID of channels you want to import \n Channels can be entered as Letter+Number combination or Number only' ...
		'\n\n Example1 : F12 A7 \n Example2 : 44 45 46 \n\n To import all channels, do not enter anything \n']));
	Channels = strsplit(Channels{1});
end
% Retrieve the corresponding channel ID
if strcmp(Mode,'gapfree'),
	ChannelLabel = DataSet.Recording{1, 1}.AnalogStream{1, 1}.Info.Label;
elseif strcmp(Mode,'sweep'),
	ChannelLabel = DataSet.Recording{1, 1}.SegmentStream{1, 1}.Info.Label;
end
if ~isempty(Channels{1}),
	ChannelID = zeros(size(Channels));
	for i = 1:length(Channels),
		ChannelID(i) = find(strcmpi(ChannelLabel,Channels{i}));
	end
else
	if strcmp(Mode,'gapfree'),
		LoadingCriteria.channel = [1:length(ChannelLabel)];
		Channels = ChannelLabel;
	elseif strcmp(Mode,'sweep'),
		LoadingCriteria.segment = [1:length(ChannelLabel)];
		Channels = ChannelLabel;
	end
end
NChannels = length(Channels);


%-----------------------------------------------------------------------------------------------------------------
% Read the Data if they were acquired as sweeps
%-----------------------------------------------------------------------------------------------------------------

if strcmp(Mode,'sweep'),
	
	 % Select the ID of sweeps to import
	if isempty(Sweeps),
		Sweeps = inputdlg(sprintf([' Enter the ID of sweeps you want to import \n\n Sweeps 10, 20 and 30 : 10,20,30' ...
			'\n All sweeps from 10 to 30 and 40 to 50 : 10:30,40:50 \n One Sweep out of 2 : 1:2:TotalNSweeps \n\n To import all sweeps, do not enter anything \n']));
		Sweeps = str2num(Sweeps{1});
	end
	NSweeps = length(Sweeps);
	
	% Import the data
	if ~isfield(LoadingCriteria,'segment'),
		for i = 1 : length(ChannelID),
			LoadingCriteria.segment = ChannelID(i);
			PartialData = DataSet.Recording{1,1}.SegmentStream{1,1}.readPartialSegmentData(LoadingCriteria);
			% Re-organize data
			ChannelData = PartialData.SegmentData';
			% Adjust unit
			RecordingUnit = PartialData.DataUnit;
			if strcmp(RecordingUnit,'V'),
				ChannelData = ChannelData*DataFactor;
			elseif strcmp(RecordingUnit,'mV'),
				ChannelData = ChannelData*DataFactor/1000;
			elseif strcmp(RecordingUnit,'µV'),
				ChannelData = ChannelData*DataFactor/1000000;
			elseif strcmp(RecordingUnit,'nV'),
				ChannelData = ChannelData*DataFactor/1000000000;
			end
			% Keep only the wanted sweep
			if ~isempty(Sweeps),
				ChannelData = ChannelData(:,Sweeps);
			else
				Sweeps = [1:size(ChannelData,2)];
				NSweeps = length(Sweeps);
			end
			% Retrieve the timestamps and adjust unit
			TimeStamps = PartialData.SegmentDataTimeStamps';
			TimeStamps = double(TimeStamps)*TimeFactor/1000000;
			% Combine [Time Data]
			ChannelData = [TimeStamps ChannelData];
			LFP = cat(3,LFP,ChannelData);
		end
	else
		PartialData = DataSet.Recording{1,1}.SegmentStream{1,1}.readPartialSegmentData(LoadingCriteria);
		% For each channel,
		for i = 1 : size(PartialData.SegmentData,2),
			% Re-organize data
			ChannelData = PartialData.SegmentData{1,i}';
			% Adjust unit
			RecordingUnit = PartialData.DataUnit{1,i};
			if strcmp(RecordingUnit,'V'),
				ChannelData = ChannelData*DataFactor;
			elseif strcmp(RecordingUnit,'mV'),
				ChannelData = ChannelData*DataFactor/1000;
			elseif strcmp(RecordingUnit,'µV'),
				ChannelData = ChannelData*DataFactor/1000000;
			elseif strcmp(RecordingUnit,'nV'),
				ChannelData = ChannelData*DataFactor/1000000000;
			end
			% Keep only the wanted sweep
			if ~isempty(Sweeps),
				ChannelData = ChannelData(:,Sweeps);
			else
				Sweeps = [1:size(ChannelData,2)];
				NSweeps = length(Sweeps);
			end
			% Retrieve the timestamps and adjust unit
			TimeStamps = PartialData.SegmentDataTimeStamps{1,i}';
			TimeStamps = double(TimeStamps)*TimeFactor/1000000;
			% Combine [Time Data]
			ChannelData = [TimeStamps ChannelData];
			LFP = cat(3,LFP,ChannelData);
		end
	end
end


%-----------------------------------------------------------------------------------------------------------------
% Read the Data if they were acquired in gap-free mode
%-----------------------------------------------------------------------------------------------------------------

if strcmp(Mode,'gapfree'),
	% Default output parameter
	Sweeps = [];
	
	% Select the timing to import
% 	if isempty(Timing),
% 		Timing = inputdlg(sprintf([' Enter the timing (in s) you want to import \n\n For one time interval : StartInterval,StopInterval' ...
% 			'\n For several time intervals : Start1,Stop1;...;StartN,StopN \n\n To import all recording, do not enter anything \n']));
% 		Timing = str2num(Timing{1});
% 	end
	if ~isempty(Timing),
		LoadingCriteria.window = Timing;
	end
	
	% Import the data
	if ~isfield(LoadingCriteria,'channel'),
		for i = 1 : length(ChannelID),
			LoadingCriteria.channel = ChannelID(i);
			PartialData = DataSet.Recording{1,1}.AnalogStream{1,1}.readPartialChannelData(LoadingCriteria);
			ChannelData = PartialData.ChannelData';
			
			% Adjust unit for each channel
			RecordingUnit = PartialData.DataUnit;
			if strcmp(RecordingUnit,'V'),
				ChannelData = ChannelData*DataFactor;
			elseif strcmp(RecordingUnit,'mV'),
				ChannelData = ChannelData*DataFactor/1000;
			elseif strcmp(RecordingUnit,'µV'),
				ChannelData = ChannelData*DataFactor/1000000;
			elseif strcmp(RecordingUnit,'nV'),
				ChannelData = ChannelData*DataFactor/1000000000;
			end
			
			% Save channel data
			LFP = [LFP ChannelData];
		end
		% Retrieve the timestamps and adjust unit
		TimeStamps = PartialData.ChannelDataTimeStamps';
		TimeStamps = double(TimeStamps)*TimeFactor/1000000;
			
		% Combine [Time Data]
		LFP = [TimeStamps LFP];
	else
		PartialData = DataSet.Recording{1,1}.AnalogStream{1,1}.readPartialChannelData(LoadingCriteria);
		ChannelData = PartialData.ChannelData';
		
		% Adjust unit for each channel
		for i = 1 : size(ChannelData,2),
			RecordingUnit = PartialData.DataUnit{i};
			if strcmp(RecordingUnit,'V'),
				ChannelData(:,i) = ChannelData(:,i)*DataFactor;
			elseif strcmp(RecordingUnit,'mV'),
				ChannelData(:,i) = ChannelData(:,i)*DataFactor/1000;
			elseif strcmp(RecordingUnit,'µV'),
				ChannelData(:,i) = ChannelData(:,i)*DataFactor/1000000;
			elseif strcmp(RecordingUnit,'nV'),
				ChannelData(:,i) = ChannelData(:,i)*DataFactor/1000000000;
			end
		end

		% Retrieve the timestamps and adjust unit
		TimeStamps = PartialData.ChannelDataTimeStamps';
		TimeStamps = double(TimeStamps)*TimeFactor/1000000;
		
		% Combine [Time Data]
		LFP = [TimeStamps ChannelData];
	end
end


%-----------------------------------------------------------------------------------------------------------------
% If wanted, export data as an Excel File
%-----------------------------------------------------------------------------------------------------------------

% Determine if Excel exporting is needed
if isempty(Export),
	Export = inputdlg(sprintf([' Do you want to export the data in Excel ? \n\n Type : yes or no']));
	Export = Export{1};
end

if strcmp(Export,'yes'),
	[FileName,PathName] = uiputfile;
	if strcmp(Mode,'gapfree'),
		% Write Data
		xlswrite([PathName FileName(1:end-4) '.xlsx'],LFP,1,'A4');
		% Name Columns
		xlswrite([PathName FileName(1:end-4) '.xlsx'],{['Time in ' Units.Time]},1,'A1');
		xlswrite([PathName FileName(1:end-4) '.xlsx'],{['Channel ID']},1,'B1');
		xlswrite([PathName FileName(1:end-4) '.xlsx'],Channels,1,'B2');
		xlswrite([PathName FileName(1:end-4) '.xlsx'],{['Voltage in ' Units.Data]},1,'B3');
		% Merge cells
		e = actxserver('Excel.Application'); % # open Activex server
		ewb = e.Workbooks.Open([PathName FileName(1:end-4) '.xlsx']); % # open file (enter full path!)
		CellRange = ['B1:',ExcelCol(NChannels+1),'1'];
		CellRange = [CellRange{:}];
		ewbActivesheetRange = ewb.Worksheets.Item(1).get('Range', CellRange);
		ewbActivesheetRange.MergeCells = 1;
		ewbActivesheetRange.HorizontalAlignment = -4108;
		CellRange = ['B3:',ExcelCol(NChannels+1),'3'];
		CellRange = [CellRange{:}];
		ewbActivesheetRange = ewb.Worksheets.Item(1).get('Range', CellRange);
		ewbActivesheetRange.MergeCells = 1;
		ewbActivesheetRange.HorizontalAlignment = -4108;
		ewbActivesheetRange = ewb.Worksheets.Item(1).get('Range', 'A1:A3');
		ewbActivesheetRange.MergeCells = 1;
		ewbActivesheetRange.VerticalAlignment = -4108;
		% Save to the same file
		ewb.Save
		ewb.Close(true)
		e.Quit
	elseif strcmp(Mode,'sweep'),
		for i = 1 : size(LFP,3),
			% Write Data
			xlswrite([PathName FileName(1:end-4) '.xlsx'],LFP(:,:,i),i,'A4');
			% Name Columns
			xlswrite([PathName FileName(1:end-4) '.xlsx'],{['Time in ' Units.Time]},i,'A1');
			xlswrite([PathName FileName(1:end-4) '.xlsx'],{['Sweep ID']},i,'B1');
			xlswrite([PathName FileName(1:end-4) '.xlsx'],Sweeps,i,'B2');
			xlswrite([PathName FileName(1:end-4) '.xlsx'],{['Voltage in ' Units.Data]},i,'B3');
			% Merge cells
			e = actxserver('Excel.Application'); % # open Activex server
			ewb = e.Workbooks.Open([PathName FileName(1:end-4) '.xlsx']); % # open file (enter full path!)
			CellRange = ['B1:',ExcelCol(NSweeps+1),'1'];
			CellRange = [CellRange{:}];
			ewbActivesheetRange = ewb.Worksheets.Item(i).get('Range', CellRange);
			ewbActivesheetRange.MergeCells = 1;
			ewbActivesheetRange.HorizontalAlignment = -4108;
			CellRange = ['B3:',ExcelCol(NSweeps+1),'3'];
			CellRange = [CellRange{:}];
			ewbActivesheetRange = ewb.Worksheets.Item(i).get('Range', CellRange);
			ewbActivesheetRange.MergeCells = 1;
			ewbActivesheetRange.HorizontalAlignment = -4108;
			ewbActivesheetRange = ewb.Worksheets.Item(i).get('Range', 'A1:A3');
			ewbActivesheetRange.MergeCells = 1;
			ewbActivesheetRange.VerticalAlignment = -4108;
			% Rename sheet
			ewb.Worksheets.Item(i).Name = ['Channel ' Channels{i}];
			% Save to the same file
			ewb.Save
			ewb.Close(true)
			e.Quit
		end
	end
end
