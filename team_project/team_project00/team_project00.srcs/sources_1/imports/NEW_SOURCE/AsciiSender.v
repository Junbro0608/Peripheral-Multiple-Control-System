/*
[MODULE_INFO_START]
Name: AsciiSender
Role: UART ASCII TX pipeline wrapper.
Summary:
  - AsciiMux selects payload and TX mode per command.
  - AsciiSenderFsm serializes payload to ASCII bytes with ready/valid handshake.
[MODULE_INFO_END]
*/
module AsciiSender (
    input  wire        iClk,
    input  wire        iRstn,

    // Command context
    input  wire [1:0]  iMode,
    input  wire        iModeLock,
    input  wire        iCmdValid,
    input  wire [4:0]  iCmdCode,

    // Core data
    input  wire [31:0] iWatchFullData,
    input  wire [31:0] iStopFullData,
    input  wire [15:0] iHcsr04Distance,
    input  wire [15:0] iDht11Temp,
    input  wire [15:0] iDht11Humi,
    input  wire        iWatchEditActive,
    input  wire        iStopEditActive,
    input  wire        iHcsrAutoRun,
    input  wire        iDht11AutoRun,
    input  wire [15:0] iDisplayBcd,

    // TX interface
    input  wire        iTxReady,
    output wire [7:0]  oTxData,
    output wire        oTxValid
);

    wire        wAsciiMux_StartPulse;
    wire [31:0] wAsciiMux_BcdPacket;
    wire [1:0]  wAsciiMux_TxMode;

    AsciiMux uAsciiMux (
        .iClk            (iClk),
        .iRstn           (iRstn),
        .iMode           (iMode),
        .iModeLock       (iModeLock),
        .iCmdValid       (iCmdValid),
        .iCmdCode        (iCmdCode),
        .iWatchFullData  (iWatchFullData),
        .iStopFullData   (iStopFullData),
        .iHcsr04Distance (iHcsr04Distance),
        .iDht11Temp      (iDht11Temp),
        .iDht11Humi      (iDht11Humi),
        .iWatchEditActive(iWatchEditActive),
        .iStopEditActive (iStopEditActive),
        .iHcsrAutoRun    (iHcsrAutoRun),
        .iDht11AutoRun   (iDht11AutoRun),
        .iDisplayBcd     (iDisplayBcd),
        .oTxStart        (wAsciiMux_StartPulse),
        .oTxBcdData      (wAsciiMux_BcdPacket),
        .oTxMode         (wAsciiMux_TxMode)
    );

    AsciiSenderFsm uAsciiSenderFsm (
        .iClk           (iClk),
        .iRstn          (iRstn),
        .i_c_mode       (wAsciiMux_TxMode),
        .i_start        (wAsciiMux_StartPulse),
        .i_dec_data     (wAsciiMux_BcdPacket),
        .i_sender_ready (iTxReady),
        .send_data      (oTxData),
        .send_valid     (oTxValid)
    );

endmodule
