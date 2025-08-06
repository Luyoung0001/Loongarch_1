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

initial begin
    clk = 0;
    reset = 1;
    mult = 0;
    alu_src1 = 0;
    alu_src2 = 0;
    mul_div_op = 0;

    #20 reset = 0;
    #10;

    // ===== 边界临界测试 =====
    
    // 1. 有符号乘法边界
    alu_src1 = 32'h00000001; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

     alu_src1 = 32'h00000002; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h00000003; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h00000004; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h00000005; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h00000006; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h00000007; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h00000008; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h00000009; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h0000000A; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h0000000B; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h0000000C; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h0000000D; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   




    alu_src1 = 32'h0000000E;
    alu_src2 = 32'h80000000; // 2
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    
    alu_src1 = 32'h0000000F;
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    
    
    alu_src1 = 32'h80000000;
    alu_src2 = 32'h80000000;
    mul_div_op = 10'b0000000010; 
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    

     alu_src1 = 32'h80000001; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h80000002; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h80000003; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h80000004; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h80000005; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h80000006; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h80000007; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h80000008; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h80000009; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h8000000A; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h8000000B; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h8000000C; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h8000000D; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   


     alu_src1 = 32'h8000000E; 
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; // MULH
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;   

    alu_src1 = 32'h8000000F;
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; 
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;    

    alu_src1 = 32'h800000FF;
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; 
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    alu_src1 = 32'h80000FFF;
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; 
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;
    
    alu_src1 = 32'h8000FFFF;
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; 
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    alu_src1 = 32'h800FFFFF;
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; 
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    alu_src1 = 32'h80FFFFFF;
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; 
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    alu_src1 = 32'h8FFFFFFF;
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; 
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

 

    alu_src1 = 32'h00000000;
    alu_src2 = 32'h80000000; 
    mul_div_op = 10'b0000000010; 
    mult = 1; #10 mult = 0;
    wait (done); #1;
    sres = $signed(alu_src1) * $signed(alu_src2);
    expected = sres[63:32];
    if (mul_result !== expected) err_counter = err_counter + 1;
    #10;

    // ===== 随机测试 =====
    for (i = 0; i < 1000; i = i + 1) begin
        // MUL (有符号低32位)
        alu_src1 = $random;
        alu_src2 = $random;
        mul_div_op = 10'b0000000001; 
        mult = 1; #10 mult = 0;
        wait (done); #1;
        sres = $signed(alu_src1) * $signed(alu_src2);
        expected = sres[31:0];
        if (mul_result !== expected) err_counter = err_counter + 1;
        #10;
        
        // MULH (有符号高32位)
        alu_src1 = $random;
        alu_src2 = $random;
        mul_div_op = 10'b0000000010; 
        mult = 1; #10 mult = 0;
        wait (done); #1;
        sres = $signed(alu_src1) * $signed(alu_src2);
        expected = sres[63:32];
        if (mul_result !== expected) err_counter = err_counter + 1;
        #10;
        
        // MULHU (无符号高32位)
        alu_src1 = $random;
        alu_src2 = $random;
        mul_div_op = 10'b0000000100;
        mult = 1; #10 mult = 0;
        wait (done); #1;
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