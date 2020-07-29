lott = [0     0     0     0     0     0     0     0;
     0     0    0      3     0    11     0     0;
     0     8    12     3     0    11     7     0;
     0     8    12     0     1     1     7     0;
     0     0     4     4     2     6     6     0;
     0     9     9     0     2     0     0     0;
     0     0    10    10     5     5     0     0;
     0     0     0     0     0     0     0     0];

lowerRange = 4;
upperRange = 10;
filename = "lots_car_2_solved_in_"+lowerRange+"-"+upperRange+"s.mat";
if isfile(filename)
    lots = cell2mat(struct2cell(load(filename)));
else
    lots = [];
end

count = 0;
prevCount = 0;
for i = 1:500
    if prevCount~=count
        prevCount = count;
        disp(count)
    end
    lot = ParkingLotnoPQ([6,6],true, false);
    tic
    lot.depart(2);
    time = toc;
    if time >=lowerRange && time <= upperRange
        count = count + 1;
        lots(:,:,count) = lot.Lot;
        save(filename, "lots")
        disp("saved")
    end
end