classdef ParkingLot
    properties
        Lot;
        Clearance;
        debug;
        pauseTime;
    end
    
    methods
        function obj = ParkingLot(rows, cols, capacity, debug, pauseTime)
            if nargin < 4
               obj.debug = false; 
            else
                obj.debug = debug;
            end
            if nargin < 5
                obj.pauseTime = 0;
            else
                obj.pauseTime = pauseTime;
            end
            
            obj.Lot = generateParkingLot(rows,cols, capacity);
            
            obj.Clearance = [];
            [nRows, nCols] = size(obj.Lot);
            obj.Clearance = zeros(1,2*nCols+2*(nRows-2));     %This is the maximum size it could be if every clearance space is occupied.
            obj.Clearance(1:nCols) = obj.Lot(1,:);
            obj.Clearance(nCols+1:2*nCols) = obj.Lot(end,:);
            obj.Clearance(2*nCols+1:2*nCols+nRows-2) = obj.Lot(2:end-1,1);
            obj.Clearance(2*nCols+nRows-1:2*nCols+2*(nRows-2)) = obj.Lot(2:end-1,end);
            obj.Clearance=obj.Clearance(obj.Clearance~=0);
            
            if obj.debug
                disp(obj.Lot)
            end
        end
        function instructions = Depart(obj, carID, solutionCount)
            allSolutions = false;
            if nargin<3
                allSolutions = true;
                solutionCount = NaN; 
            elseif solutionCount<1
               error('ERROR: second input argument ''solutionCount'' must be greater than 1') 
            end
            
            solutions = [];
            targetCar = carID;
            
            %Creating graph and adding first state
            Weight = double.empty(0,1);
            CumWeight = 0;
            
            startNodeName = "0";
            Name = startNodeName;                                                      %unique identifies for states
            dontMoveHere = "";
            targetDontMoveHere = "";
            parentState = NaN;
            NodeState = State(carID, obj.Lot, targetCar, parentState, dontMoveHere, targetDontMoveHere);   %list of states of all nodes
            NodeTable = table(Name, NodeState, CumWeight);                            %table of properties of nodes
            EndNodes = string.empty(0,2);
            EdgeTable = table(EndNodes, Weight);                          %list of weights of all edges and culmulative weight
            G = digraph(EdgeTable, NodeTable, 'omitselfloops');
            %for bredth first search (BFS)
            visited=[];
            nextToVisit=[];
            %for solution optimisation
            bestWeight = NaN;
            %adding first node to BFS queue
            nextToVisit=[nextToVisit, Name];
            
            count = 0;      %To-Do this is for debugging. remove
            while ~isempty(nextToVisit)
                count = count + 1;      %To-Do this is for debugging. remove
                nodeName=nextToVisit(1);
                nodeID=findnode(G,nodeName);
                nextToVisit = nextToVisit(2:end);
                if nodeID~=1 && G.Nodes.CumWeight(nodeID)>bestWeight
                   continue
                end
                nodeState = G.Nodes.NodeState(nodeID);
                
                if obj.debug
                    subplot(1,2,1)
                    plot(G)
                    subplot(1,2,2)
                    showLot(nodeState.Lot, nodeState.targetCar, nodeState.carID)
                    pause(obj.pauseTime)
                end
                
                if nodeState.isDestination()
                    if G.Nodes.CumWeight(nodeID) > bestWeight
                       continue
                    end
                    solutionCount = solutionCount+1;
                    solutions(end+1) = nodeID;
                    bestWeight = G.Nodes.CumWeight(nodeID);
                    if length(solutions) == solutionCount && ~allSolutions
                        break
                    end
                    continue
                end
                visited(end+1) = nodeID;
                %add adjacent states to graph and BFS queue (nextToVisit)
                for NodeState = nodeState.adjacent()
                    visitedID = obj.haveVisited(G, NodeState, visited);
                    haveVisited = false;
                    if nodeID~=1 && ~isnan(visitedID)
                        if G.Nodes.CumWeight(visitedID)>G.Nodes.CumWeight(nodeID)   %if the previous ways of getting to this edge has greater weight, remove the leading connections and make the new way of getting there to be the current edge
                            haveVisited = true;
                            [~,nid] = inedges(G,visitedID);
                            for node = nid
                                G = rmedge(G,node,visitedID);
                            end
                        end
                        continue
                    end
                    
                    if haveVisited
                        NodeState = G.Nodes.NodeState(visitedID)
                    else
                        Name = string(numnodes(G));
                    end
                    Weight = nodeState.calcWeight(NodeState);
                    if nodeID == 1       %of it's the very first node
                        parentCumWeight = 0;
                    else
                        parentCumWeight = G.Nodes.CumWeight(nodeID);      
                    end
                    CumWeight = parentCumWeight + Weight;
                    if size(solutions,1)>0 && CumWeight > bestWeight
                       continue
                    end
                    if haveVisited
                        t=visitedID;
                        G.Nodes.CumWeight(visitedID) = CumWeight;
                    else
                        nextToVisit(end+1) = Name;
                        G = addnode(G, table(Name, NodeState, CumWeight));
                        t=findnode(G,Name);
                    end
                    s=nodeID;
                    G = addedge(G, s, t, table(Weight));
                    
                    
                    
                end
            end
            instructions = [];
            if isempty(solutions)
                return
            end
            %finding the best of all found solutions
            weights = zeros(length(solutions),1);
            for i = 1:length(solutions)
                endNode = solutions(i);
                weights(i) = G.Nodes.CumWeight(endNode);
            end
                
            minWeightsIndex = find(weights==min(weights));
            for solIndex = minWeightsIndex
                bestPath = solutions(solIndex);
                instructions = [instructions, obj.getInstructions(G, bestPath)];
            end
            return                                                 
        end
        
        function vID = haveVisited(obj, G, nodeState, visited)
           visited = unique(visited);
           for vID = visited
               vState = G.Nodes.NodeState(vID);
               nodeLot = nodeState.Lot;
               nodeCarID = nodeState.carID;
               vLot = vState.Lot;
               vCarID = vState.carID;
               if nodeCarID==vCarID && all(all(nodeLot==vLot))    %clearance is a subvector derived from the outer edges of the "Lot", so no need to verify that their clearances equal to confirm that they are the same state
                   return
               end
           end
           vID = NaN;
        end
        
        function weight = weightChain(obj, G, nodeID)   %might be useless now because of the edges CumWeight property
            path = shortestpath(G, findnode(G,"0"), nodeID);
            weight = 0;
            
            for i = 1:length(path)-1
                edge = findedge(G, path(i), path(i+1));
                edgeWeight = G.Edges.Weight(edge);
                weight = weight + edgeWeight;
            end
            
        end
        
        function instructions = getInstructions(obj, G, endNode)                    %converts path to direction. e.g if node 1 and 3 are connected and
           instructions = "";                                               %the difference between their states is car 5 moving north-west, an instruction is passed "5,nw"
           run = true;
           while run
               startNode = predecessors(G, endNode);
               if startNode == 1    %if it is the very first node
                  run = false;
               end
               
               endState = G.Nodes.NodeState(endNode);
               startState = G.Nodes.NodeState(startNode);
               if all(all(startState.Lot==endState.Lot))              %we only care about when a car moves, not when we shift focus to moving another car
                   endNode = startNode;
                   continue
               end
               difference = startState.Lot~=endState.Lot;
               
               [rows, cols] = find(difference==1);
               if all(rows == rows(1))                                     %if both states' cars are horizontal
                   if endState.Lot(rows(1), max(cols))==startState.carID || endState.Lot(rows(1), min(cols))==0     %if car moved forward. there is a difference at (row(1), max(cols)), so if at the end state, the car is present at that index, then it must have travelled forward to there. same backwards(if a space is present at the index(row(1), min(cols))).
                       instructions = startState.carID + ",e" + " " +instructions;
                   elseif endState.Lot(rows(1), max(cols))==0 || endState.Lot(rows(1), min(cols))==startState.carID
                       instructions = startState.carID + ",w" + " " + instructions;
                   end
               elseif all(cols == cols(1))                                 %if both states' cars are vertical
                   if endState.Lot(max(rows), cols(1))==startState.carID || endState.Lot(min(rows), cols(1))==0     %same logic as above
                       instructions = startState.carID + ",s" + " " + instructions;
                   elseif endState.Lot(max(rows), cols(1))==0 || endState.Lot(min(rows), cols(1))==startState.carID
                       instructions = startState.carID + ",n" + " " + instructions;
                   end
               else
                  %To-Do for implementing turning 
               end
               endNode = startNode;
            end
        end
        
        function performMoves(obj, moveSet, targetCar)
            carID = NaN;
            parentState = NaN;
            dontMoveHere = "";
            targetDontMoveHere = "";
            state = State(carID, obj.Lot, targetCar, parentState, dontMoveHere, targetDontMoveHere);
            showLot(state.Lot, state.targetCar, state.carID)
            pause(1)
            for moves = moveSet
                steps = split(moves, " ")';
                steps(end) = [];
                for s = steps
                   temp = split(s, ",");
                   car = str2double(temp(1));
                   dir = temp(2);
                   state.carID = car;
                   [~, state.Lot] = state.moveInDir(dir, car);
                   showLot(state.Lot, state.targetCar, state.carID)
                   pause(0.5)
                end
            end
        end
    end
end