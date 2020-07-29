function showLot(s)
    parkingLot = obj.States(s);
    focusCar = obj.FocusCars(s);
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