/*
[MODULE_INFO_START]
Name: Dht11Core
Role: DHT11 센서와 통신하여 40비트 데이터를 수신하고 온/습도를 추출
Summary:
  - 1-wire 양방향 통신 인터페이스(Tri-state) 제어
  - 18ms Start 신호 생성 및 센서 응답(80us LOW, 80us HIGH) 감지
  - 40비트 데이터 수신 및 Checksum 검증을 통한 신뢰성 확보
StateDescription:
  - IDLE: 측정 시작 명령 대기
  - START_LOW: ioData를 18ms 동안 LOW로 구동하여 시작 신호 전송
  - START_HIGH: ioData 라인 구동을 해제하고 센서의 응답 대기
  - WAIT_LOW: 센서의 80us LOW 응답 대기 및 확인
  - WAIT_HIGH: 센서의 80us HIGH 응답 대기 및 데이터 수신 준비
  - READ_40BIT: 데이터 비트(50us LOW 이후의 HIGH 구간 길이) 측정 및 40비트 수집
  - CHECKSUM: 수신된 40비트 데이터의 Checksum 검증
  - DONE: 측정 완료 및 결과 출력 갱신
[MODULE_INFO_END]
*/
module Dht11Core #(
    parameter P_SYS_CLK_HZ = 100_000_000
)(
    input  wire        iClk,
    input  wire        iRstn,
    input  wire        iStart,
    inout  wire        ioData,
    output reg  [15:0] oTemp,
    output reg  [15:0] oHumi,
    output reg         oValid
);

    // ----------------------------------------------------
    // 1) Parameters & State Encoding
    // ----------------------------------------------------
    localparam LP_1_US       = P_SYS_CLK_HZ / 1_000_000;
    localparam LP_18_MS      = 18_000 * LP_1_US;
    localparam LP_40_US      = 40 * LP_1_US; // 0과 1을 판별하는 임계 타이머
    localparam LP_TIMEOUT_US = 200 * LP_1_US;

    localparam IDLE       = 3'd0;
    localparam START_LOW  = 3'd1;
    localparam START_HIGH = 3'd2;
    localparam WAIT_LOW   = 3'd3;
    localparam WAIT_HIGH  = 3'd4;
    localparam READ_40BIT = 3'd5;
    localparam CHECKSUM   = 3'd6;
    localparam DONE       = 3'd7;

    // ----------------------------------------------------
    // 2) Registers / Wires
    // ----------------------------------------------------
    reg [2:0]  state, state_d;
    reg [23:0] cntTimer, cntTimer_d;
    reg [5:0]  cntBit, cntBit_d;
    reg [39:0] dataShift, dataShift_d;

    reg        dataOut, dataOut_d;
    reg        dataDir, dataDir_d; // 1: Output, 0: Input (High-Z)

    reg        dataDelay;
    wire       wDataIn;
    wire       wEdgeFalling;
    wire       wEdgeRising;

    sync_2ff uDataSync2ff (
        .iAsync (ioData),
        .iClk   (iClk),
        .iRst   (~iRstn),
        .oSync  (wDataIn)
    );

    // ----------------------------------------------------
    // 3) Sequential Logic: state/register update
    // ----------------------------------------------------
    assign ioData = (dataDir == 1'b1) ? dataOut : 1'bz;
    
    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            dataDelay <= 1'b1;
        end else begin
            dataDelay <= wDataIn;
        end
    end

    assign wEdgeFalling = (dataDelay == 1'b1 && wDataIn == 1'b0);
    assign wEdgeRising  = (dataDelay == 1'b0 && wDataIn == 1'b1);

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            state     <= IDLE;
            cntTimer  <= 24'd0;
            cntBit    <= 6'd0;
            dataShift <= 40'd0;
            dataDir   <= 1'b0;
            dataOut   <= 1'b1;
        end else begin
            state     <= state_d;
            cntTimer  <= cntTimer_d;
            cntBit    <= cntBit_d;
            dataShift <= dataShift_d;
            dataDir   <= dataDir_d;
            dataOut   <= dataOut_d;
        end
    end

    // ----------------------------------------------------
    // 4. Combinational Logic (FSM & Datapath)
    // ----------------------------------------------------
    always @(*) begin
        state_d     = state;
        cntTimer_d  = cntTimer;
        cntBit_d    = cntBit;
        dataShift_d = dataShift;
        dataDir_d   = dataDir;
        dataOut_d   = dataOut;

        case (state)
            IDLE: begin
                dataDir_d  = 1'b0;
                dataOut_d  = 1'b1;
                cntTimer_d = 24'd0;
                cntBit_d   = 6'd0;
                
                if (iStart) begin
                    state_d    = START_LOW;
                    dataDir_d  = 1'b1; // Drive LOW
                    dataOut_d  = 1'b0;
                end
            end

            START_LOW: begin
                if (cntTimer >= LP_18_MS) begin
                    state_d    = START_HIGH;
                    cntTimer_d = 24'd0;
                    dataDir_d  = 1'b0; // Release to High-Z
                end else begin
                    cntTimer_d = cntTimer + 1'b1;
                end
            end

            START_HIGH: begin
                if (wEdgeFalling) begin
                    state_d    = WAIT_LOW;
                    cntTimer_d = 24'd0;
                end else if (cntTimer >= LP_TIMEOUT_US) begin
                    state_d    = IDLE;
                end else begin
                    cntTimer_d = cntTimer + 1'b1;
                end
            end

            WAIT_LOW: begin
                if (wEdgeRising) begin
                    state_d    = WAIT_HIGH;
                    cntTimer_d = 24'd0;
                end else if (cntTimer >= LP_TIMEOUT_US) begin
                    state_d    = IDLE;
                end else begin
                    cntTimer_d = cntTimer + 1'b1;
                end
            end

            WAIT_HIGH: begin
                if (wEdgeFalling) begin
                    state_d    = READ_40BIT;
                    cntTimer_d = 24'd0;
                end else if (cntTimer >= LP_TIMEOUT_US) begin
                    state_d    = IDLE;
                end else begin
                    cntTimer_d = cntTimer + 1'b1;
                end
            end

            READ_40BIT: begin
                if (wEdgeRising) begin
                    cntTimer_d = 24'd0; // HIGH 구간 시작 시 타이머 초기화
                end else if (wEdgeFalling) begin
                    // HIGH 구간 종료 시 길이를 판별해 0 또는 1 시프트
                    if (cntTimer > LP_40_US) begin
                        dataShift_d = {dataShift[38:0], 1'b1};
                    end else begin
                        dataShift_d = {dataShift[38:0], 1'b0};
                    end
                    
                    cntBit_d = cntBit + 1'b1;
                    if (cntBit == 6'd39) begin
                        state_d = CHECKSUM;
                    end
                end else begin
                    cntTimer_d = cntTimer + 1'b1;
                end
                
                if (cntTimer >= LP_TIMEOUT_US) begin
                    state_d = IDLE;
                end
            end

            CHECKSUM: begin
                state_d = DONE;
            end

            DONE: begin
                state_d = IDLE;
            end

            default: begin
                state_d = IDLE;
            end
        endcase
    end

    // ----------------------------------------------------
    // 5. Output Logic
    // ----------------------------------------------------
    wire [7:0] wHumiInt = dataShift[39:32];
    wire [7:0] wHumiDec = dataShift[31:24];
    wire [7:0] wTempInt = dataShift[23:16];
    wire [7:0] wTempDec = dataShift[15:8];
    wire [7:0] wChksum  = dataShift[7:0];
    
    wire [7:0] wCalcChksum = wHumiInt + wHumiDec + wTempInt + wTempDec;

    always @(posedge iClk or negedge iRstn) begin
        if (!iRstn) begin
            oTemp <= 16'd0;
            oHumi <= 16'd0;
            oValid <= 1'b0;
        end else begin
            oValid <= 1'b0;

            if (state == CHECKSUM) begin
                if (wCalcChksum == wChksum) begin
                    oHumi <= {wHumiInt, wHumiDec};
                    oTemp <= {wTempInt, wTempDec};
                    oValid <= 1'b1;
                end
            end
        end
    end

endmodule
