/*
[MODULE_INFO_START]
Name: FndDigitSelector
Role: 인덱스 기반 자릿수 위치 및 데이터 맵핑기
Summary:
  - 현재 출력할 자릿수 인덱스에 매칭되는 BCD값, 깜빡임, 점(DP) 마스크 데이터 매핑 분리
  - 최종 FND Anode 선택 핀 매핑 (Active-Low)
StateDescription:
[MODULE_INFO_END]
*/
module FndDigitSelector (
    input  wire [1:0]  iScanIdx,
    input  wire [15:0] iDigitsBcd,
    input  wire [3:0]  iBlinkMask,
    input  wire [3:0]  iDpMask,
    output reg  [3:0]  oDigitSel,
    output reg  [3:0]  oCurBcd,
    output reg         oCurBlink,
    output reg         oCurDp
);
    always @(*) begin
        case (iScanIdx)
            2'd0: begin
                oDigitSel = 4'b1110;
                oCurBcd   = iDigitsBcd[3:0];
                oCurBlink = iBlinkMask[0];
                oCurDp    = iDpMask[0];
            end
            2'd1: begin
                oDigitSel = 4'b1101;
                oCurBcd   = iDigitsBcd[7:4];
                oCurBlink = iBlinkMask[1];
                oCurDp    = iDpMask[1];
            end
            2'd2: begin
                oDigitSel = 4'b1011;
                oCurBcd   = iDigitsBcd[11:8];
                oCurBlink = iBlinkMask[2];
                oCurDp    = iDpMask[2];
            end
            default: begin // 2'd3
                oDigitSel = 4'b0111;
                oCurBcd   = iDigitsBcd[15:12];
                oCurBlink = iBlinkMask[3];
                oCurDp    = iDpMask[3];
            end
        endcase
    end
endmodule
