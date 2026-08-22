const int Bit_period = 5000;

// encode character -> decode see our rule
const char stream_code[] = "1110110110000110001";   // l1
// const char stream_code[] = "1110100001101100011";   // Cc
// const char stream_code[] = "11101101101";   // m

const int Tx_Pin = 4;

void setup() {
  // put your setup code here, to run once:
    pinMode(Tx_Pin, OUTPUT);
    digitalWrite(Tx_Pin, LOW);

    Serial.begin(115200);
    Serial.println("TX ready!");
}

void loop() {
  // put your main code here, to run repeatedly:
    sendVLCMessage(stream_code);
}

void sendVLCMessage(const char * bitstream) {
    int len = strlen(bitstream);

    // Transmit decode data
    for(int i=0; i<len; i++){
        if(bitstream[i] == '1')   digitalWrite(Tx_Pin, HIGH);
        else if(bitstream[i] == '0')  digitalWrite(Tx_Pin, LOW);
        delayMicroseconds(Bit_period);
    }

    // Transmit ideal
    // for(int j=0; j<20; j++) {
    //     digitalWrite(Tx_Pin, LOW);
    //     delayMicroseconds(Bit_period);
    // }

}
