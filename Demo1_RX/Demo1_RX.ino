const int analogPin = A4;

void setup() {
    // 1. 提升鮑率加寬傳輸頻寬
    Serial.begin(1000000); 

    // 2. 🚀 超頻魔法：將 ADC prescale(預除頻器) 從 128 設為 16
    // 這行程式碼會直接操控晶片底層，讓 analogRead() 速度變快 8 倍！
    ADCSRA = (ADCSRA & 0xf8) | 0x04;
}

void loop() {
    byte out = (analogRead(analogPin)) >> 2;
    Serial.write(out);
}

