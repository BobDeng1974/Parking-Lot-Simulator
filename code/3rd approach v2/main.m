lott = [0     0     0     0     0     0     0     0;
     0     3     3     4     4     2     7     0;
     0     0     9     9     0     2     7     0;
     0    14     5     8     8     1     1     0;
     0    14     5     0    10    12     0     0;
     0     0    13    13    10    12    15     0;
     0     6     6     0    11    11    15     0;
     0     0     0     0     0     0     0     0];

lott = [0     0     0     0     0     0     0     0;
     0     3     3     6    13    13    14     0;
     0     5    16     6     9     9    14     0;
     0     5    16    18    18     2     2     0;
     0     4     8     1     1    10     7     0;
     0     4     8    15    12    10     7     0;
     0    17    17    15    12    11    11     0;
     0     0     0     0     0     0     0     0];
 
 lott = [0     0     0     0     0     0     0     0;
     0     0     0    12    14    15    15     0;
     0     0     8    12    14     5     5     0;
     0    2     8     0     7     7    11     0;
     0    2     6     4     4     1    11     0;
     0    0     6    10    10     1     0     0;
     0    0     3     3     0     9     9     0;
     0     0     0     0     0     0     0     0];
 
lott = [0     0     0     0     0     0     0     0;
     0     0     5     0    11    11    16     0;
     0     1     5     9     9     8    16     0;
     0     1     6     6     2     8    12     0;
     0     0     4    14     2     0    12     0;
     0     3     4    14    10    10     7     0;
     0     3    15    15    13    13     7     0;
     0     0     0     0     0     0     0     0];
 
lott = [0     0     0     0     0     0     0     0;
     0     4     9     9    10     0    13     0;
     0     4    15     1    10     5    13     0;
     0     8    15     1     0     5    14     0;
     0     8    11    11     2     6    14     0;
     0     0     3     3     2     6     0     0;
     0     7     7    16    16    12    12     0;
     0     0     0     0     0     0     0     0];

HTime = [];
HNum = [];
Time = [];
Num = [];
for i = 1:50000
    lot = ParkingLotnoPQ([8,8],true);

    tic
    solutions1 = lot.depart(2);
    HNum = [HNum numnodes(lot.Graph)];
    HTime = [HTime toc];

    lot.heuristic = false;
    tic
    solutions2 = lot.depart(2);
    Num = [Num numnodes(lot.Graph)];
    Time = [Time toc];
    disp(i)
    if any(any(size(solutions1) ~= size(solutions2))) || (all(all(size(solutions1) == size(solutions2))) && ~(isempty(solutions1)&&isempty(solutions2)) && all(all(solutions1 ~= solutions2)))
       disp(lot.Lot) 
       disp(solutions1)
       disp(solutions2)
    end
end

[~, idx] = sort(mean([HTime;Time]));
HTime = HTime(idx);
Time = Time(idx);
HNum = HNum(idx);
Num = Num(idx);

N = length(HTime);
x = 1:N;
y = Time-HTime;
subplot(2,2,1)

% Initialize a blue map
colorMap = [zeros(N, 1), zeros(N, 1), ones(N,1)];
% If y > 0, make the markers red.
for k = 1 : length(y)
  if y(k) < 0
    colorMap(k, :) = [1,0,0]; % Red
  else
    colorMap(k, :) = [0,0,1]; % Blue
  end
end
title('x: avg(time, heuristic time) - y: time-heuristic time')
scatter(x,y,24* ones(length(y), 1), colorMap, '.');

N = length(HNum);
x = 1:N;
y = Num-HNum;
subplot(2,2,2)

% Initialize a blue map
colorMap = [zeros(N, 1), zeros(N, 1), ones(N,1)];
% If y > 0, make the markers red.
for k = 1 : length(y)
  if y(k) < 0
    colorMap(k, :) = [1,0,0]; % Red
  else
    colorMap(k, :) = [0,0,1]; % Blue
  end
end
title('x: avg(numnodes, heuristic numnodes) - y: numnodes-heuristic numnodes')
scatter(x,y,24* ones(length(y), 1), colorMap, '.');

%------------------------

N = length(HTime);
x = 1:N;
y = Time./HTime;
subplot(2,2,3)

% Initialize a blue map
colorMap = [zeros(N, 1), zeros(N, 1), ones(N,1)];
% If y > 0, make the markers red.
for k = 1 : length(y)
  if y(k) < 1
    colorMap(k, :) = [1,0,0]; % Red
  else
    colorMap(k, :) = [0,0,1]; % Blue
  end
end
title('x: avg(time, heuristic time) - y: time÷heuristic time')
scatter(x,y,24* ones(length(y), 1), colorMap, '.');

N = length(HNum);
x = 1:N;
y = Num./HNum;
subplot(2,2,4)

% Initialize a blue map
colorMap = [zeros(N, 1), zeros(N, 1), ones(N,1)];
% If y > 0, make the markers red.
for k = 1 : length(y)
  if y(k) < 1
    colorMap(k, :) = [1,0,0]; % Red
  else
    colorMap(k, :) = [0,0,1]; % Blue
  end
end
title('x: avg(numnodes, heuristic numnodes) - y: numnodes÷heuristic numnodes')
scatter(x,y,24* ones(length(y), 1), colorMap, '.');


disp('done')
disp('done')
