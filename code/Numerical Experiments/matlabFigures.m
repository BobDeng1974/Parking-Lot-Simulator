open '10343 data points.fig'



save('testData10343points',)
D=get(gca,'Children'); %get the handle of the line object
XData=get(D,'XData'); %get the x data
YData=get(D,'YData');

N = length(XData);
% Initialize a blue map
colorMap = [zeros(N, 1), zeros(N, 1), ones(N,1)];
% If y > 0, make the markers red.
count = 0;
for k = 1 : length(YData)
  if YData(k) <= 1
    colorMap(k, :) = [1,0,0]; % Red
  else
    colorMap(k, :) = [0,0,1]; % Blue
    count = count + 1;
  end
end
figure(2)
scatter(XData,1./YData,24* ones(length(YData), 1), colorMap, '.');
disp(count)

scatter(XData,YData)
disp(mean(XData))
disp(u.position)