`include "csr.h"
module IFU (
        input wire clk,             // 时钟信号
        input wire rst,             // 复位信号

        input wire [31:0] pc_i,
        output wire [31:0] pc_o,

        output wire fs_excp_out,
        output wire [15:0] fs_excp_num_out,

        // 握手信号
        input preifu_to_ifu_valid,
        output ifu_allowin,
        input idu_allowin,
        output ifu_to_idu_valid,

        // dcache 额外的属性
        output wire inst_uncache_en,

        // from csr
        input wire [1:0]  csr_datf,

        input wire [1:0]  csr_plv,
        input wire [31:0] csr_dmw0,
        input wire [31:0] csr_dmw1,
        input wire        csr_da,
        input wire        csr_pg,
        input wire [31:0] csr_tlbidx,
        input wire [31:0] csr_tlbehi,
        input wire [31:0] csr_tlbelo0,
        input wire [31:0] csr_tlbelo1,
        input wire [9:0]  csr_asid,

        // addr_trans
        output        inst_addr_trans_en,
        output [9:0]  inst_asid,
        output [31:0] inst_vaddr,
        output        inst_dmw0_en,
        output        inst_dmw1_en,
        output [31:0] inst_dmw0,
        output [31:0] inst_dmw1,
        output        inst_da,
        output        inst_pg,

        input  [7:0]  inst_index,
        input  [19:0] inst_tag,
        input  [3:0]  inst_offset,
        input         inst_tlb_found,
        input         inst_tlb_v,
        input         inst_tlb_d,
        input [ 1:0]  inst_tlb_mat,
        input [ 1:0]  inst_tlb_plv,

        // icache
        output wire icache_valid,
        output wire [19:0] icache_tag,
        output wire [7:0] icache_index,
        output wire [3:0] icache_offset,

        // 如果遇到 flush_flush 信号, 则取消请求
        // 这是因为 如果 ifu 的 请求发出后，icache 不会理会 flush_flush
        // icache 持续处理请求，最终会返回 rdata。
        // 但是这个 data 已经不是当前 pc 所需要的了
        output wire flush_sign_cancel,

        input wire icache_addr_ok,
        input wire icache_data_ok,
        input wire [31:0] icache_rdata,

        output [31:0] rdata_o, // 发送到下游的指令

        // from WBU
        input wire idle_stall,

        // debug
        input wire disable_cache,

        input wire flush_sign,

        input wire br_flush
    );

    wire req; // en
    wire [31:0] addr;
    wire addr_ok;
    wire data_ok;

    wire [31:0] rdata;

    assign icache_valid = req;

    assign icache_tag = addr[31:12];
    assign icache_index = addr[11:4];
    assign icache_offset = addr[3:0];


    assign addr_ok = icache_addr_ok;
    assign data_ok = icache_data_ok;
    assign rdata   = icache_rdata;

    reg  [31:0] pc;


    // 异常
    // 取址地址错移异常
    wire pfs_excp_adef;
    wire [15:0] excp_adef_num;
    // 取址操作页无效异常
    wire fs_excp_pif;
    wire [15:0] excp_pif_num;
    // 页特权异常
    wire fs_excp_ppi;
    wire [15:0] excp_ppi_num;
    // TLB重填异常
    wire fs_excp_tlbr;
    wire [15:0] excp_tlbr_num;

    wire pfs_excp;
    wire [15:0] fs_excp_num;

    // 异常
    // 0x0
    assign pfs_excp_adef = (pc[0] | pc[1]);
    assign excp_adef_num = pfs_excp_adef ? 16'h0001 : 16'h0000;
    // 0x1
    assign fs_excp_tlbr = !inst_tlb_found && inst_addr_trans_en;
    assign excp_tlbr_num = fs_excp_tlbr ? 16'h0002 : 16'h0000;
    // 0x2
    assign fs_excp_pif  = !inst_tlb_v && inst_addr_trans_en;
    assign excp_pif_num = fs_excp_pif ? 16'h0004 : 16'h0000;
    // 0x3
    assign fs_excp_ppi  = (csr_plv > inst_tlb_plv) && inst_addr_trans_en;
    assign excp_ppi_num = fs_excp_ppi ? 16'h0008 : 16'h0000;

    assign pfs_excp = pfs_excp_adef |
           fs_excp_tlbr |
           fs_excp_pif  |
           fs_excp_ppi;
    assign fs_excp_num = excp_adef_num | excp_pif_num |
           excp_ppi_num | excp_tlbr_num;


    // 输出
    assign fs_excp_out = pfs_excp;
    assign fs_excp_num_out = fs_excp_num;

    // 这里应该设置一个握手机制：参考的是 ysyx 中的 B1 总线，也是我之前实现过的一个模块
    // 具体的，分为两个状态：idle <---> waite_ready
    // 1、一开始处于空闲状态 idle，===> valid = 0；
    //  - 如果不需要发送消息, 则一直处于 idle 状态
    //  - 如果需要发送消息, 则将 valid = 1, 并进入 wait_ready 状态, 等待 slave 就绪
    // 2、在 wait_read 状态中, 同时检测 slave 的 ready 信号
    // - 如果ready信号有效, 则握手成功, 返回idle状态
    // - 如果ready信号无效, 则继续处于wait_ready状态等待
    // 0:   idle
    // 1:   process
    // 2:   waite_ready

    // 改进：由于我本人写了两个版本的状态机
    // 第一个状态机控制得很好，路基很清晰且容易理解，但是 ipc 太低，无法做到连续收发，
    // 严重限制了吞吐量
    // 第二个状态机逻辑也很清晰，能做到连续收发，性能瓶颈由状态机变成了访存，但是有一个问题很难解决
    // 那就是状态机可能会死锁，而且由于可能发射重复的指令，导致 后端重复执行，解决方法是弄一个过滤器，
    // 这也是死锁的来源。各种情况都会造成死锁，基本上就是遇到一个解决一个，这样是不可靠的。
    // 可能 AXI 延迟一下，就死锁了。目前还没有找到好的解决方案，于是我觉得重新写一个状态机，主要参考 OpenLA500 的设计

    // 我仔细研究了 OpenLA500 模块之间的握手机制，它基于以下 两个 问题构建：
    // 问题1：什么时机可以接收数据
    // 问题2：什么时候可以发射数据

    // 答案很简单：
    // 问题1：
    // 什么时机可以接收数据：当本单元 没有持有有效数据 或者 本单元计算完成且下游允许数据进入
    // 没有持有数据很好理解，那就是空闲，空闲当然可以接受数据
    // 不空闲也可以接受数据，但是有条件，那就是本单元计算完成，计算完成也不能接受数据，必须还得等下游允许进去
    // 这是因为下游如果不能接受数据，上游接受了后就会把原来的数据覆盖掉

    // 问题2：
    // 什么时候可以发射数据：发射数据的前提是，本单元有有效数据，且计算完成，这个很好理解


    // 以上问题可以抽象出 5 个信号：
    // xx_ready_go：计算完成
    // xx_allowin：可以接收数据
    // xx_valid：本单元是否已经拿到有效的数据
    // xx_to_yy_valid：本单元的数据是否可以传给下一个单元

    // yy_allowin：下游是否可以接收数据

    // aa_to_xx_valid：上游传来的数据是否有效
    // aa_to_xx_bus：上游来的数据载荷

    // 用状态机可以有以下表示
    // assign xx_ready_go    = xx_caculate_done;
    // assign xx_allowin     = !xx_valid || xx_ready_go && yy_allowin;
    // assign xx_to_yy_valid =  xx_valid && xx_ready_go;

    // 问题3：
    // 现在有一个新的问题，那就是状态机的转换
    // 由于目前只有一个状态机的状态 xx_valid，它代表着是否已经获取到了有效数据。更具体的准确的说法是，
    // xx_valid 代表着从 已经交付给下游后，现在是否获取到了有效数据。
    // 翻译一下就是，如果刚交付完数据后，es_allowin 就会拉高，此时 xx_valid
    // 的状态就是 上游是否有效。
    // 还有一种可能就是 reset 后，es_allowin 也会拉高，此时 xx_valid
    // 的状态就是 上游是否有效。
    // 因此，xx_valid 的含义就昭然若揭了：上一个事务完成后，xx_valid 就代表新的事务是否开始

    // 它应该怎么转换呢？
    // reset 后它清零，如果 xx_allowin 有效，那么它就是 aa_to_xx_valid，
    // 这意味着上游如果无效，它也是无效。如果上游有效，那么 xx_allowin 也就有效，并且接受了数据。

    // 一个可能得状态机如下：
    // always @(posedge clk) begin
    //     if (reset || flush_sign) begin
    //         xx_valid <= 1'b0;
    //     end
    //     else if (xx_allowin) begin
    //         xx_valid <= aa_to_xx_valid;
    //     end

    //     if (aa_to_xx_valid && yy_allowin) begin
    //         aa_to_xx_bus_r <= aa_to_xx_bus;
    //     end
    // end

    // 以上就是对于这两个问题的分析。接下来就是改造了


    reg ifu_valid;
    wire ifu_ready_go;


    always @(posedge clk) begin
        if (rst || flush_sign || br_flush) begin
            ifu_valid <= 1'b0;
            pc <= 32'd0;
        end
        else if (ifu_allowin) begin
            ifu_valid <= preifu_to_ifu_valid;
        end
        if (preifu_to_ifu_valid && ifu_allowin) begin
            pc <= pc_i;
        end
    end

    // 当当前有效的时候发起读取请求
    assign req = flush_sign ? 1'b0: ifu_valid;

    assign ifu_ready_go = data_ok;
    assign ifu_allowin = !ifu_valid || ifu_ready_go && idu_allowin;
    assign ifu_to_idu_valid = ifu_valid && ifu_ready_go && !flush_sign;

    assign pc_o =  pc;
    assign rdata_o = rdata;

    // tlb
    wire   pg_mode;
    wire   da_mode;
    assign inst_da = csr_da;
    assign inst_pg = csr_pg;
    assign pg_mode = csr_pg && !csr_da;
    assign da_mode = csr_da && !csr_pg;
    assign inst_vaddr = pc;
    assign inst_dmw0 = csr_dmw0;
    assign inst_dmw1 = csr_dmw1;

    assign inst_dmw0_en = ((inst_dmw0[`PLV0] && csr_plv == 2'd0) || (inst_dmw0[`PLV3] && csr_plv == 2'd3)) && (pc[31:29] == inst_dmw0[`VSEG]) && pg_mode;
    assign inst_dmw1_en = ((inst_dmw1[`PLV0] && csr_plv == 2'd0) || (inst_dmw1[`PLV3] && csr_plv == 2'd3)) && (pc[31:29] == inst_dmw1[`VSEG]) && pg_mode;
    assign inst_addr_trans_en = pg_mode && !inst_dmw0_en && !inst_dmw1_en;
    assign inst_asid = csr_asid;

    assign inst_uncache_en = (da_mode && (csr_datf == 2'b0))    ||
           (inst_dmw0_en && (csr_dmw0[`DMW_MAT] == 2'b0))       ||
           (inst_dmw1_en && (csr_dmw1[`DMW_MAT] == 2'b0))       ||
           (inst_addr_trans_en && (inst_tlb_mat == 2'b0)) || disable_cache;

    assign addr = {inst_tag, inst_index, inst_offset}; // 物理地址

    // 取消取指令
    assign flush_sign_cancel = flush_sign || br_flush;

endmodule
