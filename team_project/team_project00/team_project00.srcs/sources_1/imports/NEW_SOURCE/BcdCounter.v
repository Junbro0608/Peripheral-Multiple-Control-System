/*
[MODULE_INFO_START]
Name: BcdCounter
Role: 범용 2자리 BCD 카운터 (00 ~ MAX_VAL)
Summary:
  - 파라미터로 최대 10의 자리(P_MAX_TENS)와 1의 자리(P_MAX_ONES)를 설정하여 유연하게 재사용 가능
  - 하위 모듈에서 올라오는 iTick을 받아 증가하며, MAX 치달 시 oCarry를 발생시켜 상위 카운터로 전달
  - 사용자 수동 증감 (iInc, iDec) 입력을 지원하며 롤오버/언더플로우를 자동 처리
StateDescription:
[MODULE_INFO_END]
*/
module BcdCounter #(
    parameter P_MAX_TENS = 5,
    parameter P_MAX_ONES = 9,
    parameter P_RST_TENS = 0,
    parameter P_RST_ONES = 0
)(
    input  wire       iClk,
    input  wire       iRstn,

    // Controls
    input  wire       iTick,  // 하위 단위에서 넘어온 자리올림(Pulse)
    input  wire       iInc,   // 수동 증가 펄스 (해당 자리 편집용)
    input  wire       iDec,   // 수동 감소 펄스 (해당 자리 편집용)
    input  wire       iReset, // 강제 초기화 (00으로)

    // Outputs
    output reg  [3:0] oTens,
    output reg  [3:0] oOnes,
    output wire       oCarry  // 현재 단위가 MAX일 때 iTick이 들어오면 다음 단위로 Carry 발생
);

    reg [3:0] tens_d, ones_d;

    // Tick 발생 시 현재 값이 최댓값(MAX_TENS, MAX_ONES)이라면 다음 단위를 증가시키기 위해 Carry 발생
    assign oCarry = iTick && (oTens == P_MAX_TENS) && (oOnes == P_MAX_ONES);

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oTens <= P_RST_TENS[3:0];
            oOnes <= P_RST_ONES[3:0];
        end else begin
            oTens <= tens_d;
            oOnes <= ones_d;
        end
    end

    // Combinational logic for counting
    always @(*) begin
        // 유지
        tens_d = oTens;
        ones_d = oOnes;

        if (iReset) begin
            tens_d = P_RST_TENS[3:0];
            ones_d = P_RST_ONES[3:0];
        end else if (iInc || iTick) begin
            // 최대치 도달 시(예: 59, 23, 99) -> 00으로 롤오버
            if (oTens == P_MAX_TENS && oOnes == P_MAX_ONES) begin
                tens_d = 4'd0;
                ones_d = 4'd0;
            end else if (oOnes == 4'd9) begin
                // 1의 자리가 9이면 -> 10의 자리 증가, 1의 자리는 0
                tens_d = oTens + 1'b1;
                ones_d = 4'd0;
            end else begin
                // 단순히 1의 자리 증가
                ones_d = oOnes + 1'b1;
            end
        end else if (iDec) begin
            // 00 도달 시 -> 최대치로 언더플로우
            if (oTens == 4'd0 && oOnes == 4'd0) begin
                tens_d = P_MAX_TENS;
                ones_d = P_MAX_ONES;
            end else if (oOnes == 4'd0) begin
                // 1의 자리가 0이면 -> 10의 자리 감소, 1의 자리는 9
                tens_d = oTens - 1'b1;
                ones_d = 4'd9;
            end else begin
                // 단순히 1의 자리 감소
                ones_d = oOnes - 1'b1;
            end
        end
    end

endmodule
