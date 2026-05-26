/*
[MODULE_INFO_START]
Name: ControlUnit
Role: Integrates watch/stopwatch/sensor cores.
Summary:
  - Routes compact command interface to each functional core.
  - Aggregates display/full-data/status outputs.
[MODULE_INFO_END]
*/
module ControlUnit #(
    parameter P_SYS_CLK_HZ = 100_000_000
)(
    input  wire        iClk,
    input  wire        iRstn,
    input  wire        iTick1kHz,

    input  wire [1:0]  iMode,
    input  wire        iCmdValid,
    input  wire [4:0]  iCmdCode,

    input  wire        iEcho,
    output wire        oTrig,
    inout  wire        ioDhtData,

    output wire [15:0] oWatchData,
    output wire [31:0] oWatchFullData,
    output wire [3:0]  oWatchBlinkMask,
    output wire [3:0]  oWatchDotMask,
    output wire        oWatchEditActive,

    output wire [15:0] oStopData,
    output wire [31:0] oStopFullData,
    output wire [3:0]  oStopBlinkMask,
    output wire [3:0]  oStopDotMask,
    output wire        oStopEditActive,

    output wire [15:0] oHcsr04Distance,
    output wire        oHcsr04Valid,
    output wire        oHcsr04AutoRun,

    output wire [15:0] oDht11Temp,
    output wire [15:0] oDht11Humi,
    output wire        oDht11Valid,
    output wire        oDht11AutoRun
);

    WatchCore uWatchCore (
        .iClk       (iClk),
        .iRstn      (iRstn),
        .iTick1kHz  (iTick1kHz),
        .iMode      (iMode),
        .iCmdValid  (iCmdValid),
        .iCmdCode   (iCmdCode),
        .oFndData   (oWatchData),
        .oFullData  (oWatchFullData),
        .oBlinkMask (oWatchBlinkMask),
        .oDotMask   (oWatchDotMask),
        .oEditActive(oWatchEditActive)
    );

    StopwatchCore uStopwatchCore (
        .iClk       (iClk),
        .iRstn      (iRstn),
        .iTick1kHz  (iTick1kHz),
        .iMode      (iMode),
        .iCmdValid  (iCmdValid),
        .iCmdCode   (iCmdCode),
        .oFndData   (oStopData),
        .oFullData  (oStopFullData),
        .oBlinkMask (oStopBlinkMask),
        .oDotMask   (oStopDotMask),
        .oEditActive(oStopEditActive)
    );

    wire wHcsrStart;
    wire wDht11Start;

    SensorControlUnit uSensorControlUnit (
        .iClk         (iClk),
        .iRstn        (iRstn),
        .iTick1kHz    (iTick1kHz),
        .iCmdValid    (iCmdValid),
        .iCmdCode     (iCmdCode),
        .iMode        (iMode),
        .oHcsrStart   (wHcsrStart),
        .oDht11Start  (wDht11Start),
        .oHcsrAutoRun (oHcsr04AutoRun),
        .oDht11AutoRun(oDht11AutoRun)
    );

    Hcsr04Core #(
        .P_SYS_CLK_HZ (P_SYS_CLK_HZ)
    ) uHcsr04Core (
        .iClk       (iClk),
        .iRstn      (iRstn),
        .iStart     (wHcsrStart),
        .iEcho      (iEcho),
        .oTrig      (oTrig),
        .oDistance  (oHcsr04Distance),
        .oValid     (oHcsr04Valid)
    );

    Dht11Core #(
        .P_SYS_CLK_HZ (P_SYS_CLK_HZ)
    ) uDht11Core (
        .iClk       (iClk),
        .iRstn      (iRstn),
        .iStart     (wDht11Start),
        .ioData     (ioDhtData),
        .oTemp      (oDht11Temp),
        .oHumi      (oDht11Humi),
        .oValid     (oDht11Valid)
    );

endmodule
