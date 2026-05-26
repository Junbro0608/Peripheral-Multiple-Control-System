/*
[MODULE_INFO_START]
Name: baud_rate_generator
Role: RTL module implementing baud_rate_generator
Summary:
  - Implements required data/control logic for this block
  - Uses synthesizable combinational/sequential logic partition
[MODULE_INFO_END]
*/

module baud_rate_generator #(
    parameter integer P_CLK_HZ      = 100000000,
    parameter integer P_BAUD        = 9600,
    parameter integer P_OVERSAMPLE  = 16
)(
    input       iClk,
    input       iRst,
    output reg  oSampleTick
);
  
    // Example: 100MHz / (9600 * 16) = ~651
    localparam integer LP_DIV       = P_CLK_HZ / (P_BAUD * P_OVERSAMPLE);
    localparam integer LP_CNT_WIDTH = $clog2(LP_DIV);

    reg [LP_CNT_WIDTH-1:0] rCnt;

    always @(posedge iClk or posedge iRst) begin
        if (iRst) begin
            rCnt        <= {LP_CNT_WIDTH{1'b0}};
            oSampleTick <= 1'b0;
        end else begin
            if (rCnt == (LP_DIV - 1)) begin
                rCnt        <= {LP_CNT_WIDTH{1'b0}};
                oSampleTick <= 1'b1;
            end else begin
                rCnt        <= rCnt + 1'b1;
                oSampleTick <= 1'b0;
            end
        end
    end
endmodule
