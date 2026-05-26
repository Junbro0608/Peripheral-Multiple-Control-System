/*
[MODULE_INFO_START]
Name: WatchFsm
Role: Watch 모드의 런/편집(Edit) 상태를 관리하는 컨트롤러 (2-State Moore)
Summary:
  - RUN과 EDIT 2개의 상태로만 동작하며 3-always block Moore FSM 형식을 강제
  - InputDistributor의 cmdCode(oCmdCode) 신호를 기반으로 한 Toggle 명령 수신
  - 상태 및 보조 레지스터(editUnit)에 맞추어 FND의 깜빡임 출력(Blink Mask) 처리
StateDescription:
  - RUN: 시계가 정상적으로 동작하며 시각을 출력 (기본 상태, 편집 중 아님)
  - EDIT: 편집 상태 진입 (내부의 editUnit 값에 따라 좌측/우측 깜빡임 변경)
[MODULE_INFO_END]
*/

module WatchFsm (
    input  wire        iClk,
    input  wire        iRstn,

    // Controls (From InputDistributor / ControlUnit)
    input  wire        iEditModeToggle, // LP_CMD_WATCH_EDITMODE_TOGGLE
    input  wire        iEditUnitToggle, // LP_CMD_WATCH_EDITDIGIT_NEXT
    
    // Outputs
    output reg         oRun,
    output reg         oEditEn,
    output reg         oEditUnit,
    output reg  [3:0]  oBlinkMask
);

    localparam RUN  = 1'b0;
    localparam EDIT = 1'b1;

    reg state, state_d;
    reg editUnit, editUnit_d; // 0: Left, 1: Right

    // 1) 상태 레지스터 (Sequential)
    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            state    <= RUN;
            editUnit <= 1'b0;
        end else begin
            state    <= state_d;
            editUnit <= editUnit_d;
        end
    end

    // 2) 차기 상태 및 단위 결정 (Combinational)
    always @(*) begin
        state_d    = state;
        editUnit_d = editUnit;

        case (state)
            RUN: begin
                if (iEditModeToggle) begin
                    state_d    = EDIT;
                    editUnit_d = 1'b0; // 편집 진입 시 항상 왼쪽부터 시작
                end
            end
            EDIT: begin
                if (iEditModeToggle) begin
                    state_d = RUN;
                end else if (iEditUnitToggle) begin
                    editUnit_d = ~editUnit;
                end
            end
            default: begin
                state_d = RUN;
            end
        endcase
    end

    // 3) 출력 로직 (Moore: state 조합 레지스터에만 의존)
    always @(*) begin
        oRun       = 1'b0;
        oEditEn    = 1'b0;
        oEditUnit  = 1'b0;
        oBlinkMask = 4'b0000;

        case (state)
            RUN: begin
                oRun       = 1'b1;
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
