/*
[MODULE_INFO_START]
Name: SensorBcdConverter
Role: 센서 데이터 값 기반 BCD 형변환 전담 모듈
Summary:
  - HC-SR04 거리 데이터 복호화 및 최대값 9999 클리핑
  - DHT11 센서 온도 등의 정수부 추출 및 형변환
StateDescription:
[MODULE_INFO_END]
*/
module SensorBcdConverter (
    input  wire [15:0] iHcsr04Distance,
    input  wire [15:0] iDht11Temp,
    input  wire [15:0] iDht11Humi,
    output wire [15:0] oHcsr04Bcd,
    output wire [15:0] oDht11Bcd
);
    // HC-SR04 BCD Conversion
    wire [13:0] wHcsrBin = (iHcsr04Distance > 16'd9999) ? 14'd9999 : iHcsr04Distance[13:0];
    DoubleDabble uHcsrDabble (
        .iBin (wHcsrBin),
        .oBcd (oHcsr04Bcd)
    );

    // DHT11 BCD Conversion: [Humi(2digit)][Temp(2digit)]
    wire [15:0] wDhtTempBcd;
    wire [15:0] wDhtHumiBcd;

    wire [13:0] wDhtTempBin = iDht11Temp[15:8];
    wire [13:0] wDhtHumiBin = iDht11Humi[15:8];

    DoubleDabble uDhtTempDabble (
        .iBin (wDhtTempBin),
        .oBcd (wDhtTempBcd)
    );

    DoubleDabble uDhtHumiDabble (
        .iBin (wDhtHumiBin),
        .oBcd (wDhtHumiBcd)
    );

    assign oDht11Bcd = {wDhtHumiBcd[7:0], wDhtTempBcd[7:0]};
endmodule
