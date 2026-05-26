/*
[MODULE_INFO_START]
Name: FndBlinkEffect
Role: 2Hz 애니메이션 점멸 효과 오버레이
Summary:
  - 시계/스톱워치 수정 중 해당 자릿수가 반짝이는 블랭킹(Blanking) 효과 0.5초(2Hz) 적용
  - 중앙의 콜론 구분을 위한 점등 효과 0.5초 지원
StateDescription:
[MODULE_INFO_END]
*/
module FndBlinkEffect (
    input  wire       iClk,
    input  wire       iRstn,
    input  wire       iTick2Hz,
    input  wire       iCurBlink,
    input  wire       iCurDp,
    output wire       oBlanking,
    output wire       oFinalDp
);
    reg blinkToggle;

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            blinkToggle <= 1'b0;
        end else if (iTick2Hz) begin
            blinkToggle <= ~blinkToggle;
        end
    end

    assign oBlanking = (iCurBlink == 1'b1) && (blinkToggle == 1'b0);
    assign oFinalDp  = iCurDp ? ~blinkToggle : 1'b1; // Active Low
endmodule
