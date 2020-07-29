clc, clear vars, close all

parkingLot=[1  3  3  2  5  7; ...
            1  0  0  2  5  7; ...
            8  8  0  0  10 10; ...
            4  4  0  0  0  0; ...
            11 0  13 13 9  9; ...
            11 12 12 0  0  0];
        
global nRow nCol
[nRow, nCol] = size(parkingLot);
global spaces
spaces=[];
global count
count=0;

for i = 1:1:nRow
    if parkingLot(i,1)==0
        spaceCheck(parkingLot, [i,1]);
    end
    if parkingLot(i,nCol)==0
        spaceCheck(parkingLot, [i,nCol]);
    end
end

for i = 1:1:nCol
    if parkingLot(1,i)==0
        spaceCheck(parkingLot, [1,i]);
    end
    if parkingLot(nRow,i)==0
        spaceCheck(parkingLot, [nRow,i]);
    end
end

[nSpaces, ~] = size(spaces);
fprintf("Number of free accessible spaces: %i\n", nSpaces)


function spaceCheck(parkingLot, currentPoint)
    global spaces nRow nCol count
    if currentPoint(1)-1 ~= 0 && parkingLot(currentPoint(1)-1, currentPoint(2))==0
        currentSpace=[currentPoint(1), currentPoint(2), currentPoint(1)-1, currentPoint(2)];
        altCurrentSpace=[currentPoint(1)-1, currentPoint(2), currentPoint(1), currentPoint(2)];
        if isempty(spaces) || (~any(ismember(spaces,currentSpace, 'rows')) && ~any(ismember(spaces,altCurrentSpace, 'rows')))
            count=count+1;
            spaces(count,:)=currentSpace;
            spaceCheck(parkingLot, [currentPoint(1)-1, currentPoint(2)])
        end
    end
    
    if currentPoint(1)+1 <= nRow && parkingLot(currentPoint(1)+1, currentPoint(2))==0
        currentSpace=[currentPoint(1), currentPoint(2), currentPoint(1)+1, currentPoint(2)];
        altCurrentSpace=[currentPoint(1)+1, currentPoint(2), currentPoint(1), currentPoint(2)];
        if isempty(spaces) || (~any(ismember(spaces,currentSpace, 'rows')) && ~any(ismember(spaces,altCurrentSpace, 'rows')))
            count=count+1;
            spaces(count,:)=currentSpace;
            spaceCheck(parkingLot, [currentPoint(1)+1, currentPoint(2)])
        end
    end
    
    if currentPoint(2)-1 ~= 0 && parkingLot(currentPoint(1), currentPoint(2)-1)==0
        currentSpace=[currentPoint(1), currentPoint(2), currentPoint(1), currentPoint(2)-1];
        altCurrentSpace=[currentPoint(1), currentPoint(2)-1, currentPoint(1), currentPoint(2)];
        if isempty(spaces) || (~any(ismember(spaces,currentSpace, 'rows')) && ~any(ismember(spaces,altCurrentSpace, 'rows')))
            count=count+1;
            spaces(count,:)=currentSpace;
            spaceCheck(parkingLot, [currentPoint(1), currentPoint(2)-1])
        end
    end
    
    if currentPoint(2)+1 <= nCol && parkingLot(currentPoint(1), currentPoint(2)+1)==0
        currentSpace=[currentPoint(1), currentPoint(2), currentPoint(1), currentPoint(2)+1];
        altCurrentSpace=[currentPoint(1), currentPoint(2)+1, currentPoint(1), currentPoint(2)];
        if isempty(spaces) || (~any(ismember(spaces,currentSpace, 'rows')) && ~any(ismember(spaces,altCurrentSpace, 'rows')))
            count=count+1;
            spaces(count,:)=currentSpace;
            spaceCheck(parkingLot, [currentPoint(1), currentPoint(2)+1])
        end
    end
end


