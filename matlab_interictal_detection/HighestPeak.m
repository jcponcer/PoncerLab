function highestPointMatrix =  HighestPeak(start,stop,OriginalSignal)

%  USAGE
%
%    highestPointMatrix =  HighestPeakV3(start,stop,OriginalSignal)
%
%    Find the maximum and minimum value between a start point and a stop
%    point. Keep the time and value of the higher point between the absolute value
%    of the maximum and the absolute value of the minimum.
%   
%    
%    start              Matrix which contains all the start points
%    stop               Matrix which contains all the stop points
%    OriginalSignal     Original signal (matrix)
%
%  OUTPUT
%
%    highestPointMatrix        Matrix which contains all the peaks
%                           

%Initializations
length = size(start);
highestPointMatrix = zeros(length(:,1),4);

for event = 1:length
   
   %Find the minimum and the maximum of each events
   startEvent = start(event,1)+1;
   stopEvent = stop(event,1);
   RestrictedSignal = OriginalSignal(startEvent:stopEvent,:);
   [xymax,smax] = max(RestrictedSignal(:,2));
   [xymin,smin] = min(RestrictedSignal(:,2));
   
   %Keep the peak by comparing the absolute values of the minimum and maximum 
   if abs(xymax(1,1))>abs(xymin(1,1))
        extremaTime = int32(RestrictedSignal(smax(1,1),1)*10000+1);
        extremaValue = xymax(1,1);
        
        
   else
        extremaTime = int32(RestrictedSignal(smin(1,1),1)*10000+1);
        extremaValue = xymin(1,1);
   end    
   
   %Fill the output matrix with the time of the peak, the value, the start
   %point and the stop point
   highestPointMatrix(event,1)= extremaTime;
   highestPointMatrix(event,2)= extremaValue;
   highestPointMatrix(event,3)= startEvent;
   highestPointMatrix(event,4)= stopEvent;

    
end

end