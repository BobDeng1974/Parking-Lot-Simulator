
addpath 'C:\Users\USER\Documents\research\code\initial state generator'

parkingLot = generateParkingLot(8,8);
give(parkingLot)

global Clearance
Clearance = [];
global target   %target is only global for the "show" function. not necessary.

cars=unique(parkingLot)';
if cars(1,1)==0
   cars(1)=[]; 
end

try
while ~isempty(cars)
    for i = cars
        target=i;
        [canLeave] = leave(target);
        if ~canLeave
            fprintf("car %i cannot leave parking lot\n\n", target)
        end
    end
    cars=unique(parkingLot);
    if cars(1,1)==0
       cars(1)=[]; 
    end
end
catch e
    disp(target)
    give(parkingLot)
   rethrow(e) 
end
showLot()


function canLeave = leave(target)
    global Clearance
    
    
    global tryingToMove
    tryingToMove=[];        %the obstructing cars we are trying to move 
    
    showLot()
    directions=possibleDirections(target);   %by possible, i don't mean that there is a space. i mean that if no turning, a horizontal car can't move north, so north is not a possible direction.;
    if isempty(directions)
       canLeave=false;
       tryingToMove=[];
       return
    end
    dir = bestDirection(target, directions);
    hasMoved=0;     %if moved=0, it couldn't move. 1 means it moved, 2 means it moved out of the parking lot
    

    
    
    while hasMoved~=2  %while it hasn't moved out of the parking lot
        if isempty(directions)
            canLeave=false;
            tryingToMove=[];
            break
        else
            canLeave=true;
        end
        
        count=0;
        nextCarSize=carLength(carInDir(target, dir));
        dontMoveNextHere="";      %directions we shouldn't move the blocking car in(because it has tried unsuccessfully to move there before)
        maxCount=2*nextCarSize;
        while count<maxCount || maxCount==0    %
            if maxCount==0
                maxCount=-1;   %make code run only once(by failing "while" condition) if there is no car in direction
            end
            showLot(NaN, carInDir(target, dir))
            hasMoved = moveInDir(target, dir, true);
            if hasMoved == 0
                [nextMoved, triedDirections]=moveNext(target, dir, target, tryingToMove, dontMoveNextHere);
                if nextMoved
                    dontMoveNextHere=triedDirections;
                    count=count+1;
                else        %if the one blocking you can't move, move in the next best direction(opposite direction since no turning)
                    count=2*nextCarSize;    %if you can't move the next, no need repeating to move clearance car completely into parkingTlo completely out of the way
                    directions=directions(directions~=dir);
                    dontMoveNextHere=triedDirections;
                    tryingToMove=[];
                    if ~isempty(directions)
                        dir = bestDirection(target, directions); %gives the next best direction
                    end
                end
            elseif hasMoved == 2        %if its moved out of the lot(incompletely. end of car)
                indices = parkingLot==target;
                parkingLot(indices)=0;
                showLot()
                if~isempty(Clearance)
                end
                return
            end
        end
        if ~hasMoved
            directions=directions(directions~=dir);
            tryingToMove=[];
            if ~isempty(directions)
                dir = bestDirection(target, directions); %gives the next best direction
            end
        end
    end
    return
    
end


