/*
[MODULE_INFO_START]
Name: tx_arbiter
Role: Selects TX source between sender queue and loopback queue.
Summary:
  - Gives sender path priority when TX is idle and sender data is available.
  - Falls back to loopback RX FIFO data when sender data is absent.
  - Generates TX start/data and one-hot pop control for selected FIFO.
[MODULE_INFO_END]
*/

module tx_arbiter(
    input  wire       iTxBusy,
    input  wire       iSenderValid,
    input  wire [7:0] iSenderData,
    input  wire       iEchoValid,
    input  wire [7:0] iEchoData,
    output reg        oTxStart,
    output reg  [7:0] oTxData,
    output reg        oSenderPop,
    output reg        oEchoPop
);

    always @(*) begin
        oTxStart   = 1'b0;
        oTxData    = 8'h00;
        oSenderPop = 1'b0;
        oEchoPop   = 1'b0;

        if (~iTxBusy) begin
            if (iSenderValid) begin
                oTxStart   = 1'b1;
                oTxData    = iSenderData;
                oSenderPop = 1'b1;
            end else if (iEchoValid) begin
                oTxStart = 1'b1;
                oTxData  = iEchoData;
                oEchoPop = 1'b1;
            end
        end
    end

endmodule
