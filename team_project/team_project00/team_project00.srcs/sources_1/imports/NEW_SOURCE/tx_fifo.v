/*
[MODULE_INFO_START]
Name: tx_fifo
Role: RTL module implementing tx_fifo
Summary:
  - Implements required data/control logic for this block
  - Uses synthesizable combinational/sequential logic partition
[MODULE_INFO_END]
*/

module tx_fifo #(
    parameter integer P_DEPTH = 16
)(
    input  wire       iClk,
    input  wire       iRst,
    input  wire       iWrEn,
    input  wire [7:0] iWrData,
    input  wire       iRdEn,
    output wire [7:0] oRdData,
    output wire       oEmpty,
    output wire       oFull
);

    localparam integer LP_AW = $clog2(P_DEPTH);

    reg [7:0] memFifo [0:P_DEPTH-1];
    reg [LP_AW-1:0] rPtrWr;
    reg [LP_AW-1:0] rPtrRd;
    reg [LP_AW:0]   rCount;

    wire wWrFire;
    wire wRdFire;
    wire wPtrWrLast;
    wire wPtrRdLast;

    assign oEmpty = (rCount == 0);
    assign oFull  = (rCount == P_DEPTH);
    assign oRdData = memFifo[rPtrRd];

    assign wWrFire = iWrEn & ~oFull;
    assign wRdFire = iRdEn & ~oEmpty;
    assign wPtrWrLast = (rPtrWr == (P_DEPTH - 1));
    assign wPtrRdLast = (rPtrRd == (P_DEPTH - 1));

    always @(posedge iClk or posedge iRst) begin
        if (iRst) begin
            rPtrWr <= {LP_AW{1'b0}};
            rPtrRd <= {LP_AW{1'b0}};
            rCount <= {(LP_AW+1){1'b0}};
        end else begin
            if (wWrFire) begin
                memFifo[rPtrWr] <= iWrData;
                if (wPtrWrLast) begin
                    rPtrWr <= {LP_AW{1'b0}};
                end else begin
                    rPtrWr <= rPtrWr + 1'b1;
                end
            end

            if (wRdFire) begin
                if (wPtrRdLast) begin
                    rPtrRd <= {LP_AW{1'b0}};
                end else begin
                    rPtrRd <= rPtrRd + 1'b1;
                end
            end

            case ({wWrFire, wRdFire})
                2'b10: rCount <= rCount + 1'b1;
                2'b01: rCount <= rCount - 1'b1;
                default: rCount <= rCount;
            endcase
        end
    end

endmodule
