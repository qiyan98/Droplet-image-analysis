clear;
close all;

% load saved data about TRUE and ESTIMATED Weber numbers
load_str = '.\output\Weber_calculation\data_weber_est.mat';
load(load_str);
load_str = '.\output\Weber_calculation\data_weber_true.mat';
load(load_str);
clear load_str;

num_source = length(data_weber_true);
unce_data = cell(num_source,1);
error_data = zeros(3,1); mean_data = zeros(3,4);
str_lgd = [];
str_colors = {'red','blue','green'};
% cur_fig = tightPlots(1,1,6.5,[640 480],[0.1 0.1],[0.65 0.25],[0.6 0.15],'inch');
% hold on; set(gcf,'color','w'); box on;
i_plot = 0;
for i = 1:num_source
% for i = [1:2,4:8,11:15]
% for i = [2:3,10]
    i_plot = i_plot + 1;
    % load data for current source
    cur_data_est = data_weber_est(data_weber_est(:,1) == i,:);
    cur_data_true = data_weber_true{i};
    
    % delete ros with NaN terms
    ii_aux = 0;
    for ii = 1:length(cur_data_est)
        ii_aux = ii_aux + 1;
        tmp = sum(ismissing(cur_data_est(ii_aux,:)));
        if tmp~=0
            cur_data_est(ii_aux,:) = [];
            ii_aux = ii_aux - 1;
        end
    end
    
    % delete the data points with problematic 1-position
    cur_data_est(find(cur_data_est(:,6) == 1),:) = []; %#ok<FNDSB>
    num_cur_data_est = length(cur_data_est);
    
    % create variables for temporary data storage
    cur_pixel_calib = cur_data_est(1,end);
    cur_vel_vec = zeros(num_cur_data_est,1);
    cur_unce_vec = cur_vel_vec;
    cur_weber_vec = cur_vel_vec;
    
    % set minimum position displacement to ensure good uncertainty
%     min_deltaP = 60; % unit: pixel
    min_deltaP = 2/cur_pixel_calib*1e3; % unit: pixel
    for jj = 1:num_cur_data_est        
        % find next suitable data point for velocity calculation
        cur_pos = cur_data_est(jj,6);
        
        % forward search
        tmp = abs(cur_data_est(:,6) - (cur_pos + min_deltaP));
        [~,tmp] = sort(tmp);
        cur_D_fwd = cur_data_est(tmp(1),6) - cur_pos;
        cur_T_fwd = cur_data_est(tmp(1),3) - cur_data_est(jj,3);
        
        % backward search
        tmp = abs(cur_data_est(:,6) - (cur_pos - min_deltaP));
        [~,tmp] = sort(tmp);
        cur_D_bkwd = abs(cur_data_est(tmp(1),6) - cur_pos);
        cur_T_bkwd = abs(cur_data_est(tmp(1),3) - cur_data_est(jj,3));
        
        % calculate velocity
        if cur_D_fwd > cur_D_bkwd
            cur_D = cur_D_fwd;
            cur_T = cur_T_fwd;
        else
            cur_D = cur_D_bkwd;
            cur_T = cur_T_bkwd;
        end
        cur_vel_vec(jj) = cur_D/cur_T; % unit: pixel/ms
        
        % calculate uncertainty
        cur_diameter = cur_data_est(jj,5); % unit: pixel
        cur_unce_vec(jj) = sqrt((0.04/(cur_diameter*cur_pixel_calib*1e-3))^2+(0.113/(cur_D*cur_pixel_calib*1e-3))^2);
        
        % calcualte Weber number
        cur_weber_vec(jj) = 998.22/0.0728*cur_vel_vec(jj)^2*cur_diameter*(cur_pixel_calib*1e-6)^3*1e6;
    end
    cur_weber_vec(ismissing(cur_weber_vec)) = [];
    unce_data{i} = cur_unce_vec;
    error_data(i) = abs((mean(cur_weber_vec) - mean(cur_data_true(:,2)))/ mean(cur_data_true(:,2)));
    cur_diameter_mean = mean(cur_data_est(:,5));
    cur_unce_mean = sqrt((0.04/(cur_diameter_mean*cur_pixel_calib*1e-3))^2+(0.113/2)^2);
    cur_error_mean = error_data(i);
    mean_data(i,1) = mean(cur_weber_vec);       % est
    mean_data(i,2) = mean(cur_data_true(:,2));  % true
    mean_data(i,3) = cur_unce_mean;   % est error
    mean_data(i,4) = cur_error_mean;  % true error
    
