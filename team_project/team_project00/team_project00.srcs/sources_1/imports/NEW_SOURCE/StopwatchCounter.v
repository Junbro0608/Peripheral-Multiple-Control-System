/*
[MODULE_INFO_START]
Name: StopwatchCounter
Role: 현재 스톱워치 측정 시간을 기록하며, 사용자 요청 시 설정 자릿수를 수동 증감하여 편집 (BCD 구조)
Summary:
  - 지정된 클럭(P_SYS_CLK_HZ)에 따라 10ms 주기의 틱을 발생
  - FSM에서 들어오는 iRun이 1일 때만 스톱워치 틱이 진행되도록 계산
  - 범용 BcdCounter 모듈을 4번 인스턴스화 하여 코드 중복 및 복잡도 제거
  - 스톱워치의 Hour는 99까지 카운트되도록 파라미터(MAX_TENS/ONES) 설정
StateDescription:
[MODULE_INFO_END]
*/

module StopwatchCounter (
    input  wire        iClk,
    input  wire        iRstn,

    // Controls
    input  wire        iTick1kHz,  // 1ms 전역 틱
    input  wire        iRun,       // 1: 스톱워치가 실제로 흐르고 있는 상태
    input  wire        iFormat,    // 0: HH:MM, 1: SS:ms
    input  wire        iEditEn,    // 1: Edit 활성화
    input  wire        iEditUnit,  // 0: 좌측 단위, 1: 우측 단위
    input  wire        iInc,       // 펄스 형태의 증가
    input  wire        iDec,       // 펄스 형태의 감소
    input  wire        iResetTime, // 값 강제 리셋 펄스

    // Output Data
    output wire [15:0] oFndData,   // FND용 4글자용 BCD 데이터 (16bit)
    output wire [31:0] oFullData   // UART용 8글자 32bit 전체 BCD 데이터
);

    // 1) 1ms -> 10ms 주기 prescaler
    reg [3:0] cnt1ms, cnt1ms_d;
    wire tick_10ms = (iRun == 1'b1) && iTick1kHz && (cnt1ms == 4'd9);

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            cnt1ms <= 4'd0;
        end else begin
            cnt1ms <= cnt1ms_d;
        end
    end

    always @(*) begin
        cnt1ms_d = cnt1ms;
        if (iResetTime) begin
            cnt1ms_d = 4'd0;
        end else if (iRun && iTick1kHz) begin
            if (cnt1ms == 4'd9) cnt1ms_d = 4'd0;
            else cnt1ms_d = cnt1ms + 1;
        end
    end

    // 2) 편집 모드 구분 플래그
    wire edit_h  = iEditEn && (iFormat == 1'b0) && (iEditUnit == 1'b0);
    wire edit_m  = iEditEn && (iFormat == 1'b0) && (iEditUnit == 1'b1);
    wire edit_s  = iEditEn && (iFormat == 1'b1) && (iEditUnit == 1'b0);
    wire edit_cs = iEditEn && (iFormat == 1'b1) && (iEditUnit == 1'b1);

    // 3) BcdCounter 인스턴스화
    wire [3:0] cs_tens,   cs_ones;
    wire [3:0] sec_tens,  sec_ones;
    wire [3:0] min_tens,  min_ones;
    wire [3:0] hour_tens, hour_ones;

    wire carry_cs, carry_sec, carry_min, carry_hour; // hour carry는 사용안함

    BcdCounter #( .P_MAX_TENS(9), .P_MAX_ONES(9) ) uCsCounter (
        .iClk   (iClk),
        .iRstn  (iRstn),
        .iTick  (tick_10ms),
        .iInc   (iInc && edit_cs),
        .iDec   (iDec && edit_cs),
        .iReset (iResetTime),
        .oTens  (cs_tens),
        .oOnes  (cs_ones),
        .oCarry (carry_cs)
    );

    BcdCounter #( .P_MAX_TENS(5), .P_MAX_ONES(9) ) uSecCounter (
        .iClk   (iClk),
        .iRstn  (iRstn),
        .iTick  (carry_cs),
        .iInc   (iInc && edit_s),
        .iDec   (iDec && edit_s),
        .iReset (iResetTime),
        .oTens  (sec_tens),
        .oOnes  (sec_ones),
        .oCarry (carry_sec)
    );

    BcdCounter #( .P_MAX_TENS(5), .P_MAX_ONES(9) ) uMinCounter (
        .iClk   (iClk),
        .iRstn  (iRstn),
        .iTick  (carry_sec),
        .iInc   (iInc && edit_m),
        .iDec   (iDec && edit_m),
        .iReset (iResetTime),
        .oTens  (min_tens),
        .oOnes  (min_ones),
        .oCarry (carry_min)
    );

    // Stopwatch Hour: 최대 99 (Watch와 유일한 차이점)
    BcdCounter #( .P_MAX_TENS(9), .P_MAX_ONES(9) ) uHourCounter (
        .iClk   (iClk),
        .iRstn  (iRstn),
        .iTick  (carry_min),
        .iInc   (iInc && edit_h),
        .iDec   (iDec && edit_h),
        .iReset (iResetTime),
        .oTens  (hour_tens),
        .oOnes  (hour_ones),
        .oCarry (carry_hour)
    );

    // 4) 출력부 (oFndData 포맷팅)
    wire [3:0] left_tens  = (iFormat == 1'b0) ? hour_tens : sec_tens;
    wire [3:0] left_ones  = (iFormat == 1'b0) ? hour_ones : sec_ones;
    wire [3:0] right_tens = (iFormat == 1'b0) ? min_tens  : cs_tens;
    wire [3:0] right_ones = (iFormat == 1'b0) ? min_ones  : cs_ones;

    assign oFndData = {left_tens, left_ones, right_tens, right_ones};
    assign oFullData = {hour_tens, hour_ones, min_tens, min_ones, sec_tens, sec_ones, cs_tens, cs_ones};

endmodule
