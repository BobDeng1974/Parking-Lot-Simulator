classdef State
   properties
       carID;
       Lot;
       Clearance;
       dontMoveHere;
       targetCar;
       targetDontMoveHere;
       parentState
   end
   methods
        function obj = State(carID, Lot, targetCar, parentState, dontMoveHere, targetDontMoveHere)
            obj.carID = carID;
            obj.Lot = Lot;
            obj.targetCar = targetCar;
            obj.dontMoveHere = dontMoveHere;
            obj.parentState = parentState;
            if carID == targetCar
                obj.targetDontMoveHere = dontMoveHere;
            else
                obj.targetDontMoveHere = targetDontMoveHere;
            end
            
            [nRows, nCols] = size(obj.Lot);
            obj.Clearance = zeros(1,2*nCols+2*(nRows-2));     %This is the maximum size it could be if every clearance space is occupied.
            obj.Clearance(1:nCols) = obj.Lot(1,:);
            obj.Clearance(nCols+1:2*nCols) = obj.Lot(end,:);
            obj.Clearance(2*nCols+1:2*nCols+nRows-2) = obj.Lot(2:end-1,1);
            obj.Clearance(2*nCols+nRows-1:2*nCols+2*(nRows-2)) = obj.Lot(2:end-1,end);
            obj.Clearance=obj.Clearance(obj.Clearance~=0);
        end
        function isDest = isDestination(obj)
            isDest = false;
            if obj.carID == obj.targetCar     %To-Do change content of "if" block for turning when specific exit points are used.
                if any(ismember(obj.Clearance, obj.carID))
                   isDest = true; 
                end
            end
        end
        function weight = calcWeight(obj, endState)
            if obj.carID ~= endState.carID && endState.carID~=obj.targetCar                                 %if you are trying to move another car
                weight = 5;
            elseif length(endState.Clearance) > length(obj.Clearance) && obj.carID ~= obj.targetCar     %if you entered the clearance zone
               weight = 20; 
            elseif any(any(endState.Lot ~= obj.Lot))                                 %if you moved
                if obj.carID == obj.targetCar
                    weight = 1;
                else
                    weight = 2;
                end
            else
               weight = 0; 
            end
        end
        function adjStates = adjacent(obj)
            adjStates = [];
            
            if obj.carID~=obj.targetCar
                if obj.carCanMove(obj.targetCar)
                    adjStates = [State(obj.targetCar, obj.Lot, obj.targetCar, obj, obj.targetDontMoveHere), adjStates]; %focus on target car.
                end
            end
            
            directions=obj.possibleDirections();
            for dir = directions
                if obj.carID == obj.targetCar
                    dontMoveInDir = any(ismember(obj.targetDontMoveHere, dir));
                else
                    dontMoveInDir = any(ismember(obj.dontMoveHere, dir)); 
                end
                
                if dontMoveInDir
                    continue
                end
                
                [canMove, nextLot] = obj.moveInDir(dir);
                if canMove
                   tDontMoveHere = obj.oppositeDir(dir);
                   if obj.carCanMove(obj.targetCar)
                        adjStates = [adjStates, State(obj.targetCar, nextLot, obj.targetCar, obj, tDontMoveHere)];
                   end
                   if obj.carID ~= obj.targetCar && obj.parentState.carID ~= obj.carID
                        DontMoveHere = [obj.parentState.dontMoveHere, obj.oppositeDir(dir)];    %To-Do might remove. initial logic is don't want the parent car exploring another direction except the direction it is trying to move in. it might prevent finding further states because there might be other restricted options opened up by the blocking car moving that the parent car wont see if it keeps going only in that one direction. see problem state #1
                        adjStates = [adjStates, State(obj.parentState.carID, nextLot, obj.parentState.targetCar, obj.parentState.parentState, DontMoveHere, obj.parentState.targetDontMoveHere)]; %if you can move, tell your parent state to try to move again.
                   end
                else
                    carInDir = obj.carInDir(obj.carID, dir);
                    if carInDir ~= obj.targetCar && ~isnan(carInDir)       %focus on obstructing car if you can't move and youre not the target car
                        dontMoveInDir = obj.oppositeDir(dir);                  %set the dontMoveInDir to oppositeDir(dir) so that obstructing car won't try to move the previous car that commanded it to move out of the way.
                        if obj.carID == obj.targetCar
                            tDontMoveHere = dontMoveInDir; 
                        else
                            tDontMoveHere = obj.targetDontMoveHere;
                        end
                        adjStates = [adjStates, State(carInDir, obj.Lot, obj.targetCar, obj, dontMoveInDir, tDontMoveHere)];
                    end
                end
            end
        end
        
        %----------------------operations on car---------------------------
        function [canMove, nextLot] = moveInDir(obj, dir, carID)
            if nargin == 2
                carID = obj.carID;
            end
            if obj.carInDir(carID, dir)~=0        %0 means free space in the direction
                canMove = false;
                nextLot = obj.Lot;
                return
            end
            
            canMove = true;
            nextLot = obj.Lot;
            [rows, cols] = find(obj.Lot==carID);
            if obj.carOrient() == "vert"
                if dir == "n"
                    nextLot(rows(1)-1,cols(1))=carID;
                    nextLot(rows(end),cols(1))=0;
                elseif dir=="s"
                    nextLot(rows(end)+1,cols(1))=carID;
                    nextLot(rows(1),cols(1))=0;
                end
            else 
                if dir=="e"
                    nextLot(rows(1),cols(end)+1)=carID;
                    nextLot(rows(1),cols(1))=0;
                elseif dir=="w"
                    nextLot(rows(1),cols(1)-1)=carID;
                    nextLot(rows(1),cols(end))=0;
                end
            end
        end
        
        function carID = carInDir(obj, carID, dir)              %To-Do modify for turning
            [rows, cols] = find(obj.Lot==carID);
            try
                if obj.carOrient() == "vert"
                    if dir=="n"
                        carID=obj.Lot(rows(1)-1, cols(1));  
                    elseif dir=="s"                                 
                        carID=obj.Lot(rows(end)+1, cols(1));
                    end
                else
                    if dir=="e"
                        carID=obj.Lot(rows(1), cols(end)+1);
                    elseif dir=="w"
                        carID=obj.Lot(rows(1), cols(1)-1);
                    end
                end
            catch e
                if e.identifier == 'MATLAB:badsubscript'
                    carID=NaN;
                else
                    rethrow(e)
                end
            end
        end
        
        function directions = possibleDirections(obj, carID)    %To-Do modify for turning
            if nargin<2
               carID=obj.carID;
            end
            
            if obj.carOrient(carID) == "vert"
                directions=["n", "s"];
            elseif obj.carOrient(carID) == "horiz"
                directions=["e", "w"];
            end
            directions = directions(~ismember(directions, obj.dontMoveHere));
        end
        
        function bool = carCanMove(obj, carID)
            if nargin<2
               carID=obj.carID;
            end
            bool = false();
            directions = obj.possibleDirections(carID);
            
            if carID == obj.targetCar
               dontMoveInDir =  obj.targetDontMoveHere;
            else
               dontMoveInDir =  obj.dontMoveHere;
            end
            for dir = setdiff(directions, dontMoveInDir)
                if obj.carInDir(carID, dir)==0
                    bool=true;
                    return
                end
            end
            
        end
        
        function orient = carOrient(obj, carID)
            if nargin<2
               carID=obj.carID;
            end
            
            [rows, cols] = find(obj.Lot==carID);
            if all(rows==rows(1))
                orient = "horiz";
            elseif all(cols==cols(1))
                orient = "vert";
            end
        end
        
        function oppDir = oppositeDir(obj, dir)     %To-Do modify for turning
            if dir == "n"
                oppDir = "s";
            elseif dir == "s"
                oppDir = "n";
            elseif dir == "e"
                oppDir = "w";
            elseif dir == "w"
                oppDir = "e";
            end
        end
   end
end