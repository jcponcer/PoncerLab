function BatchResults = Batch_SpikeDetection(filename,threshold,channel,toDenoise)

%  USAGE
%
%    BatchResults = Batch_SpikeDetection(filename,threshold,channel,toDenoise)
%
%    Main function for the spikes detection. Filter the signal, receive
%    the spikes peaks, group the peaks to detect an event once and receive
%    the amplitude and frequency of the events.
%   
%    
%    filename       String ('filename.h5')
%    threshold      Positive integer - the events above the threshold can
%                   be interictal events
%    channel        channel of the MEA ({channel})
%    toDenoise      1 if you want to denoise, 0 else.
%
%  OUTPUT
%
%    BatchResults        Matrix which contains :
%                           -The spikes events (matrix)
%                           -The mean amplitude of the events (double)
%                           -The frequency of the events (double)
%                           -The start point of each events (matrix)
%                           -The stop point of each events (matrix)
%                           -The denoised signal if toDenoise = 1 (matrix)
%                           -The name of the file
%                           -The channel
%                           -The threshold
%                           -The original signal (matrix)
%                           -The filtered signal (matrix)
%                           -The normalized and squared signal (matrix)

%Load the signal
LoadHDF5(filename,'channel',channel,'time',[],'export','no');
OriginalSignal = ans;
%OriginalSignal = ans(6000000:18000000,:);

%OriginalSignal(:,1)=OriginalSignal(:,1)-0.1;

%Check parameter 4
%Filter and then denoise if the toDenoise parameter is equal to 1
%hpFilt = designfilt('highpassfir', 'StopbandFrequency', 100, 'PassbandFrequency', 500, 'StopbandAttenuation', 60, 'PassbandRipple', 1, 'SampleRate', 10000, 'DesignMethod', 'equiripple');
bpFilt = designfilt('highpassiir', 'FilterOrder', 2, 'PassbandFrequency', 100,'SampleRate', 10000');

if toDenoise == 1
    OriginalValue = OriginalSignal(:,2);
    OriginalTime = OriginalSignal(:,1);

    filteredSpikes = filtfilt(bpFilt,OriginalSignal);

    DenoisedData = wden(filteredSpikes(:,2),'rigrsure','h','mln',5,'db6');

    DenoisedMatrix = [filteredSpikes(:,1) DenoisedData];

    filteredSpikes = DenoisedMatrix;
else
  
    filteredSpikes = filtfilt(bpFilt,OriginalSignal);
end

filteredSpikes = OriginalSignal;
%Receive the spikes peaks
[spikesPeaks,normalizedSquaredSignal,start,stop] = spikeDetection(OriginalSignal,filteredSpikes,threshold);
length = size(spikesPeaks);
if length ~= 0
    %Group the points detected for the same interictal activity
    spikeSinglePeaks = SpikesGrouping(spikesPeaks);
    spikeSinglePeaks(~any(spikeSinglePeaks'),:) = [];

    %Calculate the mean amplitude of the spikes
    SpikeAmplitude = MeanAmplitude(spikeSinglePeaks);
    
    %Calculate the frequency of the spikes
    SpikeFrequency = Frequency(OriginalSignal,spikeSinglePeaks);

    %Add results to the batchResult
    BatchResults.spikeSinglePeaks  = spikeSinglePeaks;
    BatchResults.SpikeAmplitude  = SpikeAmplitude;
    BatchResults.SpikeFrequency  = SpikeFrequency;

    BatchResults.start  = start;
    BatchResults.stop  = stop;

end
if toDenoise == 1
    BatchResults.DenoisedMatrix  = DenoisedMatrix;
end
BatchResults.filename = filename;
BatchResults.channel = channel;
BatchResults.threshold = threshold;
BatchResults.OriginalSignal  = OriginalSignal;
BatchResults.filteredSpikes  = filteredSpikes;
BatchResults.normalizedSquaredSignal  = normalizedSquaredSignal;
end
