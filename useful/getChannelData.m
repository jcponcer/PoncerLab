function ChannelData = getChannelData(filename, channel) 

k = 0 ; 
check = 0 ; 
while check == 0  
    if k < 100 
        try 
            data = h5read(filename, '/Data/Recording_0/AnalogStream/Stream_' + string(k) +'/ChannelData') ; 
            check = 1 ;
        catch 
            k = k + 1 ;
        end
    else 
        check = 1 ;
    end
end

channels = h5read(filename, '/Data/Recording_0/AnalogStream/Stream_' + string(k) +'/InfoChannel/').Label ; 
index_channel = strcmp(channels,channel); 
time = 1:length(data) ; 
ChannelData = [time(:), data(:,index_channel)] ;
ChannelData = double(ChannelData) ; 
