/*
[MODULE_INFO_START]
Name: ascii_decoder
Role: Decodes UART ASCII command bytes into one-cycle command pulses.
Summary:
  - Accepts command bytes: U,C,D,R,L,1,2,3,S,Q,T,H,Y,J.
  - Produces decoded command pulses only when iRxValid is asserted.
  - Asserts oCmdErr for any valid byte outside supported command set.
[MODULE_INFO_END]
*/

module ascii_decoder(
    input  wire       iRxValid,
    input  wire [7:0] iRxData,
    output reg  [4:0] oBtnPulse,      // [4:0] = U,C,D,R,L
    output reg        oSw1Pulse,      // '1'
    output reg        oSw2Pulse,      // '2'
    output reg        oSw3Pulse,      // '3'
    output reg        oReqFnd,       // 'S'
    output reg        oReqState,     // 'Q'
    output reg        oReqStopwatch, // 'T'
    output reg        oReqWatch,     // 'Y'
    output reg        oReqHcsr04,    // 'H'
    output reg        oReqDht11,     // 'J'
    output reg        oCmdErr
);

    always @(*) begin
        oBtnPulse      = 5'b00000;
        oSw1Pulse      = 1'b0;
        oSw2Pulse      = 1'b0;
        oSw3Pulse      = 1'b0;
        oReqFnd        = 1'b0;
        oReqState      = 1'b0;
        oReqStopwatch  = 1'b0;
        oReqWatch      = 1'b0;
        oReqHcsr04     = 1'b0;
        oReqDht11      = 1'b0;
        oCmdErr        = 1'b0;

        if (iRxValid) begin
            case (iRxData)
                8'h55, 8'h75: oBtnPulse      = 5'b10000; // U/u
                8'h43, 8'h63: oBtnPulse      = 5'b01000; // C/c
                8'h44, 8'h64: oBtnPulse      = 5'b00100; // D/d
                8'h52, 8'h72: oBtnPulse      = 5'b00010; // R/r
                8'h4C, 8'h6C: oBtnPulse      = 5'b00001; // L/l
                8'h31: oSw1Pulse      = 1'b1;     // 1
                8'h32: oSw2Pulse      = 1'b1;     // 2
                8'h33: oSw3Pulse      = 1'b1;     // 3
                8'h53, 8'h73: oReqFnd       = 1'b1;  // S/s
                8'h51, 8'h71: oReqState     = 1'b1;  // Q/q
                8'h54, 8'h74: oReqStopwatch = 1'b1;  // T/t
                8'h59, 8'h79: oReqWatch     = 1'b1;  // Y/y
                8'h48, 8'h68: oReqHcsr04    = 1'b1;  // H/h
                8'h4A, 8'h6A: oReqDht11     = 1'b1;  // J/j
                default: oCmdErr      = 1'b1;
            endcase
        end
    end

endmodule
