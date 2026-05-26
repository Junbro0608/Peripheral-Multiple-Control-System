/*
[MODULE_INFO_START]
Name: Debounce
Role: Single-channel debounce using synchronization and counter filtering.
Summary:
  - Synchronizes asynchronous button input with sync_2ff.
  - Applies CounterFilter to require stable level for debounce window.
  - Generates one-cycle pulse on rising edge of debounced level.
[MODULE_INFO_END]
*/

module Debounce (
    input  wire iClk,
    input  wire iRst,
    input  wire iBtnAsync,
    output wire oBtnPulse
);

    wire sync2Filter_Sync;
    wire wDebouncedLevel;

    sync_2ff uSync2ff (
        .iAsync(iBtnAsync),
        .iClk  (iClk),
        .iRst  (iRst),
        .oSync (sync2Filter_Sync)
    );

    CounterFilter #(
        .MAX_COUNT(1999999)
    ) uCounterFilter (
        .iClk(iClk),
        .iRst(iRst),
        .iIn (sync2Filter_Sync),
        .oOut(wDebouncedLevel)
    );

    EdgePulse uEdgePulse (
        .iClk  (iClk),
        .iRst  (iRst),
        .iLevel(wDebouncedLevel),
        .oPulse(oBtnPulse)
    );

endmodule
