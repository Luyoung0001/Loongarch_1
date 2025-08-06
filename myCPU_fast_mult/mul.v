module mul(
        input wire [9:0] mul_div_op,
        input wire [31:0] alu_src1,
        input wire [31:0] alu_src2,
        output wire [31:0] mul_result

    );
    wire [63:0] signed_mul_result64;
    wire [63:0] unsigned_mul_result64;

    wire op_mul;   //signed multiply operation low
    wire op_mulh;  //signed multiply operation high
    wire op_mulhu;  //unsigned multiply operation high

    assign op_mul  = mul_div_op[0];
    assign op_mulh = mul_div_op[1];
    assign op_mulhu= mul_div_op[2];

    // // 这里会自动调用 ip
    // // verilator 仿真
    assign signed_mul_result64 = $signed(alu_src1) * $signed(alu_src2);
    assign unsigned_mul_result64 = $unsigned(alu_src1) * $unsigned(alu_src2);

    // mul_top o(
    //             .alu_src1(alu_src1),
    //             .alu_src2(alu_src2),
    //             .mul_div_op(1'b1),
    //             .signed_mul_result(signed_mul_result64),
    //             .unsigned_mul_result(unsigned_mul_result64)
    //         );

    assign mul_result = ({32{op_mul       }} & signed_mul_result64[31:0])
           | ({32{op_mulh      }} & signed_mul_result64[63:32])
           | ({32{op_mulhu     }} & unsigned_mul_result64[63:32]);


endmodule
