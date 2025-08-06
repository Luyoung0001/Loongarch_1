module BoothWrapper(
    input  [31:0] x_in,
    input  [31:0] y_in,
    input         op, // 0: unsigned, 1: signed
    output [31:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7,
                  pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15,
                  pp16, pp17, pp18, pp19, pp20, pp21, pp22, pp23,
                  pp24, pp25, pp26, pp27, pp28, pp29, pp30, pp31,
    output reg [31:0]sign
);

    // 两个模块都实例化
    wire [31:0] c_pp [0:31];
    wire [31:0] u_pp [0:31];
    wire [31:0] c_sign;

    Booth_Classic32 Booth_Classic32 (
        .M(x_in), .R(y_in),
        .pp0(c_pp[0]),  .pp1(c_pp[1]),  .pp2(c_pp[2]),  .pp3(c_pp[3]),
        .pp4(c_pp[4]),  .pp5(c_pp[5]),  .pp6(c_pp[6]),  .pp7(c_pp[7]),
        .pp8(c_pp[8]),  .pp9(c_pp[9]),  .pp10(c_pp[10]),.pp11(c_pp[11]),
        .pp12(c_pp[12]),.pp13(c_pp[13]),.pp14(c_pp[14]),.pp15(c_pp[15]),
        .pp16(c_pp[16]),.pp17(c_pp[17]),.pp18(c_pp[18]),.pp19(c_pp[19]),
        .pp20(c_pp[20]),.pp21(c_pp[21]),.pp22(c_pp[22]),.pp23(c_pp[23]),
        .pp24(c_pp[24]),.pp25(c_pp[25]),.pp26(c_pp[26]),.pp27(c_pp[27]),
        .pp28(c_pp[28]),.pp29(c_pp[29]),.pp30(c_pp[30]),.pp31(c_pp[31]),
        .S(c_sign)
    );

    Booth_Unsigned32 Booth_Unsigned32 (
        .M(x_in), .R(y_in),
        .pp0(u_pp[0]),  .pp1(u_pp[1]),  .pp2(u_pp[2]),  .pp3(u_pp[3]),
        .pp4(u_pp[4]),  .pp5(u_pp[5]),  .pp6(u_pp[6]),  .pp7(u_pp[7]),
        .pp8(u_pp[8]),  .pp9(u_pp[9]),  .pp10(u_pp[10]),.pp11(u_pp[11]),
        .pp12(u_pp[12]),.pp13(u_pp[13]),.pp14(u_pp[14]),.pp15(u_pp[15]),
        .pp16(u_pp[16]),.pp17(u_pp[17]),.pp18(u_pp[18]),.pp19(u_pp[19]),
        .pp20(u_pp[20]),.pp21(u_pp[21]),.pp22(u_pp[22]),.pp23(u_pp[23]),
        .pp24(u_pp[24]),.pp25(u_pp[25]),.pp26(u_pp[26]),.pp27(u_pp[27]),
        .pp28(u_pp[28]),.pp29(u_pp[29]),.pp30(u_pp[30]),.pp31(u_pp[31])
    );
always @(*) begin
    sign = (op == 1'b1) ? c_sign : 32'b0;
end

    
    assign pp0  = op ? c_pp[0]  : u_pp[0];
    assign pp1  = op ? c_pp[1]  : u_pp[1];
    assign pp2  = op ? c_pp[2]  : u_pp[2];
    assign pp3  = op ? c_pp[3]  : u_pp[3];
    assign pp4  = op ? c_pp[4]  : u_pp[4];
    assign pp5  = op ? c_pp[5]  : u_pp[5];
    assign pp6  = op ? c_pp[6]  : u_pp[6];
    assign pp7  = op ? c_pp[7]  : u_pp[7];
    assign pp8  = op ? c_pp[8]  : u_pp[8];
    assign pp9  = op ? c_pp[9]  : u_pp[9];
    assign pp10 = op ? c_pp[10] : u_pp[10];
    assign pp11 = op ? c_pp[11] : u_pp[11];
    assign pp12 = op ? c_pp[12] : u_pp[12];
    assign pp13 = op ? c_pp[13] : u_pp[13];
    assign pp14 = op ? c_pp[14] : u_pp[14];
    assign pp15 = op ? c_pp[15] : u_pp[15];
    assign pp16 = op ? c_pp[16] : u_pp[16];
    assign pp17 = op ? c_pp[17] : u_pp[17];
    assign pp18 = op ? c_pp[18] : u_pp[18];
    assign pp19 = op ? c_pp[19] : u_pp[19];
    assign pp20 = op ? c_pp[20] : u_pp[20];
    assign pp21 = op ? c_pp[21] : u_pp[21];
    assign pp22 = op ? c_pp[22] : u_pp[22];
    assign pp23 = op ? c_pp[23] : u_pp[23];
    assign pp24 = op ? c_pp[24] : u_pp[24];
    assign pp25 = op ? c_pp[25] : u_pp[25];
    assign pp26 = op ? c_pp[26] : u_pp[26];
    assign pp27 = op ? c_pp[27] : u_pp[27];
    assign pp28 = op ? c_pp[28] : u_pp[28];
    assign pp29 = op ? c_pp[29] : u_pp[29];
    assign pp30 = op ? c_pp[30] : u_pp[30];
    assign pp31 = op ? c_pp[31] : u_pp[31];

endmodule
