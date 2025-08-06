`include "csr.h"
module MEM
    #(
         parameter TLBNUM = 32
     )
     (
         // from exu
         input wire clk,
         input wire rst,

         input wire es_excp_i,
         input wire [15:0] es_excp_num_i,

         output wire ms_excp_o,
         output wire [15:0] ms_excp_num_o,

         // 数据前递到 idu
         output wire [32:0] inst_ld,
         output wire [1:0]  inst_sc,

         input wire [9:0]  es_mem_op_i,
         input wire [31:0] es_rkd_value_i,
         input wire [31:0] es_alu_result_i,
         // ================访存单元================
         // dcache
         output wire dcache_valid,
         output wire dcache_op,
         output wire [2:0] dcache_size,
         output wire [19:0] dcache_tag,
         output wire [7:0] dcache_index,
         output wire [3:0] dcache_offset,

         // 如果遇到 flush 信号, 则取消请求
         // 这是因为 如果 mem 的 请求发出后，dcache 不会理会 flush
         // dcache 持续处理请求，最终会返回 rdata。
         // 但是这个 data 已经不是当前 MEM 所需要的了

         output wire flush_sign_cancel,
         output wire  [3:0]  dcache_wstrb,
         output wire  [31:0] dcache_wdata,
         input wire dcache_addr_ok,
         input wire dcache_data_ok,
         input wire [31:0] dcache_rdata,

         // dcache 额外的属性
         output wire data_uncache_en,

         // from csr
         input wire [1:0]  csr_datm,

         input wire [1:0]  csr_plv,
         input wire [31:0] csr_dmw0,
         input wire [31:0] csr_dmw1,
         input wire        csr_da,
         input wire        csr_pg,
         input wire [31:0] csr_tlbidx,
         input wire [31:0] csr_tlbehi,
         input wire [31:0] csr_tlbelo0,
         input wire [31:0] csr_tlbelo1,
         input wire [18:0] csr_vppn,
         input wire [9:0]  csr_asid,
         input wire        ds_llbit,
         input wire [27:0] lladdr,

         // from or to addr_trans
         // for tlbsrch and access mem
         output wire           data_addr_trans_en,
         output wire [9:0]     data_asid,
         output wire [31:0]    data_vaddr,
         output wire           data_dmw0_en,
         output wire           data_dmw1_en,
         output wire [31:0]    data_dmw0,
         output wire [31:0]    data_dmw1,
         output wire           data_da,
         output wire           data_pg,

         input wire  [ 7:0]    data_index,
         input wire  [19:0]    data_tag,
         input wire  [ 3:0]    data_offset,

         input wire            data_tlb_found,
         input wire  [$clog2(TLBNUM)-1:0]     data_tlb_index,

         input wire            data_tlb_v,
         input wire            data_tlb_d,
         input wire  [1:0]     data_tlb_mat,
         input wire  [1:0]     data_tlb_plv,

         // ================访存单元================

         input wire [151:0] es_to_ms_data_i,
         input wire [31:0]  es_inst_data_i,

         output wire [31:0]  ms_inst_data_o,
         output wire [149:0] ms_to_ws_data_o,

         // from mem_sram
         output wire [70:0] bus_mem_bypass_data,

         // exception
         input wire flush_sign,

         input wire wbu_in_is_ertn, // from wbu
         output wire mem_excp, // 发射到 exu 以实现精确异常

         // 握手信号
         input exu_to_mem_valid,
         output mem_allowin,
         input wbu_allowin,
         output mem_to_wbu_valid,
         // tlb
         input wire [4:0] es_tlb_inst_bus_i,
         output wire [4:0] ms_tlb_inst_bus_o,

         // tlbsrch
         output wire [$clog2(TLBNUM)-1:0] ms_tlbsrch_index_o,
         output wire                     ms_tlbsrch_found_o,
         // invtlb
         input wire [4:0]       es_invtlb_op_i,
         input wire [9:0]       es_invtlb_asid_i,
         input wire [18:0]      es_invtlb_vpn_i,

         output wire [4:0]      ms_invtlb_op_o,
         output wire [9:0]      ms_invtlb_asid_o,
         output wire [18:0]     ms_invtlb_vpn_o,

         // debug
         input wire es_is_csr_wr_i,
         output wire ms_is_csr_wr_o,

         // refetch sign

         input [31:0] es_pc_pro_i,
         output [31:0] ms_pc_pro_o,

         input [82:0] bus_csr_rd_wr_data_i,

         output wire [1:0] ll_sc,

         output wire [31:0] ms_paddr_o,

         output wire  ms_to_ds_valid,

         input wire csr_rstat_i,
         output wire csr_rstat_o,

         //  csr_data : 当csrstat == 1时，当前指令读取到的csr寄存器(estat)的值
         input wire [31:0] csr_estat_data_i,
         input wire cnt_inst_diff_i,
         input wire [63:0] timer_64_diff_i,
         input wire [31:0] csr_data_i,

         output wire [31:0] csr_estat_data,
         output wire cnt_inst_diff,
         output wire [63:0] timer_64_diff,

         output   wire [7:0] ld_diff,
         output   wire [31:0] paddr_diff,
         output   wire [31:0] vaddr_diff,


         output  wire [7:0] st_diff,
         output  wire [31:0] st_data_diff,

         input wire inst_idle_i,
         output wire inst_idle_o,

         input wire idle_stall,
         input wire disable_cache, //debug

         // cacop
         input wire cacop_i,
         // icache
         output wire icacop_op_en,
         input wire icache_busy,
         input wire icacop_addr_ok,
         input wire icacop_data_ok,

         // dcache
         output wire dcacop_op_en,
         input wire dcache_busy,
         input wire dcacop_addr_ok,
         input wire dcacop_data_ok,

         output wire [1:0] cacop_op_mode,
         // 生成 icacop_flush
         output icacop_o,
         output cacop_op_mode_di,

         // bubble_tag
         input wire inst_bubble_i,
         output wire inst_bubble_o
     );
    reg inst_bubble_i_r;

    reg cacop_i_r;

    reg [31:0] csr_estat_data_i_r;
    reg cnt_inst_diff_i_r;
    reg [63:0] timer_64_diff_i_r;
    reg [31:0] csr_data_i_r;

    wire req; // en
    wire wr;   // |we
    wire [1:0] size; // 新增
    wire [3:0] wstrb; // we
    wire [31:0] addr; // 转换后的地址
    wire [31:0] wdata;
    wire addr_ok;
    wire data_ok;
    wire [31:0] rdata;

    assign dcache_valid = req;
    // assign dcache_op = 1'b0; // read
    assign dcache_size = {1'b0,size};
    assign dcache_tag = addr[31:12];
    assign dcache_index = addr[11:4];
    assign dcache_offset = addr[3:0];

    assign dcache_wstrb = wstrb;
    assign dcache_wdata = wdata;

    assign addr_ok = dcache_addr_ok;
    assign data_ok = dcache_data_ok;
    assign rdata   = dcache_rdata;

    // 寄存器
    reg es_excp_i_r;
    reg [15:0] es_excp_num_i_r;

    reg [9:0]  es_mem_op_i_r;
    reg [31:0] es_rkd_value_i_r;
    reg [31:0] es_alu_result_i_r;

    reg [151:0] es_to_ms_data_i_r;
    reg [31:0]  es_inst_data_i_r;

    reg [4:0]  es_tlb_inst_bus_i_r;

    reg [4:0]  es_invtlb_op_i_r;
    reg [9:0]  es_invtlb_asid_i_r;
    reg [18:0] es_invtlb_vpn_i_r;

    reg         es_is_csr_wr_i_r;
    reg [31:0]  es_pc_pro_i_r;


    reg csr_rstat_i_r;
    reg inst_idle_i_r;


    // 异常信号

    // 地址非对齐
    wire mem_excp_ale;
    wire [15:0] excp_ale_num;
    // TLB重填异常
    wire mem_excp_tlbr;
    wire [15:0] excp_tlbr_num;
    // load 操作页无效异常
    wire mem_excp_pil;
    wire [15:0] excp_pil_num;
    // store 操作页无效异常
    wire mem_excp_pis;
    wire [15:0] excp_pis_num;
    // 页特权异常
    wire mem_excp_ppi;
    wire [15:0] excp_ppi_num;
    // 页修改例外
    wire mem_excp_pme;
    wire [15:0] excp_pme_num;

    // 数据相关
    wire mem_regWr;
    wire [31:0] mem_data;
    wire [4:0] mem_regAddr;
    wire mem_over;


    wire [31:0] wire_exu_result;
    wire wire_res_from_csr;
    wire wire_res_from_mem;
    wire [4:0] wire_dest;
    wire wire_gr_we;
    wire [31:0] wire_pc;
    wire wire_csr_we_1;
    wire [13:0] wire_csr_idx;
    wire [31:0] wire_csr_wdata;
    wire wire_is_inst_ertn;
    wire [31:0] wire_error_va;

    wire gr_we;
    wire [4:0] dest;
    wire [31:0] pc;
    wire [31:0] final_result;

    // tlb
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
        } = es_tlb_inst_bus_i_r;


    assign {
            wire_res_from_csr,
            wire_res_from_mem,
            wire_exu_result,
            wire_gr_we,
            wire_dest,
            wire_pc,
            wire_csr_we_1,
            wire_csr_idx,
            wire_csr_wdata,
            wire_is_inst_ertn,
            wire_error_va
        } = es_to_ms_data_i_r;

    assign ms_to_ws_data_o = flush_sign ? 150'd0 : {
               gr_we,
               dest,
               final_result,
               pc,
               wire_csr_we_1,
               wire_csr_idx,
               wire_csr_wdata,
               wire_is_inst_ertn,
               wire_error_va
           };

    reg sc_r;
    always @(posedge clk) begin
        if(sc_do) begin
            sc_r <= 1'b1;
        end
        if(!sc_w) begin
            sc_r <= 1'b0;
        end
    end

    assign final_result = wire_res_from_mem ? rdata_final :
           wire_res_from_csr ? csr_data_i_r :
           sc_w ? {{31{1'b0}},sc_do | sc_r & sc_w}: // 如果是 sc，就看能否成功执行
           wire_exu_result;
    assign mem_excp = ms_excp || wire_is_inst_ertn;   // 发送给上一级，目的是为了取消上一级的一些执行效果，比如内存写、除法计算等等

    assign gr_we          = wire_gr_we;
    assign dest           = wire_dest;
    assign pc             = wire_pc;


    wire [9:0] mem_op = es_mem_op_i_r;

    wire st_b =  mem_op[0];
    wire st_h =  mem_op[1];
    wire st_w =  mem_op[2];
    wire ld_b =  mem_op[3];
    wire ld_bu = mem_op[4];
    wire ld_h =  mem_op[5];
    wire ld_hu = mem_op[6];
    wire ld_w =  mem_op[7];

    wire ll_w =  mem_op[8];
    wire sc_w =  mem_op[9];


    wire [3:0] st_b_we;
    wire [3:0] st_h_we;
    wire [3:0] st_w_we;

    assign st_b_we = es_alu_result_i_r[1:0] == 2'b00 ? 4'b0001 :
           es_alu_result_i_r[1:0] == 2'b01 ? 4'b0010 :
           es_alu_result_i_r[1:0] == 2'b10 ? 4'b0100 :
           4'b1000;
    assign st_h_we = es_alu_result_i_r[1:0] == 2'b00 ? 4'b0011 :
           es_alu_result_i_r[1:0] == 2'b10 ? 4'b1100 :
           4'b0000;
    assign st_w_we = 4'b1111;

    // 这里读出来的数据也很讲究

    // 解决数据相关
    assign mem_regWr = gr_we;
    assign mem_data = final_result;
    assign mem_regAddr = wire_dest;

    // 当前是否执行 ld 执行
    // 如果在执行 load 操作，将该信号传给 idu，如果 idu 发现load_use，可以直接从
    assign inst_ld = {ld_b | ld_bu | ld_h | ld_hu | ld_w | ll_w, final_result};

    wire [31:0] mem_pc;
    assign mem_pc  = es_pc_pro_i_r;
    assign bus_mem_bypass_data = {
               mem_regWr,
               mem_data,
               mem_regAddr,
               mem_pc,
               mem_over
           };


    wire done; // done 指明 MEM 计算是否完成

    reg mem_valid;
    wire mem_ready_go;

    always @(posedge clk) begin
        if (rst || flush_sign) begin
            mem_valid <= 1'b0;
            inst_bubble_i_r <= 1'b0;

            es_to_ms_data_i_r <= 152'd0;
            es_rkd_value_i_r <= 32'd0;
            es_alu_result_i_r <= 32'd0;
            csr_estat_data_i_r <= 32'd0;
            timer_64_diff_i_r <= 64'd0;
            csr_data_i_r <= 32'd0;

        end
        else if(mem_allowin) begin
            mem_valid <= exu_to_mem_valid;
        end
        if(mem_allowin && exu_to_mem_valid) begin
            es_excp_i_r <= es_excp_i;
            es_excp_num_i_r <= es_excp_num_i;
            es_mem_op_i_r <= es_mem_op_i;
            es_rkd_value_i_r <= es_rkd_value_i;
            es_alu_result_i_r <= es_alu_result_i;

            es_to_ms_data_i_r <= es_to_ms_data_i;
            es_inst_data_i_r <= es_inst_data_i;
            // tlb
            es_tlb_inst_bus_i_r <= es_tlb_inst_bus_i;
            // invtlb
            es_invtlb_op_i_r <= es_invtlb_op_i;
            es_invtlb_asid_i_r <= es_invtlb_asid_i;
            es_invtlb_vpn_i_r <= es_invtlb_vpn_i;

            es_is_csr_wr_i_r <= es_is_csr_wr_i;
            es_pc_pro_i_r <= es_pc_pro_i;

            csr_rstat_i_r <= csr_rstat_i;
            inst_idle_i_r <= inst_idle_i;

            cacop_i_r <= cacop_i;
            csr_estat_data_i_r <= csr_estat_data_i;
            cnt_inst_diff_i_r <= cnt_inst_diff_i;
            timer_64_diff_i_r <= timer_64_diff_i;
            csr_data_i_r <= csr_data_i;

            inst_bubble_i_r <= inst_bubble_i;
        end
    end

    // 这里单独维护一个状态机用于访存和 cacop
    reg [2:0] sub_fsm;
    always @(posedge clk) begin
        if(rst || flush_sign) begin
            sub_fsm <= 3'd0;
        end
        else begin
            case(sub_fsm)
                3'd0:begin
                    if(cacop_i_r && !stop_signal) begin
                        // 操作 icache的话维护状态机
                        // 进入新的状态
                        if(icacop_op_en) begin
                            sub_fsm <= 3'd2;
                        end
                        else if(dcacop_op_en) begin
                            sub_fsm <= 3'd3;
                        end
                    end
                    // 如果是访存操作
                    else if(access_memo && !stop_signal) begin
                        if(addr_ok && !data_ok) begin
                            sub_fsm <= 3'd1; // 等待
                        end
                        else if(addr_ok && data_ok) begin
                            sub_fsm <= 3'd0;
                        end
                    end
                    else if(stop_signal) begin
                        sub_fsm <= 3'd0;
                    end
                    else begin
                        sub_fsm <= 3'd0;
                    end
                end

                // 访存操作
                3'd1: begin
                    if (data_ok) begin
                        sub_fsm <= 3'd0;// 处理完成
                    end
                end
                // 处理 icacop:这两个信号一定是同步拉高的
                3'd2:begin
                    if (icacop_addr_ok && icacop_data_ok) begin
                        sub_fsm <= 3'd0; // 处理完成
                    end
                end
                // 处理 dcache
                3'd3:begin
                    if(dcacop_addr_ok && !dcacop_data_ok) begin
                        sub_fsm <= 3'd4; // 等待 ok
                    end
                    else if (dcacop_addr_ok && dcacop_data_ok) begin
                        sub_fsm <= 3'd0; // 处理完成
                    end

                end
                3'd4:begin
                    if(dcacop_data_ok) begin
                        sub_fsm <= 3'd0; // 处理完成
                    end
                end
                default:begin
                end
            endcase
        end
    end

    // done 信号的生成
    // 这个信号的前提是 mem_state 必须处在 1 状态，因为这时候缓存中存的信息是待处理的
    assign done = stop_signal ? 1'd1:
           access_memo ? data_ok : // 访存的话数据完成就 done
           cacop_i_r ? icacop_addr_ok && icacop_data_ok || dcacop_data_ok :
           1'd1;

    // 取消取指令
    assign flush_sign_cancel = flush_sign;

    // 发送访存请求
    assign req = stop_signal ? 1'b0 :
           mem_valid && access_memo && sub_fsm == 3'd0 && !addr_ok;

    assign mem_ready_go = done;
    assign mem_allowin = !mem_valid || mem_ready_go && wbu_allowin;
    assign mem_to_wbu_valid = mem_valid && mem_ready_go && !flush_sign;

    // real data
    // axi 返回的永远是 4 字节，因此这里会根据 size 以及地址生成最终的数据
    // offset[1:0] == 00 的时候：
    // size:0--->0001
    // size:1--->0011
    // size:2--->1111
    // offset[1:0] == 01 的时候：
    // size:0--->0010
    // offset[1:0] == 10 的时候：
    // size:0--->0100
    // size:1--->1100
    // offset[1:0] == 11 的时候：
    // size:0--->1000
    // 另外，这里还得考虑一下符号扩展
    wire [31:0] real_data;
    wire [31:0] rdata_final;
    // wire [31:0] paddr = {data_tag, wire_error_va[11:0]};
    wire [31:0] paddr;
    assign paddr = {data_tag, es_alu_result_i_r[11:0]};

    assign real_data =
           (data_offset[1:0] == 2'b00) ? (
               (size == 2'b00) ? (
                   ld_b ? {{24{rdata[7]}},rdata[7:0]}: {24'b0, rdata[7:0]}):
               (size == 2'b01) ? (
                   ld_h ? {{16{rdata[15]}},rdata[15:0]} : {16'b0, rdata[15:0]}):
               rdata
           ) :
           (data_offset[1:0] == 2'b01) ? (
               ld_b ? {{24{rdata[15]}},rdata[15:8]}: {24'b0, rdata[15:8]}
           ) :
           (data_offset[1:0] == 2'b10) ? (
               (size == 2'b00) ? (
                   ld_b ? {{24{rdata[23]}},rdata[23:16]}: {24'b0, rdata[23:16]}):
               (size == 2'b01) ? (
                   ld_h ? {{16{rdata[31]}},rdata[31:16]} : {16'b0, rdata[31:16]}):
               rdata
           ) :
           (data_offset[1:0] == 2'b11) ? (
               ld_b ? {{24{rdata[31]}},rdata[31:24]}: {24'b0, rdata[31:24]}
           ) :
           rdata;  // 默认情况返回原始数据

    assign rdata_final = flush_sign ? 32'd0 : real_data;


    // 这里的 over 可以提前结束:
    assign mem_over = mem_ready_go;

    // ================访存单元================
    wire stop_signal;
    assign stop_signal = flush_sign || ms_excp;

    // sc 是否执行，如果执行了，就往 rd 中写 1
    wire sc_do;
    assign sc_do = (sc_w && ds_llbit && lladdr == paddr[31:4]);

    assign size = ld_b || ld_bu || st_b ? 2'b00 :
           ld_h || ld_hu || st_h ? 2'b01 :
           st_w || ld_w || ll_w || sc_do ? 2'b10 : 2'b00;
    assign wr = (st_b || st_h || st_w || sc_do) ;

    assign wstrb = stop_signal ? 4'b0000 : // 异常
           st_b  ? st_b_we :
           st_h  ? st_h_we :
           st_w || sc_do ? st_w_we :
           4'b0000 ;
    // 写入
    assign wdata = st_b ? {4{es_rkd_value_i_r[7:0]}} :
           st_h ? {2{es_rkd_value_i_r[15:0]}} :
           st_w || sc_do ? es_rkd_value_i_r : 32'b0;

    wire read_mem  = ld_b || ld_bu || ld_h || ld_hu || ld_w || ll_w;
    wire write_mem = st_b || st_h || st_w || sc_do;

    wire access_memo = read_mem || write_mem;

    assign dcache_op = write_mem;


    // for difftest
    wire [31:0] wdata_diff;
    assign wdata_diff =  st_b ? (data_offset[1:0]==2'b00 ? {24'b0, es_rkd_value_i_r[7:0]} :
                                 data_offset[1:0]==2'b01 ? {16'b0, es_rkd_value_i_r[7:0], 8'b0} :
                                 data_offset[1:0]==2'b10 ? {8'b0, es_rkd_value_i_r[7:0], 16'b0} :
                                 {es_rkd_value_i_r[7:0], 24'b0}
                                ) :
           st_h ? (data_offset[1:0]==2'b00 ? {16'b0, es_rkd_value_i_r[15:0]} :
                   {es_rkd_value_i_r[15:0], 16'b0}
                  ) :
           es_rkd_value_i_r;

    wire pg_mode;
    wire da_mode;

    // 加上 tlb 之后，地址的意义发生了变化
    // 假设是 pg 映射模式，那么地址就得从 addr_trans 返回
    assign data_vaddr = wire_inst_tlbsrch ? {csr_vppn,13'd0} : es_alu_result_i_r;
    assign data_asid = csr_asid;
    assign data_dmw0 = csr_dmw0;
    assign data_dmw1 = csr_dmw1;
    assign data_da = csr_da;
    assign data_pg = csr_pg;

    assign pg_mode = csr_pg && !csr_da;
    assign da_mode = csr_da && !csr_pg;

    assign data_dmw0_en = ((data_dmw0[`PLV0] && csr_plv == 2'd0) || (data_dmw0[`PLV3] && csr_plv == 2'd3)) && (es_alu_result_i_r[31:29] == data_dmw0[`VSEG]) && pg_mode;
    assign data_dmw1_en = ((data_dmw1[`PLV0] && csr_plv == 2'd0) || (data_dmw1[`PLV3] && csr_plv == 2'd3)) && (es_alu_result_i_r[31:29] == data_dmw1[`VSEG]) && pg_mode;
    assign data_addr_trans_en = pg_mode && !data_dmw0_en && !data_dmw1_en && !cacop_op_mode_di;


    assign addr = {data_tag, data_index, data_offset}; // 物理地址

    assign data_uncache_en = (da_mode && (csr_datm == 2'b0))    ||
           (data_dmw0_en && (csr_dmw0[`DMW_MAT] == 2'b0))       ||
           (data_dmw1_en && (csr_dmw1[`DMW_MAT] == 2'b0))       ||
           (data_addr_trans_en && (data_tlb_mat == 2'b0))       ||
           disable_cache;


    // for tlbsrch
    assign ms_tlbsrch_index_o = data_tlb_index;
    assign ms_tlbsrch_found_o = data_tlb_found;

    // ================访存单元================
    // 异常===========================================================================

    // 检测地址是否自然对齐
    // 如果是 ld_h 或者 st_h，对齐到偶数地址
    // 如果是 ld_w 或者 st_w，对齐到4字节
    // 0x9
    assign mem_excp_ale = (ld_h || ld_hu || st_h) && es_alu_result_i_r[0] ? 1'b1 :
           (ld_w || st_w || ll_w || sc_do) && (es_alu_result_i_r[1:0] != 2'b00) ? 1'b1 : 1'b0;
    assign excp_ale_num = mem_excp_ale ? 16'h0200 :16'b0;

    wire cacop_excp = cacop_i_r && cacop_op_mode == 2'd2;

    // cacop 可能引起相关的异常
    // 0x10
    assign mem_excp_tlbr = (access_memo || cacop_excp) && !data_tlb_found && data_addr_trans_en;
    assign excp_tlbr_num = mem_excp_tlbr ? 16'h0400 : 16'b0;
    // 0x11
    assign mem_excp_pil  = (read_mem || cacop_excp) && !data_tlb_v && data_addr_trans_en;
    assign excp_pil_num = mem_excp_pil ? 16'h0800 : 16'b0;
    // 0x12
    assign mem_excp_pis  = write_mem && !data_tlb_v && data_addr_trans_en;
    assign excp_pis_num = mem_excp_pis ? 16'h1000 : 16'b0;
    // 0x13
    assign mem_excp_ppi  = access_memo && data_tlb_v && (csr_plv > data_tlb_plv) && data_addr_trans_en;
    assign excp_ppi_num = mem_excp_ppi ? 16'h2000 : 16'b0;
    // 0x14
    assign mem_excp_pme  = write_mem && data_tlb_v && (csr_plv <= data_tlb_plv) && !data_tlb_d && data_addr_trans_en;
    assign excp_pme_num = mem_excp_pme ? 16'h4000 : 16'b0;


    wire [15:0] wire_es_excp_num;
    wire wire_es_excp;
    wire [15:0] ms_excp_num;
    wire ms_excp;
    assign wire_es_excp_num = es_excp_num_i_r;
    assign wire_es_excp = es_excp_i_r;

    // 当前阶段的异常 += 上一阶段

    assign ms_excp_num = wire_es_excp_num | excp_ale_num |
           excp_tlbr_num | excp_pil_num | excp_pis_num |
           excp_ppi_num | excp_pme_num;

    // 当前阶段的异常 += 上一阶段
    assign ms_excp = wire_es_excp || mem_excp_ale ||
           mem_excp_tlbr || mem_excp_pil || mem_excp_pis ||
           mem_excp_ppi || mem_excp_pme;

    // 输出
    assign ms_excp_o = ms_excp;
    assign ms_excp_num_o = ms_excp_num;

    // tlb
    assign ms_tlb_inst_bus_o = es_tlb_inst_bus_i_r;
    // for invtlb
    assign ms_invtlb_op_o = es_invtlb_op_i_r;
    assign ms_invtlb_asid_o = es_invtlb_asid_i_r;
    assign ms_invtlb_vpn_o = es_invtlb_vpn_i_r;

    assign ms_inst_data_o = es_inst_data_i_r;
    assign ms_is_csr_wr_o = es_is_csr_wr_i_r;


    assign ms_pc_pro_o = es_pc_pro_i_r;
    assign ll_sc = es_mem_op_i_r[9:8];

    assign ms_to_ds_valid = mem_valid;

    assign csr_rstat_o = csr_rstat_i_r;
    assign csr_estat_data = (csr_rstat_i_r == 1'b1) ? csr_data_i_r : 32'b0; // 信号最好具体化，尽管写一个 final_result 没错，但是这里延迟会更低
    assign ms_paddr_o = {data_tag, es_alu_result_i_r[11:0]};

    // cacop_mode == 2'b01 || cacop_mode == 2'b01 时，表示直接索引
    // cacop_mode == 2'b10                        时，表示查询索引

    wire [4:0] cacop_op;
    wire icacop_inst;
    wire dcacop_inst;

    assign cacop_op         = wire_dest;
    assign cacop_op_mode    = cacop_op[4:3]; // 0,1,2

    assign icacop_inst      = cacop_i_r && (cacop_op[2:0] == 3'b0);
    assign dcacop_inst      = cacop_i_r && (cacop_op[2:0] == 3'b1);

    // 只有当她们都不 busy 的时候，才可以发起 cacop 操作
    assign icacop_op_en     = icacop_inst && !icache_busy && mem_valid;
    assign dcacop_op_en     = dcacop_inst && !dcache_busy && mem_valid;

    // cacop_op_mode为 0 或者 1 时，表示直接索引
    assign cacop_op_mode_di = cacop_i_r && ((cacop_op_mode == 2'b0) || (cacop_op_mode == 2'b1));


    assign cnt_inst_diff = cnt_inst_diff_i_r ;
    assign timer_64_diff = timer_64_diff_i_r;

    assign ld_diff = {2'b0, ll_w, ld_w, ld_hu, ld_h, ld_bu, ld_b};
    assign paddr_diff = {data_tag, data_index, data_offset};
    assign vaddr_diff = es_alu_result_i_r;

    assign st_data_diff = wdata_diff;
    assign st_diff = {4'b0, ds_llbit && sc_w, st_w, st_h, st_b};


    assign inst_idle_o = inst_idle_i_r;

    assign inst_sc = {sc_w, sc_do|sc_r};
    assign icacop_o = icacop_inst;

    assign inst_bubble_o = inst_bubble_i_r;
endmodule
