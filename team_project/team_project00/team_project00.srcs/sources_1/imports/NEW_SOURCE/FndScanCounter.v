/*
[MODULE_INFO_START]
Name: FndScanCounter
Role: 1kHz 주기 다이나믹 스캔 인덱스 관리자
Summary:
  - 1ms 마다 화면의 한 자리를 이동하여 스캔하기 위한 2-bit Index(0~3) 순환 카운터 기능
StateDescription:
[MODULE_INFO_END]
*/
module FndScanCounter (
    input  wire       iClk,
    input  wire       iRstn,
    input  wire       iTick1kHz,
    output reg  [1:0] oScanIdx
);
    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oScanIdx <= 2'd0;
        end else if (iTick1kHz) begin
            oScanIdx <= oScanIdx + 1'b1;
        end
    end
endmodule
