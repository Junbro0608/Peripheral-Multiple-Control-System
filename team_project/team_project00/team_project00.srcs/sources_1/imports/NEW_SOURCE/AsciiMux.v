/*
[MODULE_INFO_START]
Name: AsciiMux
Role: PC TX payload selector and formatter input mux.
Summary:
  - Selects payload based on command code.
  - Converts sensor data to BCD payload for ASCII sender.
  - Emits one-cycle start pulse with payload and explicit TX mode.
[MODULE_INFO_END]
*/
module AsciiMux (
    input  wire        iClk,
    input  wire        iRstn,

    // Command context
    input  wire [1:0]  iMode,
    input  wire        iModeLock,
    input  wire        iCmdValid,
    input  wire [4:0]  iCmdCode,

    // Core Outputs
    input  wire [31:0] iWatchFullData,
    input  wire [31:0] iStopFullData,
    input  wire [15:0] iHcsr04Distance,
    input  wire [15:0] iDht11Temp,
    input  wire [15:0] iDht11Humi,
    input  wire        iWatchEditActive,
    input  wire        iStopEditActive,
    input  wire        iHcsrAutoRun,
    input  wire        iDht11AutoRun,

    // FND mux result
    input  wire [15:0] iDisplayBcd,

    // Outputs to ASCII sender
    output reg         oTxStart,
    output reg  [31:0] oTxBcdData,
    output reg  [1:0]  oTxMode
);

    wire [15:0] wHcsrBcd;
    wire [13:0] wHcsrBin = (iHcsr04Distance > 16'd9999) ? 14'd9999 : iHcsr04Distance[13:0];

    DoubleDabble uHcsrDabble_Tx (
        .iBin (wHcsrBin),
        .oBcd (wHcsrBcd)
    );

    wire [15:0] wDhtTempBcd;
    wire [13:0] wDhtTxTempBin = iDht11Temp[15:8];
    DoubleDabble uDhtDabble_TxTemp (
        .iBin (wDhtTxTempBin),
        .oBcd (wDhtTempBcd)
    );

    wire [15:0] wDhtHumiBcd;
    wire [13:0] wDhtTxHumiBin = iDht11Humi[15:8];
    DoubleDabble uDhtDabble_TxHumi (
        .iBin (wDhtTxHumiBin),
        .oBcd (wDhtHumiBcd)
    );

    localparam [4:0] LP_CMD_SHOW_FND       = 5'd14;
    localparam [4:0] LP_CMD_SHOW_STATE     = 5'd15;
    localparam [4:0] LP_CMD_SHOW_STOPWATCH = 5'd16;
    localparam [4:0] LP_CMD_SHOW_WATCH     = 5'd17;
    localparam [4:0] LP_CMD_SHOW_HCSR04    = 5'd18;
    localparam [4:0] LP_CMD_SHOW_DHT11     = 5'd19;

    wire wEditActive = ((iMode == 2'd0) && iWatchEditActive) || ((iMode == 2'd1) && iStopEditActive);
    wire wAutoActive = ((iMode == 2'd2) && iHcsrAutoRun) || ((iMode == 2'd3) && iDht11AutoRun);

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oTxStart   <= 1'b0;
            oTxBcdData <= 32'd0;
            oTxMode    <= 2'd0;
        end else begin
            oTxStart <= 1'b0;
            oTxMode  <= 2'd0;

            if (iCmdValid) begin
                case (iCmdCode)
                    LP_CMD_SHOW_FND: begin
                        oTxStart   <= 1'b1;
                        oTxBcdData <= {16'd0, iDisplayBcd};
                        oTxMode    <= 2'd0;
                    end
                    LP_CMD_SHOW_STATE: begin
                        oTxStart   <= 1'b1;
                        oTxBcdData <= {27'd0, wAutoActive, wEditActive, iModeLock, iMode};
                        oTxMode    <= 2'd1;
                    end
                    LP_CMD_SHOW_WATCH: begin
                        oTxStart   <= 1'b1;
                        oTxBcdData <= iWatchFullData;
                        oTxMode    <= 2'd0;
                    end
                    LP_CMD_SHOW_STOPWATCH: begin
                        oTxStart   <= 1'b1;
                        oTxBcdData <= iStopFullData;
                        oTxMode    <= 2'd0;
                    end
                    LP_CMD_SHOW_HCSR04: begin
                        oTxStart   <= 1'b1;
                        oTxBcdData <= {16'h0000, wHcsrBcd};
                        oTxMode    <= 2'd2;
                    end
                    LP_CMD_SHOW_DHT11: begin
                        oTxStart   <= 1'b1;
                        oTxBcdData <= {wDhtHumiBcd[7:0], 8'h00, wDhtTempBcd[7:0], 8'h00};
                        oTxMode    <= 2'd3;
                    end
                    default: begin
                        // no-op
                    end
                endcase
            end
        end
    end

endmodule
