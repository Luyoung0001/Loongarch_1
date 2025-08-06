`include "csr.h"
module csr
    #(
         parameter TLBNUM = 32
     )
     (
         input wire clk,
         input wire rst,
         //from ds for read
         input wire [13:0] rd_addr,
         output wire [31:0] rd_data,


         //interrupt
         input wire [7:0] interuption,
         //timer 64
         output wire [63:0] timer_64_out ,
         output wire [31:0] tid_out,

         input wire [147:0] bus_wbu_to_csr_data,
         input wire [1:0] flush,
         output wire has_int,
         // to ifu
         output wire [31:0] era_out,
         output wire [31:0] eentry_out,
         output wire [31:0] tlbrentry_out,
         output [ 1:0]      plv_out,

         //from ws llbit
         input                           llbit_in     ,
         input                           llbit_set_in ,
         input  [27:0]                   lladdr_in    ,
         input                           lladdr_set_in,
         //to es
         output                          llbit_out    ,
         output [27:0]                   lladdr_out   ,




         //from addr trans
         input wire         tlbrd_en,
         input wire [31:0]  tlbehi_in,
         input wire [31:0]  tlbelo0_in,
         input wire [31:0]  tlbelo1_in,
         input wire [31:0]  tlbidx_in,
         input wire [ 9:0]  asid_in,
         // tlb
         input  wire        tlbsrch_en,
         input  wire        tlbsrch_found,
         input  wire [$clog2(TLBNUM)-1:0]  tlbsrch_index,

         output wire [9:0]  asid_out,
         output wire [18:0] vppn_out,
         output wire [31:0] tlbehi_out,
         output wire [31:0] tlbelo0_out,
         output wire [31:0] tlbelo1_out,
         output wire [31:0] tlbidx_out,
         output             pg_out,
         output             da_out,
         output [31:0]      dmw0_out,
         output [31:0]      dmw1_out,
         output [ 1:0]      datf_out,
         output [ 1:0]      datm_out,
         output [ 5:0]      ecode_out,
         output wire [$clog2(TLBNUM)-1:0]  rand_index,

         // csr regs for diff
         output [31:0]                   csr_crmd_diff,
         output [31:0]                   csr_prmd_diff,
         output [31:0]                   csr_ecfg_diff,
         output [31:0]                   csr_estat_diff,
         output [31:0]                   csr_era_diff,
         output [31:0]                   csr_badv_diff,
         output [31:0]                   csr_eentry_diff,
         output [31:0]                   csr_tlbidx_diff,
         output [31:0]                   csr_tlbehi_diff,
         output [31:0]                   csr_tlbelo0_diff,
         output [31:0]                   csr_tlbelo1_diff,
         output [31:0]                   csr_asid_diff,
         output [31:0]                   csr_save0_diff,
         output [31:0]                   csr_save1_diff,
         output [31:0]                   csr_save2_diff,
         output [31:0]                   csr_save3_diff,
         output [31:0]                   csr_tid_diff,
         output [31:0]                   csr_tcfg_diff,
         output [31:0]                   csr_tval_diff,
         output [31:0]                   csr_ticlr_diff,
         output [31:0]                   csr_llbctl_diff,
         output [31:0]                   csr_tlbrentry_diff,
         output [31:0]                   csr_dmw0_diff,
         output [31:0]                   csr_dmw1_diff,
         output [31:0]                   csr_pgdl_diff,
         output [31:0]                   csr_pgdh_diff
     );

    wire excp_flush;
    wire ertn_flush;
    assign {excp_flush, ertn_flush} = flush;

    // csr
    wire csr_wr_en;
    wire [13:0] csr_waddr;
    wire [31:0] csr_wdata;
    wire [31:0] csr_era_in;
    wire [5:0] csr_ecode;
    wire [31:0] bad_va;
    wire [8:0] csr_esubcode;
    wire va_error;
    wire excp_tlbrefill;
    wire excp_tlb;
    wire [18:0] excp_tlb_vppn;
    assign {
            csr_wr_en,
            csr_waddr,
            csr_wdata,
            csr_ecode,
            va_error,
            bad_va,
            csr_esubcode,
            excp_tlbrefill,
            excp_tlb,
            excp_tlb_vppn,
            csr_era_in
        } = bus_wbu_to_csr_data;

    reg [63:0] timer_64;
    reg        timer_en;

    localparam CRMD  = 14'h0;
    localparam PRMD  = 14'h1;
    localparam ECFG  = 14'h4;
    localparam ESTAT = 14'h5;
    localparam ERA   = 14'h6;
    localparam BADV  = 14'h7;
    localparam EENTRY = 14'hc;

    localparam TLBIDX= 14'h10;
    localparam TLBEHI= 14'h11;
    localparam TLBELO0=14'h12;
    localparam TLBELO1=14'h13;
    localparam ASID  = 14'h18;
    localparam PGDL  = 14'h19;
    localparam CPUID = 14'h20;
    localparam PGDH  = 14'h1a;
    localparam PGD   = 14'h1b;
    localparam TLBRENTRY = 14'h88;
    localparam DMW0  = 14'h180;
    localparam DMW1  = 14'h181;

    localparam SAVE0 = 14'h30;
    localparam SAVE1 = 14'h31;
    localparam SAVE2 = 14'h32;
    localparam SAVE3 = 14'h33;
    localparam TID   = 14'h40;
    localparam TCFG  = 14'h41;
    localparam TVAL  = 14'h42;
    localparam CNTC  = 14'h43;
    localparam TICLR = 14'h44;

    localparam LLBCTL= 14'h60;

    wire crmd_wen   = csr_wr_en & (csr_waddr == CRMD);
    wire prmd_wen   = csr_wr_en & (csr_waddr == PRMD);
    wire ecfg_wen   = csr_wr_en & (csr_waddr == ECFG);
    wire estat_wen  = csr_wr_en & (csr_waddr == ESTAT);
    wire era_wen    = csr_wr_en & (csr_waddr == ERA);
    wire eentry_wen = csr_wr_en & (csr_waddr == EENTRY);
    wire badv_wen   = csr_wr_en & (csr_waddr == BADV);

    wire tlbidx_wen = csr_wr_en & (csr_waddr == TLBIDX);
    wire tlbehi_wen = csr_wr_en & (csr_waddr == TLBEHI);
    wire tlbelo0_wen= csr_wr_en & (csr_waddr == TLBELO0);
    wire tlbelo1_wen= csr_wr_en & (csr_waddr == TLBELO1);
    wire asid_wen   = csr_wr_en & (csr_waddr == ASID);
    wire pgdl_wen   = csr_wr_en & (csr_waddr == PGDL);
    wire cpuid_wen  = csr_wr_en & (csr_waddr == CPUID);
    wire pgdh_wen   = csr_wr_en & (csr_waddr == PGDH);
    wire pgd_wen    = csr_wr_en & (csr_waddr == PGD);
    wire tlbrentry_wen = csr_wr_en & (csr_waddr == TLBRENTRY);
    wire DMW0_wen   = csr_wr_en & (csr_waddr == DMW0);
    wire DMW1_wen   = csr_wr_en & (csr_waddr == DMW1);

    wire save0_wen  = csr_wr_en & (csr_waddr == SAVE0);
    wire save1_wen  = csr_wr_en & (csr_waddr == SAVE1);
    wire save2_wen  = csr_wr_en & (csr_waddr == SAVE2);
    wire save3_wen  = csr_wr_en & (csr_waddr == SAVE3);

    wire tid_wen    = csr_wr_en & (csr_waddr == TID);
    wire tcfg_wen   = csr_wr_en & (csr_waddr == TCFG);
    wire tval_wen   = csr_wr_en & (csr_waddr == TVAL);
    wire ticlr_wen  = csr_wr_en & (csr_waddr == TICLR);
    wire cntc_wen   = csr_wr_en & (csr_waddr == CNTC);

    wire llbctl_wen = csr_wr_en & (csr_waddr == LLBCTL);

    reg [31:0] csr_crmd;
    reg [31:0] csr_prmd;
    reg [31:0] csr_ecfg;
    reg [31:0] csr_estat;
    reg [31:0] csr_era;
    reg [31:0] csr_eentry;
    reg [31:0] csr_badv;

    reg [31:0] csr_tlbidx;
    reg [31:0] csr_tlbehi;
    reg [31:0] csr_tlbelo0;
    reg [31:0] csr_tlbelo1;
    reg [31:0] csr_asid;
    reg [31:0] csr_tlbrentry;
    reg [31:0] csr_dmw0;
    reg [31:0] csr_dmw1;
    reg [31:0] csr_pgdl;
    reg [31:0] csr_pgdh;
    reg [31:0] csr_cpuid;
    reg [31:0] csr_cntc;

    wire [31:0] csr_pgd;
    wire tlbrd_valid_wr_en;
    wire tlbrd_invalid_wr_en;

    wire eret_tlbrefill_excp;


    assign eret_tlbrefill_excp = csr_estat[`ECODE] == 6'h3f;

    assign tlbrd_valid_wr_en   = tlbrd_en && !tlbidx_in[`NE];
    assign tlbrd_invalid_wr_en = tlbrd_en &&  tlbidx_in[`NE];

    assign csr_pgd = csr_badv[31] ? csr_pgdh : csr_pgdl;


    reg [31:0] csr_save0;
    reg [31:0] csr_save1;
    reg [31:0] csr_save2;
    reg [31:0] csr_save3;

    // timer
    reg [31:0] csr_tid;
    reg [31:0] csr_tcfg;
    reg [31:0] csr_tval;
    reg [31:0] csr_ticlr;

    reg [31:0] csr_llbctl;
    reg        llbit;
    reg [27:0] lladdr;

    // csr 读取发生在 idu 中
    assign rd_data = {32{rd_addr == CRMD  }}  & csr_crmd    |
           {32{rd_addr == PRMD  }}  & csr_prmd    |
           {32{rd_addr == ECFG  }}  & csr_ecfg    |
           {32{rd_addr == ESTAT }}  & csr_estat   |
           {32{rd_addr == ERA   }}  & csr_era	  |
           {32{rd_addr == BADV  }}  & csr_badv    |
           {32{rd_addr == EENTRY}}  & csr_eentry  |

           {32{rd_addr == TLBIDX}}  & csr_tlbidx  |
           {32{rd_addr == TLBEHI}}  & csr_tlbehi  |
           {32{rd_addr == TLBELO0}} & csr_tlbelo0 |
           {32{rd_addr == TLBELO1}} & csr_tlbelo1 |
           {32{rd_addr == ASID  }}  & csr_asid    |
           {32{rd_addr == PGDL  }}  & csr_pgdl    |
           {32{rd_addr == PGDH  }}  & csr_pgdh    |
           {32{rd_addr == PGD   }}  & csr_pgd     |
           {32{rd_addr == TLBRENTRY}} & csr_tlbrentry|
           {32{rd_addr == DMW0}}    & csr_dmw0    |
           {32{rd_addr == DMW1}}    & csr_dmw1    |
           {32{rd_addr == CPUID }}  & csr_cpuid   |
           {32{rd_addr == CNTC  }}  & csr_cntc    |

           {32{rd_addr == SAVE0 }}  & csr_save0   |
           {32{rd_addr == SAVE1 }}  & csr_save1   |
           {32{rd_addr == SAVE2 }}  & csr_save2   |
           {32{rd_addr == SAVE3 }}  & csr_save3   |
           {32{rd_addr == TID   }}  & csr_tid     |
           {32{rd_addr == TCFG  }}  & csr_tcfg    |
           {32{rd_addr == TICLR }}  & csr_ticlr   |
           {32{rd_addr == LLBCTL}}  & {csr_llbctl[31:1], llbit} |
           {32{rd_addr == TVAL  }}  & csr_tval;


    assign era_out      = csr_era;
    assign eentry_out   = csr_eentry;
    assign tlbrentry_out = csr_tlbrentry;
    assign tid_out      = csr_tid;
    assign timer_64_out = timer_64;
    assign has_int = ((csr_ecfg[`LIE] & csr_estat[`IS]) != 13'b0) & csr_crmd[`IE];
    // tlb
    assign asid_out     = csr_asid[`TLB_ASID];
    assign vppn_out     = tlbehi_wen ? csr_wdata[`VPPN] : csr_tlbehi[`VPPN];
    assign tlbehi_out   = csr_tlbehi;
    assign tlbelo0_out  = csr_tlbelo0;
    assign tlbelo1_out  = csr_tlbelo1;
    assign tlbidx_out   = csr_tlbidx;
    assign rand_index   = timer_64[$clog2(TLBNUM)-1:0];

    assign llbit_out    = llbit;
    assign lladdr_out   = lladdr;

    assign plv_out      = {2{excp_flush}} & 2'b0            |
           {2{ertn_flush}} & csr_prmd[`PPLV] |
           {2{crmd_wen  }} & csr_wdata[`PLV]   |
           {2{!excp_flush && !ertn_flush && !crmd_wen}} & csr_crmd[`PLV];


    wire no_forward   = !excp_tlbrefill && !(eret_tlbrefill_excp && ertn_flush) && !crmd_wen;

    assign pg_out      = excp_tlbrefill ? 1'b0:
           (eret_tlbrefill_excp && ertn_flush)? 1'b1:
           crmd_wen ? csr_wdata[`PG]:
           no_forward     & csr_crmd[`PG];

    assign da_out       = excp_tlbrefill ? 1'b1:
           (eret_tlbrefill_excp && ertn_flush) ? 1'b0:
           crmd_wen ? csr_wdata[`DA]:
           no_forward     & csr_crmd[`DA];

    assign dmw0_out     = DMW0_wen ? csr_wdata : csr_dmw0;
    assign dmw1_out     = DMW1_wen ? csr_wdata : csr_dmw1;

    assign datf_out     = csr_crmd[`DATF];
    assign datm_out     = csr_crmd[`DATM];
    assign ecode_out    = csr_estat[`ECODE];

    //crmd
    always @(posedge clk) begin
        if (rst) begin
            csr_crmd[ `PLV] <=  2'b0;
            csr_crmd[  `IE] <=  1'b0; // 复位后需要屏蔽中断
            csr_crmd[  `DA] <=  1'b1; // 复位后开启地址直接翻译
            csr_crmd[  `PG] <=  1'b0; // 复位后关闭映射地址翻译
            csr_crmd[`DATF] <=  2'b0;
            csr_crmd[`DATM] <=  2'b0;
            csr_crmd[31: 9] <= 23'b0;
        end
        else if (excp_flush) begin
            csr_crmd[ `PLV] <=  2'b0; // 例外发生时，将权限打到最高，关闭中断
            csr_crmd[  `IE] <=  1'b0;
            if (excp_tlbrefill) begin
                csr_crmd [`DA] <= 1'b1;
                csr_crmd [`PG] <= 1'b0;
            end
        end
        else if (ertn_flush) begin
            csr_crmd[ `PLV] <= csr_prmd[`PPLV]; // 恢复特权等级
            csr_crmd[  `IE] <= csr_prmd[`PIE ]; // 恢复中断
            if (eret_tlbrefill_excp) begin
                csr_crmd[`DA] <= 1'b0;
                csr_crmd[`PG] <= 1'b1;
            end
        end
        else if (crmd_wen) begin
            csr_crmd[ `PLV] <= csr_wdata[`PLV];
            csr_crmd[  `IE] <= csr_wdata[`IE];
            csr_crmd[  `DA] <= csr_wdata[`DA];
            csr_crmd[  `PG] <= csr_wdata[`PG];
            csr_crmd[`DATF] <= csr_wdata[`DATF];
            csr_crmd[`DATM] <= csr_wdata[`DATM];
        end
    end

    //prmd
    always @(posedge clk) begin
        if (rst) begin
            csr_prmd[31:3] <= 29'b0;
        end
        else if (excp_flush) begin
            csr_prmd[`PPLV] <= csr_crmd[`PLV];
            csr_prmd[ `PIE] <= csr_crmd[`IE ];
        end
        else if (prmd_wen) begin
            csr_prmd[`PPLV] <= csr_wdata[`PPLV];
            csr_prmd[ `PIE] <= csr_wdata[ `PIE];
        end
    end

    //estat
    always @(posedge clk) begin
        if (rst) begin
            csr_estat[1:0] <= 2'b0;     // 软中断状态位
            csr_estat[10]    <= 1'b0;   // 保留域
            csr_estat[12]    <= 1'b0;   // 核间中断，暂不考虑
            csr_estat[15:13] <= 3'b0;   // 保留域
            csr_estat[31]    <= 1'b0;   // 保留域
            // csr_estat <= 32'd0;

            timer_en <= 1'b0;
        end
        else begin
            if (ticlr_wen && csr_wdata[`CLR]) begin
                csr_estat[11] <= 1'b0;
            end
            else if (tcfg_wen) begin
                timer_en <= csr_wdata[`EN];
            end
            else if (timer_en && (csr_tval == 32'b0)) begin
                csr_estat[11] <= 1'b1;           // 减到 0 的时候，置中断
                timer_en <= csr_tcfg[`PERIODIC]; // 是否重复计时
            end
            csr_estat[9:2] <= interuption; // 直接对外部中断进行采样

            if (excp_flush) begin
                csr_estat[`ECODE] <= csr_ecode;
                csr_estat[`ESUBCODE] <= csr_esubcode;
            end
            else if (estat_wen) begin
                csr_estat[1:0] <= csr_wdata[1:0]; // 仅仅被 csr 更新
            end
        end
    end

    //era
    always @(posedge clk) begin
        if (excp_flush) begin
            csr_era <= csr_era_in; // 发生例外时写
        end
        else if (era_wen) begin
            csr_era <= csr_wdata;  // 也可以直接操作
        end
    end

    //eentry
    always @(posedge clk) begin
        if (rst) begin
            csr_eentry[5:0] <= 6'b0;
        end
        else if (eentry_wen) begin
            csr_eentry[31:6] <= csr_wdata[31:6];
        end
    end

    //badv
    always @(posedge clk) begin
        if (badv_wen) begin
            csr_badv <= csr_wdata;
        end
        else if (va_error) begin
            csr_badv <= bad_va;
        end
    end

    //cpuid
    always @(posedge clk) begin
        if (rst) begin
            csr_cpuid <= 32'b0;
        end
    end

    //save0
    always @(posedge clk) begin
        if (save0_wen) begin
            csr_save0 <= csr_wdata;
        end
    end

    //save1
    always @(posedge clk) begin
        if (save1_wen) begin
            csr_save1 <= csr_wdata;
        end
    end

    //save2
    always @(posedge clk) begin
        if (save2_wen) begin
            csr_save2 <= csr_wdata;
        end
    end

    //save3
    always @(posedge clk) begin
        if (save3_wen) begin
            csr_save3 <= csr_wdata;
        end
    end

    //tid
    always @(posedge clk) begin
        if (rst) begin
            csr_tid <= 32'b0;
        end
        else if (tid_wen) begin
            csr_tid <= csr_wdata;
        end
    end

    //tcfg
    always @(posedge clk) begin
        if (rst) begin
            csr_tcfg[`EN] <= 1'b0;
        end
        else if (tcfg_wen) begin
            csr_tcfg[      `EN] <= csr_wdata[      `EN];
            csr_tcfg[`PERIODIC] <= csr_wdata[`PERIODIC];
            csr_tcfg[ `INITVAL] <= csr_wdata[ `INITVAL];
        end
    end

    //ecfg
    always @(posedge clk) begin
        if (rst) begin
            csr_ecfg <= 32'b0;
        end
        else if (ecfg_wen) begin
            csr_ecfg[ `LIE_1] <= csr_wdata[ `LIE_1];
            csr_ecfg[ `LIE_2] <= csr_wdata[ `LIE_2];
        end
    end

    //cntc
    always @(posedge clk) begin
        if (rst) begin
            csr_cntc <= 32'b0;
        end
        else if (cntc_wen) begin
            csr_cntc <= csr_wdata;
        end
    end
    //tval
    always @(posedge clk) begin
        if (tcfg_wen) begin
            csr_tval <= {csr_wdata[ `INITVAL], 2'b0};
        end
        else if (timer_en) begin
            if (csr_tval != 32'b0) begin
                csr_tval <= csr_tval - 32'b1;
            end
            else if (csr_tval == 32'b0) begin
                csr_tval <= csr_tcfg[`PERIODIC] ? {csr_tcfg[`INITVAL], 2'b0} : 32'hffffffff;
            end
        end
    end

    //ticlr
    always @(posedge clk) begin
        if (rst) begin
            csr_ticlr <= 32'b0;
        end
    end

    // timer_64
    always @(posedge clk) begin
        if (rst) begin
            timer_64 <= 64'b0;
        end
        else begin
            timer_64 <= timer_64 + 1'b1;
        end
    end


    //tlbidx
    always @(posedge clk) begin
        if (rst) begin
            csr_tlbidx[23: 5] <= 19'b0;
            csr_tlbidx[30]    <= 1'b0;
            csr_tlbidx[4:0]   <= 5'd0;
        end
        else if (tlbidx_wen) begin
            csr_tlbidx[4:0]    <= csr_wdata[4:0];
            csr_tlbidx[`PS]    <= csr_wdata[`PS];
            csr_tlbidx[`NE]    <= csr_wdata[`NE];
        end
        else if (tlbsrch_en) begin
            if (tlbsrch_found) begin
                csr_tlbidx[4:0] <= tlbsrch_index;
                csr_tlbidx[`NE]    <= 1'b0;
            end
            else begin
                csr_tlbidx[`NE] <= 1'b1;
            end
        end
        else if (tlbrd_valid_wr_en) begin
            csr_tlbidx[`PS] <= tlbidx_in[`PS];
            csr_tlbidx[`NE] <= tlbidx_in[`NE];
        end
        else if (tlbrd_invalid_wr_en) begin
            csr_tlbidx[`PS] <= 6'b0;
            csr_tlbidx[`NE] <= tlbidx_in[`NE];
        end
    end

    //tlbehi
    always @(posedge clk) begin
        if (rst) begin
            csr_tlbehi[12:0] <= 13'b0;
        end
        else if (tlbehi_wen) begin
            csr_tlbehi[`VPPN] <= csr_wdata[`VPPN];
        end
        else if (tlbrd_valid_wr_en) begin
            csr_tlbehi[`VPPN] <= tlbehi_in[`VPPN];
        end
        else if (tlbrd_invalid_wr_en) begin
            csr_tlbehi[`VPPN] <= 19'b0;
        end
        else if (excp_tlb) begin
            csr_tlbehi[`VPPN] <= excp_tlb_vppn;
        end
    end

    //tlbelo0
    always @(posedge clk) begin
        if (rst) begin
            // csr_tlbelo0[7] <= 1'b0;
            csr_tlbelo0[31:0] <= 32'b0;
        end
        else if (tlbelo0_wen) begin
            csr_tlbelo0[`TLB_V]   <= csr_wdata[`TLB_V];
            csr_tlbelo0[`TLB_D]   <= csr_wdata[`TLB_D];
            csr_tlbelo0[`TLB_PLV] <= csr_wdata[`TLB_PLV];
            csr_tlbelo0[`TLB_MAT] <= csr_wdata[`TLB_MAT];
            csr_tlbelo0[`TLB_G]   <= csr_wdata[`TLB_G];
            csr_tlbelo0[`TLB_PPN_EN] <= csr_wdata[`TLB_PPN_EN];
        end
        else if (tlbrd_valid_wr_en) begin
            csr_tlbelo0[`TLB_V]   <= tlbelo0_in[`TLB_V];
            csr_tlbelo0[`TLB_D]   <= tlbelo0_in[`TLB_D];
            csr_tlbelo0[`TLB_PLV] <= tlbelo0_in[`TLB_PLV];
            csr_tlbelo0[`TLB_MAT] <= tlbelo0_in[`TLB_MAT];
            csr_tlbelo0[`TLB_G]   <= tlbelo0_in[`TLB_G];
            csr_tlbelo0[`TLB_PPN_EN] <= tlbelo0_in[`TLB_PPN_EN];
        end
        else if (tlbrd_invalid_wr_en) begin
            csr_tlbelo0[`TLB_V]   <= 1'b0;
            csr_tlbelo0[`TLB_D]   <= 1'b0;
            csr_tlbelo0[`TLB_PLV] <= 2'b0;
            csr_tlbelo0[`TLB_MAT] <= 2'b0;
            csr_tlbelo0[`TLB_G]   <= 1'b0;
            csr_tlbelo0[`TLB_PPN_EN] <= 20'b0;
        end
    end

    //tlbelo1
    always @(posedge clk) begin
        if (rst) begin
            // csr_tlbelo1[7] <= 1'b0;
            csr_tlbelo1[31:0] <= 32'b0;
        end
        else if (tlbelo1_wen) begin
            csr_tlbelo1[`TLB_V]   <= csr_wdata[`TLB_V];
            csr_tlbelo1[`TLB_D]   <= csr_wdata[`TLB_D];
            csr_tlbelo1[`TLB_PLV] <= csr_wdata[`TLB_PLV];
            csr_tlbelo1[`TLB_MAT] <= csr_wdata[`TLB_MAT];
            csr_tlbelo1[`TLB_G]   <= csr_wdata[`TLB_G];
            csr_tlbelo1[`TLB_PPN_EN] <= csr_wdata[`TLB_PPN_EN];
        end
        else if (tlbrd_valid_wr_en) begin
            csr_tlbelo1[`TLB_V]   <= tlbelo1_in[`TLB_V];
            csr_tlbelo1[`TLB_D]   <= tlbelo1_in[`TLB_D];
            csr_tlbelo1[`TLB_PLV] <= tlbelo1_in[`TLB_PLV];
            csr_tlbelo1[`TLB_MAT] <= tlbelo1_in[`TLB_MAT];
            csr_tlbelo1[`TLB_G]   <= tlbelo1_in[`TLB_G];
            csr_tlbelo1[`TLB_PPN_EN] <= tlbelo1_in[`TLB_PPN_EN];
        end
        else if (tlbrd_invalid_wr_en) begin
            csr_tlbelo1[`TLB_V]   <= 1'b0;
            csr_tlbelo1[`TLB_D]   <= 1'b0;
            csr_tlbelo1[`TLB_PLV] <= 2'b0;
            csr_tlbelo1[`TLB_MAT] <= 2'b0;
            csr_tlbelo1[`TLB_G]   <= 1'b0;
            csr_tlbelo1[`TLB_PPN_EN] <= 20'b0;
        end
    end

    //asid
    always @(posedge clk) begin
        if (rst) begin
            csr_asid[31:10] <= 22'h280; //ASIDBITS = 10
        end
        else if (asid_wen) begin
            csr_asid[`TLB_ASID] <= csr_wdata[`TLB_ASID];
        end
        else if (tlbrd_valid_wr_en) begin
            csr_asid[`TLB_ASID] <= asid_in;
        end
        else if (tlbrd_invalid_wr_en) begin
            csr_asid[`TLB_ASID] <= 10'b0;
        end
    end

    //TLBRENTRY
    always @(posedge clk) begin
        if (rst) begin
            csr_tlbrentry[5:0] <= 6'b0;
        end
        else if (tlbrentry_wen) begin
            csr_tlbrentry[`TLBRENTRY_PA] <= csr_wdata[`TLBRENTRY_PA];
        end
    end

    //dmw0
    always @(posedge clk) begin
        if (rst) begin
            csr_dmw0[ 2:1] <= 2'b0;
            csr_dmw0[24:6] <= 19'b0;
            csr_dmw0[28]   <= 1'b0;
        end
        else if (DMW0_wen) begin
            csr_dmw0[`PLV0]    <= csr_wdata[`PLV0];
            csr_dmw0[`PLV3]    <= csr_wdata[`PLV3];
            csr_dmw0[`DMW_MAT] <= csr_wdata[`DMW_MAT];
            csr_dmw0[`PSEG]    <= csr_wdata[`PSEG];
            csr_dmw0[`VSEG]    <= csr_wdata[`VSEG];
        end
    end

    //dmw1
    always @(posedge clk) begin
        if (rst) begin
            csr_dmw1[ 2:1] <= 2'b0;
            csr_dmw1[24:6] <= 19'b0;
            csr_dmw1[28]   <= 1'b0;
        end
        else if (DMW1_wen) begin
            csr_dmw1[`PLV0]    <= csr_wdata[`PLV0];
            csr_dmw1[`PLV3]    <= csr_wdata[`PLV3];
            csr_dmw1[`DMW_MAT] <= csr_wdata[`DMW_MAT];
            csr_dmw1[`PSEG]    <= csr_wdata[`PSEG];
            csr_dmw1[`VSEG]    <= csr_wdata[`VSEG];
        end
    end

    //pgdl
    always @(posedge clk) begin
        if (pgdl_wen) begin
            csr_pgdl[`BASE] <= csr_wdata[`BASE];
        end
    end

    //pgdh
    always @(posedge clk) begin
        if (pgdh_wen) begin
            csr_pgdh[`BASE] <= csr_wdata[`BASE];
        end
    end


    //llbctl
    always @(posedge clk) begin
        if (rst) begin
            csr_llbctl[`KLO]   <= 1'b0;
            csr_llbctl[31:3]   <= 29'b0;
            csr_llbctl[`WCLLB] <= 1'b0;
            llbit <= 1'b0;
        end
        else if (ertn_flush) begin
            if (csr_llbctl[`KLO]) begin
                csr_llbctl[`KLO] <= 1'b0;
            end
            else begin
                llbit <= 1'b0;
            end
        end
        else if (llbctl_wen) begin
            csr_llbctl[  `KLO] <= csr_wdata[  `KLO];
            if (csr_wdata[`WCLLB] == 1'b1) begin
                llbit <= 1'b0;
            end
        end
        else if (llbit_set_in) begin
            llbit <= llbit_in;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            lladdr <= 28'b0;
        end
        else if (lladdr_set_in) begin
            lladdr <= lladdr_in;
        end
    end


    // difftest
    assign csr_crmd_diff        = csr_crmd;
    assign csr_prmd_diff        = csr_prmd;
    assign csr_ecfg_diff        = csr_ecfg;
    assign csr_estat_diff       = csr_estat;
    assign csr_era_diff         = csr_era;
    assign csr_badv_diff        = csr_badv;
    assign csr_eentry_diff      = csr_eentry;
    assign csr_tlbidx_diff      = csr_tlbidx;
    assign csr_tlbehi_diff      = csr_tlbehi;
    assign csr_tlbelo0_diff     = csr_tlbelo0;
    assign csr_tlbelo1_diff     = csr_tlbelo1;
    assign csr_asid_diff        = csr_asid;
    assign csr_save0_diff       = csr_save0;
    assign csr_save1_diff       = csr_save1;
    assign csr_save2_diff       = csr_save2;
    assign csr_save3_diff       = csr_save3;
    assign csr_tid_diff         = csr_tid;
    assign csr_tcfg_diff        = csr_tcfg;
    assign csr_tval_diff        = csr_tval;
    assign csr_ticlr_diff       = csr_ticlr;
    assign csr_llbctl_diff      = {csr_llbctl[31:1], llbit};
    assign csr_tlbrentry_diff   = csr_tlbrentry;
    assign csr_dmw0_diff        = csr_dmw0;
    assign csr_dmw1_diff        = csr_dmw1;
    assign csr_pgdl_diff        = csr_pgdl;
    assign csr_pgdh_diff        = csr_pgdh;



endmodule
