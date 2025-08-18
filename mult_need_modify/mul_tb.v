`timescale 1ns / 1ps

module mul_tb_final;

reg clk, reset, mult;
reg [9:0] mul_div_op;
reg [31:0] alu_src1, alu_src2;
wire [31:0] mul_result;
wire done;

// DUT 实例
mul dut (
    .clk(clk),
    .reset(reset),
    .mult(mult),
    .mul_div_op(mul_div_op),
    .alu_src1(alu_src1),
    .alu_src2(alu_src2),
    .mul_result(mul_result),
    .done(done)
);

// 时钟
always #5 clk = ~clk;

// 主测试流程
integer i, err_counter = 0;
reg signed [63:0] sres;
reg [63:0] ures;
reg [31:0] expected;

// 执行乘法操作的任务
task do_mul;
    input [31:0] a;
    input [31:0] b;
    input [9:0] op;
    begin
        alu_src1 = a;
        alu_src2 = b;
        mul_div_op = op;
        mult = 1; // 启动乘法并保持有效
        @(posedge done); // 等待完成信号
        #5 mult = 0; // 完成信号到来后拉低 MULT
    end
endtask

initial begin
    clk = 0;
    reset = 1;
    mult = 0;
    alu_src1 = 0;
    alu_src2 = 0;
    mul_div_op = 0;

    #20 reset = 0;
    #10;

    // ===== 边界测试 =====
    
    // 1. 有符号乘法边界
    do_mul(32'h0000009c, 32'h00000b70, 10'h004); // MULH
    sres = (alu_src1) * (alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    // 2. 正数与最小负数相乘
    do_mul(32'h00000002, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h00000003, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h00000004, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h00000005, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h00000006, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h00000007, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h00000008, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h00000009, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h0000000A, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h0000000B, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h0000000C, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h0000000D, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h0000000E, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    do_mul(32'h0000000F, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    // 3. 最小负数相乘 (特殊情况)
    do_mul(32'h80000000, 32'h80000000, 10'b0000000010); 
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    // 4. 负数与最小负数相乘
    do_mul(32'h80000001, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h80000002, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h80000003, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h80000004, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h80000005, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h80000006, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h80000007, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'he1dac067, 32'h4aae3ea0, 10'b0000000001); // MULL
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[31:0];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h80000009, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h8000000A, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h8000000B, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h8000000C, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h8000000D, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   
    
    do_mul(32'h8000000E, 32'h80000000, 10'b0000000010); // MULH
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   

    do_mul(32'h8000000F, 32'h80000000, 10'b0000000010); 
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;    

    do_mul(32'h800000FF, 32'h80000000, 10'b0000000010); 
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    do_mul(32'h80000FFF, 32'h80000000, 10'b0000000010); 
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;
    
    do_mul(32'h8000FFFF, 32'h80000000, 10'b0000000010); 
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    do_mul(32'h800FFFFF, 32'h80000000, 10'b0000000010); 
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    do_mul(32'h80FFFFFF, 32'h80000000, 10'b0000000010); 
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    do_mul(32'h8FFFFFFF, 32'h80000000, 10'b0000000010); 
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    // 5. 零与最小负数相乘
    do_mul(32'h00000000, 32'h80000000, 10'b0000000010); 
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    // ===== 随机测试 =====
    for (i = 0; i < 1000; i = i + 1) begin
        // MUL (有符号低32位)
        alu_src1 = $random;
        alu_src2 = $random;
        do_mul(alu_src1, alu_src2, 10'b0000000001); 
        sres = $signed(alu_src1) * $signed(alu_src2);
        expected = sres[31:0];
        if (mul_result !== expected) err_counter = err_counter + 1;
        #10;
        
        // MULH (有符号高32位)
        alu_src1 = $random;
        alu_src2 = $random;
        do_mul(alu_src1, alu_src2, 10'b0000000010); 
        sres = $signed(alu_src1) * $signed(alu_src2);
        expected = sres[63:32];
        if (mul_result !== expected) err_counter = err_counter + 1;
        #10;
        
        // MULHU (无符号高32位)
        alu_src1 = $random;
        alu_src2 = $random;
        do_mul(alu_src1, alu_src2, 10'b0000000100);
        ures = alu_src1 * alu_src2;
        expected = ures[63:32];
        if (mul_result !== expected) err_counter = err_counter + 1;
        #10;
    end
    
    // 测试结束
    if (err_counter) $display("TEST FAILED: %0d errors", err_counter);
    else $display("TEST PASSED");
    $finish;
end

endmodule