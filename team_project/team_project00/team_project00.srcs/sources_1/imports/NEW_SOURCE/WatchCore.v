/*
[MODULE_INFO_START]
Name: WatchCore
Role: Watch mode wrapper integrating FSM and counter.
Summary:
  - Decodes command pulses for watch domain.
  - Controls edit state via WatchFsm.
  - Generates display/full data through WatchCounter.
[MODULE_INFO_END]
*/
module WatchCore (
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

    localparam [1:0] LP_MODE_WATCH                = 2'd0;
    localparam [4:0] LP_CMD_MODE_LOCAL_RESET      = 5'd3;
    localparam [4:0] LP_CMD_WATCH_FMT_TOGGLE      = 5'd4;
    localparam [4:0] LP_CMD_WATCH_EDITMODE_TOGGLE = 5'd5;
    localparam [4:0] LP_CMD_WATCH_EDITDIGIT_NEXT  = 5'd6;
    localparam [4:0] LP_CMD_EDIT_INC              = 5'd20;
    localparam [4:0] LP_CMD_EDIT_DEC              = 5'd21;

    wire wRun;
    wire wEditEn;
    wire wEditUnit;

    wire wFormatToggle   = iCmdValid && (iCmdCode == LP_CMD_WATCH_FMT_TOGGLE);
    wire wEditModeToggle = iCmdValid && (iCmdCode == LP_CMD_WATCH_EDITMODE_TOGGLE);
    wire wEditUnitToggle = iCmdValid && (iCmdCode == LP_CMD_WATCH_EDITDIGIT_NEXT);
    wire wResetTime      = iCmdValid && (iCmdCode == LP_CMD_MODE_LOCAL_RESET) && (iMode == LP_MODE_WATCH);
    wire wInc            = iCmdValid && (iCmdCode == LP_CMD_EDIT_INC) && (iMode == LP_MODE_WATCH);
    wire wDec            = iCmdValid && (iCmdCode == LP_CMD_EDIT_DEC) && (iMode == LP_MODE_WATCH);

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

    WatchFsm uWatchFsm (
        .iClk            (iClk),
        .iRstn           (iRstn),
        .iEditModeToggle (wEditModeToggle),
        .iEditUnitToggle (wEditUnitToggle),
        .oRun            (wRun),
        .oEditEn         (wEditEn),
        .oEditUnit       (wEditUnit),
        .oBlinkMask      (oBlinkMask)
    );

    WatchCounter uWatchCounter (
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
