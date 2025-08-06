module IDU (
        // from top
        input wire clk,
        input wire rst,
        // to ifu
        output wire [34:0] bus_br_data,
        // from ifu
        input wire [31:0] in_pc,
        input wire [31:0] in_rdata,

        input wire fs_excp,
        input wire [15:0] fs_excp_num,
        output wire ds_excp_out,
        output wire [15:0] ds_excp_num_out,

        // to rf
        output wire [4:0] rf_raddr1,
        output wire [4:0] rf_raddr2,

        // from rf
        input wire [31:0] rf_rdata1,
        input wire [31:0] rf_rdata2,
        // bus
        output wire [226:0] bus_ds_to_es_data,
        output wire [31:0] idu_inst_o,
        output wire [9:0] out_mem_op,

        input  wire llbit,
        input  wire [1:0]  csr_plv,

        // exception
        input wire has_int,
        input wire exu_excp,

        // 直通解决数据相关
        input wire [70:0] bus_exu_bypass_data,
        input wire [70:0] bus_mem_bypass_data,
        input wire [70:0] bus_wbu_bypass_data,

        // csr 的数据相关
        // 握手信号
        input ifu_to_idu_valid,
        output idu_allowin,
        input exu_allowin,
        output idu_to_exu_valid,
        // tlb
        output wire [4:0] tlb_inst_bus,
        // invtlb
        output wire [4:0] invtlb_op,
        output wire [9:0] invtlb_asid,
        output wire [18:0] invtlb_vpn,
        output wire is_csr_wr,

        // from WBU

        output [31:0] pc_pro_o, // PC 应该走专线


        // 对于 csr 读的操作转移到 MEM
        output wire [82:0] bus_csr_rd_wr_data,

        //every stage valid sign
        input wire es_to_ds_valid,
        input wire ms_to_ds_valid,
        input wire ws_to_ds_valid,

        // csr_rstat : 当提交指令为csrrd、csrwr、csrxchg，同时该指令对应的csr寄存器为estat寄存器时该位拉高
        output wire  csr_rstat,

        output wire inst_idle_o,
        input wire idle_stall,

        // 数据前递
        // 这里数据前递需要判断 MEM 阶段是否是访存操作以及 sc 操作
        // 如果是，那么应该优先进行前递，而不是简单的 EXU > MEM > WBU
        input wire [32:0] inst_ld_from_mem,
        input wire [1:0]  inst_sc_from_mem,

        // cacop
        output cacop_o,

        input wire flush_sign,
        output wire br_flush,

        input wire exu_tlbsrch_stall,
        input wire [31:0] tlbsrch_stall_wbu_pc,

        output wire ld_sc_inst_o,
        input wire ld_sc_inst_i,

        // 分支预测
        output wire br_taken1,
        output wire [31:0] br_target1,
        output wire [31:0] current_pc,
        output wire notice_pre,

        // bubble tag
        // 这个信号发射到 wbu 中用来 difftest 的cmt
        output wire inst_bubble_o
    );

    // 这里的 tlbsrch_stall 的理解不难
    // 当检测到 exu 单元有 tlbsrch 指令的时候，直接stall
    // 当检测到 wbu 的 pc 和 exu 单元的 pc 一致的时候，说明已经执行结束了
    // 从而消掉 stall 信号，必须是 valid 的，因为可能遇到 flush
    wire tlbsrch_stall = exu_tlbsrch_stall && tlbsrch_stall_wbu_pc != exu_pc;

    wire        pipeline_no_empty;
    wire        dbar_stall;
    wire        ibar_stall;
    wire [13:0] rd_csr_addr;
    wire [31:0] csr_rkd_value;

    // 异常类型
    wire [15:0] syscall_num;    // 系统调用异常
    wire idu_excp_syacall;

    wire [15:0] excp_ine_num;   // 指令无效异常
    wire idu_excp_ine;

    wire [15:0] excp_brk_num;   // 断点异常
    wire idu_excp_brk;

    wire [15:0] excp_ie_num;    // 中断异常
    wire idu_excp_ie;

    wire [15:0] excp_ipe_num;   // 指令等级错例外
    wire idu_excp_ipe;

    wire excp_brk;
    wire inst_valid;

    reg [15:0] fs_excp_num_r; // 从上一级接收
    reg fs_excp_r;

    wire [15:0] wire_fs_excp_num;
    wire wire_fs_excp;

    assign wire_fs_excp_num = fs_excp_num_r;
    assign wire_fs_excp = fs_excp_r;

    wire [15:0] ds_excp_num;
    wire ds_excp;
    wire is_nop;

    wire caculate_done_1;
    wire caculate_done_2;

    wire caculate_done;

    // 数据相关

    wire exu_regWr;
    wire [31:0] exu_data;
    wire [4:0] exu_regAddr;
    wire [31:0] exu_pc;
    wire exu_over;

    wire mem_regWr;
    wire [31:0] mem_data;
    wire [4:0] mem_regAddr;
    wire [31:0] mem_pc;
    wire mem_over;

    wire wbu_regWr;
    wire [31:0] wbu_data;
    wire [4:0] wbu_regAddr;
    wire [31:0] wbu_pc;
    wire wbu_over;

    assign {
            exu_regWr,
            exu_data,
            exu_regAddr,
            exu_pc,
            exu_over
        } = bus_exu_bypass_data;
    assign {
            mem_regWr,
            mem_data,
            mem_regAddr,
            mem_pc,
            mem_over
        } = bus_mem_bypass_data;
    assign {
            wbu_regWr,
            wbu_data,
            wbu_regAddr,
            wbu_pc,
            wbu_over
        } = bus_wbu_bypass_data;


    wire [31:0] alu_op;
    wire [31:0] alu_src1;
    wire [31:0] alu_src2;

    wire [9:0]  mul_div_op;
    wire        mem_we;
    wire [31:0] rkd_value;
    wire        res_from_mem;
    wire        res_from_csr;
    wire        gr_we;
    wire [4:0]  dest;

    // csr
    wire [13:0] csr_idx;    // csr 索引
    wire [31:0] csr_data = 32'd0;
    wire [31:0] csr_mask;
    wire [31:0] csr_wdata = 32'd0;
    wire is_inst_ertn;
    wire csr_we;

    wire rdcnt_en;
    wire [31:0] rdcnt_result;

    wire [31:0] idu_inst;
    wire [31:0] idu_pc;
    wire        src1_is_pc;
    wire        src2_is_imm;
    wire        dst_is_r1;
    wire        dst_is_rj;
    wire        src_reg_is_rd;
    wire [31:0] rj_value;
    wire [31:0] imm;
    wire        rj_eq_rd;
    wire [31:0] br_offs;
    wire [31:0] jirl_offs;

    wire [ 5:0] op_31_26;
    wire [ 3:0] op_25_22;
    wire [ 1:0] op_21_20;
    wire [ 4:0] op_19_15;
    wire [ 4:0] rd;
    wire [ 4:0] rj;
    wire [ 4:0] rk;
    wire [11:0] i12;
    wire [13:0] i14;
    wire [19:0] i20;
    wire [15:0] i16;
    wire [25:0] i26;

    wire [63:0] op_31_26_d;
    wire [15:0] op_25_22_d;
    wire [ 3:0] op_21_20_d;
    wire [31:0] op_19_15_d;

    // csr
    wire [31:0] rd_d;
    wire [31:0] rj_d;
    wire [31:0] rk_d;

    wire        inst_add_w;
    wire        inst_sub_w;
    wire        inst_slt;
    wire        inst_slti;
    wire        inst_sltu;
    wire        inst_sltui;
    wire        inst_nor;
    wire        inst_and;
    wire        inst_andi;
    wire        inst_or;
    wire        inst_ori;
    wire        inst_xor;
    wire        inst_xori;
    wire        inst_sll;
    wire        inst_slli_w;
    wire        inst_srl;
    wire        inst_srli_w;
    wire        inst_sra;
    wire        inst_srai_w;
    wire        inst_addi_w;
    wire        inst_ld_w;
    wire        inst_ld_b;
    wire        inst_ld_bu;
    wire        inst_ld_h;
    wire        inst_ld_hu;
    wire        inst_st_w;
    wire        inst_st_b;
    wire        inst_st_h;
    wire        inst_jirl;
    wire        inst_b;
    wire        inst_bl;
    wire        inst_blt;
    wire        inst_bltu;
    wire        inst_beq;
    wire        inst_bne;
    wire        inst_bge;
    wire        inst_bgeu;
    wire        inst_lu12i_w;
    wire        inst_pcaddu12i;

    wire        inst_mul_w;
    wire        inst_mulh_w;
    wire        inst_mulh_wu;
    wire        inst_div_w;
    wire        inst_div_wu;
    wire        inst_mod_w;
    wire        inst_mod_wu;

    wire        inst_csrrd;
    wire        inst_csrwr;
    wire        inst_csrxchg;
    wire        inst_ertn;

    wire        inst_syscall;
    wire        inst_break;

    wire        inst_rdcntid_w;
    wire        inst_rdcntvl_w;
    wire        inst_rdcntvh_w;
    wire        inst_zero;

    wire        inst_tlbsrch;
    wire        inst_tlbrd;
    wire        inst_tlbwr;
    wire        inst_tlbfill;
    wire        inst_invtlb;

    wire        need_ui5;
    wire        need_si12;
    wire        need_si14;
    wire        need_si16;
    wire        need_si20;
    wire        need_si26;
    wire        src2_is_4;
    wire        need_ui12;

    wire        inst_ll_w;
    wire        inst_sc_w;

    wire        inst_dbar;
    wire        inst_ibar;

    wire        inst_idle;

    wire        inst_cacop;
    wire        inst_valid_cacop;

    // 指令合法，但是暂时没有执行意义
    wire        inst_nop;
    wire        inst_preld;
    wire        inst_cpucfg;


    wire br_taken;
    wire [31:0] br_target;
    wire br_true;

    assign bus_br_data = {br_taken, br_target, caculate_done, br_true};
    assign bus_ds_to_es_data = (load_use_stall_1|load_use_stall_2) ? 227'd0 : {
               mul_div_op,
               alu_op,
               alu_src1,
               alu_src2,
               mem_we, // 无用的信号
               rkd_value,
               res_from_mem,
               gr_we,
               dest,
               //    idu_pc,
               res_from_csr,
               csr_data,
               csr_we,
               csr_idx,
               csr_wdata,
               is_inst_ertn
           };

    // 判断是否数据相关
    // 暂存上一级来的数据

    reg [31:0] inst_sram_rdata_reg;
    reg [31:0] pc_reg;
    wire [31:0] inst_nop_data = 32'b0000_0011_0100_0000_0000_0000_0000_0000; // nop : andi r0, r0,0



    // 分支预测怎么在这里工作
    // 我的设想是，当 br_taken_r 发生的时候，先不要“惊动”上游，先检查
    // 下来的指令，如果指令一致，撤销信号br_taken_r 并接受指令
    // 如果下来的指令不一致，说明预测错误，此时立即 flush 上游
    // 这里成本相当高，预测错误的惩罚很大，因此要尽量早的 flush 上游
    // 最早有多早?
    // 最早在 ifu 就可以“看到” 即将到来的 pc（之后优化这里）
    // 这里就不要接受，直接过滤，当过滤到合适的时候，就可以继续推进了

    // 还有一种可能就是根本不跳转，但是 preifu 命中，此时发射来了
    // 错误的 pc，这没办法做？
    // 事实上也是可以的，只要对比 idu 的 expected 的 pc 就行
    // 怎么计算 expected_pc 呢？
    // 如果 br_taken 了，就是 br_target
    // 否则 就是pc+4
    // 但是这样太繁琐，带来的思维负担太重，而且刚开始启动的时候无法得出具体数值，
    // 因此这种 expected_pc 是错误的想法

    assign br_true = idu_valid && br_taken_r && expected_pc != in_pc;

    // 这会清掉上游 ifu 的指令缓存，并且让 preifu 发生混乱，换句话说
    // 如果 br_taken 信号发出去了代价很大
    // 如果不发 br_taken 呢？
    // 那么就在 br_taken 的时候打一个标记，
    // 等待上级的 pc，如果和 br_target 一致，说明猜对了，随后取消标记
    // 如果等待错了 pc，那么就再发射 br_taken 信号
    // 因此分支预测期从这里开始----->
    assign br_flush = br_true;

    // wire [31:0] expected_pc = br_taken ? br_target : pc_reg + 4;
    reg br_taken_r;
    reg [31:0] expected_pc;

    always @(posedge clk) begin
        if(rst ||flush_sign) begin
            br_taken_r <= 1'b0;
            expected_pc <= 32'd0;
        end
        // 一次只能解决一个 taken
        else begin
            if(br_taken && caculate_done && !br_taken_r) begin
                br_taken_r <= 1'b1;
                expected_pc <= br_target;
            end
            else if(!br_taken_r) begin
                expected_pc <= pc_reg + 32'd4;
            end

            if(ifu_to_idu_valid && idu_allowin && (br_target == in_pc || just_started)) begin
                br_taken_r <= 1'b0;
            end
        end
    end

    reg [4:0] refetch_wait;

    assign notice_pre = refetch_wait == 5'd4;

    reg idu_valid;
    wire idu_ready_go;
    reg just_started;

    always @(posedge clk ) begin
        if (rst || flush_sign) begin
            idu_valid <= 1'b0;
            refetch_wait <= 5'd0;
            just_started <= 1'b1;
            pc_reg <= 32'd0;
        end
        else if(idu_allowin) begin
            idu_valid <= ifu_to_idu_valid;
        end

        if(ifu_to_idu_valid && idu_allowin) begin
            // 在这里进行分支预测结果检验
            // 刚启动的时候，expected_pc 是
            if(br_taken && caculate_done && !br_taken_r) begin
                // 跳转预测正确
                if(br_target == in_pc) begin
                    pc_reg <= in_pc;
                    inst_sram_rdata_reg <= in_rdata;
                    fs_excp_num_r <= fs_excp_num;
                    fs_excp_r <= fs_excp;

                    refetch_wait <= 5'd0;
                    // br_taken_r <= 1'b0;
                    just_started <= 1'b0;
                end
                // 跳转预测不正确, 准备纠正
                else begin
                    refetch_wait <= refetch_wait + 5'd1;
                end
            end
            else if(br_taken_r) begin
                // 跳转预测正确
                if(expected_pc == in_pc) begin
                    pc_reg <= in_pc;
                    inst_sram_rdata_reg <= in_rdata;
                    fs_excp_num_r <= fs_excp_num;
                    fs_excp_r <= fs_excp;

                    refetch_wait <= 5'd0;
                    // br_taken_r <= 1'b0;
                    just_started <= 1'b0;
                end
                // 跳转预测不正确, 准备纠正
                else begin
                    refetch_wait <= refetch_wait + 5'd1;
                end
            end
            // 也有可能进行“预测”
            else begin
                if(expected_pc == in_pc || just_started) begin
                    pc_reg <= in_pc;
                    inst_sram_rdata_reg <= in_rdata;
                    fs_excp_num_r <= fs_excp_num;
                    fs_excp_r <= fs_excp;

                    refetch_wait <= 5'd0;
                    // br_taken_r <= 1'b0;
                    just_started <= 1'b0;
                end
                // 跳转预测不正确, 准备纠正
                else begin
                    refetch_wait <= refetch_wait + 5'd1;
                end
            end
        end
    end
    assign idu_ready_go = caculate_done;
    // 有效性一定要确认
    assign idu_to_exu_valid = (idu_valid && idu_ready_go && refetch_wait == 5'd0 || idu_valid && (load_use_stall_1 | load_use_stall_2)) && !flush_sign;
    assign idu_allowin = !idu_valid || idu_ready_go && exu_allowin;

    wire [31:0] conflict_regaData;
    wire [31:0] conflict_regbData;

    // 当检测到冲突以后，就得阻塞

    // pc 不能一致，如果一致没有前递意义?

    // 数据前递 匹配
    // wire exu_forward_match_1 = exu_regWr && (rf_raddr1 == exu_regAddr) && rf_raddr1 != 5'd0 && idu_pc != exu_pc;
    // wire mem_forward_match_1 = mem_regWr && (rf_raddr1 == mem_regAddr) && rf_raddr1 != 5'd0 && idu_pc != mem_pc;
    // wire wbu_forward_match_1 = wbu_regWr && (rf_raddr1 == wbu_regAddr) && rf_raddr1 != 5'd0 && idu_pc != wbu_pc;

    // wire exu_forward_match_2 = exu_regWr && (rf_raddr2 == exu_regAddr) && rf_raddr2 != 5'd0 && idu_pc != exu_pc;
    // wire mem_forward_match_2 = mem_regWr && (rf_raddr2 == mem_regAddr) && rf_raddr2 != 5'd0 && idu_pc != mem_pc;
    // wire wbu_forward_match_2 = wbu_regWr && (rf_raddr2 == wbu_regAddr) && rf_raddr2 != 5'd0 && idu_pc != wbu_pc;
    // 事实上，如果是一个 load 循环，比如这段代码：
    // a0547ad4:	28800108 	ld.w	$r8,$r8,0
    // a0547ad8:	028006d6 	addi.w	$r22,$r22,1(0x1)
    // a0547adc:	5ffff928 	bne	$r9,$r8,-8(0x3fff8) # a0547ad4 <check_tty_count+0x2c>
    // 这种看起来在相关自己这条指令，实际上是两条指令，上次r8 加载的数据和现在 r8 相关
    // 因此不能认为 pc 就一定不一致
    wire exu_forward_match_1 = exu_regWr && (rf_raddr1 == exu_regAddr) && rf_raddr1 != 5'd0;
    wire mem_forward_match_1 = mem_regWr && (rf_raddr1 == mem_regAddr) && rf_raddr1 != 5'd0;
    wire wbu_forward_match_1 = wbu_regWr && (rf_raddr1 == wbu_regAddr) && rf_raddr1 != 5'd0;

    wire exu_forward_match_2 = exu_regWr && (rf_raddr2 == exu_regAddr) && rf_raddr2 != 5'd0;
    wire mem_forward_match_2 = mem_regWr && (rf_raddr2 == mem_regAddr) && rf_raddr2 != 5'd0;
    wire wbu_forward_match_2 = wbu_regWr && (rf_raddr2 == wbu_regAddr) && rf_raddr2 != 5'd0;

    // load_use
    // 检测 exu 的指令是否是 ld、ll、以及 sc，如果是，将会一直阻塞，
    // 一直到 exu 执行到 wbu，此时 idu 自然没有数据相关了
    // ld_sc 会用到 rj，往 rd 中存储数据
    // 因此一旦发生 load_use，我们先检查当前 use 的指令的 地址 和
    // ld_sc 指令的 rd 是否一致

    // 如果检测到了 load_use 那就 stall，但是与此同时，可以继续向后端发射空指令 bubble
    // idu use，exu 把 ld 指令发射到 mem，exu 持有 bubble，mem 持有 ld 指令，
    // 这会显示 load_use 消失，但是 mem 还没有处理完成。遇到这种情况，只需要检测 wbu 是否拿到
    // bubble，如果拿到 bubble，说明 idu 可以从寄存器中获取数据了。

    // 如何发射 bubble_inst?
    // 将当前的 将要发射的 inst 设置成 bubble（03400000），包括已经解码好的数据
    // 同时，还要设置一次 idu_to_exu_valid

    // 但是 idu 的 load_use 只能维持一拍，exu 拿到 bubble 之后信号就消失了
    // 此时 idu 依然没有等来关键数据，只能持续 load_use_stall，这个信号怎么维持呢？
    reg load_use_stalled;
    wire load_use_stall_1;
    wire load_use_stall_2;

    always@(posedge clk) begin
        if(rst || flush_sign) begin
            load_use_stalled <= 1'b0;
        end
        else begin
            if(load_use_stall_1 || load_use_stall_2) begin
                load_use_stalled <= 1'b1;
            end
            // 如果 stalled 并且 wbu 已经拿到了 bubble，
            // 说明 stalled 可以解除
            else if(load_use_stalled && idu_pc == wbu_pc) begin
                load_use_stalled <= 1'b0;
            end
        end
    end

    // load_use 的匹配机制和数据前递不一样
    wire load_use_judge_1 = (rf_raddr1 == exu_regAddr) && rf_raddr1 != 5'd0 && idu_pc != exu_pc;
    wire load_use_judge_2 = (rf_raddr2 == exu_regAddr) && rf_raddr2 != 5'd0 && idu_pc != exu_pc && !inst_cacop;

    assign load_use_stall_1 = load_use_judge_1 &&
           ld_sc_inst_i;
    assign load_use_stall_2 = load_use_judge_2 &&
           ld_sc_inst_i;

    // 根据匹配与否进行 多路选择
    assign conflict_regaData =
           exu_forward_match_1 ? exu_data :
           mem_forward_match_1 ? mem_data :
           wbu_forward_match_1 ? wbu_data : rf_rdata1;

    assign conflict_regbData =
           exu_forward_match_2 ? exu_data :
           mem_forward_match_2 ? mem_data :
           wbu_forward_match_2 ? wbu_data : rf_rdata2;

    // 这是计算完成的标志：当匹配成功的时候，必须等到其计算完成才能最终裁定 idu 是否彻底计算完成
    // 如果 stall 的时候，wbu_pc+4 等于idu_pc 就行。不一样继续 stall，否则 stall 结束，阻塞一个信号就行
    // 指令能走到 wbu，说明 mem 已经完成了访存，直接从 mem 拿数据就行。

    // 阻塞一个信号就行
    assign caculate_done_1 = (load_use_stalled | load_use_stall_1) ? 1'b0:
       exu_forward_match_1 ? exu_over ? 1'b1 : 1'b0:
       mem_forward_match_1 ? mem_over ? 1'b1 : 1'b0:
       wbu_forward_match_1 ? wbu_over ? 1'b1 : 1'b0:
           1'b1;

    assign caculate_done_2 = (load_use_stalled | load_use_stall_2) ? 1'b0:
       exu_forward_match_2 ? exu_over ? 1'b1 : 1'b0:
       mem_forward_match_2 ? mem_over ? 1'b1 : 1'b0:
       wbu_forward_match_2 ? wbu_over ? 1'b1 : 1'b0:
           1'b1;


    assign caculate_done = caculate_done_1 && caculate_done_2 &&
           !(dbar_stall || ibar_stall) && !tlbsrch_stall;

    assign idu_inst = inst_sram_rdata_reg;
    // 当前指令是空指令
    // 当前指令要携带 refetch_sign
    // 当前指令是 inst_idle
    // 这样的指令不要携带 中断异常
    // 因为空指令被标记为无效指令
    // 携带 refetch_sign 的指令以及指令携带的中断都会被抛弃
    // inst_idle 指令会直接 lock
    assign is_nop = inst_idle;
    assign idu_pc = pc_reg;
    // assign pc = idu_pc;

    assign op_31_26  = idu_inst[31:26];
    assign op_25_22  = idu_inst[25:22];
    assign op_21_20  = idu_inst[21:20];
    assign op_19_15  = idu_inst[19:15];

    assign rd   = idu_inst[4:0];
    assign rj   = idu_inst[9:5];
    assign rk   = idu_inst[14:10];

    assign i12  = idu_inst[21:10];
    assign i14  = idu_inst[23:10];
    assign i20  = idu_inst[24:5];
    assign i16  = idu_inst[25:10];
    assign i26  = {idu_inst[9:0], idu_inst[25:10]};
    // csr
    // 支持数据前递 tid

    assign csr_idx = inst_rdcntid_w ? 14'h40 : idu_inst[23:10];

    decoder_6_64 u_dec0(.in(op_31_26 ), .out(op_31_26_d ));
    decoder_4_16 u_dec1(.in(op_25_22 ), .out(op_25_22_d ));
    decoder_2_4  u_dec2(.in(op_21_20 ), .out(op_21_20_d ));
    decoder_5_32 u_dec3(.in(op_19_15 ), .out(op_19_15_d ));

    decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
    decoder_5_32 u_dec5(.in(rj  ), .out(rj_d  ));
    decoder_5_32 u_dec6(.in(rk  ), .out(rk_d  ));

    assign inst_add_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h00];
    assign inst_sub_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h02];
    assign inst_slt    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h04];
    assign inst_slti   = op_31_26_d[6'h00] & op_25_22_d[4'h8];
    assign inst_sltu   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h05];
    assign inst_sltui  = op_31_26_d[6'h00] & op_25_22_d[4'h9];
    assign inst_nor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h08];
    assign inst_and    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h09];
    assign inst_andi   = op_31_26_d[6'h00] & op_25_22_d[4'hd];
    assign inst_or     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0a];
    assign inst_ori    = op_31_26_d[6'h00] & op_25_22_d[4'he];
    assign inst_xor    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h0b];
    assign inst_xori   = op_31_26_d[6'h00] & op_25_22_d[4'hf];
    assign inst_sll    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'he];
    assign inst_slli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h01];
    assign inst_srl    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'hf];
    assign inst_srli_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h09];
    assign inst_sra    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h10];
    assign inst_srai_w = op_31_26_d[6'h00] & op_25_22_d[4'h1] & op_21_20_d[2'h0] & op_19_15_d[5'h11];
    assign inst_addi_w = op_31_26_d[6'h00] & op_25_22_d[4'ha];

    assign inst_ld_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h2];
    assign inst_ld_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h0];
    assign inst_ld_bu  = op_31_26_d[6'h0a] & op_25_22_d[4'h8];
    assign inst_ld_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h1];
    assign inst_ld_hu  = op_31_26_d[6'h0a] & op_25_22_d[4'h9];
    assign inst_st_w   = op_31_26_d[6'h0a] & op_25_22_d[4'h6];
    assign inst_st_b   = op_31_26_d[6'h0a] & op_25_22_d[4'h4];
    assign inst_st_h   = op_31_26_d[6'h0a] & op_25_22_d[4'h5];

    assign inst_jirl   = op_31_26_d[6'h13];
    assign inst_b      = op_31_26_d[6'h14];
    assign inst_bl     = op_31_26_d[6'h15];
    assign inst_blt    = op_31_26_d[6'h18];
    assign inst_bltu   = op_31_26_d[6'h1a];
    assign inst_beq    = op_31_26_d[6'h16];
    assign inst_bne    = op_31_26_d[6'h17];
    assign inst_bge    = op_31_26_d[6'h19];
    assign inst_bgeu   = op_31_26_d[6'h1b];

    assign inst_lu12i_w   = op_31_26_d[6'h05] & ~idu_inst[25];
    assign inst_pcaddu12i = op_31_26_d[6'h07] & ~idu_inst[25];

    assign inst_mul_w   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h18];
    assign inst_mulh_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h19];
    assign inst_mulh_wu = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h1] & op_19_15_d[5'h1a];
    assign inst_div_w   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h0];
    assign inst_div_wu  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h2];
    assign inst_mod_w   = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h1];
    assign inst_mod_wu  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h3];

    assign inst_csrrd      = op_31_26_d[6'h01] & ~idu_inst[25] & ~idu_inst[24] & rj_d[5'h00];
    assign inst_csrwr      = op_31_26_d[6'h01] & ~idu_inst[25] & ~idu_inst[24] & rj_d[5'h01];
    assign inst_csrxchg    = op_31_26_d[6'h01] & ~idu_inst[25] & ~idu_inst[24] & ~rj_d[5'h00] & ~rj_d[5'h01];
    assign inst_ertn       = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0e] & rj_d[5'h00] & rd_d[5'h00];
    assign inst_syscall    = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h16];
    assign inst_break      = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h2] & op_19_15_d[5'h14];

    assign inst_rdcntid_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h18] & rd_d[5'h00];
    assign inst_rdcntvl_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h18] & rj_d[5'h00] & !rd_d[5'h00];
    assign inst_rdcntvh_w  = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h19] & rj_d[5'h00];
    assign inst_zero       = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h00] & rk_d[5'h00] & rj_d[5'h00] & rd_d[5'h00];

    assign inst_invtlb     = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h13];
    assign inst_tlbsrch    = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0a] & rj_d[5'h00] & rd_d[5'h00];
    assign inst_tlbrd      = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0b] & rj_d[5'h00] & rd_d[5'h00];
    assign inst_tlbwr      = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0c] & rj_d[5'h00] & rd_d[5'h00];
    assign inst_tlbfill    = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h10] & rk_d[5'h0d] & rj_d[5'h00] & rd_d[5'h00];

    assign inst_ll_w       = op_31_26_d[6'h08] & ~idu_inst[25] & ~idu_inst[24];
    assign inst_sc_w       = op_31_26_d[6'h08] & ~idu_inst[25] &  idu_inst[24];

    assign inst_dbar       = op_31_26_d[6'h0e] & op_25_22_d[4'h1] & op_21_20_d[2'h3] & op_19_15_d[5'h04];
    assign inst_ibar       = op_31_26_d[6'h0e] & op_25_22_d[4'h1] & op_21_20_d[2'h3] & op_19_15_d[5'h05];
    assign inst_idle       = op_31_26_d[6'h01] & op_25_22_d[4'h9] & op_21_20_d[2'h0] & op_19_15_d[5'h11];

    assign inst_cacop      = op_31_26_d[6'h01] & op_25_22_d[4'h8];
    assign inst_valid_cacop = inst_cacop && (dest[2:0]==3'b0 || dest[2:0]==3'b1) && (dest[4:3]==2'd0 || dest[4:3]==2'd1 || dest[4:3]==2'd2);
    assign inst_nop = inst_cacop && ((dest[2:0]!=3'b0 && dest[2:0] != 3'b1) || (dest[4:3]==2'd3));

    assign inst_preld      = op_31_26_d[6'h0a] & op_25_22_d[4'hb];
    assign inst_cpucfg     = op_31_26_d[6'h00] & op_25_22_d[4'h0] & op_21_20_d[2'h0] & op_19_15_d[5'h0] & rk_d[5'h1b];



    // 需要用到 alu 的指令
    assign alu_op[0] = inst_add_w | inst_addi_w | inst_ld_w | inst_st_w |
           | inst_jirl | inst_bl | inst_pcaddu12i | inst_ld_b | inst_ld_bu |
           inst_ld_h | inst_ld_hu | inst_st_b | inst_st_h | inst_ll_w |
           inst_sc_w | inst_valid_cacop;

    assign alu_op[1] = inst_sub_w;
    assign alu_op[2] = inst_slt | inst_slti;
    assign alu_op[3] = inst_sltu| inst_sltui;
    assign alu_op[4] = inst_and | inst_andi;
    assign alu_op[5] = inst_nor;
    assign alu_op[6] = inst_or | inst_ori;
    assign alu_op[7] = inst_xor| inst_xori;
    assign alu_op[8] = inst_slli_w | inst_sll;
    assign alu_op[9] = inst_srli_w | inst_srl;
    assign alu_op[10] = inst_srai_w | inst_sra;
    assign alu_op[11] = inst_lu12i_w;


    assign mul_div_op[0] = inst_mul_w; // 乘法低位
    assign mul_div_op[1] = inst_mulh_w; // 有符号乘法高位
    assign mul_div_op[2] = inst_mulh_wu; // 无符号乘法高位

    assign mul_div_op[3] = inst_div_w; // 有符号除法低位
    assign mul_div_op[4] = inst_div_wu; // 无符号除法低位
    assign mul_div_op[5] = inst_mod_w; // 有符号取余低位
    assign mul_div_op[6] = inst_mod_wu; // 无符号取余低位

    assign need_ui5   =  inst_slli_w | inst_srli_w | inst_srai_w;

    assign need_si12  =  inst_addi_w | inst_ld_w | inst_st_w | inst_slti | inst_sltui | inst_ld_b | inst_ld_bu |
           inst_ld_h | inst_ld_hu | inst_st_b | inst_st_h | inst_valid_cacop;

    assign need_si14  =  inst_ll_w | inst_sc_w; // 符号扩展 14

    assign need_si16  =  inst_jirl | inst_beq | inst_bne;
    assign need_si20  =  inst_lu12i_w | inst_pcaddu12i;
    assign need_si26  =  inst_b | inst_bl;
    assign src2_is_4  =  inst_jirl | inst_bl;

    assign need_ui12  =  inst_andi | inst_ori | inst_xori;

    assign imm = src2_is_4 ? 32'h4:
           need_ui12 ? {20'b0, i12[11:0]}: // 12位零扩展立即数
           need_si14 ? {{16{i14[13]}}, i14,2'b00}: // 左移 2 位有符号扩展
           need_si20 ? {i20[19:0], 12'b0}:
           {{20{i12[11]}}, i12[11:0]};     // 12位符号扩展立即数


    assign br_offs = need_si26 ? {{ 4{i26[25]}}, i26[25:0], 2'b0} :
           {{14{i16[15]}}, i16[15:0], 2'b0} ;

    assign jirl_offs = {{14{i16[15]}}, i16[15:
                                           0], 2'b0};

    assign src_reg_is_rd = inst_beq |
           inst_bne |
           inst_st_w |
           inst_st_h |
           inst_st_b |
           inst_sc_w |
           inst_blt |
           inst_bltu |
           inst_bge |
           inst_bgeu |
           inst_csrwr  |
           inst_csrxchg;

    assign src1_is_pc    = inst_jirl | inst_bl | inst_pcaddu12i;

    assign src2_is_imm   = inst_slli_w |
           inst_srli_w |
           inst_srai_w |
           inst_addi_w |
           inst_lu12i_w|
           inst_jirl   |
           inst_bl     |
           inst_slti   |
           inst_sltui  |
           inst_andi   |
           inst_ori    |
           inst_xori   |
           inst_pcaddu12i |

           inst_st_b   |
           inst_st_h   |
           inst_st_w   |
           inst_ld_b   |
           inst_ld_bu  |
           inst_ld_h   |
           inst_ld_hu  |
           inst_ld_w   |

           inst_ll_w   |
           inst_sc_w   |
           inst_valid_cacop
           ;

    assign out_mem_op = (load_use_stall_1 | load_use_stall_2) ? 10'd0 : {inst_sc_w, inst_ll_w, inst_ld_w, inst_ld_hu, inst_ld_h, inst_ld_bu, inst_ld_b, inst_st_w, inst_st_h, inst_st_b};

    assign res_from_mem  = inst_ld_w |
           inst_ld_b |
           inst_ld_bu |
           inst_ld_h |
           inst_ld_hu |
           inst_ll_w;

    assign res_from_csr =  inst_csrrd |
           inst_csrwr |
           inst_csrxchg |
           inst_rdcntid_w |
           inst_rdcntvl_w |
           inst_rdcntvh_w |
           inst_cpucfg
           ;

    assign rd_csr_addr = csr_idx;
    assign csr_we = inst_csrwr | inst_csrxchg; // 修改 csr
    assign csr_mask = inst_csrwr ? 32'hffffffff : rj_value;

    assign csr_rkd_value = rkd_value;
    assign is_inst_ertn = inst_ertn; // 是 ertn 指令

    assign dst_is_r1 = inst_bl;
    assign dst_is_rj = inst_rdcntid_w;
    assign gr_we = inst_jirl|
           inst_bl |
           inst_add_w |
           inst_sub_w |
           inst_slt |
           inst_sltu|
           inst_nor |
           inst_and |
           inst_or  |
           inst_xor |
           inst_slli_w|
           inst_srli_w|
           inst_srai_w|
           inst_addi_w|
           inst_ld_w|
           inst_ld_b|
           inst_ld_bu|
           inst_ld_h|
           inst_ld_hu|
           inst_lu12i_w|
           inst_slti|
           inst_sltui|
           inst_andi|
           inst_ori |
           inst_xori|
           inst_sll |
           inst_srl |
           inst_sra |
           inst_pcaddu12i|
           inst_mul_w|
           inst_mulh_w|
           inst_mulh_wu|
           inst_div_w|
           inst_div_wu|
           inst_mod_w|
           inst_mod_wu|
           inst_csrrd|
           inst_csrxchg|
           inst_csrwr|
           inst_rdcntid_w|
           inst_rdcntvl_w|
           inst_rdcntvh_w|

           inst_ll_w|
           inst_sc_w|
           inst_cpucfg
           ;

    assign mem_we = inst_st_w || inst_st_b || inst_st_h || (inst_sc_w && llbit);
    assign dest = dst_is_r1 ? 5'd1 :
           dst_is_rj ? rj : rd;

    assign rf_raddr1 = rj;
    assign rf_raddr2 = src_reg_is_rd ? rd : rk;

    // 只有计算完成，才能进行数据前递
    // assign rj_value  = state_valid ? conflict_regaData : rf_rdata1;
    // assign rkd_value = state_valid ? conflict_regbData : rf_rdata2;
    assign rj_value  = conflict_regaData;
    assign rkd_value = conflict_regbData;

    wire rj_lt_rd;
    wire rj_ltu_rd;
    wire rj_gt_rd;
    wire rj_gtu_rd;

    assign rj_eq_rd = (rj_value == rkd_value);
    assign rj_lt_rd = ($signed(rj_value) < $signed(rkd_value));
    assign rj_ltu_rd = ($unsigned(rj_value) < $unsigned(rkd_value));
    assign rj_gt_rd = ($signed(rj_value) >= $signed(rkd_value));
    assign rj_gtu_rd = ($unsigned(rj_value) >= $unsigned(rkd_value));

    // 转移指令首先要计算完毕
    // 因为有前递数据会不断得刷新
    // 什么是就计算完了？
    // 我的思路是，让下游每一个模块都计算完毕，这样
    // IDU 才会拿到完整的数据并顺利完成计算d

    assign br_taken = (inst_beq && rj_eq_rd
                       || inst_bne && !rj_eq_rd
                       || inst_jirl
                       || inst_bl
                       || inst_b
                       || inst_blt  && rj_lt_rd
                       || inst_bltu && rj_ltu_rd
                       || inst_bge  && rj_gt_rd
                       || inst_bgeu && rj_gtu_rd
                      )  && idu_valid && !wire_fs_excp; // 计算完成才能裁定，这里不裁定，最终由 preIFU 进行裁定
    assign br_target = br_taken_r ? expected_pc :(inst_beq || inst_bne || inst_bl || inst_b || inst_blt || inst_bltu || inst_bge || inst_bgeu) ? (idu_pc + br_offs) :
           (rj_value + jirl_offs);

    // 如果下游有异常，当前指令全部 valid 就行，不用报指令无效异常
    assign inst_valid = inst_add_w |
           inst_sub_w|
           inst_slt |
           inst_slti|
           inst_sltu|
           inst_sltui|
           inst_nor |
           inst_and |
           inst_andi|
           inst_or  |
           inst_ori |
           inst_xor |
           inst_xori|
           inst_sll |
           inst_slli_w|
           inst_srl |
           inst_srli_w|
           inst_sra |
           inst_srai_w|
           inst_addi_w|
           inst_ld_w |
           inst_ld_b |
           inst_ld_bu|
           inst_ld_h |
           inst_ld_hu|
           inst_st_w |
           inst_st_b |
           inst_st_h |
           inst_jirl |
           inst_b    |
           inst_bl  |
           inst_blt |
           inst_bltu|
           inst_beq |
           inst_bne |
           inst_bge |
           inst_bgeu|
           inst_lu12i_w|
           inst_pcaddu12i|
           inst_mul_w|
           inst_mulh_w|
           inst_mulh_wu|
           inst_div_w|
           inst_div_wu|
           inst_mod_w|
           inst_mod_wu|
           inst_csrrd|
           inst_csrwr|
           inst_csrxchg|
           inst_ertn|
           inst_syscall|
           inst_break|
           inst_rdcntid_w|
           inst_rdcntvl_w|
           inst_rdcntvh_w|
           inst_tlbsrch    |
           inst_tlbrd      |
           inst_tlbwr      |
           inst_tlbfill    |
           inst_ll_w       |
           inst_sc_w       |
           inst_dbar       |
           inst_ibar       |
           inst_idle       |
           inst_valid_cacop|
           inst_nop        |
           inst_preld      |
           inst_cpucfg     |
           (inst_invtlb && (rd == 5'd0 ||
                            rd == 5'd1 ||
                            rd == 5'd2 ||
                            rd == 5'd3 ||
                            rd == 5'd4 ||
                            rd == 5'd5 ||
                            rd == 5'd6 ));

    wire kernel_inst = inst_csrrd      |
         inst_csrwr      |
         inst_csrxchg    |
         inst_tlbsrch    |
         inst_tlbrd      |
         inst_tlbwr      |
         inst_tlbfill    |
         inst_invtlb     |
         inst_idle       |
         inst_valid_cacop & (rd[4:3] != 2'b10)|
         inst_ertn ;


    // 异常=================================================
    // 0x4
    assign idu_excp_syacall = inst_syscall;
    assign syscall_num = idu_excp_syacall ? 16'h0010 : 16'b0;
    // 0x5
    assign idu_excp_ine = ~inst_valid;
    assign excp_ine_num = idu_excp_ine ? 16'h0020 : 16'b0;
    // 0x6
    assign idu_excp_brk = inst_break;
    assign excp_brk_num = idu_excp_brk ? 16'h0040 : 16'b0;
    // 0x7
    // 挂在指令的开头
    // 会死锁，比如死循环等待 int ，却挂不上去，这时候就可以设置一个信号
    // 当指令一样的时候设置一个计数器，当计数器的值很大比如 5 的时候且有 int，直接挂
    assign idu_excp_ie = has_int && ~is_nop;
    assign excp_ie_num = idu_excp_ie ? 16'h0080 : 16'b0;
    // 0x8
    assign idu_excp_ipe = kernel_inst && (csr_plv == 2'b11);
    assign excp_ipe_num = idu_excp_ipe ? 16'h0100 : 16'b0;

    assign ds_excp = ( wire_fs_excp | idu_excp_syacall |
                       idu_excp_ine | idu_excp_brk | idu_excp_ie | idu_excp_ipe
                     ) & ~is_nop;

    assign ds_excp_num = ~is_nop ? (wire_fs_excp_num | syscall_num | excp_ine_num | excp_brk_num | excp_ie_num) :
           ( wire_fs_excp_num | syscall_num | excp_ine_num | excp_brk_num);

    // 输出
    assign ds_excp_out =  (load_use_stall_1|load_use_stall_2) ? 1'b0 : ds_excp;
    assign ds_excp_num_out = (load_use_stall_1|load_use_stall_2) ? 16'd0 : ds_excp_num;

    // 异常=================================================

    assign alu_src1 = src1_is_pc ? idu_pc[31:0] : rj_value;
    assign alu_src2 = src2_is_imm ? imm : rkd_value;

    // tlb
    assign tlb_inst_bus = {
               inst_tlbsrch,
               inst_tlbrd,
               inst_tlbwr,
               inst_tlbfill,
               inst_invtlb
           };

    // invtlb
    assign invtlb_op = rd;
    assign invtlb_asid = rj_value[9:0];
    assign invtlb_vpn = rkd_value[31:13];

    //debug
    assign idu_inst_o = (load_use_stall_1 | load_use_stall_2) ? 32'h03400000 : inst_sram_rdata_reg;
    assign is_csr_wr = inst_csrwr |
           inst_csrxchg |
           inst_tlbrd |
           inst_tlbsrch;

    assign pc_pro_o = idu_pc;

    assign bus_csr_rd_wr_data = {
               res_from_csr,
               rd_csr_addr,
               csr_we,
               csr_mask,
               csr_rkd_value,
               inst_rdcntvl_w,
               inst_rdcntvh_w,
               inst_rdcntid_w
           };

    // ld_use
    assign ld_sc_inst_o = inst_ld_b || inst_ld_bu || inst_ld_h || inst_ld_hu || inst_ld_w || inst_ll_w || inst_sc_w;

    //ibar dbar
    assign pipeline_no_empty = es_to_ds_valid || ms_to_ds_valid || ws_to_ds_valid;

    assign dbar_stall = inst_dbar && pipeline_no_empty;
    assign ibar_stall = inst_ibar && pipeline_no_empty;

    assign csr_rstat = (inst_csrrd || inst_csrwr || inst_csrxchg) && (rd_csr_addr == 14'h5);


    assign inst_idle_o = inst_idle;

    assign cacop_o = inst_valid_cacop;

    assign br_taken1 = br_taken && caculate_done;
    assign br_target1 = br_target;
    assign current_pc = pc_reg;
    assign inst_bubble_o = idu_valid && (load_use_stall_1 | load_use_stall_2);

endmodule
