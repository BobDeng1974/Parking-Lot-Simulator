numberOfCars = 20;
departTimes = [];
for i = 1:numberOfCars
    departTimes = [departTimes,str2double(strcat(sprintf('%02d',randi([1,24])),sprintf('%02d',randi([0,59]))))];
end

disp(mat2str(departTimes))

InsertCars([5,5],departTimes,false)