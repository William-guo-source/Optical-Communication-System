clc, clear all;

%% 1. 環境初始化與設定
if ~isempty(instrfind)
    fclose(instrfind); 
    delete(instrfind);
end

% 記得看 COM port 對不對
port = 'Your COM PORT';
% baudrate 需要和 arduino 同步才可以
baudrate = 1000000;  

% 設定數據點數量
targetPoints = 20000;  

% 監控序列埠
s = serial(port, 'BaudRate', baudrate);
s.InputBufferSize = 100000; 
s.Timeout = 1;      
fopen(s);

%% 2. 開始收取數據點
fprintf('開始收點，目標接收 %d 個點...\n', targetPoints);
rawData = uint8(zeros(1, targetPoints)); 

if s.BytesAvailable > 0
    fread(s, s.BytesAvailable); % 清空舊暫存，確保收到的都是最新資料
end

count = 1;
t_start = tic; 

% 當收到指定的數量就停止不收了
while count <= targetPoints
    n = s.BytesAvailable;
    if n > 0
        % 精算還差幾個點就滿，避免最後一次抓太多超過陣列大小
        pointsNeeded = targetPoints - count + 1;
        readSize = min(n, pointsNeeded);
        
        chunk = fread(s, readSize, 'uint8');
        len = length(chunk);
        
        rawData(count : count + len - 1) = chunk;
        count = count + len;
    end
    
    % 🛡️ 安全機制：如果等了超過 5 秒還沒收滿，就強制跳出死結
    if toc(t_start) > 5
        fprintf('⚠️ 接收逾時！Arduino 可能未傳送資料。\n');
        break;
    end
end

actualTime = toc(t_start);
fclose(s); 
delete(s);

% 收點完畢，存到 finalData 中
finalData = rawData(1:count-1);
fprintf('擷取完畢！實際收到 %d 個點，耗時 %.4f 秒\n', length(finalData), actualTime);

%% 3. 警告未收到任何點
if isempty(finalData)
    error('沒有收到任何數據！');
end

%% 4. 數據正規化 (Normalization)
voltage = double(finalData) * (5.0 / 255.0); 
x_axis = 1:length(voltage); 

%% 5. 將數據繪製成可視化圖表
figure('Color', 'w', 'Position', [100, 100, 1000, 400]);
plot(x_axis, voltage, '-o', 'LineWidth', 1.5, 'MarkerSize', 4);
title(sprintf('Demo 2: 數位方波解碼 (擷取 %d 個點)', length(voltage)));
xlabel('取樣點 (Sample Points)');
ylabel('電壓 (Voltage)');
ylim([-0.5 5.5]); 
grid on;
