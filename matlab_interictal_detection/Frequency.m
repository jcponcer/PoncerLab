function frequencyValue = Frequency(OriginalSignal,EventMatrix)

%  USAGE
%
%    frequencyValue = Frequency(denoisedMatrix,event)
%
%    Calculate the frequency of the events in a signal.
%   
%    
%    OriginalSignal       Original signal (matrix)
%    EventMatrix          Contains all the detected events (matrix)
%
%  OUTPUT
%
%    frequencyValue       Value of the frequency (double)
%



length = size(OriginalSignal);
eventNumber = size(EventMatrix);
frequencyValue = eventNumber(:,1) / (length(:,1)/10000);



end
