function DistanceMatrix = Distance(start,stop)

%  USAGE
%
%    DistanceMatrix = Distance(start,stop)
%
%    Calculate the distance between the start point and the stop point for
%    each events.
%   
%    
%    start          Matrix wich contains all the start points
%    stop           Matrix wich contains all the stop points

%
%  OUTPUT
%
%    DistanceMatrix        Matrix which contains the distances

len = size(start);
DistanceMatrix = zeros(len(:,1),1);

%For each lines, we put in DistanceMatrix : stop-start
for event = 1:len(:,1)
    DistanceMatrix(event,1) = stop(event,1)-start(event,1);
    
    
end