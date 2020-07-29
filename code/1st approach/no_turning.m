global parkingLot
parkingLot=[16  3  3  5  5  7; ...
            16  15 15 2  2  7; ...
            8  8  1 14 10 10; ...
            4  4  1 14 17 17; ...
            6 0   1 13 13  9; ...
            6 12 12 11  11  9];
unmodified=parkingLot;
global clearance
clearance=[];

repeat=true;
target=1;
main(target)




function parkingLot = main(target)
    global parkingLot
    show(parkingLot)
    dir = bestDirection(parkingLot, target);
    carID = target;
    success=0;
    failCount=0;
    while success ~= 2  %while the car hasn't moved out of the parking space
        [success, parkingLot] = move(parkingLot, carID, dir, target);
        if success==0
            parkingLot = moveNext(carID, dir, target);
            failCount=failCount+1;
            %returning the cars in the clearance zone
        else
            failCount=0;
        end
        if failCount>2
            dir=oppositeDirection(dir);
        end
        
    end
end   

function parkingLot = moveNext(carID, dir, target)
    global parkingLot
    carInDir = carInDirection(carID, dir);
    carID=carInDir;
    orient=orientation(parkingLot, carInDir);
    if orient == "vertical"
        movements=["n","s"];
        count=1;
        success=0;
        while success==0 && count<=2
            [success, parkingLot] = move(parkingLot, carID, movements(count), target);
            count=count+1;
        end
        if success==0
            bestDir=bestDirection(parkingLot,carID);
            if movements(1)~=bestDir
                movements=["s" "n"];
            end
            for dir = movements
                carInDir = carInDirection(carID, dir);
                if carInDir~=target
                    [success, parkingLot] = move(parkingLot, carID, dir, target);
                    if success==0
                        parkingLot = moveNext(carID, dir, target);
                        [~, parkingLot] = move(parkingLot, carID, dir, target);
                        return
                    end
                end
            end
        end
        
    elseif orient == "horizontal"
        movements=["e","w"];
        count=1;
        success=0;
        while success==0 && count<=2
            [success, parkingLot] = move(parkingLot, carID, movements(count), target);
            count=count+1;
        end
        if success==0
            bestDir=bestDirection(parkingLot,carID);
            if movements(1)~=bestDir
                movements=["w" "e"];
            end
            for dir = movements
                carInDir = carInDirection(carID, dir);
                if carInDir~=target
                    [success, parkingLot] = move(parkingLot, carID, dir, target);
                    if success==0
                        parkingLot = moveNext(carID, dir, target);
                        [~, parkingLot] = move(parkingLot, carID, dir, target);
                        return
                    end
                end
            end
        end
    end

end

function carInDir = carInDirection(carID, dir)
    global parkingLot
    
    [carRows, carCols] = find(parkingLot==carID);       %no need to worry about index error because if index
    if dir=="n"                                         %error, car would have moved out of the parking lot befor calling this
        carInDir=parkingLot(carRows(1)-1, carCols(1));  %function.
    elseif dir=="s"                                 
        carInDir=parkingLot(carRows(2)+1, carCols(1));
    elseif dir=="e"
        carInDir=parkingLot(carRows(1), carCols(2)+1);
    elseif dir=="w"
        carInDir=parkingLot(carRows(1), carCols(1)-1);
    end
    return
    
end

