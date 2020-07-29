classdef ParkingLot < handle
   properties
      Lot
      States
      inverseState
      FocusCars
      ActionSet
      Graph
      targetCar
      cumulativeWeight
      debug
      solutions
      heuristic
   end
   
   methods
        function obj = ParkingLot(lot, rows, cols, capacity, targetCar, heuristic, debug)
            if nargin <7
               obj.debug = false; 
            else
               obj.debug = debug; 
            end
           obj.heuristic = heuristic;
           if ~isnan(lot)
               obj.Lot = lot;
           else
               obj.Lot = generateParkingLot(rows, cols, capacity);
           end
           obj.targetCar = targetCar;
           obj.Graph = digraph();
           obj.States = containers.Map('KeyType','double','ValueType','any');
           obj.FocusCars = containers.Map('KeyType','double','ValueType','double');
           obj.inverseState = containers.Map('KeyType','char','ValueType','double');
           obj.ActionSet = ["u" "d" "l" "r"];
           
           %initiate initial node
           obj.Graph = addnode(obj.Graph, 1);
           obj.States(1) = obj.Lot;
           obj.FocusCars(1) = targetCar;
           obj.addInverse(obj.States(1),obj.FocusCars(1),1);
           obj.cumulativeWeight(1) = 0;
           
        end
       
        function solutions = generateGraph(obj,s)
            queue1 = s;
            queue2 = [];
            queue3 = [];
            queue4 = [];
            solutions = [];
            bestWeight = inf;
            while ~isempty([queue1,queue2,queue3,queue4])
                if obj.heuristic
                    if ~isempty(queue1)
                        s = queue1(1);
                        q = 1;
                    elseif ~isempty(queue2)
                        s = queue2(1);
                        q = 2;
                    elseif ~isempty(queue3)
                        s = queue3(1);
                        q = 3;
                    elseif ~isempty(queue4)
                        s = queue4(1);
                        q = 4;
                    end
                else
                   s = queue1(1);
                   q = 1;
                end
                stateLot = obj.States(s);
                focusCar = obj.FocusCars(s);
                cumWeight = obj.cumulativeWeight(s);
                if obj.debug
                    obj.showLot(s)
                end
                if obj.isVert(focusCar, stateLot)
                    actionSet = ["u","d"];
                else
                    actionSet = ["l","r"];
                end
                count = 0;
                while ~isempty(actionSet)
                    count = count + 1;
                    if obj.heuristic
                        action = obj.bestDirection(focusCar, stateLot, actionSet);
                        actionIndex = find(actionSet==action);
                    else
                        actionIndex = 1;
                        action = actionSet(actionIndex);
                    end
                    actionSet(actionIndex) = [];
                    [newLot, newFocusCar] = obj.Transition(s, action);
                    if isnan(newLot)
                        continue
                    end
                    
                    if obj.stateExists(newLot, newFocusCar)
                       continue
                    end
                    
                    newNodeIndex = numnodes(obj.Graph)+1;

                    reward = obj.Reward(stateLot,focusCar, newLot,newFocusCar);
                    newCumWeight = cumWeight + reward;
                    if newCumWeight>bestWeight
                       continue 
                    end
                    obj.Graph = addedge(obj.Graph, s, newNodeIndex, reward);
                    obj.States(newNodeIndex) = newLot;
                    obj.FocusCars(newNodeIndex) = newFocusCar;
                    obj.addInverse(newLot,newFocusCar,newNodeIndex);
                    obj.cumulativeWeight(newNodeIndex) = newCumWeight;
                    
                    if obj.isEndNode(newNodeIndex)
                        if newCumWeight<bestWeight
                            bestWeight = newCumWeight;
                        end
                        solutions = [solutions, obj.getInstructions(s)];
                        continue
                    end
                    if obj.heuristic
                        if count == 1
                            queue1 = [queue1, newNodeIndex];
                        elseif count == 2
                            queue2 = [queue2, newNodeIndex];
                        elseif count == 3
                            queue3 = [queue3, newNodeIndex];
                        elseif count == 4
                            queue4 = [queue4, newNodeIndex];
                        end
                    else
                        queue1 = [queue1, newNodeIndex];
                    end
                end
                if q == 1
                    queue1(1) = [];
                elseif q == 2
                    queue2(1) = [];
                elseif q==3
                    queue3(1) = [];
                elseif q==4
                    queue4(1) = [];
                end
            end
            
            %--------might or might not increase efficiency---------
            if isempty(outedges(obj.Graph,s)) && ~obj.isEndNode(s)   %if it's a dead end and not an end node
               obj.stripBranch(s)
            end
            %-------------------------------------------------------
       end
       
       function [nextLot, nextFocusCar] = Transition(obj, state, action)
            stateLot = obj.States(state);
            focusCar = obj.FocusCars(state);
            nextLot = stateLot;
            nextFocusCar = focusCar;
            
            [rows, cols] = find(stateLot==focusCar);
            if obj.isVert(focusCar, stateLot)
                if action == "u"
                    carInDir = obj.carInDir(focusCar, action, stateLot);
                    if carInDir == 0
                        nextLot(rows(1)-1,cols(1))=focusCar;
                        nextLot(rows(end),cols(1))=0;
                        nextFocusCar = obj.targetCar;
                    elseif ~isnan(carInDir)
                       nextFocusCar = carInDir;
                    elseif isnan(carInDir) && focusCar == obj.targetCar
                        nextLot(nextLot==focusCar) = 0;
                    end
                elseif action == "d"
                    carInDir = obj.carInDir(focusCar, action, stateLot);
                    if carInDir == 0
                        nextLot(rows(end)+1,cols(1))=focusCar;
                        nextLot(rows(1),cols(1))=0;
                        nextFocusCar = obj.targetCar;
                    elseif ~isnan(carInDir)
                       nextFocusCar = carInDir;
                    elseif isnan(carInDir) && focusCar == obj.targetCar
                        nextLot(nextLot==focusCar) = 0;
                    end
                end
            else
                if action == "l"
                    carInDir = obj.carInDir(focusCar, action, stateLot);
                    if carInDir == 0
                        nextLot(rows(1),cols(1)-1)=focusCar;
                        nextLot(rows(1),cols(end))=0;
                        nextFocusCar = obj.targetCar;
                    elseif ~isnan(carInDir)
                       nextFocusCar = carInDir;
                    elseif isnan(carInDir) && focusCar == obj.targetCar
                        nextLot(nextLot==focusCar) = 0;
                    end
                elseif action == "r"
                    carInDir = obj.carInDir(focusCar, action, stateLot);
                    if carInDir == 0
                        nextLot(rows(1),cols(end)+1)=focusCar;
                        nextLot(rows(1),cols(1))=0;
                        nextFocusCar = obj.targetCar;
                    elseif ~isnan(carInDir)
                       nextFocusCar = carInDir;
                    elseif isnan(carInDir) && focusCar == obj.targetCar
                        nextLot(nextLot==focusCar) = 0;
                    end
                end
            end
            if all(all(nextLot == stateLot)) && focusCar == nextFocusCar
               nextLot = NaN;
               nextFocusCar = NaN;
            end
       end
       
       function reward = Reward(obj, lot, focusCar, nextLot, nextFocusCar)
           reward = 0;
           if focusCar ~= nextFocusCar
              reward = reward + 0.2; 
           end
           if any(any(lot~=nextLot))
                if obj.clearanceCars(lot) ~= obj.clearanceCars(nextLot)
                    reward = reward + 1;
                else
                    reward = reward + 0.5;
                end
           end
       end
       
       function bool = isEndNode(obj, s)
           bool = false;
           if ~any(any(obj.States(s)==obj.targetCar))
               bool = true;
           end
       end
       
       %--------might or might not increase efficiency---------
        function stripBranch(obj, s)
            return
            if numnodes(obj.Graph)>1
                if isempty(outedges(obj.Graph,s)) && ~obj.isEndNode(s)
                    preIDs = predecessors(obj.Graph,s);
                    obj.Graph = rmnode(obj.Graph,s);
                    for preID = preIDs
                        obj.stripBranch(preID)
                    end
                else
                    return
                end
            end
        end
       
        function instructions = getInstructions(obj, endNode)                    %converts path to direction. e.g if node 1 and 3 are connected and
           instructions = endNode+": ";                                               %the difference between their states is car 5 moving north-west, an instruction is passed "5,nw"
           run = true;
           while run
               startNodes = predecessors(obj.Graph, endNode);
               startNode = startNodes(1);
               if startNode == 1    %if it is the very first node
                  run = false;
               end
               endLot = obj.States(endNode);
               startLot = obj.States(startNode);
               if all(all(startLot==endLot))              %we only care about when a car moves, not when we shift focus to moving another car
                   endNode = startNode;
                   continue
               end
               difference = startLot~=endLot;
               
               [rows, cols] = find(difference==1);
               if all(rows == rows(1))                                     %if both states' cars are horizontal
                   if endLot(rows(1), max(cols))==obj.FocusCars(startNode) || endLot(rows(1), min(cols))==0     %if car moved forward. there is a difference at (row(1), max(cols)), so if at the end state, the car is present at that index, then it must have travelled forward to there. same backwards(if a space is present at the index(row(1), min(cols))).
                       instructions = startNode + ":" + obj.FocusCars(startNode) + ",r" + " " +instructions;
                   elseif endLot(rows(1), max(cols))==0 || endLot(rows(1), min(cols))==obj.FocusCars(startNode)
                       instructions = startNode + ":" + obj.FocusCars(startNode) + ",l" + " " + instructions;
                   end
               elseif all(cols == cols(1))                                 %if both states' cars are vertical
                   if endLot(max(rows), cols(1))==obj.FocusCars(startNode) || endLot(min(rows), cols(1))==0     %same logic as above
                       instructions = startNode + ":" + obj.FocusCars(startNode) + ",d" + " " + instructions;
                   elseif endLot(max(rows), cols(1))==0 || endLot(min(rows), cols(1))==obj.FocusCars(startNode)
                       instructions = startNode + ":" + obj.FocusCars(startNode) + ",u" + " " + instructions;
                   end
               end
               endNode = startNode;
            end
        end
        
        
       %-------------------------------------------------------
       
       function clearance = clearanceCars(obj, lot)
           clearance = [lot(1,:), lot(end,:), lot(2:end-1,1)', lot(2:end-1,end)'];
       end
       
       function carIndex = carInDir(obj, car, dir, lot)
           [rows, cols] = find(lot==car);
            try
                if obj.isVert(car,lot)
                    if dir=="u"
                        carIndex=lot(rows(1)-1, cols(1));  
                    elseif dir=="d"                                 
                        carIndex=lot(rows(end)+1, cols(1));
                    end
                else
                    if dir=="r"
                        carIndex=lot(rows(1), cols(end)+1);
                    elseif dir=="l"
                        carIndex=lot(rows(1), cols(1)-1);
                    end
                end
            catch ME
                if (strcmp(ME.identifier,'MATLAB:badsubscript'))
                    carIndex=NaN;
                else
                    rethrow(ME)
                end
            end
       end
       
       function bool = isVert(obj, car, lot)
           [~, cols] = find(lot==car);
            if all(cols==cols(1))
                bool = true;
            else
                bool = false;
            end
       end
       
       function showLot(obj, s, focusCar)
           if size(s) == 1
                parkingLot = obj.States(s);
                focusCar = obj.FocusCars(s);
           elseif nargin == 3
                parkingLot = s;
           else
              error('not enough input arguments') 
           end
           lotSize = size(parkingLot); 
           
            maxVal=max(max(parkingLot));      %same as number of cars in the parking lot
            image=zeros(lotSize(1), lotSize(2), 3);
            for i = 1:3     %convert to black and white, each car a different shade of gray. no car is completely white, none is completely black.
                image(:,:,i)=((parkingLot/maxVal)*150)+55;    
            end
            spaces=(parkingLot==0)*255;
            image=image+spaces;


            [carRows, carCols] = find(parkingLot==obj.targetCar);
            if ~isempty(carRows)        %if the target car is still in the parkingLot
                for i = 1:1:size(carRows, 1)
                    image(carRows(i), carCols(i), :)=0;
                    image(carRows(i), carCols(i), 2)=255;
                end
            end

            if focusCar~=obj.targetCar
                [carRows, carCols] = find(parkingLot==focusCar);
                for i = 1:size(carRows, 1)
                    image(carRows(i), carCols(i), :)=0;
                    image(carRows(i), carCols(i), 1)=150;
                end
            end

            figure(1)
            image=uint8(image);
            image=imresize(image, 50, "nearest");
            imshow(image)
            return
       end
        
       function performMoves(obj, moveset)
           if nargin <2
              moveset = obj.solutions; 
           end
            for moves = moveset
                pause(0.5)
                obj.showLot(zeros(size(obj.Lot)), 1)
                pause(0.5)
                steps = split(moves, " ")';
                steps(end) = [];
                for s = steps
                   pause(0.5)
                   temp = split(s, ":");
                   node = str2double(temp(1));
                   lot = obj.States(node);
                   car = obj.FocusCars(node);
                   obj.showLot(lot, car)
                end
            end
       end
        
        function bestDir = bestDirection(obj, carID, parkingLot, directions)
            if obj.isVert(carID, parkingLot)
                indices=ismember(directions, ["r", "l"]);
                directions(indices)=[]; %since no turns, if horizontal, you can't move north or south        
            else
                indices=ismember(directions, ["u", "d"]);
                directions(indices)=[]; %since no turns, if horizontal, you can't move north or south        
            end
            
            if isempty(directions)
               bestDir = "";
               return
            end

            lotSize = size(parkingLot);
            [carRows, carCols] = find(parkingLot==carID);
            obstructingCars=zeros(size(directions));
            distToExit=zeros(size(directions));
            immediateSpaces=zeros(size(directions));
            generalDirSpaces=zeros(size(directions));
            for i = 1:length(directions)
                dir=directions(i);
                if dir=="u"
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
                elseif dir == "d"
                    generalDir = parkingLot(carRows(end):lotSize(1), :);
                    generalDirSpaces(i)=sum(sum(generalDir==0));
                    for j = carRows(end):1:lotSize(1)
                        if parkingLot(j,carCols(1))~=0
                            obstructingCars(i)=obstructingCars(i)+1;
                        elseif parkingLot(j,carCols(1))==0 && obstructingCars(i)==1     %how many spaces immediately next to car
                            immediateSpaces(i)=immediateSpaces(i)+1;
                        end
                        distToExit(i)=distToExit(i)+1;
                    end
                elseif dir=="r"
                    generalDir = parkingLot(:, carCols(end):lotSize(2));
                    generalDirSpaces(i)=sum(sum(generalDir==0));
                    for j = carCols(end):1:lotSize(2)
                        if parkingLot(carRows(1),j)~=0
                            obstructingCars(i)=obstructingCars(i)+1;
                        elseif parkingLot(carRows(1),j)==0 && obstructingCars(i)==1     %how many spaces immediately next to car
                            immediateSpaces(i)=immediateSpaces(i)+1;
                        end
                        distToExit(i)=distToExit(i)+1;
                    end
                elseif dir=="l"
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
                maxGenDirSpaces=minCars(1);
                for i=minCars
                   if generalDirSpaces(i)>generalDirSpaces(maxGenDirSpaces)
                       maxGenDirSpaces=i;
                   elseif generalDirSpaces(i)>generalDirSpaces(maxGenDirSpaces) && i~=maxGenDirSpaces
                       maxGenDirSpaces=[maxGenDirSpaces, i];
                   end
                end
                if length(maxGenDirSpaces)==1
                    bestDir=directions(maxGenDirSpaces);
                else
                    minDist = maxGenDirSpaces(1);
                    for i = maxGenDirSpaces
                       if distToExit(i)<distToExit(minDist)
                           minDist=i;
                       elseif distToExit(i)==distToExit(minDist) && i~=minDist  %if the distance to exit is the same and you are not comparing the same element to itself
                           minDist=[minDist, i];
                       end
                    end
                    if length(minDist)==1
                        bestDir=directions(minDist);
                    else                                %if the distance to exit is the same, compare number of spaces right next to the car in the directions
                        minImSpaces = minDist(1);
                        for i = minDist
                           if immediateSpaces(i)>immediateSpaces(minImSpaces)
                               minImSpaces=i;
                           end
                        end
                        bestDir=directions(minImSpaces(1));
                    end
                end
            end
            return
        end
        
        function addInverse(obj, lot, focusCar, node)
            temp = mat2str(lot);
            key = strrep(temp," "+int2str(focusCar)+ " "," " + focusCar+"f ");
            obj.inverseState(key) = node;
        end
        
        function bool = stateExists(obj, lot, focusCar)
            temp = mat2str(lot);
            key = strrep(temp," "+int2str(focusCar)+ " "," " + focusCar+"f ");
            bool = isKey(obj.inverseState,key);
        end

   end
   
end