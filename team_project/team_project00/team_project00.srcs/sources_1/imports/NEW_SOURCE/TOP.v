/*
[MODULE_INFO_START]
Name: TOP
Role: ?꾨줈?앺듃??理쒖긽??紐⑤뱢濡쒖꽌 紐⑤뱺 ?섎뱶?⑥뼱 紐⑤뱢怨??몃? ? ?곌껐 ?섑띁
Summary:
  - 100MHz ?쒖뒪???대윮怨?iRst ?ㅼ쐞移섎? ?댁슜??湲濡쒕쾶 由ъ뀑 援ъ“ ?뺤꽦 (Active-Low 蹂???ы븿)
  - INPUTFPGA, InputControl???듯빐 ?섎뱶?⑥뼱 踰꾪듉怨?UART ?낅젰??痍⑦빀?섏뿬 Command & Mode ?앹꽦
  - ControlUnit怨??고븯 4媛??쇱꽌/?쒓컙 肄붿뼱瑜??곌껐?섏뿬 ?곗씠???섏쭛 諛?諛고룷
  - DisplayMux 諛?FndController瑜??듯빐 FND(7-Segment)???곹솴蹂??곗씠???쒖텧
  - AsciiSender 諛?UART TX 紐⑤뱢???듯빐 ?щ㎎?낅맂 ASCII ?곗씠??PC ?≪떊 (?듭떊 ?붿쭊 ?듯빀)
StateDescription:
[MODULE_INFO_END]
*/