function [nextMoved, triedDirections] = moveNext(carID, dir, target, tringToMove, dontMoveHere)   %target is the car we are trying to get out of the lot.
    carID = carInDir(carID, dir);
    if nargin<5
       dontMoveHere="";
    end
    triedDirections=dontMoveHere;   %directions we've tried moving the car in(initially set it to directions we're told not to move in during function call)
    
    if isnan(carID)     %if no car in its direction to move
       nextMoved=false ;
       return
    end
    
    
    global tryingToMove     %only global because of the showLot function.
    tryingToMove=[tryingToMove, carID];
    showLot(tryingToMove)
    
    directions=possibleDirections(carID);   %by possible, i don't mean that there is a space. i mean that if no turning, a horizontal car can't move north, so north is not a possible direction.
    for i=dontMoveHere
        directions=directions(directions~=i);    %directions we were told not to move in when called.
    end
    
    
    
    while ~isempty(directions)
        dir = bestDirection(carID, directions);
        showLot(tryingToMove, carInDir(carID, dir))
        if ~any(ismember([target, tryingToMove], carInDir(carID, dir)))  %if the car blocking me(the car in my direction) is *not* one of the cars we don't to move i.e target car and cars in chain of cars we want to move
            count=0;
            nextCarSize=carLength(carID);       %to-do change to nextCarSize=carLength(carInDir(carID, dir)) and fix error 
            dontMoveNextHere=""; %directions for the blocking car not to move in
            maxCount=2*nextCarSize;
            while count<maxCount && nextCarSize~=0  %nextCarSize~=0 for when there is no nextCar in direction and carLength(carID) outputs 0
                hasMoved = moveInDir(carID, dir);
                if hasMoved==0      %if we can't move the car in the direction, move the car blocking it
                    [nextMoved, nextTriedDirs] = moveNext(carID, dir, target, tringToMove, dontMoveNextHere);
                    if nextMoved
                    	 count=count+1;
                         dontMoveNextHere=nextTriedDirs;
                         hasMoved = moveInDir(carID, dir);
                         if hasMoved
                             tryingToMove=tryingToMove(tryingToMove~=carID);
                             showLot(tryingToMove)
                             nextMoved=true;
                             return
                         elseif count==maxCount  %if it hasn't moved and the car blocking it has moved n times(i.e if count==carSize) where n is the size of the car blocking it.(to allow blocking car to move *completely* out of the way)
                            triedDirections=[triedDirections, dir];
                            directions=directions(directions~=dir);
                            if ~isempty(directions)
                                dir = bestDirection(carID, directions);
                                showLot(tryingToMove, carInDir(carID, dir))
                            end
                         end
                    else   %if we can't move the car blocking it, try another direction
                        triedDirections=[triedDirections, dir];
                        directions=directions(directions~=dir);
                        if ~isempty(directions)
                            dir = bestDirection(carID, directions);
                            showLot(tryingToMove, carInDir(carID, dir))
                        end
                        count=2*nextCarSize;    %if you can't move the next, no need repeating to move clearance car completely into parkingTlo completely out of the way
                    end
                elseif hasMoved>0  %if the car did move
                    tryingToMove=tryingToMove(tryingToMove~=carID);
                    showLot(tryingToMove)
                    nextMoved=true;
                    return
                end
            end
        else                                                        %if the car in the direction is one of the cars that we don't want to move, it is not possible to move in that direction
            triedDirections=[triedDirections, dir];
            directions=directions(directions~=dir);
            if ~isempty(directions)
                dir = bestDirection(carID, directions);
                showLot(tryingToMove, carInDir(carID, dir))
            end
        end
    end
    nextMoved=false;
    tryingToMove=tryingToMove(tryingToMove~=carID);
    showLot(tryingToMove)
    return
end




