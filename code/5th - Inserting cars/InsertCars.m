function lot = InsertCars(lot,departTimes,debug)
    global States State2Node Graph BestCost CarList OrderedCarList DepartureTimes CumulativeCost
    inputLength = length(lot);
    if inputLength==2
        startLot = zeros(lot(1)+2,lot(2)+2);
    else
        startLot = lot;
    end
    
    if length(departTimes)>(size(startLot,1)*size(startLot,2))/2
        error('number of cars above maximum capacity for lot size')
    end
    
    States = containers.Map('KeyType','double','ValueType','any');
    State2Node = containers.Map('KeyType','char','ValueType','any');
    CumulativeCost = containers.Map('KeyType','double','ValueType','double');
    DepartureTimes = containers.Map('KeyType','char','ValueType','any');
    States(1) = startLot;
    State2Node(mat2str(startLot)) = 1;
    CumulativeCost(1) = 0;
    Graph = digraph();
    CarList = 1:length(departTimes);
    [~,idx] = sort(departTimes);
    OrderedCarList = CarList(idx);
    
    BestCost = inf;
    node = 1;
    carIdx = 1;
    lot = insertRecursive(node,carIdx);
end

function bestEndLot = insertRecursive(node,carIdx)
    global Graph States State2Node CarList OrderedCarList BestCost CumulativeCost
    adjStates = adjacentStates(States(node),CarList(carIdx));
    if isempty(adjStates)
       return 
    end
    
    for i = 1:size(adjStates,3)
       adjLot = adjStates(:,:,i);
       if haveVisited(adjLot)
          return 
       end
       
       %add adjacent node connection
       newNodeIdx = numnodes(Graph)+1;
       dTime = departureTime(adjLot,OrderedCarList);
       if isnan(dTime) %if the car cannot depart
           return
       end
       
       newCost = CumulativeCost(node) + dTime;
       if newCost > BestCost   %if this path is not optimal
           return
       end
       
       States(newNodeIdx) = adjLot;
       State2Node(mat2str(newNodeIdx)) = newNodeIdx;
       Graph = addedge(Graph,node, newNodeIdx);
       CumulativeCost(newNodeIdx) = newCost;
       if carIdx+1 <= length(CarList) %if you've not inserted all cars
           insertRecursive(newNodeIdx,carIdx+1); %insert the next car
       elseif newCost < BestCost   
           BestCost = newCost;
           bestEndLot = adjLot;
           disp(bestEndLot)
       end
    end
end

function adjStates = adjacentStates(Lot,car)
    adjStates = [];
    %start queue. indeces of all the places at the outer edges of the
    %parking lot you can come in from.
    startQueue = [];
    lotSize = size(Lot);
    rowVecL = find(Lot(2:end-1,  2  )==0)+1;
    rowVecR = find(Lot(2:end-1,end-1)==0)+1;
    colVecU = find(Lot(  2  ,3:end-2)==0)+2;
    colVecD = find(Lot(end-1,3:end-2)==0)+2;
    startQueue = [startQueue; rowVecL, repelem(      2     ,length(rowVecL))'];
    startQueue = [startQueue; rowVecR, repelem(lotSize(2)-1,length(rowVecR))'];
    startQueue = [startQueue; repelem(      2     ,length(colVecU))', colVecU'];
    startQueue = [startQueue; repelem(lotSize(1)-1,length(colVecD))', colVecD'];
    
    exploreQueue = [];
    Explored = containers.Map('KeyType','char','ValueType','logical');
    
    while ~isempty(startQueue) || ~isempty(exploreQueue)
        if isempty(exploreQueue)
            exploreQueue = [exploreQueue; startQueue(1,:)];
            startQueue(1,:) = [];
        end
        currentCell = exploreQueue(1,:);
        exploreQueue(1,:) = [];
        
        Explored(mat2str(currentCell)) = true;
        
        for i = [-1,1]  %exploring the four adjacent cells to this one
            adjCell1 = [currentCell(1)+i,currentCell(2)];
            adjCell2 = [currentCell(1),currentCell(2)+i];
            
            if (adjCell1(1)>1 && adjCell1(1)<lotSize(1) && adjCell1(2)>1 && adjCell1(2)<lotSize(2)) && (Lot(adjCell1(1),adjCell1(2))==0) && (~isKey(Explored,mat2str(adjCell1))) %if it's not in the clearance zone, it's a free space, and it hasn't already been explored.
                newLot = Lot;
                newLot(currentCell(1),currentCell(2))=car;
                newLot(adjCell1(1),adjCell1(2))=car;
                adjStates = cat(3,adjStates,newLot);
                if ~any(ismember([startQueue;exploreQueue],adjCell1,'rows'))
                   exploreQueue = [exploreQueue;adjCell1]; 
                end
            end
            if (adjCell2(1)>1 && adjCell2(1)<lotSize(1) && adjCell2(2)>1 && adjCell2(2)<lotSize(2)) && (Lot(adjCell2(1),adjCell2(2))==0) && (~isKey(Explored,mat2str(adjCell2)))
                newLot = Lot;
                newLot(currentCell(1),currentCell(2))=car;
                newLot(adjCell2(1),adjCell2(2))=car;
                adjStates = cat(3,adjStates,newLot);
                if ~any(ismember([startQueue;exploreQueue],adjCell2,'rows'))
                    exploreQueue = [exploreQueue;adjCell2];
                end
            end
        end
    end
end

function dTime = departureTime(lot,OcarList)
    global DepartureTimes
    pLot = ParkingLotTurn(lot,true);
    dTime = 0;
    
    for car = OcarList
       if ~ismember(car,lot)
          continue 
       end
       keyString = mat2str(pLot.Lot)+"-"+car;
       if isKey(DepartureTimes,keyString)
           temp = DepartureTimes(keyString);
           anotherTemp = split(temp,"-");
           newLot = str2num(anotherTemp(1));
           time = str2double(anotherTemp(2));
       else
           tic
           newLot = pLot.depart(car);
           time = toc;
           DepartureTimes(keyString) = mat2str(newLot) + "-" + time;
       end
       
       if isnan(newLot) %if car cant depart
           dTime = NaN;
           return
       else
           dTime = dTime + time;
           pLot = ParkingLotTurn(newLot,true);
       end
    end
end

function bool = haveVisited(lot)
    global State2Node
    key = mat2str(lot);
    bool = isKey(State2Node,key);
end