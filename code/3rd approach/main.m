lott = generateParkingLot(7, 7, 80)

tic
lot = ParkingLot(lott, 2,2,80,2, true, true);
lot.generateGraph(1)
disp(lot.solutions)
toc



tic
lot = ParkingLot(lott, 7,7,80,2, false, true);
lot.generateGraph(1)
disp(lot.solutions)
toc