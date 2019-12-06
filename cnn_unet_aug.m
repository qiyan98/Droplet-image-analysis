clear;
close all;
rng('shuffle');

imageSize = [480 640 1];
numClasses = 3;

% Create unet network
% lgraph = helperDeeplabv3PlusResnet18(imageSize, numClasses);
unet_layers = unetLayers(imageSize,numClasses,'EncoderDepth',2);

gTruth = load('dataset_gTruth.mat');
gTruth = gTruth.gTruth;
num_sample = height(gTruth.LabelData);

% construct the collective gTruth dataset with data augmentation
gTruth_imds = imageDatastore(gTruth.DataSource.Source);
gTruth_pxds = pixelLabelDatastore(gTruth);
augmenter = imageDataAugmenter('RandXReflection',true,'RandYReflection',true,...
    'RandScale',[1 1],'RandRotation',[-45 45],'RandXTranslation',[0 0],'RandYTranslation',[0 0]);

% % no data augmentation
% augmenter = imageDataAugmenter();

gTruthData = pixelLabelImageDatastore(gTruth_imds,gTruth_pxds,'dataaugmentation',augmenter);

% partition the gTruth data to get trainingData
num_sample_training = floor(0.8*num_sample);
idx_training = randperm(num_sample_training);
trainingData = partitionByIndex(gTruthData,idx_training);

% partition the gTruth data to get validationData
idx_validation = randperm(num_sample - num_sample_training) + num_sample_training;
validationData = partitionByIndex(gTruthData,idx_validation);

% class weighting
tbl = countEachLabel(gTruthData);
totalNumberOfPixels = sum(tbl.PixelCount);
frequency = tbl.PixelCount / totalNumberOfPixels;
classWeights = 1./frequency;
layer_end = pixelClassificationLayer('Name','labels','Classes',tbl.Name,'ClassWeights',classWeights);
unet_layers = removeLayers(unet_layers,'Segmentation-Layer');
unet_layers = addLayers(unet_layers,layer_end);
unet_layers = connectLayers(unet_layers,'Softmax-Layer','labels');

% set training options
opts = trainingOptions('adam', ...
    'InitialLearnRate',0.003, ...
    'LearnRateSchedule','piecewise',...
    'LearnRateDropPeriod',5,...
    'LearnRateDropFactor',0.9,...
    'MiniBatchSize',4,...
    'MaxEpochs',50, ...
    'Plots','training-progress',...
    'ValidationData',validationData,...
    'ValidationFrequency',50);

% train and save the current network
net = trainNetwork(trainingData,unet_layers,opts);
cur_timestr = datestr(now,'mmm_dd_HH_MM');
save_str = ['cnn_unet_aug_',cur_timestr,'.mat'];
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
% plot(s.Centroid,'r*');
