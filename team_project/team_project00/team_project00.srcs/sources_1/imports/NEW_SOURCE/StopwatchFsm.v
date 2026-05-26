/*
[MODULE_INFO_START]
Name: StopwatchFsm
Role: Stopwatch run/edit FSM.
Summary:
  - Controls run enable, edit enable, edit unit, and blink mask.
  - After reset, stopwatch starts in paused RUN state (oRun=0).
[MODULE_INFO_END]
*/
module StopwatchFsm (
    input  wire        iClk,
    input  wire        iRstn,
    input  wire        iEditModeToggle,
    input  wire        iEditUnitToggle,
    input  wire        iRunToggle,
    input  wire        iPauseReq,

    output reg         oRun,
    output reg         oEditEn,
    output reg         oEditUnit,
    output reg  [3:0]  oBlinkMask
);

    localparam RUN  = 1'b0;
    localparam EDIT = 1'b1;

    reg state;
    reg state_d;
    reg editUnit;
    reg editUnit_d;
    reg runArmed;
    reg runArmed_d;

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            state    <= RUN;
            editUnit <= 1'b0;
            runArmed <= 1'b0;
        end else begin
            state    <= state_d;
            editUnit <= editUnit_d;
            runArmed <= runArmed_d;
        end
    end

    always @(*) begin
        state_d    = state;
        editUnit_d = editUnit;
        runArmed_d = runArmed;

        if (iPauseReq) begin
            state_d    = RUN;
            editUnit_d = 1'b0;
            runArmed_d = 1'b0;
        end else begin
            case (state)
                RUN: begin
                    if (iEditModeToggle) begin
                        state_d    = EDIT;
                        editUnit_d = 1'b0;
                    end else if (iRunToggle) begin
                        runArmed_d = ~runArmed;
                    end
                end

                EDIT: begin
                    if (iEditModeToggle) begin
                        state_d    = RUN;
                    end else if (iEditUnitToggle) begin
                        editUnit_d = ~editUnit;
                    end
                end

                default: begin
                    state_d = RUN;
                end
            endcase
        end
    end

    always @(*) begin
        oRun       = 1'b0;
        oEditEn    = 1'b0;
        oEditUnit  = 1'b0;
        oBlinkMask = 4'b0000;

        case (state)
            RUN: begin
                oRun       = runArmed;
                oEditEn    = 1'b0;
                oEditUnit  = 1'b0;
                oBlinkMask = 4'b0000;
            end

            EDIT: begin
                oRun      = 1'b0;
                oEditEn   = 1'b1;
                oEditUnit = editUnit;
                if (editUnit == 1'b0) begin
                    oBlinkMask = 4'b1100;
                end else begin
                    oBlinkMask = 4'b0011;
                end
            end

            default: begin
                oRun       = 1'b0;
                oEditEn    = 1'b0;
                oEditUnit  = 1'b0;
                oBlinkMask = 4'b0000;
            end
        endcase
    end

endmodule
