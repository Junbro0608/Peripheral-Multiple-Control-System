/*
[MODULE_INFO_START]
Name: DisplayMux
Role: 화면 출력 채널 다중화 및 포맷 변환 브릿지 래퍼 (Display Dedicated)
Summary:
  - SensorBcdConverter: 이진 출력 코어 데이터를 인간 친화적인 화면용 BCD로 형 변환
  - DisplayModeSelector: iMode 기반으로 출력 대상을 오직 FND 렌더링에만 집중하여 다중화결합
StateDescription:
[MODULE_INFO_END]
*/
module DisplayMux (
    input  wire [1:0]  iMode,

    // Core Outputs
    input  wire [15:0] iWatchData,
    input  wire [3:0]  iWatchBlinkMask,
    input  wire [3:0]  iWatchDotMask,

    input  wire [15:0] iStopData,
    input  wire [3:0]  iStopBlinkMask,
    input  wire [3:0]  iStopDotMask,

    input  wire [15:0] iHcsr04Distance,
    input  wire [15:0] iDht11Temp,
    input  wire [15:0] iDht11Humi,

    // Outputs to FND Controller
    output wire [15:0] oFndBcd,
    output wire [3:0]  oBlinkMask,
    output wire [3:0]  oDpMask
);

    wire [15:0] wHcsrBcd;
    wire [15:0] wDhtBcd;

    SensorBcdConverter uSensorBcdConverter (
        .iHcsr04Distance (iHcsr04Distance),
        .iDht11Temp      (iDht11Temp),
        .iDht11Humi      (iDht11Humi),
        .oHcsr04Bcd      (wHcsrBcd),
        .oDht11Bcd       (wDhtBcd)
    );

    DisplayModeSelector uDisplayModeSelector (
        .iMode           (iMode),
        .iWatchData      (iWatchData),
        .iWatchBlinkMask (iWatchBlinkMask),
        .iWatchDotMask   (iWatchDotMask),
        .iStopData       (iStopData),
        .iStopBlinkMask  (iStopBlinkMask),
        .iStopDotMask    (iStopDotMask),
        .iHcsr04Bcd      (wHcsrBcd),
        .iDht11Bcd       (wDhtBcd),
        .oFndBcd         (oFndBcd),
        .oBlinkMask      (oBlinkMask),
        .oDpMask         (oDpMask)
    );

endmodule
