function BatchResults = Batch_InterictalDetection(filename,threshold,channel,toDenoise)

%  USAGE
%
%    BatchResults = Batch_InterictalDetection(filename,threshold,channel,toDenoise)
%
%    Main function for the interictal detection. Filter the signal, receive
%    the interictal peaks, group the peaks to detect an event once and receive
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
%                           -The IIA events (matrix)
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
%If toDenoise = 1, denoise the signal and then filter. Else, just filter

%hpFilt = designfilt('highpassfir', 'StopbandFrequency', 250, 'PassbandFrequency', 350, 'StopbandAttenuation', 60, 'PassbandRipple', 1, 'SampleRate', 10000, 'DesignMethod', 'equiripple');
hpFilt = designfilt('lowpassiir','FilterOrder',2,'PassbandFrequency',40,'SampleRate', 10000);

if toDenoise == 1
    OriginalValue = OriginalSignal(:,2);
    OriginalTime = OriginalSignal(:,1);
    %filteredSpikes = filtfilt(hpFilt,OriginalSignal);
    DenoisedData = wden(OriginalValue,'rigrsure','h','mln',5,'db4');
    DenoisedMatrix = [OriginalTime DenoisedData];
    %filteredInterIctalActivity = FilterLFP(DenoisedMatrix,'passband',[1,40],'nyquist',5000,'order',2);
    filteredInterIctalActivity = filtfilt (hpFilt,DenoisedMatrix);
    %noise = std(filteredInterIctalActivity(:,2));
    %noise = std(filteredSpikes(:,2));
    %threshold = 1.2*noise;
else
    %filteredInterIctalActivity = FilterLFP(OriginalSignal,'passband',[1,50],'nyquist',5000,'order',2);
    filteredInterIctalActivity = filtfilt (hpFilt,OriginalSignal);
    %filteredInterIctalActivity = OriginalSignal;
end






%Receive the interictal peaks
[interictalPeaks,normalizedSquaredSignal,start,stop] = interictalDetection(OriginalSignal,filteredInterIctalActivity,threshold);
length = size(interictalPeaks);
if length ~= 0
    %Group the points detected for the same interictal activity
    [interictalSinglePeaks,positiveEvent,negativeEvent] = EventsGrouping(interictalPeaks);
    interictalSinglePeaks(~any(interictalSinglePeaks'),:) = [];
    
    %If the events are positives, remove the negatives events and reciprocally
    finalInterictalSinglePeaks = removePositiveNegative(interictalSinglePeaks,positiveEvent,negativeEvent);

    %Calculate the mean amplitude of the IIA
    InterictalAmplitude = MeanAmplitude(finalInterictalSinglePeaks);
    
    %Calculate the frequency of the IIA
    InterictalFrequency = Frequency(OriginalSignal,finalInterictalSinglePeaks);
    
    %Add results to the batchResult
    BatchResults.finalInterictalSinglePeaks  = finalInterictalSinglePeaks;
    BatchResults.InterictalAmplitude  = InterictalAmplitude;
    BatchResults.InterictalFrequency  = InterictalFrequency;

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
BatchResults.filteredInterIctalActivity  = filteredInterIctalActivity;
%BatchResults.SquaredSignal = squaredSignal;
BatchResults.normalizedSquaredSignal  = normalizedSquaredSignal;
%BatchResults.stdsignal = noise;
%BatchResults.filteredspikes = filteredSpikes;
end
