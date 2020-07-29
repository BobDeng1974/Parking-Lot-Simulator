close all
lot = ParkingLot(7,7, 80, true);

targetCar = randi([1,max(max(lot.Lot))]);
disp(targetCar)
moveSet=lot.Depart(targetCar,1);
close all
disp(moveSet)
for moves = moveSet
    lot.performMoves(moves, targetCar);
    close all
end



