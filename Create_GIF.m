%Gif Creator for Matlab
%Program Call: Create_GIF.m
%11/27/2017
%Version: 1.0

%---Description------------------------------------------------------------
%A script/program that can be called for creating gifs from PNG files. The
%program will ask for the "DelayTime" which is the time before the gif
%switches frames, and a name for the .gif file. The program will open a
%dialog box, where you can input these parameters, and then open a new
%dialog box where you can select your files. You can select as many files
%as you want to incorporate into your .gif file. The .gif file will be
%saved in the same directory as the image files that it was created from.
%An extended version where it can be saved anywhere is under development.

%Currently, the program is only tested on .png files and on Matlab R2017.
%However, the program should work for other bitmap-type image files and I
%will be testing it on Octave to see if it works. 
%--------------------------------------------------------------------------

%Program Code
delaytime = inputdlg('How much time would you like between frames in your file? (In Seconds)');
filename = inputdlg('What would you like to name your gif? (No need to include the .gif extension)');

delaytime = str2num(delaytime{:});

[fname,pname,filterindex] = uigetfile('M:/Research/StabilityDiagram2/273/*.png','Please Select Your File','MultiSelect','on');
idx = length(fname);
filename = strcat(pname,filename{:},'.gif');

for i = 1:idx
    myimg = imread(strcat(pname,fname{i}));
    if size(myimg,3) == 3 % RGB picture
        [A,map] = rgb2ind(myimg,256);
    elseif size(myimg,3) == 1 % grayscale picture
        [A,map] = gray2ind(myimg,256);
    end
    
    if i == 1
        imwrite(A,map,filename,'gif','LoopCount',Inf,'DelayTime',delaytime);
    else
        imwrite(A,map,filename,'gif','WriteMode','append','DelayTime',delaytime);
    end
end


