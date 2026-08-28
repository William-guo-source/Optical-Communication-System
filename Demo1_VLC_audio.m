%% 環境初始化
clc, clear all;

% 使用新版建議的清除方式
if ~isempty(instrfind)
    fclose(instrfind);
    delete(instrfind);
end

%% 1. 記得看 COM port 對不對、還有我們和助教 arduino 設的鮑率有沒有對上
port = 'COM4';      
baudrate = 1000000;  
duration = 70;       % 預期錄音秒數

% 建立序列埠物件
s = serial(port, 'BaudRate', baudrate);
% ⚠️ 重要優化：錄音長達 35 秒，緩衝區必須加大到 100 萬，以避免爆掉！
s.InputBufferSize = 1000000; 
s.Timeout = 1;      % 設定逾時避免程式死鎖
fopen(s);

%% 2. 手動觸發錄音
fprintf('=== 接收端 Arduino 錄音系統 (除噪版) ===\n');
fprintf('1. 設定錄音時長: %d 秒\n', duration);
input('>> 請先點擊播放音樂，隨即按下 [Enter] 開始錄音：', 's');

%% 3. 開始擷取數據 (使用高效能讀取)
fprintf('錄音中...\n');

% 預分配一個足夠大的空間，避免在迴圈內動態調整矩陣大小 (耗時)
estimatedMaxPoints = duration * 15000; % 稍微抓寬鬆一點
rawData = uint8(zeros(1, estimatedMaxPoints)); 

% 清空開啟連線後到按下 Enter 前產生的舊緩存
if s.BytesAvailable > 0
    fread(s, s.BytesAvailable); 
end

count = 1;
t_start = tic; 

while toc(t_start) < duration
    n = s.BytesAvailable;
    if n > 0
        % 讀取目前緩衝區所有內容
        chunk = fread(s, n, 'uint8');
        len = length(chunk);
        
        % 檢查是否會超過預分配空間，若超過則動態擴張（保險機制）
        if count + len - 1 > length(rawData)
            rawData = [rawData, zeros(1, 50000, 'uint8')]; % 增加空間
        end
        
        % 把讀取到的值丟進去 rawData，並增加 count 長度
        rawData(count : count + len - 1) = chunk;
        count = count + len;
    end
    % 微量暫停，讓 CPU 休息並給 Serial 機會填寫 Buffer
    pause(0.01); 
end
actualTime = toc(t_start);

% 立即關閉序列埠，釋放硬體資源
fclose(s);
delete(s);

% 有效數據
finalData = rawData(1:count-1);
fprintf('錄音結束！\n實際擷取點數: %d\n實際錄音時間: %.3f 秒\n', length(finalData), actualTime);

%% 4. 訊號處理與修正播放
if isempty(finalData)
    error('Error：未接收到數據。請檢查 Arduino 是否正常傳送 Serial.write。');
end

% A. 轉換與去除直流偏壓
y = double(finalData);
y = (y - mean(y)) / 128; 

% B. 計算實際採樣率
actualFs = length(y) / actualTime; 
fprintf('計算得出的實際採樣率 (Fs): %.2f Hz\n', actualFs);

% C1. 🚀 數位帶通濾波器 (Band-Pass Filter)
fprintf('正在進行數位濾波除噪...\n');
% 保留人聲黃金頻段 (300Hz ~ 3000Hz)，砍掉低頻市電 60Hz or 120Hz 嗡嗡聲與高頻沙沙聲
low_cutoff_freq = 150;  
high_cutoff_freq = 4000; 
if high_cutoff_freq < (actualFs / 2)
    Wn = [low_cutoff_freq, high_cutoff_freq] / (actualFs / 2);
    [b, a] = butter(6, Wn, 'bandpass'); 
    y = filtfilt(b, a, y); 
end

% D. 🚀 終極魔法：軟體正規化 + 噪音閘門 (Noise Gate)
 max_val = max(abs(y));
 % 設定一個噪音門檻 (例如 0.05 代表 5% 的音量)
 noise_threshold = 0.05; 
 if max_val > noise_threshold
     % 如果最大音量超過門檻，代表有放音樂，我們才把它等比例放大
     y = y / max_val;
 else
     % 如果最大音量不到門檻，代表現在根本沒放音樂 (全是 127, 128 附近的底噪)
     % 直接無情地把整段陣列變成 0，強制靜音！
     y = zeros(size(y));
     fprintf('🤫 偵測到無音樂狀態，已啟動噪音門強制靜音。\n');
 end

%% 5. 視覺化 (雙圖表：時間波形 + 頻譜)
figure('Color', 'w', 'Position', [100, 100, 1000, 450]);

% 子圖 1：時間域波形 (看音樂形狀)
subplot(1,2,1);
t_axis = (0:(length(y)-1)) / actualFs; 
plot(t_axis, y, 'Color', [0 0.447 0.741]);
title('Arduino 擷取波形 (已濾波除噪)');
xlabel('時間 (s)');
ylabel('振幅 (Amplitude)');
grid on;
ylim([-1.1 1.1]);

% 子圖 2：🚀 頻譜圖 快速傅立葉轉換 FFT (抓出雜訊真兇)
subplot(1,2,2);
N = length(y);
Y_fft = abs(fft(y));
fprintf('超尖頻率: %d \n', max(Y_fft));
f_axis = (0:N-1)*(actualFs/N);
plot(f_axis(1:floor(N/2)), Y_fft(1:floor(N/2)), 'Color', [0.850 0.325 0.098]);
title('頻譜圖 (尋找異常尖刺)');
xlabel('頻率 (Hz)');
ylabel('能量 (Amplitude)');
% 只顯示 0 ~ 4000Hz 的範圍，方便觀察
xlim([0 4000]);
grid on;

%% 6. 檔案輸出
fprintf('正在準備輸出音訊檔...\n');
try
    % 輸出 WAV 檔，維持使用 11025 Hz 的音效卡撥音標準頻率，避免播放器錯誤
    audiowrite('./Capston/VLC_Demo1_Audio_Filtered.wav', y, round(actualFs));
    fprintf('✅ 濾波後的音訊已存檔為 VLC_Demo1_Audio_Filtered.wav\n');
catch ME
    fprintf('⚠️ 檔案存取失敗: %s\n', ME.message);
end