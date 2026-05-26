/*
[MODULE_INFO_START]
Name: GlobalTickGen
Role: 전체 시스템에서 공통으로 사용할 기준 틱(Tick) 신호를 생성
Summary:
  - 시스템 클럭(P_SYS_CLK_HZ)을 분주하여 딱 1클럭 주기를 갖는 1kHz(1ms) 및 2Hz(0.5s) 틱 펄스를 출력
  - 1kHz 틱: FND 다이나믹 스캐닝 및 시계/스톱워치 모듈의 시간 측정 기준값으로 활용
  - 2Hz 틱: 편집 모드 등에서 UI(FND Segment)의 0.5초 주기 깜빡임(Blink)을 제어하는 데 활용
StateDescription:
[MODULE_INFO_END]
*/

module GlobalTickGen #(
    parameter P_SYS_CLK_HZ = 100_000_000
) (
    input  wire iClk,
    input  wire iRstn,

    // Outputs (1사이클 펄스)
    output reg  oTick1kHz,
    output reg  oTick2Hz
);
    localparam LP_1KHZ_CYCLES = P_SYS_CLK_HZ / 1_000;
    localparam LP_2HZ_CYCLES  = P_SYS_CLK_HZ / 2;

    reg [23:0] cnt1kHz;
    reg [26:0] cnt2Hz;

    // 1kHz (1ms) 1-Cycle Pulse 생성 로직
    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            cnt1kHz   <= 24'd0;
            oTick1kHz <= 1'b0;
        end else begin
            if (cnt1kHz >= (LP_1KHZ_CYCLES - 1)) begin
                cnt1kHz   <= 24'd0;
                oTick1kHz <= 1'b1; // 딱 1클럭(10ns) 동안만 High 유지
            end else begin
                cnt1kHz   <= cnt1kHz + 1'b1;
                oTick1kHz <= 1'b0;
            end
        end
    end
    // 2Hz (0.5s) 1-Cycle Pulse 생성 로직
    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            cnt2Hz   <= 27'd0;
            oTick2Hz <= 1'b0;
        end else begin
            if (cnt2Hz >= (LP_2HZ_CYCLES - 1)) begin
                cnt2Hz   <= 27'd0;
                oTick2Hz <= 1'b1; // 딱 1클럭(10ns) 동안만 High 유지
            end else begin
                cnt2Hz   <= cnt2Hz + 1'b1;
                oTick2Hz <= 1'b0;
            end
        end
    end

endmodule
