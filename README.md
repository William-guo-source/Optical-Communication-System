# 💡 光通訊收發模組 (Optical Transceiver Module)

本專案實作了一套基於可見光通訊 (Visible Light Communication, VLC) 的硬體收發系統。內容涵蓋類比與數位電路設計 (Schematics)、實體電路板焊接、Arduino ADC 超頻取樣設定，以及運用 MATLAB 進行後端數位訊號處理 (DSP) 與波形重建。

## 🔌 硬體電路設計 (Hardware Design)

系統分為發射端 (TX) 與接收端 (RX) 兩部分，採用光電二極體進行光電轉換：
*   **發射端 (TX)：** 負責將類比/數位訊號載入光源。
    *   實體電路：![TX Board](./TX_Board.JPG)
    *   電路原理圖：![TX Schematic](./TX_schematic.png)
*   **接收端 (RX)：** 核心感測元件使用 **BPW-34** 光電二極體 (Photodiode)，搭配放大電路擷取微弱的光訊號。
    *   實體電路：![RX Board](./RX_Board.JPG)
    *   電路原理圖：![RX Schematic](./RX_schematic.png)
    *   感測元件特寫：![BPW-34](./BPW-34.JPG)

## ⏱️ 取樣理論與 ADC 設定 (Sampling Theory & ADC)

為了解決高頻訊號失真問題，本專案對 Arduino 的硬體 ADC 暫存器進行了超頻設定與理論驗證：
*   **ADC 除頻器設定：** 調整 Prescaler Divisor 以提高轉換速率。 ![Divisor Setting](./Divisor.png)
*   **取樣時序分析：** 依據 Datasheet 設定準確的轉換時序。 ![ADC Sampling Timing](./sampling.png)
*   **Nyquist 採樣定理驗證：** 確保系統取樣率 $f_s \ge 2f_{max}$，避免訊號混疊 (Aliasing)。 ![Nyquist Theory](./Nyquist.png)

## ✨ 核心實作展示 (Demos)

### 🎵 Demo 1: 類比音訊光傳輸 (Audio Transmission)
透過光訊號傳遞音訊，並使用 MATLAB 將擷取到的原始訊號進行濾波，利用 `y - mean(y)` 消除硬體產生的直流偏壓 (DC Bias)。
*   **MATLAB 處理波形：** ![Demo1 Sound Wave](./Demo1_sound.png)
*   **濾波後音訊結果：** [點此聆聽 VLC_Demo1_Audio_Filtered.wav](./VLC_Demo1_Audio_Filtered.wav)

### 🔢 Demo 2: 數位方波解碼 (Digital Square Wave Decoding)
發送端載入編碼後的數位方波，接收端透過 MATLAB 進行精準的電壓映射 (Voltage Mapping) 與邏輯位準判斷，成功還原數位資訊。
*   **解碼波形結果：** ![Demo2 Decode](./Demo2_decode.png)

### 📈 Demo 3: 模組頻寬量測 (Bandwidth Measurement)
針對實體焊接的光電收發電路進行極限測試，量測電路的頻率響應與極限頻寬。
*   **示波器頻寬量測：** ![Demo3 Bandwidth](./Demo3_bandwidth.png)
*   **TX 頻率響應：** ![TX Frequency Response](./TX_freq_resp.png)
*   **RX 頻率響應：** ![RX Frequency Response](./RX_freq_resp.png)
*   **整體效能與數據總結：** ![Measure Result](./Measure_result.png)

## 🚀 開發工具 (Tech Stack)
*   **微控制器：** Arduino (C/C++)
*   **訊號分析：** MATLAB
*   **硬體驗證：** 示波器 (Oscilloscope)、電路圖繪製軟體