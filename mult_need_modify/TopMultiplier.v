module TopMultiplier (
  input         clk,
  input         reset,
  input         mult,          // 乘法使能信号
  input  [31:0] x_in,
  input  [31:0] y_in,
  input         signed_op,     // 1=有符号乘法, 0=无符号
  output reg [63:0] result_out,
  output reg    done           // 计算完成标志
);

  // ===== 状态寄存器 =====
  reg [2:0] state;
  localparam IDLE        = 3'b000;
  localparam BOOTH       = 3'b001;
  localparam WALLACE     = 3'b010;
  localparam SIGN_COMP   = 3'b011;
  localparam PARTIAL_ADD = 3'b100;
  localparam FINAL_ADD   = 3'b101;
  
  // ===== 中间结果寄存器 =====
  // Booth编码输出
  wire [31:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
  wire [31:0] pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15;
  wire [31:0] pp16, pp17, pp18, pp19, pp20, pp21, pp22, pp23;
  wire [31:0] pp24, pp25, pp26, pp27, pp28, pp29, pp30, pp31;
  wire [31:0] sign;
  
  // Wallace树输出
  wire [63:0] opa, opb;
  
  // 加法器输出
  reg [63:0] sign_compensate;
  reg [63:0] partial_sum;
  reg [63:0] final_sum;
  
  // 控制信号
  reg        signed_op_reg;
  reg        special_case;
  reg [31:0] x_in_reg, y_in_reg;

  // ===== 特殊输入预处理 =====
  wire [31:0] x_in_ = (x_in == 32'h80000000) ? y_in : x_in;
  wire [31:0] y_in_ = (x_in == 32'h80000000) ? 32'h80000000 : y_in;
  wire        is_special_case = (x_in == 32'h80000000 && y_in == 32'h80000000 && signed_op);

  // ===== 模块实例化 =====
  BoothWrapper booth (
    .x_in(x_in_reg),
    .y_in(y_in_reg),
    .op(signed_op_reg),
    .pp0(pp0), .pp1(pp1), .pp2(pp2), .pp3(pp3),
    .pp4(pp4), .pp5(pp5), .pp6(pp6), .pp7(pp7),
    .pp8(pp8), .pp9(pp9), .pp10(pp10), .pp11(pp11),
    .pp12(pp12), .pp13(pp13), .pp14(pp14), .pp15(pp15),
    .pp16(pp16), .pp17(pp17), .pp18(pp18), .pp19(pp19),
    .pp20(pp20), .pp21(pp21), .pp22(pp22), .pp23(pp23),
    .pp24(pp24), .pp25(pp25), .pp26(pp26), .pp27(pp27),
    .pp28(pp28), .pp29(pp29), .pp30(pp30), .pp31(pp31),
    .sign(sign)
  );

  WallaceTree32x32 wallace (
    .pp0(pp0), .pp1(pp1), .pp2(pp2), .pp3(pp3),
    .pp4(pp4), .pp5(pp5), .pp6(pp6), .pp7(pp7),
    .pp8(pp8), .pp9(pp9), .pp10(pp10), .pp11(pp11),
    .pp12(pp12), .pp13(pp13), .pp14(pp14), .pp15(pp15),
    .pp16(pp16), .pp17(pp17), .pp18(pp18), .pp19(pp19),
    .pp20(pp20), .pp21(pp21), .pp22(pp22), .pp23(pp23),
    .pp24(pp24), .pp25(pp25), .pp26(pp26), .pp27(pp27),
    .pp28(pp28), .pp29(pp29), .pp30(pp30), .pp31(pp31),
    .opa(opa),
    .opb(opb)
  );
  wire [63:0] sign_compensate_wire;
  // 符号补偿加法器
  CS_Adder64 sign_comp_adder (
    .a({~sign, 32'b0}),
    .b({31'b0, 1'b1, 32'b0}),
    .cin(1'b0),
    .sum(sign_compensate_wire),
    .cout()
  );
  
  wire [63:0] partial_sum_wire;
  // 部分和加法器
  CS_Adder64 partial_adder (
    .a(opa_reg),
    .b(opb_reg),
    .cin(1'b0),
    .sum(partial_sum_wire),
    .cout()
  );
  
    wire [63:0] final_sum_wire;
  
  // 寄存器存储中间结果
  reg [63:0] opa_reg, opb_reg;
  reg [63:0] sign_compensate_reg;
  reg [63:0] partial_sum_reg;
  // 最终加法器
  CS_Adder64 final_adder (
    .a(partial_sum_reg),
    .b(signed_op_reg ? sign_compensate_reg : 64'b0),
    .cin(1'b0),
    .sum(final_sum_wire),
    .cout()
  );


  // ===== 状态机控制逻辑 =====
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
      done <= 0;
      result_out <= 0;
      signed_op_reg <= 0;
      special_case <= 0;
      x_in_reg <= 0;
      y_in_reg <= 0;
    end else begin
      // 默认值
      done <= 0;
      
      case (state)
        IDLE: begin
          if (mult) begin
            // 锁存输入和控制信号
            signed_op_reg <= signed_op;
            special_case <= is_special_case;
            x_in_reg <= x_in_;
            y_in_reg <= y_in_;
            state <= BOOTH;
          end
        end
        
        BOOTH: begin
          // Booth编码完成，进入Wallace树压缩
          state <= WALLACE;
        end
        
        WALLACE: begin
          // Wallace树压缩完成，锁存结果
          opa_reg <= opa;
          opb_reg <= opb;
          state <= SIGN_COMP;
        end
        
        SIGN_COMP: begin
          // 计算符号补偿
          sign_compensate_reg <= sign_compensate_wire;
          state <= PARTIAL_ADD;
        end
        
        PARTIAL_ADD: begin
          // 计算部分和
          partial_sum_reg <= partial_sum_wire;
          state <= FINAL_ADD;
        end
        
        FINAL_ADD: begin
          // 计算最终和
          result_out <= special_case ? 64'h4000000000000000 : final_sum_wire;
          done <= 1;
          state <= IDLE;
        end
      endcase
    end
  end

endmodule