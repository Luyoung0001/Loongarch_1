module mul(
        input clk,
        input reset,
        input mult,//乘法使能
        input wire [9:0] mul_div_op,
        input wire [31:0] alu_src1,
        input wire [31:0] alu_src2,
        output wire [31:0] mul_result,
        output wire done
    );
    wire [63:0] mul_res64;
    wire done_internal;

    wire signed_op = (mul_div_op[0] || mul_div_op[1]) ? 1'b1 : 1'b0;

    TopMultiplier topmul_inst (
                      .clk(clk),
                      .reset(reset),
                      .mult(mult),
                      .x_in(alu_src1),
                      .y_in(alu_src2),
                      .signed_op(signed_op),
                      .done(done_internal),
                      .result_out(mul_res64)
                  );

    assign done = done_internal;

    reg [31:0] mul_result_reg;

    always @(*) begin
        case (mul_div_op[2:0])
            3'b001:
                mul_result_reg = mul_res64[31:0];
            3'b010,3'b100:
                mul_result_reg = mul_res64[63:32];
            default:
                mul_result_reg = 32'b0;
        endcase
    end

    assign mul_result = mul_result_reg;


endmodule
