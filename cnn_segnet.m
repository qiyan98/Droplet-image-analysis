clear;
close all;

inputSize = [480 640 1];
numClasses = 3;

gTruth = load('dataset_gTruth.mat');
gTruth = gTruth.gTruth;
val_ds = load('dataset_validation.mat');
val_ds = val_ds.gTruth;

segnet_layers = segnetLayers(inputSize,numClasses,2);

trainingData = pixelLabelImageDatastore(gTruth);
validationData = pixelLabelImageDatastore(val_ds);
num_sample = height(gTruth.LabelData);
opts = trainingOptions('sgdm', ...
    'InitialLearnRate',0.03, ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',4,...
    'LearnRateDropFactor',0.9,...
    'MiniBatchSize',4,...
    'MaxEpochs',150, ...
    'Plots','training-progress',...
    'ValidationData',validationData,...
    'ValidationFrequency',4);

tbl = countEachLabel(trainingData);
totalNumberOfPixels = sum(tbl.PixelCount);
frequency = tbl.PixelCount / totalNumberOfPixels;
classWeights = 1./frequency;
layer_end = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
segnet_layers = removeLayers(segnet_layers,'pixelLabels');
segnet_layers = addLayers(segnet_layers,layer_end);
segnet_layers = connectLayers(segnet_layers,'softmax','labels');

net = trainNetwork(trainingData,segnet_layers,opts);
cur_timestr = datestr(now,'mmm_dd_HH_MM');
save_str = ['cnn_unet_',cur_timestr,'.mat'];
save(save_str);
%%
% close all;
testImage = imread('imageTest00.bmp');
[C,scores] = semanticseg(testImage,net,'outputtype','double');
for i=1:numel(C)
    if C(i) == 3 || C(i) == 2
        C(i) = 0;
    end
    if C(i) == 1
        C(i) = 255;
    end
end
% B = labeloverlay(testImage,C);
B = uint8(C);
B = imbinarize(B);

figure;
subplot(2,2,1);
imshow(testImage);
title('#1, Original image');
subplot(2,2,2);
imshow(B)
title('#2, Segmeented by CNN');


% figure;
E = B;
% E2 = imfill(E,4,'holes');
E2 = bwmorph(E,'bridge',10);
% E2 = bwmorph(E2,'open',inf);
% E2 = bwmorph(E2,'thicken');
% E2 = medfilt2(E2);
% se = strel('disk',5);
% E2 = imdilate(E2,se);
% E2 = imdilate(E,se);
% E2 = imdilate(E,se);
% E2 = imdilate(E,se);
% E2 = imdilate(E,se);
% E = imclearborder(E,4);
subplot(2,2,3);
imshow(E2);
title('#3, After simple processing');

F = edge(E2,'Canny',0.01);
% se90 = strel('line', 10, 90);
% se0 = strel('line', 10, 0);
% F = imdilate(F,[se90 se0]);
F = imfill(F,'holes');
% F = imclearborder(F,4);
% seD = strel('diamond',1);
% E = imerode(E,seD);
subplot(2,2,4);
imshow(F);
title('#4, Direct image processing from #1');
%%
figure;
imshow(E2);
hold on;
s = regionprops(E2,'all');
% plot(s.Centroid(:,1), s.Centroid(:,2), 'b*');
plot(s.Centroid,'r*');