module TOP (
    input  wire        iClk100m,
    input  wire        iRst,        // Basys3 C Center Button (Active-High)

    // FPGA Local Inputs
    input  wire        iBtnU,       // Up (Btn[4])
    input  wire        iBtnD,       // Down (Btn[2])
    input  wire        iBtnR,       // Right (Btn[1])
    input  wire        iBtnL,       // Left (Btn[0])
    input  wire [2:0]  iSw,         // Switches (Sw[2] = Lock, Sw[1:0] = Command)

    // FND Outputs
    output wire [6:0]  oSeg,
    output wire        oDp,
    output wire [3:0]  oDigitSel,

    // Sensor I/O
    output wire        oHcsr04Trig,
    input  wire        iHcsr04Echo,
    inout  wire        ioDht11Data,

    // UART I/O
    input  wire        iUartRx,
    output wire        oUartTx
);

    // =========================================================================
    // 0. Global Reset & Active-Low Conversion
    // =========================================================================
    wire wRstn = ~iRst; // ?쒖뒪???꾨컲?먯꽌 Active-Low 由ъ뀑 ?ъ슜

    // =========================================================================
    // 1. Global Tick Generation
    // =========================================================================
    wire wTick1kHz;
    wire wTick2Hz;

    GlobalTickGen #(
        .P_SYS_CLK_HZ(100_000_000)
    ) uGlobalTickGen (
        .iClk       (iClk100m),
        .iRstn      (wRstn),
        .oTick1kHz  (wTick1kHz),
        .oTick2Hz   (wTick2Hz)
    );

    // =========================================================================
    // 2. FPGA Physical Input Handling
    // =========================================================================
    wire [4:0] wBtnPulseFpga;
    wire [2:0] wSwLevelFpga;

    // {U, C, D, R, L} ?뺥깭濡??곌껐. C(Center)??H/W 由ъ뀑?대?濡??뚰봽??由ъ뀑 ?몃━嫄곗뿏 0 ?좊떦
    wire [4:0] wBtnAsync = {iBtnU, 1'b0, iBtnD, iBtnR, iBtnL};

    INPUTFPGA uInputFpga (
        .iBtnAsync  (wBtnAsync),
        .iSwAsync   (iSw),
        .iClk       (iClk100m),
        .iRst       (iRst), // INPUTFPGA ?대???Active-High 由ъ뀑 ?덇굅???ъ슜
        .oBtnPulse  (wBtnPulseFpga),
        .oSwLevel   (wSwLevelFpga)
    );

    // =========================================================================
    // 3. UART RX & Command Decoding
    // =========================================================================
    wire wRxValid;
    wire [7:0] wRxData;

    wire [4:0] wBtnPulsePc;
    wire       wSw1PulsePc;
    wire       wSw2PulsePc;
    wire       wSw3PulsePc;
    wire       wReqFndPc;
    wire       wReqStatePc;
    wire       wReqStopwatchPc;
    wire       wReqWatchPc;
    wire       wReqHcsr04Pc;
    wire       wReqDht11Pc;

    ascii_decoder uAsciiDecoder (
        .iRxValid      (wRxValid),
        .iRxData       (wRxData),
        .oBtnPulse     (wBtnPulsePc),
        .oSw1Pulse     (wSw1PulsePc),
        .oSw2Pulse     (wSw2PulsePc),
        .oSw3Pulse     (wSw3PulsePc),
        .oReqFnd       (wReqFndPc),
        .oReqState     (wReqStatePc),
        .oReqStopwatch (wReqStopwatchPc),
        .oReqWatch     (wReqWatchPc),
        .oReqHcsr04    (wReqHcsr04Pc),
        .oReqDht11     (wReqDht11Pc),
        .oCmdErr       ()
    );

    // =========================================================================
    // 4. Input Merge & Command Distribution (InputControl)
    // =========================================================================
    wire [1:0] wMode;
    wire       wModeLock;
    wire       wCmdValid;
    wire [4:0] wCmdCode;

    InputControl uInputControl (
        .iClk             (iClk100m),
        .iRst             (iRst),
        .iBtnPulseFpga    (wBtnPulseFpga),
        .iSwLevelFpga     (wSwLevelFpga),
        .iBtnPulsePc      (wBtnPulsePc),
        .iSw1PulsePc      (wSw1PulsePc),
        .iSw2PulsePc      (wSw2PulsePc),
        .iSw3PulsePc      (wSw3PulsePc),
        .iReqFndPc        (wReqFndPc),
        .iReqStatePc      (wReqStatePc),
        .iReqStopwatchPc  (wReqStopwatchPc),
        .iReqWatchPc      (wReqWatchPc),
        .iReqHcsr04Pc     (wReqHcsr04Pc),
        .iReqDht11Pc      (wReqDht11Pc),
        .oMode            (wMode),
        .oModeLock        (wModeLock),
        .oCmdValid        (wCmdValid),
        .oCmdCode         (wCmdCode)
    );

    // =========================================================================
    // 5. Core Execution (ControlUnit)
    // =========================================================================
    wire [15:0] wWatchData;
    wire [31:0] wWatchFullData;
    wire [3:0]  wWatchBlinkMask;
    wire [3:0]  wWatchDotMask;
    wire        wWatchEditActive;

    wire [15:0] wStopData;
    wire [31:0] wStopFullData;
    wire [3:0]  wStopBlinkMask;
    wire [3:0]  wStopDotMask;
    wire        wStopEditActive;

    wire [15:0] wHcsr04Distance;
    wire        wHcsr04Valid;
    wire        wHcsr04AutoRun;

    wire [15:0] wDht11Temp;
    wire [15:0] wDht11Humi;
    wire        wDht11Valid;
    wire        wDht11AutoRun;

    ControlUnit uControlUnit (
        .iClk             (iClk100m),
        .iRstn            (wRstn),
        .iTick1kHz        (wTick1kHz),
        .iMode            (wMode),
        .iCmdValid        (wCmdValid),
        .iCmdCode         (wCmdCode),
        .iEcho            (iHcsr04Echo),
        .oTrig            (oHcsr04Trig),
        .ioDhtData        (ioDht11Data),
        .oWatchData       (wWatchData),
        .oWatchFullData   (wWatchFullData),
        .oWatchBlinkMask  (wWatchBlinkMask),
        .oWatchDotMask    (wWatchDotMask),
        .oWatchEditActive (wWatchEditActive),
        .oStopData        (wStopData),
        .oStopFullData    (wStopFullData),
        .oStopBlinkMask   (wStopBlinkMask),
        .oStopDotMask     (wStopDotMask),
        .oStopEditActive  (wStopEditActive),
        .oHcsr04Distance  (wHcsr04Distance),
        .oHcsr04Valid     (wHcsr04Valid),
        .oHcsr04AutoRun   (wHcsr04AutoRun),
        .oDht11Temp       (wDht11Temp),
        .oDht11Humi       (wDht11Humi),
        .oDht11Valid      (wDht11Valid),
        .oDht11AutoRun    (wDht11AutoRun)
    );

    // =========================================================================
    // 6. FND Display Output (DisplayMux -> FndController)
    // =========================================================================
    wire [15:0] wDisplayBcd;
    wire [3:0]  wDisplayBlink;
    wire [3:0]  wDisplayDot;

    DisplayMux uDisplayMux (
        .iMode            (wMode),
        .iWatchData       (wWatchData),
        .iWatchBlinkMask  (wWatchBlinkMask),
        .iWatchDotMask    (wWatchDotMask),
        .iStopData        (wStopData),
        .iStopBlinkMask   (wStopBlinkMask),
        .iStopDotMask     (wStopDotMask),
        .iHcsr04Distance  (wHcsr04Distance),
        .iDht11Temp       (wDht11Temp),
        .iDht11Humi       (wDht11Humi),
        .oFndBcd          (wDisplayBcd),
        .oBlinkMask       (wDisplayBlink),
        .oDpMask          (wDisplayDot)
    );

    FndController uFndController (
        .iClk       (iClk100m),
        .iRstn      (wRstn),
        .iTick1kHz  (wTick1kHz),
        .iTick2Hz   (wTick2Hz),
        .iDigitsBcd (wDisplayBcd),
        .iBlinkMask (wDisplayBlink),
        .iDpMask    (wDisplayDot),
        .oSeg       (oSeg),
        .oDp        (oDp),
        .oDigitSel  (oDigitSel)
    );

    // =========================================================================
    // 7. UART ASCII TX Pipeline (AsciiSender -> uart_interface)
    // =========================================================================
    wire [7:0] wTxData;
    wire       wTxStart;
    wire       wSenderReady;

    AsciiSender uAsciiSender (
        .iClk             (iClk100m),
        .iRstn            (wRstn),
        .iMode            (wMode),
        .iModeLock        (wModeLock),
        .iCmdValid        (wCmdValid),
        .iCmdCode         (wCmdCode),
        .iWatchFullData   (wWatchFullData),
        .iStopFullData    (wStopFullData),
        .iHcsr04Distance  (wHcsr04Distance),
        .iDht11Temp       (wDht11Temp),
        .iDht11Humi       (wDht11Humi),
        .iWatchEditActive (wWatchEditActive),
        .iStopEditActive  (wStopEditActive),
        .iHcsrAutoRun     (wHcsr04AutoRun),
        .iDht11AutoRun    (wDht11AutoRun),
        .iDisplayBcd      (wDisplayBcd),
        .iTxReady         (wSenderReady),
        .oTxData          (wTxData),
        .oTxValid         (wTxStart)
    );

    uart_interface #(
        .P_CLK_HZ     (100_000_000),
        .P_BAUD       (9600),
        .P_OVERSAMPLE (16),
        .P_FIFO_DEPTH (16)
    ) uUartInterface (
        .iClk         (iClk100m),
        .iRst         (iRst),
        .iUartRx      (iUartRx),
        .oUartTx      (oUartTx),
        .iSenderData  (wTxData),
        .iSenderValid (wTxStart),
        .oSenderReady (wSenderReady),
        .oDecoderData (wRxData),
        .oDecoderValid(wRxValid)
    );

endmodule
