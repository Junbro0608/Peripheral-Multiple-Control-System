/*
[MODULE_INFO_START]
Name: SensorControlUnit
Role: 매뉴얼/오토 타이머 기반으로 센서(HC-SR04, DHT11) 모듈에 Start 펄스를 제공
Summary:
  - 지정된 주기(초음파 100ms, 온습도 2000ms)마다 자동 측정 타이머 구동
  - 단일 측정(Manual)과 자동 측정(Auto) 커맨드를 모두 처리하여 센서에 단일 Trigger 펄스 제공
StateDescription:
[MODULE_INFO_END]
*/
module SensorControlUnit (
    input  wire        iClk,
    input  wire        iRstn,
    input  wire        iTick1kHz,
    
    // Command context
    input  wire        iCmdValid,
    input  wire [4:0]  iCmdCode,
    input  wire [1:0]  iMode,
    
    // Output Pulses to Cores
    output wire        oHcsrStart,
    output wire        oDht11Start,
    output wire        oHcsrAutoRun,
    output wire        oDht11AutoRun
);

    // ----------------------------------------------------
    // 1. HC-SR04 Trigger Logic
    // ----------------------------------------------------
    // PC 'H' request (cmd 18) should also trigger a fresh measurement.
    wire wHcsrManual     = iCmdValid &&
                           (((iCmdCode == 5'd11) && (iMode == 2'd2)) ||
                            (iCmdCode == 5'd18));
    wire wHcsrAutoToggle = iCmdValid && (iCmdCode == 5'd10) && (iMode == 2'd2);
    
    reg hcsrAutoRun;
    reg [6:0] hcsrAutoMsCnt; // 0 ~ 99 (100ms)

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            hcsrAutoRun   <= 1'b0;
            hcsrAutoMsCnt <= 7'd0;
        end else begin
            if (wHcsrAutoToggle) begin
                hcsrAutoRun <= ~hcsrAutoRun;
            end
            
            if (hcsrAutoRun && iTick1kHz) begin
                if (hcsrAutoMsCnt >= 7'd99) hcsrAutoMsCnt <= 7'd0;
                else hcsrAutoMsCnt <= hcsrAutoMsCnt + 1;
            end else if (!hcsrAutoRun) begin
                hcsrAutoMsCnt <= 7'd0;
            end
        end
    end
    
    wire wHcsrAutoPulse = (hcsrAutoRun && iTick1kHz && hcsrAutoMsCnt == 7'd99);
    assign oHcsrStart   = wHcsrManual | wHcsrAutoPulse;
    assign oHcsrAutoRun = hcsrAutoRun;

    // ----------------------------------------------------
    // 2. DHT11 Trigger Logic
    // ----------------------------------------------------
    // PC 'J' request (cmd 19) should also trigger a fresh measurement.
    wire wDht11Manual     = iCmdValid &&
                            (((iCmdCode == 5'd13) && (iMode == 2'd3)) ||
                             (iCmdCode == 5'd19));
    wire wDht11AutoToggle = iCmdValid && (iCmdCode == 5'd12) && (iMode == 2'd3);
    
    reg dht11AutoRun;
    reg [10:0] dht11AutoMsCnt; // 0 ~ 1999 (2000ms)

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            dht11AutoRun   <= 1'b0;
            dht11AutoMsCnt <= 11'd0;
        end else begin
            if (wDht11AutoToggle) begin
                dht11AutoRun <= ~dht11AutoRun;
            end
            
            if (dht11AutoRun && iTick1kHz) begin
                if (dht11AutoMsCnt >= 11'd1999) dht11AutoMsCnt <= 11'd0;
                else dht11AutoMsCnt <= dht11AutoMsCnt + 1;
            end else if (!dht11AutoRun) begin
                dht11AutoMsCnt <= 11'd0;
            end
        end
    end
    
    wire wDht11AutoPulse = (dht11AutoRun && iTick1kHz && dht11AutoMsCnt == 11'd1999);
    assign oDht11Start   = wDht11Manual | wDht11AutoPulse;
    assign oDht11AutoRun = dht11AutoRun;

endmodule
