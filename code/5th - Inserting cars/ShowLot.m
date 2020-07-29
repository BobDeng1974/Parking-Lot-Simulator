function ShowLot(lot,focusCar,targetCar)
      if nargin <3
         targetCar = focusCar; 
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
      image = image.*(lot ~= targetCar);
      image(:,:,2) = image(:,:,2)+((lot==targetCar)*255);

      figure(1)
      image = uint8(image);
      image=imresize(image, 40, "nearest");
      imshow(image)
   end