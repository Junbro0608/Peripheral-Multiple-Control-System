/*
[MODULE_INFO_START]
Name: DebounceWrapper
Role: Multi-channel debounce wrapper for button inputs.
Summary:
  - Instantiates Debounce module for each button channel.
  - Exposes both debounced level and one-cycle pulse per button.
[MODULE_INFO_END]
*/

module DebounceWrapper(
    input  wire [4:0] iBtnAsync,
    input  wire       iClk,
    input  wire       iRst,
    output wire [4:0] oBtnPulse
);

    genvar idxBtn;
    generate
        for (idxBtn = 0; idxBtn < 5; idxBtn = idxBtn + 1) begin: genDebounce
            Debounce uDebounce (
                .iClk        (iClk),
                .iRst        (iRst),
                .iBtnAsync   (iBtnAsync[idxBtn]),
                .oBtnPulse   (oBtnPulse[idxBtn])
            );
        end
    endgenerate

endmodule
