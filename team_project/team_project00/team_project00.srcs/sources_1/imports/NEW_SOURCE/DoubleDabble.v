/*
[MODULE_INFO_START]
Name: DoubleDabble
Role: Binary -> BCD Converter (Double Dabble Hex to BCD 로직)
Summary:
  - 14bit 이진수(최대 9999)를 받아와 16bit BCD(4자리) 단위로 변환
StateDescription:
[MODULE_INFO_END]
*/
module DoubleDabble (
    input  wire [13:0] iBin,
    output reg  [15:0] oBcd
);
    integer i;
    always @(*) begin
        oBcd = 16'd0;
        for (i = 13; i >= 0; i = i - 1) begin
            if (oBcd[3:0] >= 5)   oBcd[3:0]   = oBcd[3:0] + 3;
            if (oBcd[7:4] >= 5)   oBcd[7:4]   = oBcd[7:4] + 3;
            if (oBcd[11:8] >= 5)  oBcd[11:8]  = oBcd[11:8] + 3;
            if (oBcd[15:12] >= 5) oBcd[15:12] = oBcd[15:12] + 3;
            oBcd = {oBcd[14:0], iBin[i]};
        end
    end
endmodule
