/*
[MODULE_INFO_START]
Name: uart_interface
Role: UART integration wrapper using RX/TX FIFOs and TX arbiter.
Summary:
  - Instantiates baud_rate_generator, uart_rx, uart_tx, rx_fifo, tx_fifo, tx_arbiter.
  - Provides sender-side enqueue interface with backpressure (oSenderReady).
  - Provides decoder output stream (oDecoderData/oDecoderValid) from UART RX bytes.
  - Supports loopback path (RX FIFO -> TX arbiter) with sender path priority.
[MODULE_INFO_END]
*/

module uart_interface #(
    parameter integer P_CLK_HZ      = 100_000_000,
    parameter integer P_BAUD        = 9600,
    parameter integer P_OVERSAMPLE  = 16,
    parameter integer P_FIFO_DEPTH  = 16
)(
    input  wire       iClk,
    input  wire       iRst,
    input  wire       iUartRx,
    output wire       oUartTx,

    input  wire [7:0] iSenderData,
    input  wire       iSenderValid,
    output wire       oSenderReady,

    output wire [7:0] oDecoderData,
    output wire       oDecoderValid
);

    wire       wSampleTick;

    wire       wRxValid;
    wire [7:0] wRxData;

    wire [7:0] wRxFifoData;
    wire       wRxFifoEmpty;
    wire       wRxFifoFull;

    wire [7:0] wTxFifoData;
    wire       wTxFifoEmpty;
    wire       wTxFifoFull;

    wire       wTxStart;
    wire [7:0] wTxData;
    wire       wTxBusy;

    wire       wSenderPop;
    wire       wEchoPop;

    assign oSenderReady  = ~wTxFifoFull;
    assign oDecoderData  = wRxData;
    assign oDecoderValid = wRxValid;

    baud_rate_generator #(
        .P_CLK_HZ     (P_CLK_HZ),
        .P_BAUD       (P_BAUD),
        .P_OVERSAMPLE (P_OVERSAMPLE)
    ) uBaudRateGenerator (
        .iClk        (iClk),
        .iRst        (iRst),
        .oSampleTick (wSampleTick)
    );

    uart_rx uUartRx (
        .iClk        (iClk),
        .iRst        (iRst),
        .iSampleTick (wSampleTick),
        .iUartRx     (iUartRx),
        .oRxValid    (wRxValid),
        .oRxData     (wRxData)
    );

    rx_fifo #(
        .P_DEPTH (P_FIFO_DEPTH)
    ) uRxFifo (
        .iClk    (iClk),
        .iRst    (iRst),
        .iWrEn   (wRxValid),
        .iWrData (wRxData),
        .iRdEn   (wEchoPop),
        .oRdData (wRxFifoData),
        .oEmpty  (wRxFifoEmpty),
        .oFull   (wRxFifoFull)
    );

    tx_fifo #(
        .P_DEPTH (P_FIFO_DEPTH)
    ) uTxFifo (
        .iClk    (iClk),
        .iRst    (iRst),
        .iWrEn   (iSenderValid),
        .iWrData (iSenderData),
        .iRdEn   (wSenderPop),
        .oRdData (wTxFifoData),
        .oEmpty  (wTxFifoEmpty),
        .oFull   (wTxFifoFull)
    );

    tx_arbiter uTxArbiter (
        .iTxBusy     (wTxBusy),
        .iSenderValid(~wTxFifoEmpty),
        .iSenderData (wTxFifoData),
        .iEchoValid  (~wRxFifoEmpty),
        .iEchoData   (wRxFifoData),
        .oTxStart    (wTxStart),
        .oTxData     (wTxData),
        .oSenderPop  (wSenderPop),
        .oEchoPop    (wEchoPop)
    );

    uart_tx uUartTx (
        .iClk        (iClk),
        .iRst        (iRst),
        .iSampleTick (wSampleTick),
        .iTxStart    (wTxStart),
        .iTxData     (wTxData),
        .oUartTx     (oUartTx),
        .oTxBusy     (wTxBusy),
        .oTxDone     ()
    );

endmodule
