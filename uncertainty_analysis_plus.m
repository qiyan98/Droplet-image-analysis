clear;
close all;

load '.\output\Uncertainty_analysis\data_uncertainty.mat';
data_backup = data_mat;
data_mat = data_mat(:,3:13);
num_pts = size(data_mat,1);
% true area - estimated area - true diameter - estimated diameter - true edge - estimated edge

num_error = 0;
for i = 1:num_pts
    % diameter estimation error check
    if data_mat(i,4) < 0.5*data_mat(i,3) || data_mat(i,4) > 1.5*data_mat(i,3)
%         data_mat(i,:) = zeros(1,11);
        num_error = num_error + 1;
    end
    
    % edge estimation error check
    if data_mat(i,6) < 0.5*data_mat(i,5) || data_mat(i,6) > 1.5*data_mat(i,5)
%         data_mat(i,:) = zeros(1,11);
        num_error = num_error + 1;
    end
end

% data_mat(data_mat == 0) = [];
% data_len = length(data_mat)/11;
% data_mat = reshape(data_mat,data_len,11);

data_len = length(data_mat);

error_mat = zeros(data_len,5);
for i = 1:data_len
    cur_pixel_calib = data_mat(i,end);
    % relative error
%     error_mat(i,1) = (data_mat(i,2) - data_mat(i,1)); % area error (pixel^2)
%     error_mat(i,2) = (data_mat(i,4) - data_mat(i,3)); % diameter error (pixel)
%     error_mat(i,3) = (data_mat(i,6) - data_mat(i,5)); % edge position error (pixel)
%     error_mat(i,4) = (data_mat(i,8) - data_mat(i,7))/data_mat(i,7)*100; % velocity error
%     error_mat(i,5) = (data_mat(i,10) - data_mat(i,9))/data_mat(i,9)*100; % weber error
    
    % absolute error
    error_mat(i,1) = (data_mat(i,2) - data_mat(i,1))*(cur_pixel_calib*1e-3)^2; % area error (mm^2)
    error_mat(i,2) = (data_mat(i,4) - data_mat(i,3))*cur_pixel_calib*1e-3; % diameter error (mm)
    error_mat(i,3) = (data_mat(i,6) - data_mat(i,5))*cur_pixel_calib*1e-3; % edge position error (mm)
%     error_mat(i,4) = (data_mat(i,8) - data_mat(i,7))/data_mat(i,7)*100; % velocity error
%     error_mat(i,5) = (data_mat(i,10) - data_mat(i,9))/data_mat(i,9)*100; % weber error
end

error_mat(202,:) = [];
error_area = error_mat(:,1);
error_diameter = error_mat(:,2);
error_edge = error_mat(:,3);

% std_area = sqrt(error_area'*error_area/(data_len-1));
% u_area = std_area/data_len;
% std_diameter = sqrt(error_diameter'*error_diameter/(data_len-1));
% u_diameter = std_diameter/data_len;
% std_edge = sqrt(error_edge'*error_edge/(data_len-1));
% u_edge = std_edge/data_len;

%%
% figure; histfit(error_mat(:,1)); xlabel('Area error /mm^2');
% pd = fitdist(error_mat(:,1),'normal');
%%
figure; 
cur_fig = tightPlots(1,1,6.85*0.8,[5 4],[0.1 0.1],[0.8 0.1],[0.8 0.1],'inch');
histfit(error_mat(:,2));
set(gca,'fontsize',18);
xlabel('直径检测偏差 (mm)','fontsize',20);
ylabel('样本数目','fontsize',20);
% xlabel('Diameter estimation error (mm)');
pd_diameter = fitdist(error_mat(:,2),'normal'); set(gcf,'color','w');
% text(0.7,0.6,['sigma = ',num2str(round(pd_diameter.sigma,4)),' mm'],'units','normalized','fontsize',14);
text(0.48,0.86,['拟合分布均值: ',num2str(round(pd_diameter.mean,2)),'mm'],'units','normalized','fontsize',14);
text(0.48,0.8,['拟合分布标准差: ',num2str(round(pd_diameter.sigma,2)),'mm'],'units','normalized','fontsize',14);
%%
figure; 
cur_fig = tightPlots(1,1,6.85*0.8,[5 4],[0.1 0.1],[0.8 0.1],[0.8 0.1],'inch');
histfit(error_mat(:,3)); 
set(gca,'fontsize',16);
xlabel('位置检测偏差 (mm)','fontsize',20);
% xlabel('Upper edge estimation error (mm)');
ylabel('样本数目','fontsize',20);
pd_edge = fitdist(error_mat(:,3),'normal'); set(gcf,'color','w');
% text(0.7,0.6,['sigma = ',num2str(round(pd_edge.sigma,4)),' mm'],'units','normalized','fontsize',14);
text(0.49,0.71,['拟合分布均值：',num2str(round(pd_edge.mean,2)),' mm'],'units','normalized','fontsize',14);
text(0.49,0.65,['拟合分布标准差：',num2str(round(pd_edge.sigma,2)),' mm'],'units','normalized','fontsize',14);
xlim([-0.15 0.25]);
%%
% figure; 
% cur_fig = tightPlots(1,1,6.85*0.8,[5 4],[0.1 0.1],[0.8 0.1],[0.4 0.1],'inch');
% histfit(error_mat(:,4)); 
% set(gca,'fontsize',18);
% xlabel('Velocity error (%)','fontsize',20);
% % xlabel('Upper edge estimation error (mm)');
% pd_velocity = fitdist(error_mat(:,4),'normal'); set(gcf,'color','w');
% % text(0.7,0.6,['sigma = ',num2str(round(pd_edge.sigma,4)),' mm'],'units','normalized','fontsize',14);
% text(0.1,0.6,['sigma = ',num2str(round(pd_velocity.sigma,2)),' %'],'units','normalized','fontsize',20);
%%
% figure; 
% cur_fig = tightPlots(1,1,6.85*0.8,[5 4],[0.1 0.1],[0.8 0.1],[0.4 0.1],'inch');
% histfit(error_mat(:,5)); 
% set(gca,'fontsize',18);
% xlabel('Weber number error (%)','fontsize',20);
% % xlabel('Upper edge estimation error (mm)');
% pd_weber = fitdist(error_mat(:,5),'normal'); set(gcf,'color','w');
% % text(0.7,0.6,['sigma = ',num2str(round(pd_edge.sigma,4)),' mm'],'units','normalized','fontsize',14);
% text(0.1,0.6,['sigma = ',num2str(round(pd_weber.sigma,2)),' %'],'units','normalized','fontsize',20);
%%
% Type-B uncertainty (errors are assumed to be normally-distributed)
u_diameter = pd_diameter.sigma;
u_edge = pd_edge.sigma;