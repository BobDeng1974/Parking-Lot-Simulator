function showLot(parkingLot, target, movingCar)      %movingCar is the car we are currently trying to move
                                    %and lookingAt is the car in the way
    
    mainCar=target;     %mainCar is the car we are trying to get out of the lot.
    lotSize = size(parkingLot);
    %--------------------------------setting default values
    if nargin==2
        movingCar = NaN;
    end
    
    maxVal=max(max(parkingLot));      %same as number of cars in the parking lot
    image=zeros(lotSize(1), lotSize(2), 3);
    for i = 1:3     %convert to black and white, each car a different shade of gray. no car is completely white, none is completely black.
        image(:,:,i)=((parkingLot/maxVal)*150)+55;    
    end
    spaces=(parkingLot==0)*255;
    image=image+spaces;
    
    
    [carRows, carCols] = find(parkingLot==mainCar);
    if ~isempty(carRows)        %if the target car is still in the parkingLot
        for i = 1:1:size(carRows, 1)
            row=carRows(i);
            col=carCols(i);
            image(row, col, :)=0;
            image(row, col, 2)=255;
        end
    end
    
    if ~isnan(movingCar)
        carCount=length(movingCar);
        shades=linspace(100,150,carCount);
        for carIndex = 1:length(movingCar)
            car=movingCar(carIndex);
            if car ~= target
                [carRows, carCols] = find(parkingLot==car);
                for i = 1:size(carRows, 1)
                    row=carRows(i);
                    col=carCols(i);
                    image(row, col, :)=0;
                    image(row, col, 1)=uint8(shades(carIndex));
                end
            end
        end
    end
        
    figure(1)
    image=uint8(image);
    image=imresize(image, 50, "nearest");
    imshow(image)
    return
end