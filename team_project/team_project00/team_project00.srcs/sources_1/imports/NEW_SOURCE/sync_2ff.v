/*
[MODULE_INFO_START]
Name: sync_2ff
Role: RTL module implementing sync_2ff
Summary:
  - Implements required data/control logic for this block
  - Uses synthesizable combinational/sequential logic partition
[MODULE_INFO_END]
*/

module sync_2ff (
    input  wire  iAsync,
    input  wire  iClk,
    input  wire  iRst,
    output wire  oSync
);

    reg      rSync_d1;
    reg      rSync_d2;

    always @(posedge iClk or posedge iRst) begin
        if (iRst) begin
            rSync_d1 <= 1'b0;
            rSync_d2 <= 1'b0;
        end else begin
            rSync_d1 <= iAsync;
            rSync_d2 <= rSync_d1;
        end
    end

    assign oSync = rSync_d2;

endmodule
