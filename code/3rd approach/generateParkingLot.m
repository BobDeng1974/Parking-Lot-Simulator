function parkingLot = generateParkingLot(nRows, nCols, cap)
    global carID
    carID=1;
    if nargin<1
        square=input("Do you want a square matrix?: ", 's');

        nRows=randi([2 20]);
        if square=="y"
            nCols=nRows;
        else
            nCols=randi([2 20]);
        end
    end
    
    global parkingLot
    parkingLot=zeros(nRows, nCols);
    
    capacity = 0;
    
    while hasSpaces(parkingLot) || capacity < cap
        capacity = sum(sum(parkingLot~=0))/(nRows*nCols)*100;
        int = randi([1, 2],1,1);
        if int==1
            orient="horiz";
        elseif int==2
            orient="vert";
        end

        carSize = randi([2, 2],1,1);
        [rows, cols]=find(parkingLot==0);
        while ~isempty(rows)
            zerosCount=length(rows);
            zero=randi([1, zerosCount],1,1);
            zeroIndex=[rows(zero), cols(zero)];

            if ~carFits(carSize, orient, zeroIndex)
                rows(zero)=[];
                cols(zero)=[];
            else
                break 
            end
        end
    end
    
    newLot = zeros(size(parkingLot,1)+2, size(parkingLot,2)+2);
    count = 1;
    for i = 2:1:size(newLot,1)-1
        newLot(i,2:end-1) = parkingLot(count,:);
        count = count + 1;
    end
    parkingLot = newLot;
    %making clearance zone
end
    
function bool = carFits(carSize, orient, zeroIndex)
    global parkingLot
    global carID
    row=zeroIndex(1);
    col=zeroIndex(2);
    if orient=="vert"
        for i = 0:1:carSize-1
            if row-(carSize-1)<1
                bool=false;
                break
            end
            if parkingLot(row-i, col)==0
                parkingLot(row-i, col)=carID;
                bool=true;
            else
                bool=false;
                parkingLot(row-(i-1):row, col)=0;
                break
            end
        end
        if bool==true
            carID=carID+1;
            return
        end
        for i = 0:1:carSize-1
            if row+(carSize-1)>size(parkingLot,1)
                bool=false;
                break
            end
            if parkingLot(row+i, col)==0
                parkingLot(row+i, col)=carID;
                bool=true;
            else
                parkingLot(row:row+(i-1), col)=0;
                bool=false;
                break
            end
        end
        if bool==true
            carID=carID+1;
        end
        return
    elseif orient == "horiz"
        for i = 0:1:carSize-1
            if col-(carSize-1)<1
                bool=false;
                break
            end
            if parkingLot(row, col-i)==0
                parkingLot(row, col-i)=carID;
                bool=true;
            else
                parkingLot(row, col-(i-1):col)=0;
                bool=false;
                break
            end
        end
        if bool==true
            carID=carID+1;
            return
        end
        for i = 0:1:carSize-1
            if col+(carSize-1)>size(parkingLot,2)
                bool=false;
                break
            end
            if parkingLot(row, col+i)==0
                parkingLot(row, col+i)=carID;
                bool=true;
            else
                parkingLot(row, col:col+(i-1))=0;
                bool=false;
                break
            end
        end
        if bool==true
            carID=carID+1;
        end
        return
    end

end




function showLot(parkingLot)
    lotSize=size(parkingLot);
    maxVal=max(max(parkingLot));      %same as number of cars in the parking lot
    image=zeros(lotSize(1), lotSize(2), 3);
    for i = 1:3     %convert to black and white, each car a different shade of gray. no car is completely white, none is completely black.
        image(:,:,i)=((parkingLot/maxVal)*150)+55;    
    end
    spaces=(parkingLot==0)*255;
    image=image+spaces;

    figure(1)
    image=uint8(image);
    image=imresize(image, 50, "nearest");
    imshow(image)
    return
end

function bool = hasSpaces(parkingLot)
    [nRow, nCol] = size(parkingLot);
    [rows, cols]=find(parkingLot==0);
    bool = false;
    while ~isempty(rows)
        zerosCount=length(rows);
        zero=randi([1, zerosCount],1,1);
        zeroIndex=[rows(zero), cols(zero)];
        if zeroIndex(1)~=1
            if parkingLot(zeroIndex(1)-1, zeroIndex(2)) == 0
                bool=true;
                return
            else
                bool=false;
            end
        end
        if zeroIndex(1)~=nRow
            if parkingLot(zeroIndex(1)+1, zeroIndex(2)) == 0
                bool=true;
                return
            else
                bool=false;
            end
        end
        if zeroIndex(2)~=1
            if parkingLot(zeroIndex(1), zeroIndex(2)-1) == 0
                bool=true;
                return
            else
                bool=false;
            end
        end
        if zeroIndex(2)~=nCol
            if parkingLot(zeroIndex(1), zeroIndex(2)+1) == 0
                bool=true;
                return
            else
                bool=false;
            end
        end
        if ~bool
            rows(zero)=[];
            cols(zero)=[];
        end
    end
end


function lot = give(matrix)
    global parkingLot
    global Clearance
    [nRows, nCols] = size(matrix);
    matrixName=inputname(1);
    fprintf("%s = [", matrixName)
    
    if nRows>1
        tempEnd=nRows-1;
    else
        tempEnd=nRows;
    end
    
    for i = 1:tempEnd
        for j = 1:nCols
            value=matrix(i, j);
            if class(value)=='string'
                if isempty(str2num(value))
                    fprintf("""%s"" ",value)
                else
                    fprintf("%i ",str2num(value))
                end
            else
                fprintf("%i ",value)
            end
        end
        if nRows>1
            fprintf(";...\n")
            for k = repmat(" ", 1, length(matrixName)+4)
               fprintf("%s", k)
            end
            
        end
        
    end
    if nRows>1
        for i = 1:nCols
            value=matrix(nRows, i);
            if class(value)=='string'
                if isempty(str2num(value))
                    fprintf("""%s"" ",value)
                else
                    fprintf("%i ",str2num(value))
                end
            else
                fprintf("%i ",value)
            end
        end
    end
    fprintf("];\n")
end