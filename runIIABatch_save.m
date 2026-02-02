%Run the IIA batch and save the result.

%clear
%Select the analysis main function 
mfile='W:\Analysis\MEA\MEA_Toolbox\Batch_InterictalDetection.m';
%Select the batch file
bfile='W:\Analysis\MEA\2022-11-22\IIA_spikes_detection\Slice2\IIABatch16h59.bat';
%Run the analysis for all the lines in the batch file
batch = StartBatch(mfile,bfile);
%Save the result in a destination folder
IIA_batchResultsTest = batch.UserData;
save('W:\Analysis\MEA\2022-11-22\IIA_spikes_detection\Slice2\IIA_detection_16h59.mat','IIA_batchResultsTest','-v7.3');
%clearvars batch IIA_batchResultsTest;