function bestDir = bestDirection(carID, directions)
    
    global Clearance
    if isHoriz(carID)
        indices=ismember(directions, ["n", "s"]);
        directions(indices)=[]; %since no turns, if horizontal, you can't move north or south        
    elseif isVert(carID)
        indices=ismember(directions, ["e", "w"]);
        directions(indices)=[]; %since no turns, if horizontal, you can't move north or south        
    end
    
    lotSize = size(parkingLot);
    [carRows, carCols] = find(parkingLot==carID);
    obstructingCars=zeros(size(directions));
    distToExit=zeros(size(directions));
    immediateSpaces=zeros(size(directions));
    generalDirSpaces=zeros(size(directions));
    for i = 1:length(directions)
        dir=directions(i);
        if dir=="n"
            generalDir = parkingLot(1:carRows(1), :);
            generalDirSpace(i)=sum(sum(generalDir==0));
            for j = 1:1:carRows(1)
                if parkingLot(j,carCols(1))~=0
                    obstructingCars(i)=obstructingCars(i)+1;
                elseif parkingLot(j,carCols(1))==0 && obstructingCars(i)==1     %how many spaces immediately next to car
                    immediateSpaces(i)=immediateSpaces(i)+1;
                end
                distToExit(i)=distToExit(i)+1;
            end
         elseif dir=="s"
            generalDir = parkingLot(carRows(length(carRows)):size(parkingLot,1), :);
            generalDirSpaces(i)=sum(sum(generalDir==0));
            for j = carRows(length(carRows)):1:lotSize(1)
                if parkingLot(j,carCols(1))~=0
                    obstructingCars(i)=obstructingCars(i)+1;
                elseif parkingLot(j,carCols(1))==0 && obstructingCars(i)==1     %how many spaces immediately next to car
                    immediateSpaces(i)=immediateSpaces(i)+1;
                end
                distToExit(i)=distToExit(i)+1;
            end
        elseif dir=="e"
            generalDir = parkingLot(:, carCols(length(carCols)):size(parkingLot,2));
            generalDirSpaces(i)=sum(sum(generalDir==0));
            for j = carCols(length(carCols)):1:lotSize(2)
                if parkingLot(carRows(1),j)~=0
                    obstructingCars(i)=obstructingCars(i)+1;
                elseif parkingLot(carRows(1),j)==0 && obstructingCars(i)==1     %how many spaces immediately next to car
                    immediateSpaces(i)=immediateSpaces(i)+1;
                end
                distToExit(i)=distToExit(i)+1;
            end
        elseif dir=="w"
            generalDir = parkingLot(:, 1:carCols(1));
            generalDirSpaces(i)=sum(sum(generalDir==0));
            for j = 1:1:carCols(1)
                if parkingLot(carRows(1),j)~=0
                    obstructingCars(i)=obstructingCars(i)+1;
                elseif parkingLot(carRows(1),j)==0 && obstructingCars(i)==1     %how many spaces immediately next to car
                    immediateSpaces(i)=immediateSpaces(i)+1;
                end
                distToExit(i)=distToExit(i)+1;
            end
        end
    end
    
    
    minCars = find(obstructingCars==min(obstructingCars));
    
    if length(minCars)==1                  %if only one direction has fewest blocking cars, no need to compare
        bestDir=directions(minCars);
    else                                    %if multiple directions have fewest blocking cars, compare distance to exit
        minDist=minCars(1);
        for i=minCars
           if distToExit(i)<distToExit(minDist)
               minDist=i;
           elseif distToExit(i)==distToExit(minDist) && i~=minDist
               minDist=[minDist, i];
           end
        end
        if length(minDist)==1
            bestDir=directions(minDist);
        else
            maxGenDirSpaces = minDist(1);
            for i = minDist
               if generalDirSpaces(i)>generalDirSpaces(maxGenDirSpaces)
                   maxGenDirSpaces=i;
               elseif generalDirSpaces(i)==generalDirSpaces(maxGenDirSpaces) && i~=maxGenDirSpaces  %if the distance to exit is the same and you are not comparing the same element to itself
                   maxGenDirSpaces=[maxGenDirSpaces, i];
               end
            end
            if length(maxGenDirSpaces)==1
                bestDir=directions(maxGenDirSpaces);
            else                                %if the distance to exit is the same, compare number of spaces right next to the car in the directions
                maxImSpaces = maxGenDirSpaces(1);
                for i = maxGenDirSpaces
                   if immediateSpaces(i)>immediateSpaces(maxImSpaces)
                       maxImSpaces=i;
                   end
                end
                bestDir=directions(maxImSpaces(1));
            end
        end
    end
    return
end

