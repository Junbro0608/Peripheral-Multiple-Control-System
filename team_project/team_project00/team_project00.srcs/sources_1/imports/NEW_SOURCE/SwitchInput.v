/*
[MODULE_INFO_START]
Name: SwitchInput
Role: Synchronizes FPGA switch inputs into system clock domain.
Summary:
  - Applies sync_2ff per switch bit.
  - Outputs stable synchronous switch level for control logic.
[MODULE_INFO_END]
*/

module SwitchInput(
    input  wire [2:0] iSwAsync,
    input  wire       iClk,
    input  wire       iRst,
    output wire [2:0] oSwLevel
);

    genvar idxSw;
    generate
        for (idxSw = 0; idxSw < 3; idxSw = idxSw + 1) begin: genSwSync
            sync_2ff uSwSync2ff (
                .iAsync(iSwAsync[idxSw]),
                .iClk  (iClk),
                .iRst  (iRst),
                .oSync (oSwLevel[idxSw])
            );
        end
    endgenerate

endmodule
