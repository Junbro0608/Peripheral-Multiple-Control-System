/*
[MODULE_INFO_START]
Name: EdgePulse
Role: Generates one-cycle pulse on rising edge of input level.
Summary:
  - Detects rising edge of iLevel in iClk domain.
  - Outputs one-cycle pulse on oPulse for event-style control logic.
[MODULE_INFO_END]
*/

module EdgePulse (
    input  wire iClk,
    input  wire iRst,
    input  wire iLevel,
    output wire oPulse
);

    reg level_d1;

    always @(posedge iClk or posedge iRst) begin
        if (iRst) begin
            level_d1 <= 1'b0;
        end else begin
            level_d1 <= iLevel;
        end
    end

    assign oPulse = iLevel & ~level_d1;

endmodule
