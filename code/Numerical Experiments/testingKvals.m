car = 2;
range = linspace(0,2,100);
AllPerfs = [];
kVals = [];

numLots = 1;
lots = cell2mat(struct2cell(load("lots_car_2_solved_in_10-30s.mat")));
%lots = lots(:,:,1:numLots);

lot = ParkingLot(lots(:,:,5), true);
lot.hValTweaks([10,0,0,0])
lot.depart(2);
disp(numnodes(lot.Graph));
 

k4AllPerfs = [];
f = waitbar(0,"Starting");
g = waitbar(0,"k values: 0,0,0,0");
for k1 = 0
   for k2 = 0
      for k3 = 0
         for k4 = range
             kstring = "k values: " + round(k1,2) + ", " + round(k2,2) + ", " + round(k3,2) +", " + round(k4,2);
             rangeLength = length(range);
             waitbar(1/rangeLength.^4,f,"in progress...")
             kValsPerf = [];
             waitbar(0,f)
             lot.hValTweaks([k1,k2,k3,k4])
             for i = 1:numLots
                 waitbar(i/numLots,g,kstring)
                 %lot = ParkingLot(lots(:,:,i),false, false);
                 lot.heuristic = false;
                 lot.depart(car);
                 Perf = numnodes(lot.Graph)
                 
                 lot.heuristic = true;
                 lot.depart(car);
                 HPerf = numnodes(lot.Graph)
                 kValsPerf = [kValsPerf, Perf/HPerf];
             end
             AllPerfs = [AllPerfs, mean(kValsPerf)];             
             kVals = [kVals, k1+","+k2+","+k3+","+k4+","];
            plot(AllPerfs)
         end
      end
   end

end
bestvalsidx = max(AllPerfs);