%     % plot
%     cur_T = cur_data_est(:,3);
%     figure; hold on; set(gcf,'color','w');
%     plot(cur_T,cur_weber_vec,'-o');            
%     plot(cur_data_true(:,1),cur_data_true(:,2),'-x'); % time - Weber

%     plot(cur_data_true(:,1),cur_data_true(:,4),'.-'); % time - diameter
%     plot(cur_data_est(:,3),cur_data_est(:,5),'o-');   % time - diameter
    
%     if i == 10
%         plot(cur_data_est(1:end-7,3),cur_data_est(1:end-7,6)*cur_pixel_calib*1e-3,'.','markersize',8,'color',str_colors{i_plot});
%     else
%         plot(cur_data_est(:,3),cur_data_est(:,6)*cur_pixel_calib*1e-3,'.','markersize',8,'color',str_colors{i_plot});
%     end
%     plot(cur_data_true(:,1),cur_data_true(:,5)*cur_pixel_calib*1e-3,'d','markersize',8,'color',str_colors{i_plot});
%     cur_str = ['试样',num2str(i_plot),'CNN方法检测'];
%     cur_str = {cur_str,['试样',num2str(i_plot),'人工标定']};
%     str_lgd = [str_lgd,cur_str];
end
%%
% legend(str_lgd,'location','best');
% xlabel('时间 (ms)','fontsize',18);
% ylabel('液滴位置 (mm)','fontsize',18);
% set(gca,'fontsize',14);

% figure; set(gcf,'color','w'); plot(error_data,'-x','linewidth',2);
% figure; set(gcf,'color','w');hist(error_data);
mean_data_backup = mean_data;
    
mean_data([1,4,9,10,11,16:21],:) = [];
% mean_data([1,4,10,11],:) = [];
%%
figure; set(gcf,'color','w');
cur_fig = tightPlots(1,1,6.25,[680 480],[0.1 0.1],[0.7 0.2],[0.7 0.2],'inch');
bar(mean_data(:,1:2));
legend('CNN法估计值','人工标定值','location','best','fontsize',14);
% set(gca,'Xtick',1:length(mean_data));
xlabel('实验数据试样编号','fontsize',20);
ylabel('Weber数','fontsize',20);
set(gca,'fontsize',16);
%%
figure; set(gcf,'color','w');
cur_fig = tightPlots(1,1,6.25,[680 480],[0.1 0.1],[0.7 0.2],[0.7 0.2],'inch');
bar(mean_data(:,3:4)*100);
legend('估计误差','实际偏差','location','best','fontsize',14);
xlabel('实验数据试样编号','fontsize',20);
ylabel('Weber数计算偏差 (%)','fontsize',20);
set(gca,'fontsize',16);
%%
figure;
cur_fig = tightPlots(1,1,6.25,[680 480],[0.1 0.1],[0.8 0.2],[0.9 0.25],'inch');
set(gcf,'color','w'); hold on; box on;
X = [ones(length(mean_data),1),mean_data(:,1)];
b = regress(mean_data(:,2),X);
tmp = [10.1:0.1:13.5];
Z = b(1) + b(2)*tmp;
plot(mean_data(:,1),mean_data(:,2),'d','markersize',8,'color','black','markerfacecolor','black');
plot(tmp,tmp,'-','linewidth',1,'color','black');
xlim([10 13.5]); ylim([10 13.6]);
set(gca,'fontsize',16);
xlabel('Weber数 (本文方法)','fontsize',20);
ylabel('Weber数 (真实值)','fontsize',20);
legend('数据点','y=x参考线','location','best');
%%
% figure; set(gcf,'color','w');
% f_e = @(x,y) sqrt((2*sqrt(2)*0.04/x)^2 + (0.04/y)^2);
% f_e = @(y)f_e(y,2);
% x_vec = 0.1:0.1:3; y_yec = zeros(length(x_vec),1);
% for jj = 1:length(x_vec)
%     y_yec(jj) = f_e(x_vec(jj));
% end
% plot(x_vec,y_yec,'-o','linewidth',2);
% xlabel('L_p（mm）','fontsize',14);
% ylabel('Weber数计算的不确定度','fontsize',14);