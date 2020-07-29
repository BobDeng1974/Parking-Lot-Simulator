car = 2;
range = linspace(-100,100,400);
AllPerfs = [];
kVals = [];

numLots = 5;
lots = cell2mat(struct2cell(load("lots_car_2_solved_in_4-10s.mat")));
lots = lots(:,:,1:numLots);

k4AllPerfs = [];
f = waitbar(0,"Starting");
g = waitbar(0,"k values: 0,0,0,0");
for k1 = range
   for k2 = range
      for k3 = range
         for k4 = range
             kstring = "k values: " + round(k1,2) + ", " + round(k2,2) + ", " + round(k3,2) +", " + round(k4,2);
             rangeLength = length(range);
             waitbar(find(range==k1)*find(range==k2)*find(range==k3)*find(range==k4)/rangeLength.^4,f,"in progress...")
             kValsPerf = [];
             waitbar(0,f)
             
             for i = 1:numLots
                 waitbar(i/numLots,g,kstring)
                 lot = ParkingLotnoPQ(lots(:,:,i),false, false);
                 tic
                 lot.depart(car);
                 time = toc;
                 lot.heuristic = true;
                 lot.hValTweaks([k1,k2,k3,k4])
                 lot.initialise()
                 tic
                 lot.depart(car);
                 kValsPerf = [kValsPerf, time/toc];
             end
             k4Perfs = [k4AllPerfs, mean(kValsPerf)];
             AllPerfs = [k4AllPerfs, mean(kValsPerf)];             
             kVals = [kVals, k1+","+k2+","+k3+","+k4+","];                     
         end
         plot(range,k4Perfs)
      end
   end

end
bestvalsidx = max(AllPerfs);
save("bestkvals",kVals(bestvalsidx))
