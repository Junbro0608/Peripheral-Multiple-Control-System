/*
[MODULE_INFO_START]
Name: uart_tx
Role: UART transmitter based on Moore FSM.
Summary:
  - Sends one start bit, 8 data bits (LSB first), and one stop bit.
  - Uses 16x sample tick timing for each serial bit period.
  - Provides state-based busy/done outputs for upper TX control.
StateDescription:
  - IDLE: Waits for iTxStart and latches iTxData.
  - START: Drives UART line low for one bit period.
  - DATA: Sends 8 data bits, one bit per bit period.
  - STOP: Drives UART line high for one bit period.
  - DONE: Pulses oTxDone for one cycle, then returns to IDLE.
[MODULE_INFO_END]
*/

module uart_tx(
    input  wire       iClk,
    input  wire       iRst,
    input  wire       iSampleTick,
    input  wire       iTxStart,
    input  wire [7:0] iTxData,
    output reg        oUartTx,
    output reg        oTxBusy,
    output reg        oTxDone
);

    localparam [2:0] IDLE  = 3'd0;
    localparam [2:0] START = 3'd1;
    localparam [2:0] DATA  = 3'd2;
    localparam [2:0] STOP  = 3'd3;
    localparam [2:0] DONE  = 3'd4;

    reg [2:0] state;
    reg [2:0] state_d;

    reg [3:0] sampleCnt;
    reg [3:0] sampleCnt_d;
    reg [2:0] bitCnt;
    reg [2:0] bitCnt_d;
    reg [7:0] shift;
    reg [7:0] shift_d;

    always @(posedge iClk or posedge iRst) begin
        if (iRst) begin
            state     <= IDLE;
            sampleCnt <= 4'd0;
            bitCnt    <= 3'd0;
            shift     <= 8'd0;
        end else begin
            state     <= state_d;
            sampleCnt <= sampleCnt_d;
            bitCnt    <= bitCnt_d;
            shift     <= shift_d;
        end
    end

    always @(*) begin
        state_d     = state;
        sampleCnt_d = sampleCnt;
        bitCnt_d    = bitCnt;
        shift_d     = shift;

        case (state)
            IDLE: begin
                sampleCnt_d = 4'd0;
                bitCnt_d    = 3'd0;
                if (iTxStart) begin
                    shift_d = iTxData;
                    state_d = START;
                end
            end

            START: begin
                if (iSampleTick) begin
                    if (sampleCnt == 4'd15) begin
                        sampleCnt_d = 4'd0;
                        bitCnt_d    = 3'd0;
                        state_d     = DATA;
                    end else begin
                        sampleCnt_d = sampleCnt + 1'b1;
                    end
                end
            end

            DATA: begin
                if (iSampleTick) begin
                    if (sampleCnt == 4'd15) begin
                        sampleCnt_d = 4'd0;
                        if (bitCnt == 3'd7) begin
                            state_d = STOP;
                        end else begin
                            bitCnt_d = bitCnt + 1'b1;
                        end
                    end else begin
                        sampleCnt_d = sampleCnt + 1'b1;
                    end
                end
            end

            STOP: begin
                if (iSampleTick) begin
                    if (sampleCnt == 4'd15) begin
                        sampleCnt_d = 4'd0;
                        state_d     = DONE;
                    end else begin
                        sampleCnt_d = sampleCnt + 1'b1;
                    end
                end
            end

            DONE: begin
                state_d = IDLE;
            end

            default: begin
                state_d = IDLE;
            end
        endcase
    end

    always @(*) begin
        oUartTx = 1'b1;
        oTxBusy = 1'b0;
        oTxDone = 1'b0;

        case (state)
            START: begin
                oUartTx = 1'b0;
                oTxBusy = 1'b1;
            end

            DATA: begin
                oUartTx = shift[bitCnt];
                oTxBusy = 1'b1;
            end

            STOP: begin
                oUartTx = 1'b1;
                oTxBusy = 1'b1;
            end

            DONE: begin
                oUartTx = 1'b1;
                oTxBusy = 1'b1;
                oTxDone = 1'b1;
            end

            default: begin
                oUartTx = 1'b1;
                oTxBusy = 1'b0;
                oTxDone = 1'b0;
            end
        endcase
    end

endmodule
