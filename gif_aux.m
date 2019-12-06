clear;
close all;

tic;
imds = imageDatastore('.\imageData_weber');
pic_num = length(imds.Files);


if exist('.\imageData_weber\cur_png','dir')
    rmdir('.\imageData_weber\cur_png','s');
end
mkdir('.\imageData_weber\cur_png');

for i = 1:pic_num
    curImage = imread(imds.Files{i});
    img_name = ['.\imageData_weber\cur_png\',num2str(i),'.png'];
    imwrite(curImage,img_name);
end

toc;