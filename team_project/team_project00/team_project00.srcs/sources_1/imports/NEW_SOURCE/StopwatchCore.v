/*
[MODULE_INFO_START]
Name: StopwatchCore
Role: Stopwatch mode wrapper integrating FSM and counter.
Summary:
  - Decodes stopwatch-specific command pulses.
  - Controls run/edit state through StopwatchFsm.
  - Generates display/full data through StopwatchCounter.
[MODULE_INFO_END]
*/
module StopwatchCore (
    input  wire        iClk,
    input  wire        iRstn,

    input  wire        iTick1kHz,
    input  wire [1:0]  iMode,
    input  wire        iCmdValid,
    input  wire [4:0]  iCmdCode,

    output wire [15:0] oFndData,
    output wire [31:0] oFullData,
    output wire [3:0]  oBlinkMask,
    output wire [3:0]  oDotMask,
    output wire        oEditActive
);

    localparam [1:0] LP_MODE_STOPWATCH            = 2'd1;
    localparam [4:0] LP_CMD_MODE_LOCAL_RESET      = 5'd3;
    localparam [4:0] LP_CMD_STOP_FMT_TOGGLE       = 5'd7;
    localparam [4:0] LP_CMD_STOP_EDITMODE_TOGGLE  = 5'd8;
    localparam [4:0] LP_CMD_STOP_EDITDIGIT_NEXT   = 5'd9;
    localparam [4:0] LP_CMD_EDIT_INC              = 5'd20;
    localparam [4:0] LP_CMD_EDIT_DEC              = 5'd21;

    wire wRun;
    wire wEditEn;
    wire wEditUnit;

    wire wFormatToggle   = iCmdValid && (iCmdCode == LP_CMD_STOP_FMT_TOGGLE);
    wire wEditModeToggle = iCmdValid && (iCmdCode == LP_CMD_STOP_EDITMODE_TOGGLE);
    wire wRightCmd       = iCmdValid && (iCmdCode == LP_CMD_STOP_EDITDIGIT_NEXT);
    wire wEditUnitToggle = wRightCmd && wEditEn;
    wire wRunToggle      = wRightCmd && !wEditEn;
    wire wResetTime      = iCmdValid && (iCmdCode == LP_CMD_MODE_LOCAL_RESET) && (iMode == LP_MODE_STOPWATCH);
    wire wInc            = iCmdValid && (iCmdCode == LP_CMD_EDIT_INC) && (iMode == LP_MODE_STOPWATCH);
    wire wDec            = iCmdValid && (iCmdCode == LP_CMD_EDIT_DEC) && (iMode == LP_MODE_STOPWATCH);

    reg formatFlag;
    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            formatFlag <= 1'b0;
        end else if (wFormatToggle) begin
            formatFlag <= ~formatFlag;
        end
    end

    assign oDotMask    = 4'b0100;
    assign oEditActive = wEditEn;

    StopwatchFsm uStopwatchFsm (
        .iClk            (iClk),
        .iRstn           (iRstn),
        .iEditModeToggle (wEditModeToggle),
        .iEditUnitToggle (wEditUnitToggle),
        .iRunToggle      (wRunToggle),
        .iPauseReq       (wResetTime),
        .oRun            (wRun),
        .oEditEn         (wEditEn),
        .oEditUnit       (wEditUnit),
        .oBlinkMask      (oBlinkMask)
    );

    StopwatchCounter uStopwatchCounter (
        .iClk       (iClk),
        .iRstn      (iRstn),
        .iTick1kHz  (iTick1kHz),
        .iRun       (wRun),
        .iFormat    (formatFlag),
        .iEditEn    (wEditEn),
        .iEditUnit  (wEditUnit),
        .iInc       (wInc),
        .iDec       (wDec),
        .iResetTime (wResetTime),
        .oFndData   (oFndData),
        .oFullData  (oFullData)
    );

endmodule
