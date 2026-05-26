/*
[MODULE_INFO_START]
Name: InputPriority
Role: Resolves source priority between FPGA input events and PC input events.
Summary:
  - Applies bit-wise PC priority on button pulses.
  - Detects FPGA switch toggle events from switch levels.
  - Applies bit-wise PC priority on switch event pulses.
[MODULE_INFO_END]
*/

module InputPriority(
    input  wire       iClk,
    input  wire       iRst,
    input  wire [4:0] iBtnPulseFpga,
    input  wire [4:0] iBtnPulsePc,
    input  wire [2:0] iSwLevelFpga,
    input  wire [2:0] iSwPulsePc,
    output wire [4:0] oBtnPulse,
    output wire [2:0] oSwPulse
);

    reg  [2:0] swLevelPrev;
    wire [2:0] wSwTogglePulse;

    assign wSwTogglePulse = iSwLevelFpga ^ swLevelPrev;

    always @(posedge iClk or posedge iRst) begin
        if (iRst) begin
            swLevelPrev <= 3'b000;
        end else begin
            swLevelPrev <= iSwLevelFpga;
        end
    end

    assign oBtnPulse = iBtnPulsePc | (iBtnPulseFpga & ~iBtnPulsePc);
    assign oSwPulse  = iSwPulsePc  | (wSwTogglePulse & ~iSwPulsePc);

endmodule
