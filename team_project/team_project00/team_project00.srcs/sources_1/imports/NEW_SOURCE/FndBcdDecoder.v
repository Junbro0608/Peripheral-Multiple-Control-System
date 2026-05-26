/*
[MODULE_INFO_START]
Name: FndBcdDecoder
Role: 논리 BCD 값을 물리적 LED 선호도로 변환하는 렌더러
Summary:
  - 깜빡임 블랭킹 신호를 받아 완전 소등 처리
  - 0 ~ 9 및 보조 문자열을 7-Segment 하드웨어 핀 배열(Active-Low)으로 해독
StateDescription:
[MODULE_INFO_END]
*/
module FndBcdDecoder (
    input  wire [3:0] iCurBcd,
    input  wire       iBlanking,
    output reg  [6:0] oSeg
);
    always @(*) begin
        if (iBlanking) begin
            oSeg = 7'b111_1111;
        end else begin
            case (iCurBcd)
                4'h0: oSeg = 7'b100_0000;
                4'h1: oSeg = 7'b111_1001;
                4'h2: oSeg = 7'b010_0100;
                4'h3: oSeg = 7'b011_0000;
                4'h4: oSeg = 7'b001_1001;
                4'h5: oSeg = 7'b001_0010;
                4'h6: oSeg = 7'b000_0010;
                4'h7: oSeg = 7'b101_1000;
                4'h8: oSeg = 7'b000_0000;
                4'h9: oSeg = 7'b001_0000;
                4'hA: oSeg = 7'b000_1000;
                4'hB: oSeg = 7'b000_0011;
                4'hC: oSeg = 7'b100_0110;
                4'hD: oSeg = 7'b010_0001;
                4'hE: oSeg = 7'b000_0110;
                4'hF: oSeg = 7'b000_1110;
                default: oSeg = 7'b111_1111;
            endcase
        end
    end
endmodule
