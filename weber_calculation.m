%% Initialization
tic;
clear;
close all;

% load trained CNN network
% load('.\output\trained_model_exp3_MAX\cnn_unet_aug_adam_0.0005+4+100+depth3.mat');
load('.\output\trained_model_exp3_MAX\NoAug_DepthCmp\cnn_unet_NoAug_0.0005_5_0.9+4+30+depth4.mat');
clearvars -except net;

% load pretrained image denoise CNN network
net_denoise = denoisingNetwork('DnCNN');

% load Excel table
data_table = readtable('Table_of_Uncertainty.xlsx');
data_mat_backup = table2array(data_table(:,2:end));
% data_mat_old = [data_mat_backup(:,1:10) data_mat_backup(:,end)];
data_mat_old = data_mat_backup;
data_source = table2array(data_table(:,1));
[name_source,init_idx_source,cate_idx_source] = unique(data_source);

data_weber_true = cell(length(name_source),1);
data_mat = [];
%% Loop over different sources
for i_source = 1:length(name_source)
% for i_source = 1
    % load the original iamges of current data source
    cur_source = name_source{i_source};
    tmp = strcat('.\imageData_uncertainty\',cur_source);
    imds = imageDatastore(tmp);
    pixel_calib = data_mat_old(init_idx_source(i_source),end);
    
    %%
    pic_num = length(imds.Files);
    area_vec = zeros(3,1); diameter_vec = zeros(3,1);
    metric_vec = zeros(3,1); upper_edge_vec = zeros(3,1);

    % structure to store true Weber numbers
    cur_source_len = sum(cate_idx_source == i_source);
    curT_true = data_mat_old(init_idx_source(i_source):init_idx_source(i_source) + cur_source_len - 1,2);
    curWeber_true = data_mat_old(init_idx_source(i_source):init_idx_source(i_source) + cur_source_len - 1,11);
    curPixel_calib = data_mat_old(init_idx_source(i_source):init_idx_source(i_source) + cur_source_len - 1,13);
    curD_true = data_mat_old(init_idx_source(i_source):init_idx_source(i_source) + cur_source_len - 1,5);
    curPos_true = data_mat_old(init_idx_source(i_source):init_idx_source(i_source) + cur_source_len - 1,7);
    data_weber_true{i_source} = [curT_true curWeber_true curPixel_calib curD_true curPos_true];
    clear curT_true curWeber_true curPixel_calib curD_true curPos_true;
    
%     cur_source_len = pic_num;
    ii_pic = 0;
    cur_source_len = 3;
    for i_pic = 1:cur_source_len
        
        ii_pic = ii_pic + 1;
        % show current process
        disp(['# Source: ',num2str(i_source),'/',num2str(length(name_source)),' , ',num2str(ii_pic), ' out of ',num2str(pic_num),' ...']);
        
        % read current image
        curImage = imread(imds.Files{i_pic});
        
        % denoise using pretrained CNN
        curImage = denoiseImage(curImage,net_denoise);
        
        %     figure; set(gcf,'color','w');
        %     subplot(2,1,1); imshow(curImage_backup);
        %     subplot(2,1,2); imshow(curImage);
        
        % do semantic segementation and extract the foreground object
        [segImage,~] = semanticseg(curImage,net,'outputtype','double');
        [catImage,~] = semanticseg(curImage,net);
        catImage = labeloverlay(curImage,catImage);
        
        % show current image
        %     figure; imshow(curImage);
        %     set(gcf,'color','w');
        %     title('Pic ID = ',num2str(i_pic),'fontsize',14);
        
        % do post-processing
        for i=1:numel(segImage)
            if segImage(i) == 3 || segImage(i) == 2
                segImage(i) = 0;
            end
            if segImage(i) == 1
                segImage(i) = 255;
            end
        end
        pp1Image = imbinarize(segImage);
        pp2Image = bwareaopen(pp1Image,2000);
        pp2Image = imfill(pp2Image,'holes');
        
        [cur_B,cur_L] = bwboundaries(pp2Image,'noholes');
        cur_stats = regionprops(cur_L,'Area','Centroid');
        pp3Image = cur_L;
        
        % show the boundaries of objects in current image
        %     figure;
        %     imshow(label2rgb(cur_L,@jet,[.5 .5 .5]));
        %     hold on;
        %     for k = 1:length(cur_B)
        %         boundary = cur_B{k};
        %         plot(boundary(:,2),boundary(:,1),'w','LineWidth',2);
        %         plot(cur_stats(k).Centroid(1),cur_stats(k).Centroid(2),'.r','markersize',12);
        %     end
        
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
        
        % only keep the most circular object
        metrix_max = max(cur_metric(:));
        for k = 1:length(cur_B)
            if cur_metric(k) < metrix_max
                pp3Image(cur_L==k) = 0;
            end
        end
        if isempty(cur_B)
            metrix_max = 0;
        end
        
        % show the most circular object kept in current image
        [cur_B_new,cur_L_new] = bwboundaries(pp3Image,'noholes');
        cur_stats_new = regionprops(cur_L_new,'Area','Centroid');
        
        %%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% save for gif %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%
        
        cur_fig = tightPlots(1,1,6.5,[640 480],[0.1 0.1],[0.1 0.1],[0.1 0.1],'inch');
        set(gcf,'visible','off','color','w');
        imshow(label2rgb(cur_L_new,@white,[.0 .0 .0]));
%         imshow(catImage);
        hold on;
        for k = 1:length(cur_B_new)
            boundary = cur_B_new{k};
%             plot(boundary(:,2),boundary(:,1),'r','LineWidth',2);
%             plot(cur_stats_new(k).Centroid(1),cur_stats_new(k).Centroid(2),'.r','markersize',12);
        end
%         text(0.63,0.9,['X = ',num2str(round(cur_stats_new.Centroid(1),1))],'units','normalized','fontsize',20,'color','red');
%         text(0.63,0.8,['Y = ',num2str(round(cur_stats_new.Centroid(2),1))],'units','normalized','fontsize',20,'color','red');
        
        area_vec(i_pic) = sum(pp3Image(:))/max(pp3Image(:));
        diameter_vec(i_pic) = sqrt(4*area_vec(i_pic)/pi);
        metric_vec(i_pic,:) = metrix_max;
%         text(0.63,0.7,['d = ',num2str(round(diameter_vec(i_pic),1))],'units','normalized','fontsize',20,'color','red');
        
        % detect the upper edge
        if k > 1 % if there is more than one circle
            disp('Bad thing happens!!! More than one circle has been found!!!');
        else % if there is a sole circle
            num_pixel = sum(sum(cur_L_new == 1));
            thold_pixel = 5;
            line_upper = min(boundary(:,1));
            line_lower = max(boundary(:,1));
            is_finished = 0;
            for ii = line_upper:line_lower
                cur_line = cur_L_new(ii,:);
                if is_finished
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
            upper_edge_vec(i_pic) = cur_upper_edge;
        end
%         text(0.63,0.8,['Pos. = ',num2str(round(upper_edge_vec(i_pic),1))],'units','normalized','fontsize',20,'color','red');
        str_fig = ['.\output\Weber_calculation\','source',num2str(i_source),'_',num2str(i_pic),'.png'];
        saveas(gcf,str_fig);
        close(gcf);
        %%%%%%%%%%%%%%%%%%%%%%%%
        %%%%% save for gif %%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%
        
        %     figure;
        %     set(gcf,'color','w');
        %     subplot(3,1,1);
        %     imshow(curImage);
        %     subplot(3,1,2);
        %     imshow(catImage);
        %     subplot(3,1,3);
        %     imshow(pp3Image);
        
        i_pic;
        
    end
    %%
    % figure;
    % set(gcf,'color','w');
    % subplot(2,1,1); imshow(curImage); title('Original image','fontsize',20);
    % subplot(2,1,2); imshow(catImage); title('Segmented image','fontsize',20);
    
    area_backup = area_vec;
    diameter_backup = diameter_vec;
    upper_edge_backup = upper_edge_vec;
    
    area_vec(area_vec == 0) = [];
    diameter_vec(diameter_vec == 0) = [];
    upper_edge_vec(upper_edge_vec == 0) = [];
    
%     area_vec = pixel_calib^2*area_vec;
%     diameter_vec = pixel_calib*diameter_vec;
%     upper_edge_vec = pixel_calib*upper_edge_vec;
    
    %%
    % data_mat has 8 columns
    data_mat_add = zeros(5,8);
    data_mat_add(1:cur_source_len,1) = ones(cur_source_len,1)*i_source; % source
    data_mat_add(1:cur_source_len,2) = (1:cur_source_len)'; % image id
    data_mat_add(1:cur_source_len,3) = (1:cur_source_len)'*1/20; % time
    data_mat_add(1:cur_source_len,4) = area_vec; % estimated area
    data_mat_add(1:cur_source_len,5) = diameter_vec; % estimated diameter
    data_mat_add(1:cur_source_len,6) = upper_edge_vec; % estimated position
    data_mat_add(1:cur_source_len,7) = metric_vec; % roundness info.
    data_mat_add(1:cur_source_len,8) = ones(cur_source_len,1)*pixel_calib; % pixel calibration info.
    
    data_mat = [data_mat;data_mat_add];
%     save(save_str);
end
data_weber_est = data_mat;
save_str = '.\output\Weber_calculation\data_weber_est.mat';
save(save_str,'data_weber_est');
save_str = '.\output\Weber_calculation\data_weber_true.mat';
save(save_str,'data_weber_true');
toc;