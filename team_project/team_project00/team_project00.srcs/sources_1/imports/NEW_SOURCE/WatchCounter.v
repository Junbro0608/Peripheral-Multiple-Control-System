/*
[MODULE_INFO_START]
Name: WatchCounter
Role: Watch time counter with editable fields.
Summary:
  - Generates 10ms tick from 1kHz tick.
  - Maintains HH/MM/SS/CS using chained BCD counters.
  - Supports edit increment/decrement and local reset.
[MODULE_INFO_END]
*/
module WatchCounter (
    input  wire        iClk,
    input  wire        iRstn,

    // Controls
    input  wire        iTick1kHz,
    input  wire        iRun,
    input  wire        iFormat,    // 0: HH:MM, 1: SS:CS
    input  wire        iEditEn,
    input  wire        iEditUnit,  // 0: left, 1: right
    input  wire        iInc,
    input  wire        iDec,
    input  wire        iResetTime,

    // Output data
    output wire [15:0] oFndData,
    output wire [31:0] oFullData
);

    reg [3:0] cnt1ms;
    reg [3:0] cnt1ms_d;
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
            if (cnt1ms == 4'd9) begin
                cnt1ms_d = 4'd0;
            end else begin
                cnt1ms_d = cnt1ms + 1'b1;
            end
        end
    end

    wire edit_h  = iEditEn && (iFormat == 1'b0) && (iEditUnit == 1'b0);
    wire edit_m  = iEditEn && (iFormat == 1'b0) && (iEditUnit == 1'b1);
    wire edit_s  = iEditEn && (iFormat == 1'b1) && (iEditUnit == 1'b0);
    wire edit_cs = iEditEn && (iFormat == 1'b1) && (iEditUnit == 1'b1);

    wire [3:0] cs_tens;
    wire [3:0] cs_ones;
    wire [3:0] sec_tens;
    wire [3:0] sec_ones;
    wire [3:0] min_tens;
    wire [3:0] min_ones;
    wire [3:0] hour_tens;
    wire [3:0] hour_ones;

    wire carry_cs;
    wire carry_sec;
    wire carry_min;
    wire carry_hour;

    BcdCounter #(
        .P_MAX_TENS(9),
        .P_MAX_ONES(9)
    ) uCsCounter (
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

    BcdCounter #(
        .P_MAX_TENS(5),
        .P_MAX_ONES(9)
    ) uSecCounter (
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

    BcdCounter #(
        .P_MAX_TENS(5),
        .P_MAX_ONES(9)
    ) uMinCounter (
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

    BcdCounter #(
        .P_MAX_TENS(2),
        .P_MAX_ONES(3),
        .P_RST_TENS(1),
        .P_RST_ONES(2)
    ) uHourCounter (
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

    wire [3:0] left_tens  = (iFormat == 1'b0) ? hour_tens : sec_tens;
    wire [3:0] left_ones  = (iFormat == 1'b0) ? hour_ones : sec_ones;
    wire [3:0] right_tens = (iFormat == 1'b0) ? min_tens  : cs_tens;
    wire [3:0] right_ones = (iFormat == 1'b0) ? min_ones  : cs_ones;

    assign oFndData  = {left_tens, left_ones, right_tens, right_ones};
    assign oFullData = {hour_tens, hour_ones, min_tens, min_ones, sec_tens, sec_ones, cs_tens, cs_ones};

endmodule
