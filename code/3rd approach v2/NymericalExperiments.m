dk1 = 2.5;
dk2 = 2.5;
dk3 = 1;
dk4 = 0.5;
for j = 1:10
    car = 5;
    range = -10:0.1:10;
    Allk1ValsPerf = [];
    Allk2ValsPerf = [];
    Allk3ValsPerf = [];
    Allk4ValsPerf = [];
    perf = [];
    for i = 1:50
       k1ValsPerf = [];
       k2ValsPerf = [];
       k3ValsPerf = [];
       k4ValsPerf = [];
       lot = ParkingLotnoPQ([6,6],false, false);
       tic
       lot.depart(car);
       thisPerf = toc;
       perf = [perf, thisPerf];
       lot.heuristic = true;
       disp('k1')
       for k1 = range
          lot.hValTweaks([k1,dk2,dk3,dk4])
          lot.initialise()
          tic
          lot.depart(car);
          k1ValsPerf = [k1ValsPerf, toc];
       end
       disp('k2')
       for k2 = range
          lot.hValTweaks([dk1,k2,dk3,dk4])
          lot.initialise()
          tic
          lot.depart(car); 
          k2ValsPerf = [k2ValsPerf, toc];
       end
       disp('k3')
       for k3 = range
          lot.hValTweaks([dk1,dk2,k3,dk4])
          lot.initialise()
          tic
          lot.depart(car);
          k3ValsPerf = [k3ValsPerf, toc];
       end
       disp('k4')
       for k4 = range
          lot.hValTweaks([dk1,dk2,dk3,k4])
          lot.initialise()
          tic
          lot.depart(car);
          k4ValsPerf = [k4ValsPerf, toc];
       end
       k1ValsPerf = thisPerf./k1ValsPerf;
       k2ValsPerf = thisPerf./k2ValsPerf;
       k3ValsPerf = thisPerf./k3ValsPerf;
       k4ValsPerf = thisPerf./k4ValsPerf;
       subplot(2,2,1)
       plot(range,k1ValsPerf)
       subplot(2,2,2)
       plot(range,k2ValsPerf)
       subplot(2,2,3)
       plot(range,k3ValsPerf)
       subplot(2,2,4)
       plot(range,k4ValsPerf)

       Allk1ValsPerf = [Allk1ValsPerf, k1ValsPerf];
       Allk2ValsPerf = [Allk2ValsPerf, k2ValsPerf];
       Allk3ValsPerf = [Allk3ValsPerf, k3ValsPerf];
       Allk4ValsPerf = [Allk4ValsPerf, k4ValsPerf];
    end
    save("experiment"+j+".mat",'range','Allk1ValsPerf','Allk2ValsPerf','Allk3ValsPerf','Allk4ValsPerf')
    [~, idx] = max(mean(Allk1ValsPerf,1));
    dk1 = range(idx);
    [~, idx] = max(mean(Allk2ValsPerf,1));
    dk2 = range(idx);
    [~, idx] = max(mean(Allk3ValsPerf,1));
    dk3 = range(idx);
    [~, idx] = max(mean(Allk4ValsPerf,1));
    dk4 = range(idx);
end
disp('k1 = ' + dk1)
disp('k2 = ' + dk2)
disp('k3 = ' + dk3)
disp('k4 = ' + dk4)