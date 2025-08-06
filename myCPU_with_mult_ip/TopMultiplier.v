module TopMultiplier (
  input         clk,
  input         reset,
  input         mult,
  input  [31:0] x_in,
  input  [31:0] y_in,
  input         signed_op,
  output        done,
  output [63:0] result_out
);

  wire [31:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7,
              pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15,
              pp16, pp17, pp18, pp19, pp20, pp21, pp22, pp23,
              pp24, pp25, pp26, pp27, pp28, pp29, pp30, pp31;
  wire [63:0] opa, opb;
  wire [31:0] sign;


  wire [63:0] sign_compensate;
  wire [63:0] res_tmp;
  wire [63:0] result_out_;


  wire [31:0] x_in_ = (x_in == 32'h80000000) ? y_in : x_in;
  wire [31:0] y_in_ = (x_in == 32'h80000000) ? 32'h80000000 : y_in;


  BoothWrapper booth (
    .x_in(x_in_),
    .y_in(y_in_),
    .op(signed_op),
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

  wire done0;
  WallaceTree32x32 wallace (
    .clk(clk),
    .reset(reset),
    .mult(mult),
    .pp0(pp0), .pp1(pp1), .pp2(pp2), .pp3(pp3),
    .pp4(pp4), .pp5(pp5), .pp6(pp6), .pp7(pp7),
    .pp8(pp8), .pp9(pp9), .pp10(pp10), .pp11(pp11),
    .pp12(pp12), .pp13(pp13), .pp14(pp14), .pp15(pp15),
    .pp16(pp16), .pp17(pp17), .pp18(pp18), .pp19(pp19),
    .pp20(pp20), .pp21(pp21), .pp22(pp22), .pp23(pp23),
    .pp24(pp24), .pp25(pp25), .pp26(pp26), .pp27(pp27),
    .pp28(pp28), .pp29(pp29), .pp30(pp30), .pp31(pp31),
    .opa(opa),
    .opb(opb),
    .done(done0)
  );

  reg [1:0] state;
  reg req1, req2, req3;
  localparam IDLE  = 2'b00,
             STAGE1 = 2'b01,
             STAGE2 = 2'b10,
             DONE   = 2'b11;


  reg [63:0] opa_reg, opb_reg;
  reg [31:0] sign_reg;
  reg latch_valid;


  always @(posedge clk or posedge reset) begin
    if (reset) begin
      opa_reg <= 64'b0;
      opb_reg <= 64'b0;
      sign_reg <= 32'b0;
      latch_valid <= 1'b0;
    end else begin
      if (done0) begin
        opa_reg <= opa;
        opb_reg <= opb;
        sign_reg <= sign;
        latch_valid <= 1'b1;
      end else if (state == IDLE) begin
        latch_valid <= 1'b0;
      end
    end
  end

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= IDLE;
      req1 <= 0;
      req2 <= 0;
      req3 <= 0;
    end else begin
      case (state)
        IDLE: begin
          req1 <= 0;
          req2 <= 0;
          req3 <= 0;
          if (mult) begin
            req1 <= 1;
            state <= STAGE1;
          end
        end

        STAGE1: begin
          req1 <= 1;
          if (done0) begin
            req2 <= 1;
            state <= STAGE2;
          end
        end

        STAGE2: begin
          req2 <= 1;
          if (done1 && done2) begin
            req3 <= 1;
            state <= DONE;
          end
        end

        DONE: begin
          req3 <= 1;
          if (done) begin
            state <= IDLE;
          end
        end
      endcase
    end
  end
  wire done1, done2;

  CS_Adder64 signcomp (
    .clk(clk),
    .reset(reset),
    .reqst(req2 && latch_valid),
    .a({~sign_reg, 32'b0}),
    .b({31'b0, 1'b1, 32'b0}),
    .cin(1'b0),
    .sum(sign_compensate),
    .cout(),
    .done(done1)
  );

  CS_Adder64 resulttemp (
    .clk(clk),
    .reset(reset),
    .reqst(req2 && latch_valid),
    .a(opa_reg),
    .b(opb_reg),
    .cin(1'b0),
    .sum(res_tmp),
    .cout(),
    .done(done2)
  );

  CS_Adder64 result (
    .clk(clk),
    .reset(reset),
    .reqst(req3),
    .a(res_tmp),
    .b(signed_op ? sign_compensate : 64'b0),
    .cin(1'b0),
    .sum(result_out_),
    .cout(),
    .done(done)
  );

  assign result_out = (x_in == 32'h80000000 && y_in == 32'h80000000 && signed_op) ?
                      64'h4000000000000000 : result_out_;

endmodule