function [success, parkingLot] = move(parkingLot, carID, direction, target)
    global clearance
    [carRows, carCols] = find(parkingLot==carID);
    orient=orientation(parkingLot, carID);
    lotSize = size(parkingLot);
    
    
    if orient=="vertical"
        if direction=="n"
            %if car at the end of lot
            if (carRows(1)-1)<1
                parkingLot(carRows(1),carCols(1))=0;
                parkingLot(carRows(2),carCols(1))=0;
                if ~target
                    clearance=[clearance; [carID, carRows(1), carCols(1)]];
                end
                success=2;  %car has moved out of the parking lot
                show(parkingLot)
                return
            elseif parkingLot(carRows(1)-1, carCols(1))==0
                parkingLot(carRows(1)-1,carCols(1))=carID;
                parkingLot(carRows(2),carCols(1))=0;
                success=1;
                show(parkingLot)
                return
            else
                success=0;
                return
            end
        elseif direction=="s"
            %if car at the end of lot
            if (carRows(2)+1)>lotSize(1)
                parkingLot(carRows(1),carCols(1))=0;
                parkingLot(carRows(2),carCols(1))=0;
                if ~target
                    clearance=[clearance; [carID, carRows(2), carCols]];
                end
                success=2;  %car has moved out of the parking lot
                show(parkingLot)
                return
            elseif parkingLot(carRows(2)+1, carCols(1))==0
                parkingLot(carRows(2)+1,carCols(1))=carID;
                parkingLot(carRows(1),carCols(1))=0;
                success=1;
                show(parkingLot)
                return
            else
                success=0;
                return
            end

        else
            disp("syntax error")
            success=0;
            return
        end

    elseif orient=="horizontal"
        if direction=="e"
            if (carCols(2)+1)>lotSize(2)
                parkingLot(carRows(1),carCols(1))=0;
                parkingLot(carRows(1),carCols(2))=0;
                if ~target
                    clearance=[clearance; [carID, carRows(1), carCols(2)]];
                end
                success=2;  %car has moved out of the parking lot
                show(parkingLot)
                return
            elseif parkingLot(carRows(1),carCols(2)+1)==0
                parkingLot(carRows(1),carCols(2)+1)=carID;
                parkingLot(carRows(1),carCols(1))=0;
                success=1;
                show(parkingLot)
                return
            else
                success=0;
                return
            end
        elseif direction=="w"
            if (carCols(1)-1)<1
                parkingLot(carRows(1),carCols(1))=0;
                parkingLot(carRows(1),carCols(2))=0;
                if ~target
                    clearance=[clearance; [carID, carRows(1), carCols(1)]];
                end
                success=2;  %car has moved out of the parking lot
                show(parkingLot)
                return
            elseif parkingLot(carRows(1),carCols(1)-1)==0
                parkingLot(carRows(1),carCols(1)-1)=carID;
                parkingLot(carRows(1),carCols(2))=0;
                success=1;
                show(parkingLot)
                return
            else
                success=0;
                return
            end
        else
            disp("syntax error")
            success=0;
            return
        end
    end
end

function orient = orientation(parkingLot, carID)
    [carRows, carCols] = find(parkingLot==carID);
    if carRows(1)==carRows(2)
        orient="horizontal";
    elseif carCols(1)==carCols(2)
        orient="vertical";
    end
end

function dir = bestDirection(parkingLot, carID)
    lotSize = size(parkingLot);
    [carRows, carCols] = find(parkingLot==carID);
    orient=orientation(parkingLot, carID);
    if orient == "vertical"        
        runningSums=[0 0];
        counts=[0 0];
        for i = 1:1:carRows(1)
            if parkingLot(i,carCols(1))~=0
                runningSums(1)=runningSums(1)+1;
            end
            counts(1)=counts(1)+1;
        end
        for i = carRows(2):1:lotSize(1)
            if parkingLot(i,carCols(1))~=0
                runningSums(2)=runningSums(2)+1;
            end
            counts(2)=counts(2)+1;
        end
        
    elseif orient == "horizontal"        
        runningSums=[0 0];
        counts=[0 0];
        for i = 1:1:carCols(1)
            if parkingLot(carRows(1),i)~=0
                runningSums(1)=runningSums(1)+1;
            end
            counts(1)=counts(1)+1;
        end
        for i = carCols(2):1:lotSize(2)
            if parkingLot(carRows(1),i)~=0
                runningSums(2)=runningSums(2)+1;
            end
            counts(2)=counts(2)+1;
        end
    end
    
    minSum = find(runningSums==min(runningSums));
    [~, sizeMin] = size(minSum);
    if sizeMin>1
        compareCount=[];
        for i = minSum
            compareCount=[compareCount, counts(i)];
        end
        minCount=find(compareCount==min(compareCount));
        minimum=minSum(minCount(1));    %minCount(1) in case their running sums and counts are the same.
    else
        minimum=minSum;
    end

    if minimum==1
        if orient=="vertical"
            dir="u";
            return
        elseif orient=="horizontal"
            dir="l";
            return
        end
    elseif minimum==2
        if orient=="vertical"
            dir="d";
            return
        elseif orient=="horizontal"
            dir="r";
            return
        end
    end
end

function oppositeDir = oppositeDirection(dir)
    if dir == "n"
        oppositeDir="s";
    elseif dir == "s"
        oppositeDir="n";
    elseif dir == "e"
        oppositeDir="w";
    elseif dir == "w"
        oppositeDir="e";
    end
    return
end


function show(parkingLot)
    maximum=max(max(parkingLot));
    parkingLot=(parkingLot/maximum)*255;
    spaces=(parkingLot==0)*255;
    parkingLot(:,:,2)=parkingLot(:,:,1)+spaces;
    parkingLot(:,:,3)=parkingLot(:,:,1);
    parkingLot=uint8(parkingLot);
    figure(1)
    parkingLot=imresize(parkingLot, 50, "nearest");
    imshow(parkingLot)
end