function hasMoved = moveInDir(carID, dir, isTarget, enteringLot)
    global Clearance
    
    global tryingToMove
    global target
    %--------------setting default
    if nargin<3
        if carID==target
            isTarget=true;
        else
            isTarget=false;
        end
        enteringLot=false;
    elseif nargin<4
        enteringLot=false;
    end
    
    [carRows, carCols] = find(parkingLot==carID);
    lotSize = size(parkingLot);
    
    if inClearance(carID)
        clearanceCars = double(Clearance(:,1)');
        index=find(clearanceCars==carID,1);
        if carLength(carID, true)==carLength(carID)   %if the car has completely come back in
          Clearance(index,:)=[];    %remove the car from clearance
          if enteringLot    %for when a clearance car is trying to reenter the parkingLot
             hasMoved=3;
             return
          end
       end
    end
    
    if isHoriz(carID)
        if dir=="e"
            if inClearance(carID)
                if Clearance(index, 3) == "w"
                    if parkingLot(carRows(1),carCols(length(carCols))+1)==0      %for clearance cars moving back into the parking Lot
                        parkingLot(carRows(1),carCols(length(carCols))+1)=carID;
                        hasMoved=1;
                    else
                        hasMoved=0; 
                    end
                elseif Clearance(index, 3) == "e" && isTarget           %for clearance cars moving out of parking lot. don't move this way if it is not the car trying to leave
                    parkingLot(carRows(1),carCols(length(carCols)))=0;
                    if ~ismember(parkingLot, carID)     %if it just moved out of parkingLot
                        hasMoved=2;
                    else
                        hasMoved=1;
                    end
                elseif ~isTarget    %if it's not the car trying to leave
                    hasMoved=0;
                end
            elseif (carCols(length(carRows))+1)>lotSize(2)  %handling entering the Clearance zone
                if ~isTarget    %the target doesn't need to be taken into the Clearance zone. it is leaving the parking lot.
                    carSize=carLength(carID);
                    Clearance=[Clearance; [carID, isHoriz(carID), dir, carSize]];
                end
                parkingLot(carRows(1),carCols(1))=0;
                hasMoved=2;
            elseif parkingLot(carRows(1),carCols(length(carRows))+1)==0
                parkingLot(carRows(1),carCols(length(carRows))+1)=carID;
                parkingLot(carRows(1),carCols(1))=0;
                hasMoved=1;
            else
                hasMoved=0;
            end

        elseif dir=="w"
            if inClearance(carID)
                if Clearance(index, 3) == "e"
                    if parkingLot(carRows(1),carCols(1)-1)==0      %for clearance cars moving back into the parking Lot
                        parkingLot(carRows(1),carCols(1)-1)=carID;
                        hasMoved=1;
                    else
                        hasMoved=0; 
                    end
                elseif Clearance(index, 3) == "w" && isTarget          %for clearance cars moving out of parking lot
                    parkingLot(carRows(1),carCols(1))=0;
                    if ~ismember(parkingLot, carID)     %if it just moved out of parkingLot
                        hasMoved=2;
                    else
                        hasMoved=1;
                    end
                elseif ~isTarget    %if it's not the car trying to leave
                    hasMoved=0;
                end
            elseif (carCols(1)-1)<1     %handling entering the Clearance zone
                if ~isTarget    %the target doesn't need to be taken into the Clearance zone. it is leaving the parking lot.
                    carSize=carLength(carID);
                    Clearance=[Clearance; [carID, isHoriz(carID), dir, carSize]];
                end
                parkingLot(carRows(1),carCols(length(carRows)))=0;
                hasMoved=2;
            elseif parkingLot(carRows(1),carCols(1)-1)==0
                parkingLot(carRows(1),carCols(1)-1)=carID;
                parkingLot(carRows(1),carCols(length(carRows)))=0;
                hasMoved=1;
            else
                hasMoved=0;
            end
        end
    elseif isVert(carID)
        if dir=="n"
            if inClearance(carID)
                if Clearance(index, 3) == "s"
                    if parkingLot(carRows(1)-1,carCols(1))==0      %for clearance cars moving back into the parking Lot
                        parkingLot(carRows(1)-1,carCols(1))=carID;
                        hasMoved=1;
                    else
                        hasMoved=0; 
                    end
                elseif Clearance(index, 3) == "n" && isTarget          %for clearance cars moving out of parking lot
                    parkingLot(carRows(1),carCols(1))=0;
                    if ~ismember(parkingLot, carID)     %if it just moved out of parkingLot
                        hasMoved=2;
                    else
                        hasMoved=1;
                    end
                elseif ~isTarget    %if it's not the car trying to leave
                    hasMoved=0;
                end
            elseif (carRows(1)-1)<1     %handling entering the Clearance zone
                if ~isTarget    %the target doesn't need to be taken into the Clearance zone. it is leaving the parking lot.
                    carSize=carLength(carID);
                    Clearance=[Clearance; [carID, isHoriz(carID), dir, carSize]];
                end
                parkingLot(carRows(length(carRows)),carCols(1))=0;
                hasMoved=2;
            elseif parkingLot(carRows(1)-1, carCols(1))==0
                parkingLot(carRows(1)-1,carCols(1))=carID;
                parkingLot(carRows(length(carRows)),carCols(1))=0;
                hasMoved=1;
            else
                hasMoved=0;
            end

        elseif dir=="s"
            if inClearance(carID)
                if Clearance(index, 3) == "n"
                    if parkingLot(carRows(length(carRows))+1, carCols(1))==0      %for clearance cars moving back into the parking Lot
                        parkingLot(carRows(length(carRows))+1,carCols(1))=carID;
                        hasMoved=1;
                    else
                        hasMoved=0; 
                    end
                elseif Clearance(index, 3) == "s" && isTarget          %for clearance cars moving out of parking lot
                    parkingLot(carRows(length(carRows)),carCols(1))=0;
                    if ~ismember(parkingLot, carID)     %if it just moved out of parkingLot
                        hasMoved=2;
                    else
                        hasMoved=1;
                    end
                elseif ~isTarget    %if it's not the car trying to leave
                    hasMoved=0;
                end
            elseif (carRows(length(carRows))+1)>lotSize(1)  %handling entering the Clearance zone
                if ~isTarget    %the target doesn't need to be taken into the Clearance zone. it is leaving the parking lot.
                    carSize=carLength(carID);
                    Clearance=[Clearance; [carID, isHoriz(carID), dir, carSize]];
                end
                parkingLot(carRows(1),carCols(1))=0;
                hasMoved=2;
            elseif parkingLot(carRows(length(carRows))+1, carCols(1))==0
                parkingLot(carRows(length(carRows))+1,carCols(1))=carID;
                parkingLot(carRows(1),carCols(1))=0;
                hasMoved=1;
            else
                hasMoved=0;
            end
        end
    end
    
    if hasMoved>0
       showLot(tryingToMove) 
    end
    return
end

function returnClearanceCars()
    global Clearance
    clearanceCars = double(Clearance(:,1)');
    
    for i = clearanceCars
        index=find(clearanceCars==carID,1);
    end
end


%----------minor functions--------------------
function carSize = carLength(carID, insideLot)
    global Clearance
    
    if nargin<2
        insideLot=false;
    end
    [carRows, ~] = find(parkingLot==carID);
    if insideLot
        carSize=length(carRows);
    else
       if inClearance(carID)
           clearanceCars = double(Clearance(:,1)');
           index=find(clearanceCars==carID,1);
           carSize=double(Clearance(index, 4));
       else
          carSize=length(carRows);
       end
    end
    return
end

function bool = inClearance(carID)
    global Clearance
    
    if isnan(carID)
        bool=false;
    elseif ~isempty(Clearance)
        clearanceCars = double(Clearance(:,1)');
        bool=any(ismember(clearanceCars, carID));
    else
        bool=false;
    end
end

function bool = isHoriz(carID)
    
    global Clearance
    if inClearance(carID)
        clearanceCars = double(Clearance(:,1)');
        index=find(clearanceCars==carID,1);
        if Clearance(index, 2) == "true"       %because the second column of clearance is the boolean boolean isHoriz()
            bool=true;
        else
            bool=false;
        end
    else
        [carRows, ~] = find(parkingLot==carID);
        if carRows(1)==carRows(2)
            bool=true;
        else
            bool=false;
        end
    end
    return
end

function bool = isVert(carID)
    
    global Clearance
    if inClearance(carID)
        clearanceCars = double(Clearance(:,1)');
        index=find(clearanceCars==carID,1);
        if Clearance(index, 2) == "true"  % "~" because %because the second column of clearance is the boolean boolean isHoriz()
            bool=false;
        else
            bool=true;
        end
    else    
        [~, carCols] = find(parkingLot==carID);
        if carCols(1)==carCols(2)
            bool=true;
        else
            bool=false;
        end
    end
    return
end

function car = carInDir(carID, dir)
    
    global Clearance
    
    [carRows, carCols] = find(parkingLot==carID);       %no need to worry about index error because if index
    try                                                 %error, car would have moved out of the parking lot befor calling this
        if dir=="n"                                         %function.
            car=parkingLot(carRows(1)-1, carCols(1));  
        elseif dir=="s"                                 
            car=parkingLot(carRows(length(carRows))+1, carCols(1));
        elseif dir=="e"
            car=parkingLot(carRows(1), carCols(length(carCols))+1);
        elseif dir=="w"
            car=parkingLot(carRows(1), carCols(1)-1);
        end
        if car == 0 
           car=NaN;     %to prevent confusion with spaces
        end
        return
    catch e
        if e.identifier == 'MATLAB:badsubscript'
            car=NaN;
        else
            rethrow(e)
        end
    end
     return   
end

function directions = possibleDirections(carID, enteringLot) %by possible, i don't mean that there is a space. i mean that if no turning, a horizontal car can't move north
    global Clearance
    
    if nargin<2
       enteringLot=false; 
    end
    
    if inClearance(carID) && enteringLot
        clearanceCars = double(Clearance(:,1)');
        index=find(clearanceCars==carID,1);
        isHorizontal=Clearance(index, 2);
        dir=Clearance(index, 3);
        if isHorizontal=="true"
            if dir=="e"
                directions="w";
            elseif dir=="w"
                directions="e";
            end
        else
            if dir=="n"
                directions="s";
            elseif dir=="s"
                directions="n";
            end
        end
    elseif isVert(carID)
        directions=["n","s"];
    elseif isHoriz(carID)
        directions=["e","w"];
    end
    
    return
end

























%--------------------------Show Image Function-----------------------------


function showLot(movingCar, lookingAt)      %movingCar is the car we are currently trying to move
                                    %and lookingAt is the car in the way
    
    global Clearance
    global target
    pause(0.2)
    mainCar=target;     %mainCar is the car we are trying to get out of the lot.
    lotSize = size(parkingLot);
    %--------------------------------setting default values
    if nargin==0
        movingCar = NaN;
        lookingAt = NaN;
    elseif  nargin == 1
        lookingAt = NaN;
    end
    
    maxVal=max(max(parkingLot));      %same as number of cars in the parking lot
    image=zeros(lotSize(1), lotSize(2), 3);
    for i = 1:3     %convert to black and white, each car a different shade of gray. no car is completely white, none is completely black.
        image(:,:,i)=((parkingLot/maxVal)*150)+55;    
    end
    spaces=(parkingLot==0)*255;
    image=image+spaces;
    
    
    [carRows, carCols] = find(parkingLot==mainCar);
    if ~isempty(carRows)        %if the target car is still in the parkingLot
        for i = 1:1:size(carRows, 1)
            row=carRows(i);
            col=carCols(i);
            image(row, col, :)=0;
            image(row, col, 2)=255;
        end
    end
    
    if ~isnan(movingCar)
        carCount=length(movingCar);
        shades=linspace(100,150,carCount);
        for carIndex = 1:length(movingCar)
            car=movingCar(carIndex);
            [carRows, carCols] = find(parkingLot==car);
            for i = 1:size(carRows, 1)
                row=carRows(i);
                col=carCols(i);
                image(row, col, :)=0;
                image(row, col, 1)=uint8(shades(carIndex));
            end
        end
    end
    
    if ~isnan(lookingAt)
        [carRows, carCols] = find(parkingLot==lookingAt);
        for i = 1:size(carRows, 1)
            row=carRows(i);
            col=carCols(i);
            image(row, col, :)=0;
            image(row, col, 3)=255;
        end
    end
    
    figure(1)
    image=uint8(image);
    image=imresize(image, 50, "nearest");
    imshow(image)
    return
end

function lot = give(matrix)
    
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


