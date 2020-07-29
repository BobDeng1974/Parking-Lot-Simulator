classdef ParkingLot < handle
   properties
       Lot
       targetCar
       Graph
       States
       distance
       FocusCars
       inverseState
       ActionSet
       heuristic
       k1
       k2
       k3
       k4
       solutions
       
       c1
       c2
       c3
       c4
       
       queue1
       queue2
       queue3
       queue4
       
       debug
   end
   
   methods
       function obj = ParkingLot(lot, heuristic, debug)
           if nargin<3
               obj.debug = false;
               if nargin <2
                   obj.heuristic = true;
               end
           else
               obj.debug = debug;
           end
               
           if all(size(lot) ==  [1,2])
               obj.Lot = generateParkingLot(lot(1),lot(2));
           else
               obj.Lot = lot;
           end
           obj.heuristic = heuristic;
           obj.Graph = digraph();
           obj.States = containers.Map('KeyType','double','ValueType','any');
           obj.FocusCars = containers.Map('KeyType','double','ValueType','double');
           obj.inverseState = containers.Map('KeyType','char','ValueType','double');
           obj.ActionSet = ["u","d","l","r"];
           obj.c1 = 0.1;
           obj.c2 = 0.3;
           obj.c3 = 1.5;
           obj.c4 = 0.9;
           
           obj.k1 = 2.5;
           obj.k2 = 2.5;
           obj.k3 = 1;
           obj.k4 = 0.5;
       end
       
       function initialise(obj)
           obj.Graph = digraph();
           obj.States = containers.Map('KeyType','double','ValueType','any');
           obj.FocusCars = containers.Map('KeyType','double','ValueType','double');
           obj.inverseState = containers.Map('KeyType','char','ValueType','double');
           
           s = 1;
           obj.Graph = addnode(obj.Graph, s);
           obj.States(s) = obj.Lot;
           obj.FocusCars(s) = obj.targetCar;
           obj.addState2node(obj.States(s),obj.FocusCars(s),s);
           obj.distance(s) = 0;
           
           %Bredth-first search priority queues
           obj.queue1 = s;
           obj.queue2 = [];
           obj.queue3 = [];
           obj.queue4 = [];
       end
       
       function solutions = depart(obj, targetCar)
           obj.targetCar = targetCar;
           solutions = [];
           obj.initialise()
           
           shortestDist = inf;  %shortest distance to an end node
           while ~isempty([obj.queue1,obj.queue2,obj.queue3,obj.queue4])
               [s, currentQ] = obj.pickFromQueue();
               stateLot = obj.States(s);
               focusCar = obj.FocusCars(s);
               currentDist = obj.distance(s);
               
               if obj.debug
                  obj.showLot(s) 
               end
           
               if obj.isVert(focusCar,stateLot)
                   actionSet = ["u","d"];
               else
                   actionSet = ["l","r"];
               end
               
               scores = obj.actionScores(focusCar, stateLot, actionSet);
               [~,queueOrder] = sort(scores,'descend');
               
               
               for i = 1:length(actionSet)
                   action = actionSet(i);
                   score = scores(i);
                   
                   [newLot, newFocusCar] = obj.Transition(s,action);
                   
                   if all(all(isnan(newLot)))
                      continue 
                   end
                   cost = obj.Cost(stateLot,focusCar, newLot);
                   newDist = currentDist + cost;
                   if newDist > shortestDist || obj.stateExists(newLot, newFocusCar)
                       continue
                   end
                   
                   %Adding new arc (edge)
                   newNodeIndex = numnodes(obj.Graph)+1;
                   obj.Graph = addedge(obj.Graph, s, newNodeIndex, cost);
                   obj.States(newNodeIndex) = newLot;
                   obj.FocusCars(newNodeIndex) = newFocusCar;
                   obj.addState2node(newLot,newFocusCar,newNodeIndex);
                   obj.distance(newNodeIndex) = newDist;
                   
                   if obj.isEndNode(newNodeIndex)
                       if newDist<shortestDist
                           shortestDist = newDist;
                           solutions = obj.getInstructions(s);
                       else
                           solutions = [solutions, obj.getInstructions(s)];
                       end
                       continue
                   end
                   if obj.heuristic
                       addQ = find(queueOrder==i);
                   else
                       addQ=1;
                   end
                   obj.addToQueue(newNodeIndex,addQ)
               end
               obj.pullFromQueue(currentQ)  %remove first element from queue
           end
           
       end
       
       function [nextLot, nextFocusCar] = Transition(obj, s, action)
           stateLot = obj.States(s);
           focusCar = obj.FocusCars(s);
           nextLot = stateLot;
           nextFocusCar = focusCar;
           
           carInDir = obj.carInDir(focusCar, action, stateLot);
           if isnan(carInDir)
               if focusCar == obj.targetCar
                   nextLot(nextLot==focusCar) = 0;  %target car exits from lot
                   return
               end
               nextLot = NaN;
               nextFocusCar = NaN;
               return
           elseif carInDir ~= 0
              nextFocusCar = carInDir;
              return
           end
           
           nextFocusCar = obj.targetCar;
           [rows, cols] = find(stateLot==focusCar);
           if action == "u"
               nextLot(rows(1)-1,cols(1)) = focusCar;
               nextLot(rows(end),cols(1)) = 0;
           elseif action == "d"
               nextLot(rows(end)+1,cols(1)) = focusCar;
               nextLot(rows(1),cols(1)) = 0;
           elseif action == "l"
               nextLot(rows(1),cols(1)-1) = focusCar;
               nextLot(rows(1),cols(end)) = 0;
           elseif action == "r"
               nextLot(rows(1),cols(end)+1) = focusCar;
               nextLot(rows(1),cols(1)) = 0;
           end
       end
       
       function cost = Cost(obj,lot,focusCar,newLot)
           cost = 0;
           if any(any(lot ~= newLot))
               if focusCar == obj.targetCar
                   cost = obj.c1;
               else
                  if all([lot(1,:),lot(end,:),lot(:,1)',lot(:,end)'] ~= [newLot(1,:),newLot(end,:),newLot(:,1)',newLot(:,end)'])
                      cost = obj.c3;
                  else
                      cost = obj.c2;
                  end
               end
           else
              cost = obj.c4; 
           end
       end
       
       function setCostVals(obj, costs)
           obj.c1 = costs(1);
           obj.c2 = costs(2);
           obj.c3 = costs(3);
           obj.c4 = costs(4);
       end
       
       function scores = actionScores(obj, car, lot, actionSet)
           actionSetSize = length(actionSet);
           
           numberOfCriteria = 4;
           criteria = zeros(actionSetSize,numberOfCriteria);
           [rows, cols] = find(lot==car);
           for i = 1:length(actionSet)
               action = actionSet(i);
               if action == "u"
                   generalDirSpaces = sum(sum(lot(1:rows(1), :)==0));
                   allInDir = lot(1:rows(1),cols(1))';
                   allInDir(end) = [];    %removing focus car from allInDir
                   distToExit = length(allInDir);
                   obstructingCars = length(unique(allInDir(allInDir~=0)));
                   immediateSpaces = 0;
                   j = length(allInDir);
                   while j > 0 && allInDir(j) == 0
                       immediateSpaces = immediateSpaces + 1;
                       j = j - 1;
                   end
               elseif action == "d"
                   generalDirSpaces = sum(sum(lot(rows(end):end, :)==0));
                   allInDir = lot(rows(end):end,cols(1))';
                   allInDir(1) = [];
                   distToExit = length(allInDir);
                   obstructingCars = length(unique(allInDir(allInDir~=0)));
                   immediateSpaces = 0;
                   j = 1;
                   while j <= length(allInDir) && allInDir(j) == 0
                       immediateSpaces = immediateSpaces + 1;
                       j = j + 1;
                   end
               elseif action == "l"
                   generalDirSpaces = sum(sum(lot(:, 1:cols(1))==0));
                   allInDir = lot(rows(1), 1:cols(1));
                   allInDir(end) = [];
                   distToExit = length(allInDir);
                   obstructingCars = length(unique(allInDir(allInDir~=0)));
                   immediateSpaces = 0;
                   j = length(allInDir);
                   while j > 0 && allInDir(j) == 0
                       immediateSpaces = immediateSpaces + 1;
                       j = j - 1;
                   end
               elseif action == "r"
                   generalDirSpaces = sum(sum(lot(:, cols(end):end)==0));
                   allInDir = lot(rows(1), cols(end):end);
                   allInDir(1) = [];
                   distToExit = length(allInDir);
                   obstructingCars = length(unique(allInDir(allInDir~=0)));
                   immediateSpaces = 0;
                   j = 1;
                   while j <= length(allInDir) && allInDir(j) == 0
                       immediateSpaces = immediateSpaces + 1;
                       j = j + 1;
                   end
               end
               
               criteria(i,1) = generalDirSpaces;    %the number of spaces in general direction of the specified action
               criteria(i,2) = distToExit;          %the linear distance of the car to the exit using the direction of the specified action
               criteria(i,3) = obstructingCars;     %the number of obstructing cars in the direction of the specified action
               criteria(i,4) = immediateSpaces;     %the number of free spaces immediately after the car in the direction of the specified action
           end
           %normalise criteria scores so max value is 1
           for i = 1:size(criteria,2)
               c = criteria(:,i);
               criteria(:,i) = c/max(c);
           end
           criteria(isnan(criteria)) = 0;
           
           maxVal = 1;
           if car ~= obj.targetCar
               criteria(:,2) = 0;   %distance to exit wouldnt matter for moving obstructing cars
           end
           
           %adjust criteria value curve
           criteriaCopy = criteria;
           criteria(:,2) = maxVal.*(1-(criteriaCopy(:,2)/maxVal).^(obj.k2));    %distToExit
           criteria(:,3) = maxVal.*(1-(criteriaCopy(:,3)/maxVal).^(obj.k3));    %obstructingCars
           
           if car ~= obj.targetCar
               criteria(:,2) = 0;   %distance to exit only matters when moving target car
           else
               criteria(:,1) = criteriaCopy(:,1) .* (maxVal*(criteriaCopy(:,2)/maxVal).^(1/obj.k1));    %generalDirSpaces
               criteria(:,4) = criteriaCopy(:,4) .* (maxVal - maxVal*(criteriaCopy(:,2)/maxVal).^(1/obj.k4));    %immediateSpaces. the closer you are to the exit, the less the immediate spaces matter(with a curve)
           end
           
           %adjusting criteria based on importance
           criteria(:,3) = 1.5 .* criteria(:,3);
           criteria(:,2) = 1.3 .* criteria(:,2);
           criteria(:,1) = 0.9 .* criteria(:,1);
           
           %choosing best score
           scores = sum(criteria,2);
       end
       
       function hValTweaks(obj, hVals)
           obj.k1 = hVals(1);
           obj.k2 = hVals(2);
           obj.k3 = hVals(3);
           obj.k4 = hVals(4);
       end
       
       %state-to-node functions
       function addState2node(obj,lot,focusCar,node)
           temp = mat2str(lot);
           key = strrep(temp, " " + int2str(focusCar) + " ", " " + focusCar + "f ");
           obj.inverseState(key) = node;
       end
       
       function node = state2node(obj,lot,focusCar)
           temp = mat2str(lot);
           key = strrep(temp, " " + int2str(focusCar) + " ", " " + focusCar + "f ");
           try
               node = obj.inverseState(key);
           catch ME
               if (strcmp(ME.identifier,'MATLAB:Containers:Map:NoKey'))
                  node = NaN; 
               else
                   rethrow(ME)
               end
           end
       end
       
       function bool = stateExists(obj,lot,focusCar)
           temp = mat2str(lot);
           key = strrep(temp, " " + int2str(focusCar) + " ", " " + focusCar + "f ");
           bool = isKey(obj.inverseState,key);
       end
       
       %Bredth-first search queue management
       function [s,Q] = pickFromQueue(obj)
            if obj.heuristic
                if ~isempty(obj.queue1)
                    s = obj.queue1(1);
                    Q = 1;
                elseif ~isempty(obj.queue2)
                    s = obj.queue2(1);
                    Q = 2;
                elseif ~isempty(obj.queue3)
                    s = obj.queue3(1);
                    Q = 3;
                elseif ~isempty(obj.queue4)
                    s = obj.queue4(1);
                    Q = 4;
                end
            else
                s = obj.queue1(1);
                Q = 1;
            end 
       end
       
       function addToQueue(obj,val,Q)
           if obj.heuristic
               if Q == 1
                   obj.queue1 = [obj.queue1,val];
               elseif Q == 2
                   obj.queue2 = [obj.queue2,val];
               elseif Q == 3
                   obj.queue3 = [obj.queue3,val];
               elseif Q == 4
                   obj.queue4 = [obj.queue4,val];
               end
           else
               obj.queue1 = [obj.queue1,val];
           end
       end
       
       function pullFromQueue(obj,Q)
           if Q == 1
               obj.queue1(1) = [];
           elseif Q == 2
               obj.queue2(1) = [];
           elseif Q==3
               obj.queue3(1) = [];
           elseif Q==4
               obj.queue4(1) = [];
           end
       end
       
       %mini functions
       function instructions = getInstructions(obj, endNode)
           instructions = "";
           
           run = true;
           while run
              startNodes = predecessors(obj.Graph, endNode);
              startNode = startNodes(1);
              if startNode == 1
                  run = false;
              end
              
              startLot = obj.States(startNode);
              endLot = obj.States(endNode);
              if all(all(startLot==endLot))
                  endNode = startNode;
                  continue
              end
              
              difference = startLot ~= endLot;
              
              [rows,cols] = find(difference);
              if all(rows==rows(1))
                  if endLot(rows(1), max(cols))==obj.FocusCars(startNode) || endLot(rows(1), min(cols))==0     %if car moved forward. there is a difference at (row(1), max(cols)), so if at the end state, the car is present at that index, then it must have travelled forward to there. same backwards(if a space is present at the index(row(1), min(cols))).
                      instructions = obj.FocusCars(startNode) + ":r" + "," +instructions;
                  elseif endLot(rows(1), max(cols))==0 || endLot(rows(1), min(cols))==obj.FocusCars(startNode)
                      instructions = obj.FocusCars(startNode) + ":l" + "," +instructions;
                  end
              elseif all(cols==cols(1))
                  if endLot(max(rows), cols(1))==obj.FocusCars(startNode) || endLot(min(rows), cols(1))==0     %same logic as above
                      instructions = obj.FocusCars(startNode) + ":d" + "," +instructions;
                  elseif endLot(max(rows), cols(1))==0 || endLot(min(rows), cols(1))==obj.FocusCars(startNode)
                      instructions = obj.FocusCars(startNode) + ":u" + "," +instructions;
                  end
              end
              endNode = startNode;
           end
       end
       
       function bool = isEndNode(obj,s)
           bool = false;
           if ~any(any(obj.States(s)==obj.targetCar))
               bool = true;
           end
       end
       
       function bool = isVert(obj,car,lot)
           [~,cols] = find(lot==car);
           if all(cols==cols(1))
               bool = true;
           else
               bool = false;
           end
       end
       
       function carIndex = carInDir(obj, car, dir, lot)
           [rows, cols] = find(lot==car);
           try
               if obj.isVert(car,lot)
                   if dir == "u"
                       carIndex = lot(rows(1)-1,cols(1));
                   elseif dir == "d"
                       carIndex = lot(rows(end)+1,cols(1));
                   end
               else
                   if dir == "l"
                       carIndex = lot(rows(1),cols(1)-1);
                   elseif dir == "r"
                       carIndex = lot(rows(1),cols(end)+1);
                   end
               end
           catch ME
              if (strcmp(ME.identifier,'MATLAB:badsubscript'))
                  carIndex = NaN;
              else
                  rethrow(ME)
              end
           end
       end
       
       function showLot(obj,lot,focusCar)
          if size(lot) == 1
             s = lot;
             lot = obj.States(s);
             focusCar = obj.FocusCars(s);
          else
             error("not enough input arguments") 
          end
          
          lotSize = size(lot);
          image = zeros(lotSize(1),lotSize(2),3);
          
          maxVal = max(max(lot));
          for i = 1:3
              image(:,:,i) = ((lot/maxVal)*150)+55;  %all cars black and white between colors (55,55,55) and (150,150,150)
          end
          image(image==55) = 255;    %coloring spaces white
          
          %coloring focus car
          image = image.*(lot ~= focusCar);
          image(:,:,1) = image(:,:,1)+((lot==focusCar)*150);
          
          %coloring target car
          image = image.*(lot ~= obj.targetCar);
          image(:,:,2) = image(:,:,2)+((lot==obj.targetCar)*255);
          
          figure(1)
          image = uint8(image);
          image=imresize(image, 50, "nearest");
          imshow(image)
       end
   end
end