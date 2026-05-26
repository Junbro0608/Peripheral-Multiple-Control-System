/*
[MODULE_INFO_START]
Name: CounterFilter
Role: Counter-based input stability filter for debounce.
Summary:
  - Updates output only when input change persists for configured cycles.
  - Rejects short glitches shorter than the configured count window.
[MODULE_INFO_END]
*/

module CounterFilter #(

    parameter MAX_COUNT = 1999999 
)(
    input  wire iClk,
    input  wire iRst,
    input  wire iIn,
    output reg  oOut
);

    localparam CNT_WIDTH = $clog2(MAX_COUNT);

    reg [CNT_WIDTH-1:0] cnt;

    always @(posedge iClk or posedge iRst) begin
        if (iRst) begin
            cnt  <= 0;
            oOut <= 1'b0;
        end else if (iIn == oOut) begin
            cnt  <= 0;
        end else if (cnt == MAX_COUNT) begin
            cnt  <= 0;
            oOut <= iIn;
        end else begin
            cnt  <= cnt + 1'b1;
        end
    end

endmodule