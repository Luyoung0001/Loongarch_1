module tlb
    #(
         parameter TLBNUM = 32
     )
     (
         input  wire         clk,

         // Search port 0
         input  wire [18:0] s0_vppn,
         input  wire        s0_va_bit12,  // for odd page
         input  wire [9:0]  s0_asid,
         output wire        s0_found,
         output wire [$clog2(TLBNUM)-1:0] s0_index,
         output wire [19:0] s0_ppn,
         output wire [5:0]  s0_ps,
         output wire [1:0]  s0_plv,
         output wire [1:0]  s0_mat,
         output wire        s0_d,
         output wire        s0_v,

         // Search port 1
         input  wire [18:0] s1_vppn,
         input  wire        s1_va_bit12,  // for odd page
         input  wire [9:0]  s1_asid,
         output wire        s1_found,
         output wire [$clog2(TLBNUM)-1:0] s1_index,
         output wire [19:0] s1_ppn,
         output wire [5:0]  s1_ps,
         output wire [1:0]  s1_plv,
         output wire [1:0]  s1_mat,
         output wire        s1_d,
         output wire        s1_v,

         // Invalidate port
         input  wire        invtlb_valid,
         input  wire [4:0]  invtlb_op,
         input  wire [9:0]  invtlb_asid,
         input  wire [18:0] invtlb_vpn,

         // Write port
         input  wire                     we,
         input  wire [$clog2(TLBNUM)-1:0] w_index,
         input  wire                     w_e,
         input  wire [18:0]              w_vppn,
         input  wire [5:0]               w_ps,
         input  wire [9:0]               w_asid,
         input  wire                     w_g,
         input  wire [19:0]              w_ppn0,
         input  wire [1:0]               w_plv0,
         input  wire [1:0]               w_mat0,
         input  wire                     w_d0,
         input  wire                     w_v0,
         input  wire [19:0]              w_ppn1,
         input  wire [1:0]               w_plv1,
         input  wire [1:0]               w_mat1,
         input  wire                     w_d1,
         input  wire                     w_v1,

         // Read port
         input  wire [$clog2(TLBNUM)-1:0] r_index,
         output wire                     r_e,
         output wire [18:0]              r_vppn,
         output wire [5:0]               r_ps,
         output wire [9:0]               r_asid,
         output wire                     r_g,
         output wire [19:0]              r_ppn0,
         output wire [1:0]               r_plv0,
         output wire [1:0]               r_mat0,
         output wire                     r_d0,
         output wire                     r_v0,
         output wire [19:0]              r_ppn1,
         output wire [1:0]               r_plv1,
         output wire [1:0]               r_mat1,
         output wire                     r_d1,
         output wire                     r_v1
     );

    // TLB entry registers
    reg [18:0] tlb_vppn [TLBNUM-1:0] /* verilator public */;
    reg        tlb_e    [TLBNUM-1:0] /* verilator public */;
    reg [9:0]  tlb_asid [TLBNUM-1:0] /* verilator public */;
    reg        tlb_g    [TLBNUM-1:0] /* verilator public */;
    reg [5:0]  tlb_ps   [TLBNUM-1:0] /* verilator public */;
    reg [19:0] tlb_ppn0 [TLBNUM-1:0] /* verilator public */;
    reg [1:0]  tlb_plv0 [TLBNUM-1:0] /* verilator public */;
    reg [1:0]  tlb_mat0 [TLBNUM-1:0] /* verilator public */;
    reg        tlb_d0   [TLBNUM-1:0] /* verilator public */;
    reg        tlb_v0   [TLBNUM-1:0] /* verilator public */;
    reg [19:0] tlb_ppn1 [TLBNUM-1:0] /* verilator public */;
    reg [1:0]  tlb_plv1 [TLBNUM-1:0] /* verilator public */;
    reg [1:0]  tlb_mat1 [TLBNUM-1:0] /* verilator public */;
    reg        tlb_d1   [TLBNUM-1:0] /* verilator public */;
    reg        tlb_v1   [TLBNUM-1:0] /* verilator public */;

    // Match signals
    wire [TLBNUM-1:0] match0;
    wire [TLBNUM-1:0] match1;
    wire [$clog2(TLBNUM)-1:0] match0_en;
    wire [$clog2(TLBNUM)-1:0] match1_en;
    wire [TLBNUM-1:0] s0_odd_page_buffer;
    wire [TLBNUM-1:0] s1_odd_page_buffer;

    // Generate match logic for all TLB entries
    genvar i;
    generate
        for (i = 0; i < TLBNUM; i = i + 1) begin: match
            // Match logic for search ports
            assign match0[i] = tlb_e[i] &&
                   ((tlb_ps[i] == 6'd12) ? s0_vppn == tlb_vppn[i] : s0_vppn[18:9] == tlb_vppn[i][18:9]) &&
                   ((s0_asid == tlb_asid[i]) || tlb_g[i]);

            assign match1[i] = tlb_e[i] &&
                   ((tlb_ps[i] == 6'd12) ? s1_vppn == tlb_vppn[i] : s1_vppn[18:9] == tlb_vppn[i][18:9]) &&
                   ((s1_asid == tlb_asid[i]) || tlb_g[i]);

            // Odd page buffer logic
            assign s0_odd_page_buffer[i] = (tlb_ps[i] == 6'd12) ? s0_va_bit12 : s0_vppn[8];
            assign s1_odd_page_buffer[i] = (tlb_ps[i] == 6'd12) ? s1_va_bit12 : s1_vppn[8];
        end
    endgenerate

    // Encoders for match results
    encoder_32_5 en_match0 (.in({{(32-TLBNUM){1'b0}}, match0}), .out(match0_en));
    encoder_32_5 en_match1 (.in({{(32-TLBNUM){1'b0}}, match1}), .out(match1_en));

    // Search port 0 outputs
    assign s0_found = |match0;
    assign s0_index = {{(5-$clog2(TLBNUM)){1'b0}}, match0_en};
    assign s0_ps    = tlb_ps[match0_en];
    assign s0_ppn   = s0_odd_page_buffer[match0_en] ? tlb_ppn1[match0_en] : tlb_ppn0[match0_en];
    assign s0_v     = s0_odd_page_buffer[match0_en] ? tlb_v1[match0_en]   : tlb_v0[match0_en];
    assign s0_d     = s0_odd_page_buffer[match0_en] ? tlb_d1[match0_en]   : tlb_d0[match0_en];
    assign s0_mat   = s0_odd_page_buffer[match0_en] ? tlb_mat1[match0_en] : tlb_mat0[match0_en];
    assign s0_plv   = s0_odd_page_buffer[match0_en] ? tlb_plv1[match0_en] : tlb_plv0[match0_en];

    // Search port 1 outputs
    assign s1_found = |match1;
    assign s1_index = {{(5-$clog2(TLBNUM)){1'b0}}, match1_en};
    assign s1_ps    = tlb_ps[match1_en];
    assign s1_ppn   = s1_odd_page_buffer[match1_en] ? tlb_ppn1[match1_en] : tlb_ppn0[match1_en];
    assign s1_v     = s1_odd_page_buffer[match1_en] ? tlb_v1[match1_en]   : tlb_v0[match1_en];
    assign s1_d     = s1_odd_page_buffer[match1_en] ? tlb_d1[match1_en]   : tlb_d0[match1_en];
    assign s1_mat   = s1_odd_page_buffer[match1_en] ? tlb_mat1[match1_en] : tlb_mat0[match1_en];
    assign s1_plv   = s1_odd_page_buffer[match1_en] ? tlb_plv1[match1_en] : tlb_plv0[match1_en];

    // Write port logic
    always @(posedge clk) begin
        if (we) begin
            tlb_vppn[w_index] <= w_vppn;
            tlb_asid[w_index] <= w_asid;
            tlb_g[w_index]   <= w_g;
            tlb_ps[w_index]  <= w_ps;
            tlb_ppn0[w_index] <= w_ppn0;
            tlb_plv0[w_index] <= w_plv0;
            tlb_mat0[w_index] <= w_mat0;
            tlb_d0[w_index]   <= w_d0;
            tlb_v0[w_index]   <= w_v0;
            tlb_ppn1[w_index] <= w_ppn1;
            tlb_plv1[w_index] <= w_plv1;
            tlb_mat1[w_index] <= w_mat1;
            tlb_d1[w_index]  <= w_d1;
            tlb_v1[w_index]   <= w_v1;
        end
    end

    // Read port outputs
    assign r_vppn = tlb_vppn[r_index];
    assign r_asid = tlb_asid[r_index];
    assign r_g    = tlb_g[r_index];
    assign r_ps   = tlb_ps[r_index];
    assign r_e    = tlb_e[r_index];
    assign r_v0   = tlb_v0[r_index];
    assign r_d0   = tlb_d0[r_index];
    assign r_mat0 = tlb_mat0[r_index];
    assign r_plv0 = tlb_plv0[r_index];
    assign r_ppn0 = tlb_ppn0[r_index];
    assign r_v1   = tlb_v1[r_index];
    assign r_d1   = tlb_d1[r_index];
    assign r_mat1 = tlb_mat1[r_index];
    assign r_plv1 = tlb_plv1[r_index];
    assign r_ppn1 = tlb_ppn1[r_index];

    // TLB entry invalidation logic
    generate
        for (i = 0; i < TLBNUM; i = i + 1) begin: invalid_tlb_entry
            always @(posedge clk) begin
                if (we && (w_index == i)) begin
                    tlb_e[i] <= w_e;
                end
                else if (invtlb_valid) begin
                    case (invtlb_op)
                        5'd0, 5'd1:
                            tlb_e[i] <= 1'b0;
                        5'd2:
                            if (tlb_g[i])
                                tlb_e[i] <= 1'b0;
                        5'd3:
                            if (!tlb_g[i])
                                tlb_e[i] <= 1'b0;
                        5'd4:
                            if (!tlb_g[i] && (tlb_asid[i] == invtlb_asid))
                                tlb_e[i] <= 1'b0;
                        5'd5:
                            if (!tlb_g[i] && (tlb_asid[i] == invtlb_asid) &&
                                    ((tlb_ps[i] == 6'd12) ? (tlb_vppn[i] == invtlb_vpn) :
                                     (tlb_vppn[i][18:9] == invtlb_vpn[18:9])))
                                tlb_e[i] <= 1'b0;
                        5'd6:
                            if ((tlb_g[i] || (tlb_asid[i] == invtlb_asid)) &&
                                    ((tlb_ps[i] == 6'd12) ? (tlb_vppn[i] == invtlb_vpn) :
                                     (tlb_vppn[i][18:9] == invtlb_vpn[18:9])))
                                tlb_e[i] <= 1'b0;
                        default :begin
                        end
                    endcase
                end
            end
        end
    endgenerate

endmodule
