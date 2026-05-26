/*
[MODULE_INFO_START]
Name: INPUTFPGA
Role: Aggregates FPGA physical inputs for downstream input control.
Summary:
  - Routes button path through DebounceWrapper to generate button pulses.
  - Routes switch path through SwitchInput to generate synchronized switch levels.
[MODULE_INFO_END]
*/

module INPUTFPGA(
    input  wire [4:0] iBtnAsync,
    input  wire [2:0] iSwAsync,
    input  wire       iClk,
    input  wire       iRst,
    output wire [4:0] oBtnPulse,
    output wire [2:0] oSwLevel
);

    DebounceWrapper uDebounceWrapper (
        .iBtnAsync   (iBtnAsync),
        .iClk        (iClk),
        .iRst        (iRst),
        .oBtnPulse   (oBtnPulse)
    );

    SwitchInput uSwitchInput (
        .iSwAsync(iSwAsync),
        .iClk    (iClk),
        .iRst    (iRst),
        .oSwLevel(oSwLevel)
    );

endmodule
