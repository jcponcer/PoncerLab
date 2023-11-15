function [interictalSinglePeaks,positiveEvent,negativeEvent]=EventsGrouping(interictalPeaks)

%  USAGE
%
%    [interictalSinglePeaks,positiveEvent,negativeEvent]=EventsGrouping(interictalPeaks)
%
%    Groups events that belong to the same activity. if there are several detected 
%    events for the same activity, we just keep the peak. The interval between
%    two events is at least 250 ms.
%   
%    
%    interictalPeaks       Matrix which contains all the detected events
%
%  OUTPUT
%
%    interictalSinglePeaks        Matrix which contains just one peak for
%                                 each activities
%    positiveEvent                Number of positive events in the signal
%                                 (int)
%    negativeEvent                Number of negative events in the signal
%                                 (int)


%Define the minimum interval between two activities
betweenInterictalEventDuration = 2500;

%Initializations
interictalSinglePeaksNumber = 1;
row = 1;
length = size(interictalPeaks,1);
interictalSinglePeaks = zeros(length,4);
interictalSinglePeaks(1,1) = interictalPeaks(1,1);
interictalSinglePeaks(1,2) = interictalPeaks(1,2);
interictalSinglePeaks(1,3) = interictalPeaks(1,3);
interictalSinglePeaks(1,4) = interictalPeaks(1,4)+betweenInterictalEventDuration;
positiveEvent = 0;
negativeEvent = 0;

while row <= length
    if row ~= length
        %If two events have less than 250ms between them, we consider that
        %there are on the same interictal activity. We keep the event who
        %has the higher absolute value.
        if (interictalPeaks(row,1)+betweenInterictalEventDuration) >= interictalPeaks(row+1,1)
            if  abs(interictalSinglePeaks(interictalSinglePeaksNumber,2)) <= abs(interictalPeaks(row+1,2))
                interictalSinglePeaks(interictalSinglePeaksNumber,1) = interictalPeaks(row+1,1);
                interictalSinglePeaks(interictalSinglePeaksNumber,2) = interictalPeaks(row+1,2);



            end
        %If two events have more than 250ms between them, we consider that
        %there are two different interictal activities. We also count the
        %number of positives and negatives activities.
        else
            if (interictalSinglePeaks(interictalSinglePeaksNumber,2))>=0
                positiveEvent = positiveEvent +1;
            else
                negativeEvent = negativeEvent + 1;
            end
            interictalSinglePeaks(interictalSinglePeaksNumber,4) = interictalPeaks(row,4)+betweenInterictalEventDuration;
            
            interictalSinglePeaksNumber = interictalSinglePeaksNumber + 1; 
            interictalSinglePeaks(interictalSinglePeaksNumber,1) = interictalPeaks(row+1,1);
            interictalSinglePeaks(interictalSinglePeaksNumber,2) = interictalPeaks(row+1,2);
            interictalSinglePeaks(interictalSinglePeaksNumber,3) = interictalPeaks(row+1,3);


        end
    
    
    else
        if (interictalSinglePeaks(interictalSinglePeaksNumber,2))>=0
            positiveEvent = positiveEvent +1;
        else
        	negativeEvent = negativeEvent + 1;
        end
        interictalSinglePeaks(interictalSinglePeaksNumber,4) = interictalPeaks(row,4)+betweenInterictalEventDuration;
    end
    row = row+1;
    
end
end