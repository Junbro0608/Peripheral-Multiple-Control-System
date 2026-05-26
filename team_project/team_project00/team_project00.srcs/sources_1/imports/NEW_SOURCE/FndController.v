/*
[MODULE_INFO_START]
Name: FndController
Role: FND 동적 스캐닝 및 시각 효과 렌더링 엔진 래퍼
Summary:
  - 인덱스 카운터, 자릿수 맵핑, 애니메이션 효과기, 레거시 디코더 모듈의 하위 래핑 구조 (하위 모듈 4개 구조화)
  - 1kHz 틱과 2Hz 틱을 받아 다이나믹하게 깜빡이는 FND 출력 총괄
StateDescription:
[MODULE_INFO_END]
*/

module FndController (
    input  wire        iClk,
    input  wire        iRstn,       // Active-low
    input  wire        iTick1kHz,   // FND 다이나믹 스캐닝용 (1ms)
    input  wire        iTick2Hz,    // 깜빡임 효과용 (0.5s Pulse)
    input  wire [15:0] iDigitsBcd,  // 4자리 BCD 입력
    input  wire [3:0]  iBlinkMask,  // 자리별 깜빡임 여부 마스크
    input  wire [3:0]  iDpMask,     // 자리별 DP 켜기 마스크
    output wire [6:0]  oSeg,        // 7-Segment (Active-Low)
    output wire        oDp,         // Decimal Point (Active-Low)
    output wire [3:0]  oDigitSel    // Anode Select (Active-Low)
);

    wire [1:0] wScanIdx;
    wire [3:0] wCurBcd;
    wire       wCurBlink;
    wire       wCurDp;
    wire       wBlanking;

    // 4-1. 인덱스 생성 및 순환 루프 모듈
    FndScanCounter uFndScanCounter (
        .iClk      (iClk),
        .iRstn     (iRstn),
        .iTick1kHz (iTick1kHz),
        .oScanIdx  (wScanIdx)
    );

    // 4-2. 자릿수 위치 및 데이터 동기화 매핑 모듈
    FndDigitSelector uFndDigitSelector (
        .iScanIdx   (wScanIdx),
        .iDigitsBcd (iDigitsBcd),
        .iBlinkMask (iBlinkMask),
        .iDpMask    (iDpMask),
        .oDigitSel  (oDigitSel),
        .oCurBcd    (wCurBcd),
        .oCurBlink  (wCurBlink),
        .oCurDp     (wCurDp)
    );

    // 4-3. 애니메이션 깜빡임 제어 모듈
    FndBlinkEffect uFndBlinkEffect (
        .iClk       (iClk),
        .iRstn      (iRstn),
        .iTick2Hz   (iTick2Hz),
        .iCurBlink  (wCurBlink),
        .iCurDp     (wCurDp),
        .oBlanking  (wBlanking),
        .oFinalDp   (oDp)
    );

    // 4-4. 물리 7-Segment 변환 디코더 모듈
    FndBcdDecoder uFndBcdDecoder (
        .iCurBcd    (wCurBcd),
        .iBlanking  (wBlanking),
        .oSeg       (oSeg)
    );

endmodule
