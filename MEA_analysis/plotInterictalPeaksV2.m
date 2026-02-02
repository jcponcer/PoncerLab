function plotInterictalPeaksV2(Number,IIA_batchResults)

length = size(IIA_batchResults{Number, 1}.OriginalSignal);
threshold = zeros(length(:,1),1);
for point = 1:length(:,1)
   threshold(point,1)=IIA_batchResults{Number, 1}.threshold; 
end

thresholdMatrix = [IIA_batchResults{Number, 1}.OriginalSignal(:,1) threshold];
figure
subplot(3,1,1);
plot(IIA_batchResults{Number, 1}.OriginalSignal(:,1),IIA_batchResults{Number, 1}.OriginalSignal(:,2))
title('Original Signal')
hold on


plot(IIA_batchResults{Number, 1}.OriginalSignal(IIA_batchResults{Number, 1}.finalInterictalSinglePeaks(:,1),1),...
  IIA_batchResults{Number, 1}.OriginalSignal(IIA_batchResults{Number, 1}.finalInterictalSinglePeaks(:,1),2),'*g')
xlim([0 inf]);

% IIA_batchResults{Number, 1}.finalInterictalSinglePeaksA=IIA_batchResults{Number, 1}.finalInterictalSinglePeaks(:,1)-1;
% IIA_batchResults{Number, 1}.finalInterictalSinglePeaks(:,1)=IIA_batchResults{Number, 1}.finalInterictalSinglePeaks(:,1)-999;
% plot(IIA_batchResults{Number, 1}.OriginalSignal(IIA_batchResults{Number, 1}.finalInterictalSinglePeaks(:,1),1),...
%    IIA_batchResults{Number, 1}.OriginalSignal(IIA_batchResults{Number, 1}.finalInterictalSinglePeaksA(:,1),2),'*g')

% plot(IIA_batchResults{1, 1}.OriginalSignal(:,1),IIA_batchResults{1, 1}.normalizedSquaredSignal)
% hold on

subplot(3,1,2);

plot(IIA_batchResults{Number, 1}.filteredInterIctalActivity(:,1),IIA_batchResults{Number, 1}.filteredInterIctalActivity(:,2))
xlim([0 inf]);
title('DenoisedFileteredSignal')
% plot(IIA_batchResults{Number, 1}.OriginalSignal(1:8745,1),xmax,'*r')
% plot(IIA_batchResults{Number, 1}.OriginalSignal(IIA_batchResults{Number, 1}.interictalSinglePeaks(:,1),1),...
%    IIA_batchResults{Number, 1}.OriginalSignal(IIA_batchResults{Number, 1}.interictalSinglePeaks(:,1),2),'*r')
 subplot(3,1,3);
 plot(IIA_batchResults{Number, 1}.OriginalSignal(:,1),IIA_batchResults{Number, 1}.normalizedSquaredSignal(:,1))
 xlim([0 inf]);
 title('NormalizedSquaredSignal')
 hold on
 plot(thresholdMatrix(:,1),thresholdMatrix(:,2))
 
 
 
 