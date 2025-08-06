`include "csr.h"
module WBU
    #(
         parameter TLBNUM = 32
     )
     (
         // from mem
         input wire clk,
         input wire rst,

         input wire [149:0] bus_mem_to_wbu_data,
         input wire [31:0] pc_pro_i,
         input wire [31:0] inst_data_i,

         input wire ms_excp,
         input wire [15:0] ms_excp_num,

         // to rf
         output wire rf_we,
         output wire [4:0] rf_waddr,
         output wire [31:0] rf_wdata,
         output wire [31:0] pc,
         // bus
         output wire [70:0] bus_wbu_bypass_data,
         // csr
         output wire [147:0] bus_wub_to_csr_data,
         // ertn
         output wire is_ertn,

         // 握手信号
         input  wire mem_to_wbu_valid,
         output wire wbu_allowin,
         // tlb
         input wire [4:0] tlb_inst_bus,
         // from csr
         input wire [31:0] csr_tlbidx,
         input wire [31:0] csr_tlbehi,
         input wire [31:0] csr_tlbelo0,
         input wire [31:0] csr_tlbelo1,
         input wire [$clog2(TLBNUM)-1:0]  csr_rand_index,
         input wire [9:0]  csr_asid,
         input wire [5:0] csr_ecode_i,

         // tlbsrch
         output  wire                          tlbsrch_en,
         input   wire [$clog2(TLBNUM)-1:0]     tlbsrch_index,
         input   wire                          tlbsrch_found,
         output  wire                          tlbsrch_found_o,
         output  wire [$clog2(TLBNUM)-1:0]     tlbsrch_index_o,

         // tlbrd
         output wire [31:0]     to_trans_tlbidx_o, // 发射给 trans 模块
         input wire  [31:0]     from_trans_tlbehi_in, // 来自 tlb
         input wire  [31:0]     from_trans_tlbelo0_in,
         input wire  [31:0]     from_trans_tlbelo1_in,
         input wire  [31:0]     from_trans_tlbidx_in,
         input wire  [9:0]      from_trans_asid_in,

         output  wire         csr_tlbrd_en_o, // 发射到 csr
         output  wire [31:0]  csr_tlbehi_o,
         output  wire [31:0]  csr_tlbelo0_o,
         output  wire [31:0]  csr_tlbelo1_o,
         output  wire [31:0]  csr_tlbidx_o,
         output  wire [9:0]   csr_asid_o,
         // tlbwr
         output wire        tlbwr_en_o,
         output wire [9:0]  tlbwr_fill_w_asid_o,
         output wire [31:0] tlbwr_fill_tlbehi_o,
         output wire [31:0] tlbwr_fill_tlbelo0_o,
         output wire [31:0] tlbwr_fill_tlbelo1_o,
         output wire [31:0] tlbwr_fill_tlbidx_o,
         output wire [5:0]  tlbwr_fill_ecode_o, // tlbwr tlbfill

         // tlbfill
         output wire  tlbfill_en_o,
         output wire  [$clog2(TLBNUM)-1:0] rand_index_o,
         // invtlb
         input wire   [4:0]       invtlb_op_i,
         input wire   [9:0]       invtlb_asid_i,
         input wire   [18:0]      invtlb_vpn_i,
         output wire  [4:0]       invtlb_op_o,
         output wire  [9:0]       invtlb_asid_o,
         output wire  [18:0]      invtlb_vpn_o,
         output wire              invtlb_en_o,
         // debug
         output wire [31:0] inst_data_o,
         input  wire        is_csr_wr_i,
         output wire        is_csr_wr_o,


         //llbit
         output        ws_llbit_set                     ,
         output        ws_llbit                         ,
         output        ws_lladdr_set                    ,
         output [27:0] ws_lladdr                        ,
         input wire [1:0]   ll_sc_i,
         input wire [31:0]  paddr_i,

         output   wire   ws_to_ds_valid,

         // csr_data : 当csr_rstat == 1时，当前指令读取到的csr寄存器(estat)的值
         input wire csr_rstat_i,
         input wire [31:0] csr_estat_data_i,

         output   wire   ws_valid_diff,
         output   wire   ws_csr_rstat_en_diff,
         output   wire  [31:0] ws_csr_data_diff,

         input  wire cnt_inst_diff_i,
         input wire [63:0] timer_64_diff_i,


         input   wire [7:0] ld_diff_i,
         input   wire [31:0] paddr_diff_i,
         input   wire [31:0] vaddr_diff_i,


         output   wire   cmt_tlbfill_en,
         output   wire   [$clog2(TLBNUM)-1:0] cmt_rand_index,
         output   wire eret_diff,
         output   wire [5:0] ecode_diff,


         output   wire [7:0] ld_diff,
         output   wire [31:0] paddr_diff,
         output   wire [31:0] vaddr_diff,
         output wire cnt_inst_diff_o,
         output wire [63:0] timer_64_diff_o,

         input  wire [7:0] st_diff_i,
         input  wire [31:0] st_data_diff_i,

         output  wire [7:0] st_diff,
         output  wire [31:0] st_data_diff,

         output wire ws_excp_diff,

         input wire inst_idle_i,
         output wire idle_stall,
         input wire has_int, // 有了 has_int 立即解冻

         // cacop
         input wire icacop_op_en_i,
         input wire uncache_en_i,

         // flush
         // preifu 的 flush
         output wire [4:0] preifu_flush,
         output wire refetch_sign,
         output wire [31:0] refetch_pc,
         // 其它模块的 flush
         output wire flush,
         // 发射到 csr 的异常信号
         output [1:0] wbu2_csr_excp,
         output wire [31:0] tlbsrch_stall_wbu_pc_o,

         // bubble_tag
         input wire inst_bubble_i
     );
    reg inst_bubble_i_r;
    reg uncache_en_i_r;
    reg icacop_op_en_i_r;

    reg inst_idle_i_r;
    reg after_br_invalid_i_r;
    reg csr_rstat_i_r;
    reg [31:0] csr_estat_data_i_r;
    reg cnt_inst_diff_i_r;
    reg [63:0] timer_64_diff_i_r;

    reg [7:0]ld_diff_i_r;
    reg [31:0] paddr_diff_i_r;
    reg [31:0] vaddr_diff_i_r;

    reg [7:0]st_diff_i_r;
    reg [31:0] st_data_diff_i_r;


    reg [31:0] paddr_i_r;
    reg [1:0] ll_sc_i_r;

    wire ll_w;
    wire sc_w;

    assign {sc_w,ll_w} = ll_sc_i_r;

    // for debug
    reg is_csr_wr_i_r;



    // to_csr
    wire csr_we;
    wire [13:0] csr_addr;
    wire [31:0] csr_wdata;
    wire [31:0] csr_era;
    wire [5:0] csr_ecode;
    wire [31:0] bad_va;
    wire [8:0] csr_esubcode;
    wire va_error;
    wire excp_tlbrefill;
    wire excp_tlb;
    wire [18:0] excp_tlb_vppn;

    // 异常信号
    reg [15:0] ms_excp_num_r; // 从上一级接收
    reg ms_excp_r;

    wire [15:0] wire_ms_excp_num;
    wire wire_ms_excp;

    wire [15:0] ws_excp_num;
    wire ws_excp;

    assign wire_ms_excp_num = ms_excp_num_r;
    assign wire_ms_excp = ms_excp_r;

    assign ws_excp_num = wire_ms_excp_num;
    // 直接在这里挂之后idle 之后的异常
    assign ws_excp = wire_ms_excp || inst_idle_i_r && has_int;

    // 数据相关
    wire wbu_regWr;
    wire [31:0] wbu_data;
    wire [4:0] wbu_regAddr;
    wire wbu_over;


    wire wire_gr_we;
    wire [4:0] wire_dest;
    wire [31:0] wire_final_result;
    wire [31:0] wire_pc;
    wire wire_csr_we;
    wire [13:0] wire_csr_idx;
    wire [31:0] wire_csr_wdata;
    wire wire_is_inst_ertn;
    wire [31:0] wire_error_va;

    reg [149:0] bus_mem_to_wbu_data_r;
    reg [31:0] inst_data_i_r;
    assign {
            wire_gr_we,
            wire_dest,
            wire_final_result,
            wire_pc,
            wire_csr_we,
            wire_csr_idx,
            wire_csr_wdata,
            wire_is_inst_ertn,
            wire_error_va
        } = bus_mem_to_wbu_data_r;

    // tlb
    reg [4:0] tlb_inst_bus_r;
    wire wire_inst_tlbsrch;
    wire wire_inst_tlbrd;
    wire wire_inst_tlbwr;
    wire wire_inst_tlbfill;
    wire wire_inst_invtlb;
    assign {
            wire_inst_tlbsrch,
            wire_inst_tlbrd,
            wire_inst_tlbwr,
            wire_inst_tlbfill,
            wire_inst_invtlb
        } = tlb_inst_bus_r;

    reg [$clog2(TLBNUM)-1:0] tlbsrch_index_r;
    reg tlbsrch_found_r;

    reg [4:0] invtlb_op_i_r;
    reg [9:0] invtlb_asid_i_r;
    reg [18:0] invtlb_vpn_i_r;


    reg [31:0] pc_pro_i_r;

    wire flush_sign;


    wire done;
    reg fillter_r;

    reg [31:0] last_pc;

    // dummy_signal
    wire waite_ready_i = 1'b1;
    reg wbu_valid;
    wire wbu_ready_go;

    always @(posedge clk) begin
        if (rst || flush_sign) begin
            wbu_valid <= 1'b0;
            inst_bubble_i_r <= 1'b0;

            bus_mem_to_wbu_data_r <= 150'd0;
            csr_estat_data_i_r <= 32'd0;
            timer_64_diff_i_r <= 64'd0;
            tlb_inst_bus_r <= 5'd0;
        end
        else if(wbu_allowin) begin
            wbu_valid <= mem_to_wbu_valid;
        end
        if(mem_to_wbu_valid && wbu_allowin) begin
            bus_mem_to_wbu_data_r <= bus_mem_to_wbu_data;
            inst_data_i_r <= inst_data_i;
            ms_excp_num_r <= ms_excp_num;
            ms_excp_r <= ms_excp;
            tlb_inst_bus_r <= tlb_inst_bus;
            // tlbsrch
            tlbsrch_index_r <= tlbsrch_index;
            tlbsrch_found_r <= tlbsrch_found;
            // invtlb
            invtlb_op_i_r <= invtlb_op_i;
            invtlb_asid_i_r <= invtlb_asid_i;
            invtlb_vpn_i_r <= invtlb_vpn_i;

            // debug
            is_csr_wr_i_r <= is_csr_wr_i;


            pc_pro_i_r <= pc_pro_i;

            ll_sc_i_r  <= ll_sc_i;
            paddr_i_r <= paddr_i;

            csr_rstat_i_r <= csr_rstat_i;
            csr_estat_data_i_r <= csr_estat_data_i;

            cnt_inst_diff_i_r <= cnt_inst_diff_i;
            timer_64_diff_i_r <= timer_64_diff_i;


            ld_diff_i_r <= ld_diff_i;
            paddr_diff_i_r <= paddr_diff_i;
            vaddr_diff_i_r <= vaddr_diff_i;


            st_diff_i_r <= st_diff_i;
            st_data_diff_i_r <= st_data_diff_i;

            inst_idle_i_r <= inst_idle_i;


            icacop_op_en_i_r <= icacop_op_en_i;

            uncache_en_i_r <= uncache_en_i;

            inst_bubble_i_r <= inst_bubble_i;

        end

    end

    assign done = !idle_stall; // 如果有 idle_stall，那么计算不完成
    assign wbu_ready_go = done;
    assign wbu_allowin = !wbu_valid || wbu_ready_go;

    // 这里要考虑 idle_stall
    wire real_valid;
    assign real_valid = wbu_valid && !idle_stall && !ws_excp;

    assign wbu_over = wbu_valid;
    // 输出到 regfile
    assign rf_we    = wire_gr_we && real_valid;
    assign rf_waddr = wire_dest;
    assign rf_wdata = wire_final_result;
    assign pc       = wire_pc;

    // 输出到 csr
    assign csr_we = wire_csr_we && real_valid;
    assign csr_addr = wire_csr_idx;
    assign csr_wdata = wire_csr_wdata;

    // tlb
    // tlbsrch
    assign tlbsrch_en = wire_inst_tlbsrch && real_valid;
    assign tlbsrch_found_o = tlbsrch_found_r;
    assign tlbsrch_index_o = tlbsrch_index_r;
    // tlbrd
    assign to_trans_tlbidx_o = csr_tlbidx;
    assign csr_tlbrd_en_o = wire_inst_tlbrd && real_valid;
    assign csr_tlbehi_o = from_trans_tlbehi_in;
    assign csr_tlbelo0_o = from_trans_tlbelo0_in;
    assign csr_tlbelo1_o = from_trans_tlbelo1_in;
    assign csr_tlbidx_o = from_trans_tlbidx_in;
    assign csr_asid_o = from_trans_asid_in;
    // tlbwr tlbfill
    assign tlbwr_en_o = wire_inst_tlbwr && real_valid;
    assign tlbwr_fill_tlbehi_o = csr_tlbehi;
    assign tlbwr_fill_tlbelo0_o = csr_tlbelo0;
    assign tlbwr_fill_tlbelo1_o = csr_tlbelo1;
    assign tlbwr_fill_tlbidx_o = csr_tlbidx;
    assign tlbwr_fill_ecode_o = csr_ecode_i;
    assign tlbwr_fill_w_asid_o = csr_asid;

    assign tlbfill_en_o = wire_inst_tlbfill && real_valid;
    assign rand_index_o = csr_rand_index;
    // invtlb
    assign invtlb_en_o = wire_inst_invtlb && real_valid;
    assign invtlb_op_o = invtlb_op_i_r;
    assign invtlb_asid_o = invtlb_asid_i_r;
    assign invtlb_vpn_o = invtlb_vpn_i_r;




    // 解决数据相关
    assign wbu_regWr = rf_we;
    assign wbu_data = wire_final_result;
    assign wbu_regAddr = wire_dest;

    wire [31:0] wbu_pc = pc_pro_i_r;
    assign bus_wbu_bypass_data = {
               wbu_regWr,
               wbu_data,
               wbu_regAddr,
               wbu_pc,
               wbu_over
           };



    assign is_ertn = wire_is_inst_ertn;
    // 这里应该怎么设置地址呢？
    // 如果是普通异常，没事
    // 如果是中断，分为两种情况：
    // 挂在了指令的 "开头" : 直接就是 wire_pc
    // 挂在里指令的 "中间" : 那就是 wire_pc + 4
    // 怎么判断是在开头还是中间 : last_pc == pc_reg
    // 当中断来的时候，都会接受：
    // 普通在中间直接挂

    assign csr_era = wire_pc;

    // 约定
    // adef:0
    // fs_tlbr:1
    // fs_pif:2
    // fs_ppi:3
    // syscall:4
    // ine:5
    // brk:6
    // ie:7
    // ipe:8
    // ale:9
    // exu_tlbr:10
    // exu_pil:11
    // exu_pis:12
    // exu_ppi:13
    // exu_pme:14

    // 检测异常
    assign {csr_ecode,
            va_error,
            bad_va,
            csr_esubcode,
            excp_tlbrefill,
            excp_tlb,
            excp_tlb_vppn} =
           ws_excp_num[7] || (inst_idle_i_r && has_int) ? {`ECODE_INT , 1'b0, 32'b0, 9'b0, 1'b0, 1'b0, 19'b0}:
           ws_excp_num[0] ? {`ECODE_ADEF, wbu_valid, wire_pc, `ESUBCODE_ADEF, 1'b0, 1'b0, 19'b0} :
           ws_excp_num[1] ? {`ECODE_TLBR, wbu_valid, wire_pc, 9'b0, wbu_valid, wbu_valid, wire_pc[31:13]} :
           ws_excp_num[2] ? {`ECODE_PIF , wbu_valid, wire_pc, 9'b0, 1'b0, wbu_valid, wire_pc[31:13]} :
           ws_excp_num[3] ? {`ECODE_PPI , wbu_valid, wire_pc, 9'b0, 1'b0, wbu_valid, wire_pc[31:13]} :
           ws_excp_num[4] ? {`ECODE_SYS, 1'b0, 32'b0, 9'b0, 1'b0, 1'b0, 19'b0}:
           ws_excp_num[6] ? {`ECODE_BRK , 1'b0, 32'b0, 9'b0, 1'b0, 1'b0, 19'b0} :
           ws_excp_num[5] ? {`ECODE_INE , 1'b0, 32'b0, 9'b0, 1'b0, 1'b0, 19'b0} :
           ws_excp_num[8] ? {`ECODE_IPE , 1'b0, 32'b0, 9'b0, 1'b0, 1'b0, 19'b0} :
           ws_excp_num[9] ? {`ECODE_ALE , wbu_valid, wire_error_va, 9'b0, 1'b0, 1'b0, 19'b0} :
           ws_excp_num[10] ? {`ECODE_TLBR, wbu_valid, wire_error_va, 9'b0, wbu_valid, wbu_valid, wire_error_va[31:13]} :
           ws_excp_num[14] ? {`ECODE_PME , wbu_valid, wire_error_va, 9'b0, 1'b0, wbu_valid, wire_error_va[31:13]} :
           ws_excp_num[13] ? {`ECODE_PPI , wbu_valid, wire_error_va, 9'b0, 1'b0, wbu_valid, wire_error_va[31:13]} :
           ws_excp_num[12] ? {`ECODE_PIS , wbu_valid, wire_error_va, 9'b0, 1'b0, wbu_valid, wire_error_va[31:13]} :
           ws_excp_num[11] ? {`ECODE_PIL , wbu_valid, wire_error_va, 9'b0, 1'b0, wbu_valid, wire_error_va[31:13]} :
           69'b0;

    // 信号发射到下游
    assign bus_wub_to_csr_data = {
               csr_we,
               csr_addr,
               csr_wdata,
               csr_ecode,
               va_error,
               bad_va,
               csr_esubcode,
               excp_tlbrefill,
               excp_tlb,
               excp_tlb_vppn,
               csr_era};

    //llbit
    assign ws_llbit_set  = (ll_w || sc_w) && real_valid;
    // assign ws_llbit      = ll_w && !uncache_en_i_r;
    // assign ws_lladdr_set = ll_w && !uncache_en_i_r && real_valid;
    assign ws_llbit      = ll_w;
    assign ws_lladdr_set = ll_w && real_valid;
    assign ws_lladdr     =  paddr_i_r[31:4];


    assign inst_data_o = inst_data_i_r;
    assign is_csr_wr_o = is_csr_wr_i_r;

    // wbu 一共发射以下 2 种异常:
    // ws_excp
    // wire_is_inst_ertn：严格来说，这不是异常，但是都是一个跳转，
    // 其中 ws_excp 包含 excp_tlbrefill

    // 由于异常要从跳转，说到底，有点像 IDU 中的 br_taken(那可不可以给 ertn、syscall 加类似于分支预测呢？这个想法很有趣)
    // 因此要清空中间所有的缓存，这导致了以下几种 flush:
    // excp_flush
    // excp_tlbrefill_flush
    // etrn_flush
    // tlbrefill_flush
    // icacop_flush
    // tlbop_csrwr_flush

    // 这几种 flush 发射到 preifu 需要严格区分，因为跳转的 pc 不尽相同
    // 但是 通往 ifu、idu、exu、mem、wbu 不需要区分，都是 flush 清空指令缓存
    // 至于两个 excp 信号，通往 csr 即可

    // 还有一个要注意的，如果 exu、mem 这两个单元有异常、icacop 和 tlbop_csrwr，那么这些单元停止任何计算
    // 比如 exu 的乘除法，mem 的访存

    // 其中还要发射 refetch 信号，产生 refetch 信号的有两个信号源
    // icacop_flush
    // tlbop_csrwr_flush

    wire excp_flush = ws_excp && wbu_valid;
    wire excp_tlbrefill_flush = excp_tlbrefill && wbu_valid;
    wire ertn_flush = wire_is_inst_ertn && real_valid;
    wire icacop_flush = icacop_op_en_i_r && real_valid;
    wire tlbop_csrwr_flush = (wire_inst_invtlb ||
                              wire_inst_tlbrd ||
                              wire_inst_tlbwr ||
                              wire_inst_tlbfill || wire_csr_we) && real_valid;

    // preifu
    assign preifu_flush = {excp_flush, excp_tlbrefill_flush, ertn_flush, icacop_flush, tlbop_csrwr_flush};
    assign refetch_sign = icacop_flush || tlbop_csrwr_flush;
    assign refetch_pc = wbu_pc + 32'd4; // 重新取出本条指令后面的指令
    // 其他模块
    assign flush = |preifu_flush;
    // 发射到 csr 的异常信号
    assign wbu2_csr_excp = {excp_flush, ertn_flush};
    assign flush_sign = |preifu_flush; // 本单模块使用


    assign ws_to_ds_valid = wbu_valid;

    assign idle_stall = inst_idle_i_r && !has_int;
    assign tlbsrch_stall_wbu_pc_o = wbu_pc;

    // difftest
    assign ws_valid_diff = real_valid && !inst_bubble_i_r; // 不要提交 idle 就能过 difftest?
    assign ws_csr_rstat_en_diff = csr_rstat_i_r;
    assign ws_csr_data_diff     = csr_estat_data_i_r;

    assign cnt_inst_diff_o = cnt_inst_diff_i_r;
    assign timer_64_diff_o = timer_64_diff_i_r;

    assign cmt_tlbfill_en = wire_inst_tlbfill && real_valid;
    assign cmt_rand_index = rand_index_o;

    assign ld_diff = ld_diff_i_r;
    assign paddr_diff = paddr_diff_i_r;
    assign vaddr_diff = vaddr_diff_i_r;

    assign eret_diff = wire_is_inst_ertn && real_valid;
    assign ecode_diff = csr_ecode;

    assign st_data_diff = st_data_diff_i_r;
    assign st_diff = st_diff_i_r;

    assign ws_excp_diff = ws_excp && wbu_valid;


endmodule
