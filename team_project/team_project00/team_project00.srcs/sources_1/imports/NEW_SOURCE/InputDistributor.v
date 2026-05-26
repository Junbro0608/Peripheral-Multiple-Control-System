/*
[MODULE_INFO_START]
Name: InputDistributor
Role: Converts merged input events into compact core command outputs.
Summary:
  - Maintains current mode state and applies global/mode-specific command mapping.
  - Converts button/switch/UART requests into one-cycle command code outputs.
  - Exposes compact outputs for core integration: mode, mode-lock, cmd-valid, cmd-code.
[MODULE_INFO_END]
*/

module InputDistributor(
    input  wire       iClk,
    input  wire       iRst,
    input  wire [4:0] iBtnPulse,
    input  wire [2:0] iSwLevel,
    input  wire [2:0] iSwPulse,
    input  wire       iReqFnd,
    input  wire       iReqState,
    input  wire       iReqStopwatch,
    input  wire       iReqWatch,
    input  wire       iReqHcsr04,
    input  wire       iReqDht11,
    output reg  [1:0] oMode,
    output wire       oModeLock,
    output reg        oCmdValid,
    output reg  [4:0] oCmdCode
);

    localparam [1:0] LP_MODE_WATCH     = 2'd0;
    localparam [1:0] LP_MODE_STOPWATCH = 2'd1;
    localparam [1:0] LP_MODE_HCSR04    = 2'd2;
    localparam [1:0] LP_MODE_DHT11     = 2'd3;

    localparam [4:0] LP_CMD_NONE                 = 5'd0;
    localparam [4:0] LP_CMD_GLOBAL_RESET         = 5'd1;
    localparam [4:0] LP_CMD_MODE_NEXT            = 5'd2;
    localparam [4:0] LP_CMD_MODE_LOCAL_RESET     = 5'd3;
    localparam [4:0] LP_CMD_WATCH_FMT_TOGGLE     = 5'd4;
    localparam [4:0] LP_CMD_WATCH_EDITMODE_TOGGLE= 5'd5;
    localparam [4:0] LP_CMD_WATCH_EDITDIGIT_NEXT = 5'd6;
    localparam [4:0] LP_CMD_STOP_FMT_TOGGLE      = 5'd7;
    localparam [4:0] LP_CMD_STOP_EDITMODE_TOGGLE = 5'd8;
    localparam [4:0] LP_CMD_STOP_EDITDIGIT_NEXT  = 5'd9;
    localparam [4:0] LP_CMD_HCSR_AUTO_TOGGLE     = 5'd10;
    localparam [4:0] LP_CMD_HCSR_MANUAL_MEASURE  = 5'd11;
    localparam [4:0] LP_CMD_DHT_AUTO_TOGGLE      = 5'd12;
    localparam [4:0] LP_CMD_DHT_MANUAL_MEASURE   = 5'd13;
    localparam [4:0] LP_CMD_SHOW_FND             = 5'd14;
    localparam [4:0] LP_CMD_SHOW_STATE           = 5'd15;
    localparam [4:0] LP_CMD_SHOW_STOPWATCH       = 5'd16;
    localparam [4:0] LP_CMD_SHOW_WATCH           = 5'd17;
    localparam [4:0] LP_CMD_SHOW_HCSR04          = 5'd18;
    localparam [4:0] LP_CMD_SHOW_DHT11           = 5'd19;
    localparam [4:0] LP_CMD_EDIT_INC             = 5'd20;
    localparam [4:0] LP_CMD_EDIT_DEC             = 5'd21;
    // Command code map:
    //  1: Global reset
    //  2: Mode next
    //  3: Mode-local reset (L)
    //  4/5/6: Watch format/editmode/edit-digit-next
    //  7/8/9: Stopwatch format/editmode/edit-digit-next
    // 10/11: HCSR04 auto-toggle/manual-measure
    // 12/13: DHT11  auto-toggle/manual-measure
    // 14..19: Show requests S,Q,T,Y,H,J

    reg  [1:0] mode_d;
    reg        cmdValid_d;
    reg  [4:0] cmdCode_d;

    wire wBtnU;
    wire wBtnC;
    wire wBtnD;
    wire wBtnR;
    wire wBtnL;
    wire wSw1Pulse;
    wire wSw2Pulse;
    wire wSw3Pulse;
    reg  rModeLockPc;

    assign wBtnU      = iBtnPulse[4];
    assign wBtnC      = iBtnPulse[3];
    assign wBtnD      = iBtnPulse[2];
    assign wBtnR      = iBtnPulse[1];
    assign wBtnL      = iBtnPulse[0];
    assign wSw1Pulse  = iSwPulse[0];
    assign wSw2Pulse  = iSwPulse[1];
    assign wSw3Pulse  = iSwPulse[2];
    assign oModeLock  = iSwLevel[2] | rModeLockPc;

    // Registered outputs (sequential)
    always @(posedge iClk or posedge iRst) begin
        if (iRst) begin
            oMode     <= LP_MODE_WATCH;
            oCmdValid <= 1'b0;
            oCmdCode  <= LP_CMD_NONE;
            rModeLockPc <= 1'b0;
        end else begin
            oMode     <= mode_d;
            oCmdValid <= cmdValid_d;
            oCmdCode  <= cmdCode_d;
            if (wSw3Pulse) begin
                rModeLockPc <= ~rModeLockPc;
            end
        end
    end

    // Next-state / next-command combinational logic
    always @(*) begin
        mode_d     = oMode;
        cmdValid_d = 1'b0;
        cmdCode_d  = LP_CMD_NONE;

        // Priority:
        // 1) Global reset
        // 2) UART display/status requests (S,Q,T,Y,H,J)
        // 3) Mode-local/global controls from merged buttons/switches
        if (wBtnC) begin
            mode_d     = LP_MODE_WATCH;
            cmdValid_d = 1'b1;
            cmdCode_d  = LP_CMD_GLOBAL_RESET;
        end else if (iReqFnd) begin
            cmdValid_d = 1'b1;
            cmdCode_d  = LP_CMD_SHOW_FND;
        end else if (iReqState) begin
            cmdValid_d = 1'b1;
            cmdCode_d  = LP_CMD_SHOW_STATE;
        end else if (iReqStopwatch) begin
            cmdValid_d = 1'b1;
            cmdCode_d  = LP_CMD_SHOW_STOPWATCH;
        end else if (iReqWatch) begin
            cmdValid_d = 1'b1;
            cmdCode_d  = LP_CMD_SHOW_WATCH;
        end else if (iReqHcsr04) begin
            cmdValid_d = 1'b1;
            cmdCode_d  = LP_CMD_SHOW_HCSR04;
        end else if (iReqDht11) begin
            cmdValid_d = 1'b1;
            cmdCode_d  = LP_CMD_SHOW_DHT11;
        end else if (wBtnL) begin
            cmdValid_d = 1'b1;
            cmdCode_d  = LP_CMD_MODE_LOCAL_RESET;
        end else if (wBtnR) begin
            cmdValid_d = 1'b1;
            if (!oModeLock) begin
                mode_d    = (oMode == LP_MODE_DHT11) ? LP_MODE_WATCH : (oMode + 2'd1);
                cmdCode_d = LP_CMD_MODE_NEXT;
            end else begin
                case (oMode)
                    LP_MODE_WATCH:     cmdCode_d = LP_CMD_WATCH_EDITDIGIT_NEXT;
                    LP_MODE_STOPWATCH: cmdCode_d = LP_CMD_STOP_EDITDIGIT_NEXT;
                    LP_MODE_HCSR04:    cmdCode_d = LP_CMD_HCSR_AUTO_TOGGLE;
                    default:           cmdCode_d = LP_CMD_DHT_AUTO_TOGGLE;
                endcase
            end
        end else if (wBtnD) begin
            case (oMode)
                LP_MODE_WATCH,
                LP_MODE_STOPWATCH: begin
                    cmdValid_d = 1'b1;
                    cmdCode_d  = LP_CMD_EDIT_DEC;
                end
                LP_MODE_HCSR04: begin
                    cmdValid_d = 1'b1;
                    cmdCode_d  = LP_CMD_HCSR_MANUAL_MEASURE;
                end
                LP_MODE_DHT11: begin
                    cmdValid_d = 1'b1;
                    cmdCode_d  = LP_CMD_DHT_MANUAL_MEASURE;
                end
                default: begin
                    cmdValid_d = 1'b0;
                    cmdCode_d  = LP_CMD_NONE;
                end
            endcase
        end else if (wSw1Pulse) begin
            case (oMode)
                LP_MODE_WATCH: begin
                    cmdValid_d = 1'b1;
                    cmdCode_d  = LP_CMD_WATCH_FMT_TOGGLE;
                end
                LP_MODE_STOPWATCH: begin
                    cmdValid_d = 1'b1;
                    cmdCode_d  = LP_CMD_STOP_FMT_TOGGLE;
                end
                default: begin
                    cmdValid_d = 1'b0;
                    cmdCode_d  = LP_CMD_NONE;
                end
            endcase
        end else if (wSw2Pulse) begin
            case (oMode)
                LP_MODE_WATCH: begin
                    cmdValid_d = 1'b1;
                    cmdCode_d  = LP_CMD_WATCH_EDITMODE_TOGGLE;
                end
                LP_MODE_STOPWATCH: begin
                    cmdValid_d = 1'b1;
                    cmdCode_d  = LP_CMD_STOP_EDITMODE_TOGGLE;
                end
                default: begin
                    cmdValid_d = 1'b0;
                    cmdCode_d  = LP_CMD_NONE;
                end
            endcase
        end else if (wBtnU) begin
            case (oMode)
                LP_MODE_WATCH,
                LP_MODE_STOPWATCH: begin
                    cmdValid_d = 1'b1;
                    cmdCode_d  = LP_CMD_EDIT_INC;
                end
                default: begin
                    cmdValid_d = 1'b0;
                    cmdCode_d  = LP_CMD_NONE;
                end
            endcase
        end
    end

endmodule
