function finalInterictalSinglePeaks = removePositiveNegative(interictalSinglePeaks,positiveEvent,negativeEvent)

%  USAGE
%
%    finalInterictalSinglePeaks = removePositiveNegative(interictalSinglePeaks,positiveEvent,negativeEvent)
%
%    Remove the positives events if there are more negatives events than
%    positives event and reciprocally.
%   
%    
%    interictalSinglePeaks       Matrix which contains all the detected
%                                events
%    positiveEvent               Number of positives events detected
%    negativeEvent               Number of negatives events detected
%   
%
%  OUTPUT
%
%    finalInterictalSinglePeaks        Matrix which contains the events
%                                      whithout the positives or negatives
%                                      events
%

%Determine if there are more positives events than negatives events or not.
if negativeEvent >= positiveEvent
   length = negativeEvent;
   isNegative = 1;
else
   length = positiveEvent;
   isNegative = 0;
end
finalInterictalSinglePeaks = zeros(length,4);
count = 1;
for event = 1:size(interictalSinglePeaks,1)
    %If there are more negatives events, copy the negatives events to a new
    %matrix
    if isNegative == 1
       if  interictalSinglePeaks(event,2)<0
           finalInterictalSinglePeaks(count,1) = interictalSinglePeaks(event,1);
           finalInterictalSinglePeaks(count,2) = interictalSinglePeaks(event,2);
           finalInterictalSinglePeaks(count,3) = interictalSinglePeaks(event,3);
           finalInterictalSinglePeaks(count,4) = interictalSinglePeaks(event,4);
           count = count + 1;
       end
    %If there are more positives events, copy the positives events to a new
    %matrix   
    else
       if  interictalSinglePeaks(event,2)>0
           finalInterictalSinglePeaks(count,1) = interictalSinglePeaks(event,1);
           finalInterictalSinglePeaks(count,2) = interictalSinglePeaks(event,2);
           finalInterictalSinglePeaks(count,3) = interictalSinglePeaks(event,3);
           finalInterictalSinglePeaks(count,4) = interictalSinglePeaks(event,4);
           count = count + 1;
       end
    end
end    
end