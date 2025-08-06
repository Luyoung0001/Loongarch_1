module nextpc_gen(
        input  wire        clk,
        input  wire        rst,
        input  wire [31:0] pc_i,         // 来自 pre-IFU 的当前 PC
        output wire [31:0] pc_next,      // 预测的下一个 PC

        // 来自 IDU 的实际分支信息
        input  wire        br_taken,     // 实际是否跳转
        input  wire [31:0] current_pc,   // 本条分支的 PC
        input  wire [31:0] br_target,    // 实际跳转目标
        input  wire        notice_pre    // 分支预测失败标志
    );

    // ==========================
    // 配置与结构定义
    // ==========================
`define V        64
`define cur_pc   63:32
`define next_pc  31:0

    localparam NUM_WAYS = 4;
    localparam NUM_SETS = 64;

    reg [64:0] br_buffer_1 [NUM_SETS-1:0]/*debug*/;
    reg [64:0] br_buffer_2 [NUM_SETS-1:0];
    reg [64:0] br_buffer_3 [NUM_SETS-1:0];
    reg [64:0] br_buffer_4 [NUM_SETS-1:0];

    reg [1:0] repl_ptr [NUM_SETS-1:0];

    // 读索引
    wire [5:0] index = pc_i[7:2];

    // 命中判断，互斥优先级命中
    wire hit1 = br_buffer_1[index][`V] && (br_buffer_1[index][`cur_pc] == pc_i);
    wire hit2 = !hit1 && br_buffer_2[index][`V] && (br_buffer_2[index][`cur_pc] == pc_i);
    wire hit3 = !hit1 && !hit2 && br_buffer_3[index][`V] && (br_buffer_3[index][`cur_pc] == pc_i);
    wire hit4 = !hit1 && !hit2 && !hit3 && br_buffer_4[index][`V] && (br_buffer_4[index][`cur_pc] == pc_i);

    wire [31:0] br_buffer_1_data = br_buffer_1[index][`next_pc];
    wire [31:0] br_buffer_2_data = br_buffer_2[index][`next_pc];
    wire [31:0] br_buffer_3_data = br_buffer_3[index][`next_pc];
    wire [31:0] br_buffer_4_data = br_buffer_4[index][`next_pc];

    // 组合逻辑预测输出
    assign pc_next =
           notice_pre ? current_pc + 32'd4 :
           hit1 ? br_buffer_1_data :
           hit2 ? br_buffer_2_data :
           hit3 ? br_buffer_3_data :
           hit4 ? br_buffer_4_data :
           pc_i + 32'd4;

    // 写索引
    wire [5:0] wr_index = current_pc[7:2];

    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                br_buffer_1[i] <= 65'b0;
                br_buffer_2[i] <= 65'b0;
                br_buffer_3[i] <= 65'b0;
                br_buffer_4[i] <= 65'b0;
                repl_ptr[i]    <= 2'b00;
            end
        end
        else if (notice_pre) begin
            // 失效对应项
            if (br_buffer_1[wr_index][`V] && br_buffer_1[wr_index][`cur_pc] == current_pc) begin
                br_buffer_1[wr_index][`V] <= 1'b0;
            end
            else if (br_buffer_2[wr_index][`V] && br_buffer_2[wr_index][`cur_pc] == current_pc) begin
                br_buffer_2[wr_index][`V] <= 1'b0;
            end
            else if (br_buffer_3[wr_index][`V] && br_buffer_3[wr_index][`cur_pc] == current_pc) begin
                br_buffer_3[wr_index][`V] <= 1'b0;
            end
            else if (br_buffer_4[wr_index][`V] && br_buffer_4[wr_index][`cur_pc] == current_pc) begin
                br_buffer_4[wr_index][`V] <= 1'b0;
            end
        end
        else if (br_taken) begin
            // 优先写入空位
            if (!br_buffer_1[wr_index][`V]) begin
                br_buffer_1[wr_index][`V]       <= 1'b1;
                br_buffer_1[wr_index][`cur_pc]  <= current_pc;
                br_buffer_1[wr_index][`next_pc] <= br_target;
            end
            else if (!br_buffer_2[wr_index][`V]) begin
                br_buffer_2[wr_index][`V]       <= 1'b1;
                br_buffer_2[wr_index][`cur_pc]  <= current_pc;
                br_buffer_2[wr_index][`next_pc] <= br_target;
            end
            else if (!br_buffer_3[wr_index][`V]) begin
                br_buffer_3[wr_index][`V]       <= 1'b1;
                br_buffer_3[wr_index][`cur_pc]  <= current_pc;
                br_buffer_3[wr_index][`next_pc] <= br_target;
            end
            else if (!br_buffer_4[wr_index][`V]) begin
                br_buffer_4[wr_index][`V]       <= 1'b1;
                br_buffer_4[wr_index][`cur_pc]  <= current_pc;
                br_buffer_4[wr_index][`next_pc] <= br_target;
            end
            else begin
                // 全满则使用轮替替换
                case (repl_ptr[wr_index])
                    2'b00: begin
                        br_buffer_1[wr_index][`V]       <= 1'b1;
                        br_buffer_1[wr_index][`cur_pc]  <= current_pc;
                        br_buffer_1[wr_index][`next_pc] <= br_target;
                    end
                    2'b01: begin
                        br_buffer_2[wr_index][`V]       <= 1'b1;
                        br_buffer_2[wr_index][`cur_pc]  <= current_pc;
                        br_buffer_2[wr_index][`next_pc] <= br_target;
                    end
                    2'b10: begin
                        br_buffer_3[wr_index][`V]       <= 1'b1;
                        br_buffer_3[wr_index][`cur_pc]  <= current_pc;
                        br_buffer_3[wr_index][`next_pc] <= br_target;
                    end
                    2'b11: begin
                        br_buffer_4[wr_index][`V]       <= 1'b1;
                        br_buffer_4[wr_index][`cur_pc]  <= current_pc;
                        br_buffer_4[wr_index][`next_pc] <= br_target;
                    end
                endcase
                repl_ptr[wr_index] <= repl_ptr[wr_index] + 2'b01;
            end
        end
    end

endmodule
