function amplitude = MeanAmplitude(DetectedEventsMatrix)
%  USAGE
%
%    amplitude = MeanAmplitude(DetectedEventsMatrix)
%
%    Calculate the mean amplitude of all the events which are in the input
%    matrix
%   
%    
%    DetectedEventsMatrix       Matrix which contains all the detected
%                               events
%    
%
%  OUTPUT
%
%    amplitude                  Value of the mean amplitude (double)
%
%

%Keep the value of the events
data = DetectedEventsMatrix(:,2);

%Calculate the mean of the values
amplitude = mean(data);


end