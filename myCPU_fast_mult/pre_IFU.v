module pre_IFU (
        input wire clk,             // 时钟信号
        input wire rst,             // 复位信号
        input wire [34:0] bus_br_data,
        output wire [31:0] pc_o,

        input wire [31:0] csr_era,
        input wire [31:0] csr_eentry,
        input wire [31:0] csr_tlbrentry,
        // 握手信号
        input wire ifu_allowin,
        output wire preifu_to_ifu_valid,


        input wire [4:0] preifu_flush_i,
        input wire refetch_sign_i,
        input wire [31:0] refetch_pc_i,


        // 简单分支预测
        output wire [31:0] pc_pre,
        input wire [31:0] seq_pc
    );

    reg  [31:0] pc;

    wire excp_flush;
    wire excp_tlbrefill_flush;
    wire ertn_flush;
    wire icacop_flush;
    wire tlbop_csrwr_flush;

    assign  {excp_flush, excp_tlbrefill_flush, ertn_flush, icacop_flush, tlbop_csrwr_flush} = preifu_flush_i;
    wire flush_sign = |preifu_flush_i;


    // wire [31:0] seq_pc;
    wire [31:0] nextpc;

    wire br_taken;
    wire [31:0] br_target;
    wire caculate_done;

    wire [31:0] inst_flush_pc;
    wire br_true;

    assign {br_taken, br_target,caculate_done,br_true} = bus_br_data;

    assign inst_flush_pc = {32{ertn_flush}} & csr_era;
    assign pc_pre = pc;

    // 这里要注意优先级
    // refetch
    // tlbrefill
    // excp
    // ertn
    // br_taken
    // seq_pc <--------可以接预测器

    // wire [31:0] seq_pc = pc + 32'd4;

    assign nextpc =
           refetch_sign_i ? refetch_pc_i :
           excp_tlbrefill_flush ? csr_tlbrentry :
           excp_flush ? csr_eentry:
           ertn_flush ? inst_flush_pc:
           br_taken && br_true ? br_target :
           seq_pc;

    reg preifu_valid;
    wire preifu_allowin;

    wire to_preifu_valid = 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            preifu_valid <= 1'b0;
            pc <= 32'h1bfffffc;
        end
        else begin
            if (preifu_allowin) begin
                preifu_valid <= to_preifu_valid;
            end
            if (to_preifu_valid && preifu_allowin) begin
                pc <= nextpc;
            end
        end
    end
    assign pc_o = pc;

    // flush 和 refetch 信号是分开的
    // 这里的逻辑就是，当空闲的时候，可以接受 next_pc
    // 当 refetch_sign 或者 flush 的时候，说明要重新取数据，立即接受 next_pc
    // 当 跳转且跳转信号有效的时候，立即接受 next_pc
    // 当无事发生，且ifu 可以接收数据的时候，立即接受 next_pc

    assign preifu_allowin  = !preifu_valid||        // 空闲
           refetch_sign_i                 ||        // refetch
           flush_sign                     ||        // flush
           br_taken && br_true && caculate_done      ||        // br_flush
           ifu_allowin                              // 下游可以接收数据
           ;
    assign preifu_to_ifu_valid =  preifu_valid && !flush_sign;
endmodule



