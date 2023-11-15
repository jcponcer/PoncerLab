function [interictalPeaks,normalizedSquaredSignal,start,stop] = interictalDetection(OriginalSignal,filteredInterIctalActivity,threshold)

%  USAGE
%
%    [interictalPeaks,normalizedSquaredSignal,start,stop] = interictalDetection(OriginalSignal,filteredInterIctalActivity,threshold)
%
%    Detect the interictal peaks due to a threshold and a duration control.
%    The threshold is applied on the normalized and squared signal.
%   
%    
%    OriginalSignal                  Original signal (matrix)
%    filteredInterIctalActivity      Filtered signal (matrix)
%    threshold                       Positive integer - the events above the threshold can
%                                    be interictal events
%
%  OUTPUT
%
%    interictalPeaks                 Matrix which contains the detected IIA peaks
%    normalizedSquaredSignal         Normalized and squared signal (matrix)
%    start                           Matrix which contains the start point
%                                    of each events
%    stop                            Matrix which contains the stop point
%                                    of each events

%Take the square of the signal
squaredSignal = filteredInterIctalActivity(:,2) .* filteredInterIctalActivity(:,2);

%Normalize the signal
%[normalizedSquaredSignal,stdSquaredSignal] = unity(squaredSignal,[],[]);
normalizedSquaredSignal = squaredSignal+abs(min(squaredSignal));

%Put the threshold to keep just events which are above it
thresholded = normalizedSquaredSignal > threshold;
%thresholded = squaredSignal > threshold;
start = find(diff(thresholded)>0);
stop = find(diff(thresholded)<0);

%Calculate the duration of each events
distanceMatrix = Distance(start,stop);

%Determine the peak of each events
highestPointMatrix = HighestPeak(start,stop,OriginalSignal);
length = size(distanceMatrix);
interictalPeaks = zeros(length(:,1),4);
interictalEventNumber = 1;

%Save the events which have a duration between 20 and 250 ms in the result
%matrix
for event = 1:length(:,1)
   if distanceMatrix(event,1)>=200 && distanceMatrix(event,1)<=2500
       interictalPeaks(interictalEventNumber,1) = highestPointMatrix(event,1);
       interictalPeaks(interictalEventNumber,2) = highestPointMatrix(event,2);
       interictalPeaks(interictalEventNumber,3) = highestPointMatrix(event,3);
       interictalPeaks(interictalEventNumber,4) = highestPointMatrix(event,4);
       interictalEventNumber = interictalEventNumber + 1;
   
  
   end

end
%Remove the useless zeros
interictalPeaks(~any(interictalPeaks'),:) = [];
end