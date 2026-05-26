/*
[MODULE_INFO_START]
Name: uart_rx
Role: UART receiver based on Moore FSM.
Summary:
  - Detects start bit, samples 8 data bits (LSB first), and validates stop bit.
  - Uses synchronized RX input and 16x oversampling tick.
  - Provides one-cycle oRxValid pulse in DONE state when a byte is received.
StateDescription:
  - IDLE: Waits for start-bit falling edge.
  - START: Confirms start bit at half-bit timing.
  - DATA: Samples 8 data bits at bit boundaries.
  - STOP: Checks stop bit level at bit boundary.
  - DONE: Pulses oRxValid and returns to IDLE.
[MODULE_INFO_END]
*/

module uart_rx(
    input  wire       iClk,
    input  wire       iRst,
    input  wire       iSampleTick,
    input  wire       iUartRx,
    output wire       oRxValid,
    output wire [7:0] oRxData
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
    reg [7:0] rxData;
    reg [7:0] rxData_d;

    wire wRxSync;

    sync_2ff uRxSync2ff (
        .iAsync(iUartRx),
        .iClk  (iClk),
        .iRst  (iRst),
        .oSync (wRxSync)
    );

    always @(posedge iClk or posedge iRst) begin
        if (iRst) begin
            state     <= IDLE;
            sampleCnt <= 4'd0;
            bitCnt    <= 3'd0;
            shift     <= 8'd0;
            rxData    <= 8'd0;
        end else begin
            state     <= state_d;
            sampleCnt <= sampleCnt_d;
            bitCnt    <= bitCnt_d;
            shift     <= shift_d;
            rxData    <= rxData_d;
        end
    end

    always @(*) begin
        state_d     = state;
        sampleCnt_d = sampleCnt;
        bitCnt_d    = bitCnt;
        shift_d     = shift;
        rxData_d    = rxData;

        case (state)
            IDLE: begin
                sampleCnt_d = 4'd0;
                bitCnt_d    = 3'd0;
                if (~wRxSync) begin
                    state_d = START;
                end
            end

            START: begin
                if (iSampleTick) begin
                    if (sampleCnt == 4'd7) begin
                        sampleCnt_d = 4'd0;
                        if (~wRxSync) begin
                            bitCnt_d = 3'd0;
                            state_d  = DATA;
                        end else begin
                            state_d = IDLE;
                        end
                    end else begin
                        sampleCnt_d = sampleCnt + 1'b1;
                    end
                end
            end

            DATA: begin
                if (iSampleTick) begin
                    if (sampleCnt == 4'd15) begin
                        sampleCnt_d      = 4'd0;
                        shift_d[bitCnt]  = wRxSync;
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
                        if (wRxSync) begin
                            rxData_d = shift;
                            state_d  = DONE;
                        end else begin
                            state_d = IDLE;
                        end
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
    
    assign oRxValid = (state == DONE);
    assign oRxData  = rxData;

endmodule
