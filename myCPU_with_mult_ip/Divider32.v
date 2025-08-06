module Divider32 (
        input clk,
        input reset,
        input div,          // 除法启动信号
        input div_signed,   // 1=有符号除法，0=无符号除法
        input [31:0] x,     // 被除数
        input [31:0] y,     // 除数
        output reg [31:0] q, // 商
        output reg [31:0] r, // 余数
        output reg busy,     // 忙信号
        output reg done      // 完成信号
    );

    // 内部寄存器
    reg [63:0] dividend_reg;
    reg [63:0] shifted_next;     // 组合逻辑下一状态
    reg [31:0] divisor_reg;
    reg [5:0]  count;
    reg        x_neg, y_neg;     // 符号标志

    wire [31:0] x_abs = (div_signed && x[31]) ? -x : x;
    wire [31:0] y_abs = (div_signed && y[31]) ? -y : y;

    always @* begin
        shifted_next = {dividend_reg[62:0], 1'b0};
        if (shifted_next[63:32] >= divisor_reg) begin
            shifted_next[63:32] = shifted_next[63:32] - divisor_reg;
            shifted_next[0]     = 1'b1;
        end else begin
            shifted_next[0]     = 1'b0;
        end
    end

    // 时序逻辑：状态机与寄存器更新
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q            <= 32'd0;
            r            <= 32'd0;
            busy         <= 1'b0;
            done         <= 1'b0;
            count        <= 6'd0;
            dividend_reg <= 64'd0;
            divisor_reg  <= 32'd0;
            x_neg        <= 1'b0;
            y_neg        <= 1'b0;
        end else if (div && !busy) begin
            dividend_reg <= {32'd0, x_abs};
            divisor_reg  <= y_abs;
            busy         <= 1'b1;
            done         <= 1'b0;
            count        <= 6'd0;
            x_neg        <= (div_signed && x[31]);
            y_neg        <= (div_signed && y[31]);
        end else if (busy) begin
            if (count < 6'd32) begin
                dividend_reg <= shifted_next;
                count        <= count + 6'd1;
            end else begin
                busy <= 1'b0;
                done <= 1'b1;
                if (div_signed) begin
                    q <= (x_neg ^ y_neg) ? -dividend_reg[31:0] : dividend_reg[31:0];
                    r <= x_neg ? -dividend_reg[63:32] : dividend_reg[63:32];
                end else begin
                    q <= dividend_reg[31:0];
                    r <= dividend_reg[63:32];
                end
            end
        end else begin
            done <= 1'b0;
        end
    end

endmodule
