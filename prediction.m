tic;
clear;
close all;

% unet
% load('.\output\trained_model_exp3_MAX\NoAug_DepthCmp\cnn_unet_NoAug_0.001_5_0.9+4+50+depth3.mat');
% load('.\output\trained_model_exp3_MAX\NoAug_DepthCmp\cnn_unet_NoAug_0.0005_5_0.9+4+30+depth4.mat');

% segnet
% depth = 2 leads to bette result!
load('.\output\trained_model_exp3_MAX\SegNet_NoAug_DepthCmp\cnn_segnet_NoAug_0.05_5_9+4+50+depth2.mat');
% load('.\output\trained_model_exp3_MAX\SegNet_NoAug_DepthCmp\cnn_segnet_NoAug_0.01_5_9+4+50+depth3.mat');
% load('.\output\trained_model_exp3_MAX\SegNet_NoAug_DepthCmp\cnn_segnet_NoAug_0.005_5_9+4+50+depth4.mat');

% load('cnn_segnet_Jun_04_08_54.mat');

% imds = imageDatastore('.\imageData_postImpact\');
% imds = imageDatastore('.\imageData_weber');
imds = imageDatastore('.\imageData_slope');
pic_num = length(imds.Files);

if exist('.\output\postImpact','dir')
    rmdir('.\output\postImpact','s');
end
mkdir('.\output\postImpact');

area_vec = zeros(3,1); diameter_vec = zeros(3,1); center_mat = zeros(3,2);
metric_vec = zeros(3,1); upper_edge_vec = zeros(3,1);

for i_pic=1:pic_num
    % show current process
    disp([num2str(i_pic), ' out of ',num2str(pic_num),' ...']);
    
    curImage_backup = imread(imds.Files{i_pic});
    curImage = curImage_backup + 50;
    curImage = imadjust(curImage,[0.3 1],[]);
%     curImage = curImage_backup;
    
    % do semantic segementation and extract the foreground object
    [segImage,~] = semanticseg(curImage,net,'outputtype','double');
    for i=1:numel(segImage)
        if segImage(i) == 3 || segImage(i) == 2
            segImage(i) = 0;
        end
        if segImage(i) == 1
            segImage(i) = 255;
        end
    end
    
    pp1Image = imbinarize(segImage);
    pp2Image = bwareaopen(pp1Image,10000);
    pp2Image = imfill(pp2Image,'holes');
    
    [cur_B,cur_L] = bwboundaries(pp2Image,'noholes');
    cur_stats = regionprops(cur_L,'Area','Centroid');
    pp3Image = cur_L;
    
    % loop over the boundaries
    cur_area = zeros(1,length(cur_B));
    cur_metric = cur_area;
    for k = 1:length(cur_B)
        % obtain (X,Y) boundary coordinates corresponding to label 'k'
        boundary = cur_B{k};
        
        % compute a simple estimate of the object's perimeter
        delta_sq = diff(boundary).^2;
        perimeter = sum(sqrt(sum(delta_sq,2)));
        
        % obtain the area calculation corresponding to label 'k'
        cur_area(k) = cur_stats(k).Area;
        
        % compute the roundness metric
        cur_metric(k) = 4*pi*cur_area(k)/perimeter^2;
    end
    
    % only keep the largest object
    pp3Image_new = pp3Image;
    
    size_max = max(cur_area(:));
    metrix_max = max(cur_metric(:));
    for k = 1:length(cur_B)
%         if cur_area(k) < size_max
        if cur_metric(k) < metrix_max
            pp3Image_new(cur_L==k) = 0;
        end
    end
    
    % show the largest object kept in current image
    [cur_B_new,cur_L_new] = bwboundaries(pp3Image_new,'noholes');
    catImage = labeloverlay(curImage_backup,pp3Image_new);

%     [cur_B_new,cur_L_new] = bwboundaries(pp3Image,'noholes');
%     catImage = labeloverlay(curImage_backup,pp3Image);
    
    %     for k = 1:length(cur_B)
    %         if cur_metric(k) < metrix_max
    %             pp3Image(cur_L==k) = 0;
    %         end
    %     end
    
    figure;
    cur_fig = tightPlots(1,1,6.5,[640 480],[0.1 0.1],[0.1 0.1],[0.1 0.1],'inch');
%     set(gcf,'visible','off','color','w');
    
%     axes(cur_fig(1));
%     set(gcf,'visible','off');
%     imshow(curImage_backup);
    
    axes(cur_fig(1));
%     set(gcf,'visible','off');
%     catImage = labeloverlay(curImage_backup,segImage);
    imshow(catImage); hold on;
    for k = 1:length(cur_B_new)
        boundary = cur_B_new{k};
        plot(boundary(:,2),boundary(:,1),'k','LineWidth',3);
    end
    
%     axes(cur_fig(3));
%     set(gcf,'visible','off');
%     imshow(label2rgb(cur_L_new,[0 255 255]/255,[0.9 0.9 0.9]));
%     hold on;
%     for k = 1:length(cur_B_new)
%         boundary = cur_B_new{k};
%         plot(boundary(:,2),boundary(:,1),'k','LineWidth',2);
%         %         plot(cur_stats_new(k).Centroid(1),cur_stats_new(k).Centroid(2),'.r','markersize',12);
%     end
    
    %%%%% detect the upper edge %%%%%
    if length(cur_B_new) > 1 % if there is more than one circle
        disp('Bad thing happens!!! More than one circle has been found!!!');
    else % if there is a sole circle
        num_pixel = sum(sum(cur_L_new == 1));
        thold_pixel = 5;
        boundary = cur_B_new{1};
        line_upper = min(boundary(:,1));
        line_lower = max(boundary(:,1));
        is_finished = 0;
        % loop over each line
        for ii = line_upper:line_lower
            cur_line = cur_L_new(ii,:);
            if is_finished == 1
                break;
            end
            for jj = 1:640-thold_pixel
                is_ok = 1;
                for kk = 0:thold_pixel
                    if cur_line(jj+kk) == 0
                        is_ok = 0;
                    end
                end
                if is_ok % if there is consective thold_pixel pixels being one in this line
                    cur_upper_edge = ii;
                    is_finished = 1;
                    break;
                end
            end
        end
        if is_finished == 0
            cur_upper_edge = -1;
        end
        upper_edge_vec(i_pic) = cur_upper_edge;
    end
    if i_pic == 100
        disp('good');
    end
    %%%%% detect the upper edge %%%%%
    area_vec(i_pic) = sum(pp3Image(:))/max(pp3Image(:));
    diameter_vec(i_pic) = sqrt(4*area_vec(i_pic)/pi);
    
%     text(0.58,0.8,['Pos.=',num2str(round(upper_edge_vec(i_pic),1))],'units','normalized','fontsize',14);
    area_vec(i_pic) = sum(pp3Image(:))/max(pp3Image(:));
    diameter_vec(i_pic) = sqrt(4*area_vec(i_pic)/pi);
%     text(0.58,0.7,['d=',num2str(round(diameter_vec(i_pic),1))],'units','normalized','fontsize',14);
    str_fig = ['.\output\Weber_calculation\',num2str(i_pic),'.png'];
    
    img_name = ['.\output\postImpact\',num2str(i_pic),'.png'];
    saveas(gcf,img_name);
    close(gcf);
end

toc;