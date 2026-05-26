/*
[MODULE_INFO_START]
Name: InputControl
Role: Merges FPGA local input pulses and PC(UART ASCII) input pulses for Control Unit.
Summary:
  - Delegates switch-event generation and priority resolution to InputPriority submodule.
  - Delegates mode-aware command conversion/distribution to InputDistributor submodule.
[MODULE_INFO_END]
*/

module InputControl(
    input  wire       iClk,
    input  wire       iRst,
    input  wire [4:0] iBtnPulseFpga,    // from DebounceWrapper
    input  wire [2:0] iSwLevelFpga,     // from INPUTFPGA/SwitchInput
    input  wire [4:0] iBtnPulsePc,      // from ascii_decoder

    input  wire       iSw1PulsePc,      // from ascii_decoder
    input  wire       iSw2PulsePc,      // from ascii_decoder
    input  wire       iSw3PulsePc,      // from ascii_decoder
    input  wire       iReqFndPc,        // from ascii_decoder
    input  wire       iReqStatePc,      // from ascii_decoder
    input  wire       iReqStopwatchPc,  // from ascii_decoder
    input  wire       iReqWatchPc,      // from ascii_decoder
    input  wire       iReqHcsr04Pc,     // from ascii_decoder
    input  wire       iReqDht11Pc,      // from ascii_decoder

    output wire [1:0] oMode,            // to Control Unit
    output wire       oModeLock,        // to Control Unit
    output wire       oCmdValid,        // to Control Unit
    output wire [4:0] oCmdCode          // to Control Unit
);

    wire [2:0] wSwPulsePc;
    wire [4:0] wBtnPulsePrio;
    wire [2:0] wSwPulsePrio;

    assign wSwPulsePc = {iSw3PulsePc, iSw2PulsePc, iSw1PulsePc};

    InputPriority uInputPriority (
        .iClk        (iClk),
        .iRst        (iRst),
        .iBtnPulseFpga(iBtnPulseFpga),
        .iBtnPulsePc  (iBtnPulsePc),
        .iSwLevelFpga (iSwLevelFpga),
        .iSwPulsePc   (wSwPulsePc),
        .oBtnPulse    (wBtnPulsePrio),
        .oSwPulse     (wSwPulsePrio)
    );

    InputDistributor uInputDistributor (
        .iClk          (iClk),
        .iRst          (iRst),
        .iBtnPulse     (wBtnPulsePrio),
        .iSwLevel      (iSwLevelFpga),
        .iSwPulse      (wSwPulsePrio),
        .iReqFnd       (iReqFndPc),
        .iReqState     (iReqStatePc),
        .iReqStopwatch (iReqStopwatchPc),
        .iReqWatch     (iReqWatchPc),
        .iReqHcsr04    (iReqHcsr04Pc),
        .iReqDht11     (iReqDht11Pc),
        .oMode         (oMode),
        .oModeLock     (oModeLock),
        .oCmdValid     (oCmdValid),
        .oCmdCode      (oCmdCode)
    );

endmodule
