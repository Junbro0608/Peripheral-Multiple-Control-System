/*
[MODULE_INFO_START]
Name: DisplayModeSelector
Role: Mode 분기 기반 화면 출력 데이터 다중화 선택기
Summary:
  - 4개 코어에서 생성된 BCD 및 마스크 데이터를 현재 모드 상태에 맞춰 FND 포맷으로 선택 결합
StateDescription:
[MODULE_INFO_END]
*/
module DisplayModeSelector (
    input  wire [1:0]  iMode,
    input  wire [15:0] iWatchData,
    input  wire [3:0]  iWatchBlinkMask,
    input  wire [3:0]  iWatchDotMask,
    input  wire [15:0] iStopData,
    input  wire [3:0]  iStopBlinkMask,
    input  wire [3:0]  iStopDotMask,
    input  wire [15:0] iHcsr04Bcd,
    input  wire [15:0] iDht11Bcd,
    output reg  [15:0] oFndBcd,
    output reg  [3:0]  oBlinkMask,
    output reg  [3:0]  oDpMask
);
    always @(*) begin
        oFndBcd    = iWatchData;
        oBlinkMask = 4'b0000;
        oDpMask    = 4'b0000;

        case (iMode)
            2'd0: begin // WATCH
                oFndBcd    = iWatchData;
                oBlinkMask = iWatchBlinkMask;
                oDpMask    = iWatchDotMask;
            end
            2'd1: begin // STOPWATCH
                oFndBcd    = iStopData;
                oBlinkMask = iStopBlinkMask;
                oDpMask    = iStopDotMask;
            end
            2'd2: begin // HCSR04
                oFndBcd    = iHcsr04Bcd;
                oBlinkMask = 4'b0000;
                oDpMask    = 4'b0000;
            end
            2'd3: begin // DHT11
                oFndBcd    = iDht11Bcd; 
                oBlinkMask = 4'b0000;
                oDpMask    = 4'b0000;
            end
        endcase
    end
endmodule
