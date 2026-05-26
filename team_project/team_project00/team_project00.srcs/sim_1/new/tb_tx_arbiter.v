`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/22 13:25:01
// Design Name: 
// Module Name: tb_tx_arbiter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_tx_arbiter ();

    reg iTxBusy, iSenderValid, iEchoValid;
    reg [7:0] iSenderData, iEchoData;

    wire oSenderPop, oEchoPop,oTxStart;
    wire [7:0] oTxData;

    tx_arbiter u_tx_arbiter (
        .iTxBusy     (iTxBusy),
        .iSenderValid(iSenderValid),
        .iSenderData (iSenderData),
        .iEchoValid  (iEchoValid),
        .iEchoData   (iEchoData),
        .oTxStart    (oTxStart),
        .oTxData     (oTxData),
        .oSenderPop  (oSenderPop),
        .oEchoPop    (oEchoPop)
    );


    initial begin
        iTxBusy = 0;
        iSenderValid = 0;
        iEchoValid = 0  ;
        iEchoData = 0;
        iSenderData = 0;

        #40;
        iTxBusy = 0;
        iSenderData = 8'h30;
        iSenderValid = 1'b1;
        iEchoData = 8'h37;
        iEchoValid = 1'b1;

        #10;
        iEchoValid = 1'b0;
        iSenderValid = 1'b0;

        #50
        $stop;

    end
endmodule
