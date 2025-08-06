module CS_Adder64(
    input clk,
    input reset,
    input reqst,
    input  [63:0] a,
    input  [63:0] b,
    input         cin,
    output reg [63:0] sum,
    output reg cout,
    output reg done
);

    // Generate and propagate signals for each stage
    wire [63:0] g0, p0;
    wire [63:0] g1, p1;
    wire [63:0] g2, p2;
    wire [63:0] g3, p3;
    wire [63:0] g4, p4;
    wire [63:0] g5, p5;
    wire [63:0] g6, p6;
    wire c1;

    // Stage 0: initial generate and propagate
    assign g0 = a & b;
    assign p0 = a ^ b;

    // Carry from bit 0 including cin, and sum bit 0
    assign c1    = g0[0] | (p0[0] & cin);
    

    // Stage 1: prefix with distance 1
    assign g1[0] = c1;
    assign p1[0] = 1'b0;
    assign g1[1] = g0[1] | (p0[1] & c1);
    assign p1[1] = 1'b0;
    assign g1[2] = g0[2] | (p0[2] & g0[1]);
    assign p1[2] = p0[2] & p0[1];
    assign g1[3] = g0[3] | (p0[3] & g0[2]);
    assign p1[3] = p0[3] & p0[2];
    assign g1[4] = g0[4] | (p0[4] & g0[3]);
    assign p1[4] = p0[4] & p0[3];
    assign g1[5] = g0[5] | (p0[5] & g0[4]);
    assign p1[5] = p0[5] & p0[4];
    assign g1[6] = g0[6] | (p0[6] & g0[5]);
    assign p1[6] = p0[6] & p0[5];
    assign g1[7] = g0[7] | (p0[7] & g0[6]);
    assign p1[7] = p0[7] & p0[6];
    assign g1[8] = g0[8] | (p0[8] & g0[7]);
    assign p1[8] = p0[8] & p0[7];
    assign g1[9] = g0[9] | (p0[9] & g0[8]);
    assign p1[9] = p0[9] & p0[8];
    assign g1[10] = g0[10] | (p0[10] & g0[9]);
    assign p1[10] = p0[10] & p0[9];
    assign g1[11] = g0[11] | (p0[11] & g0[10]);
    assign p1[11] = p0[11] & p0[10];
    assign g1[12] = g0[12] | (p0[12] & g0[11]);
    assign p1[12] = p0[12] & p0[11];
    assign g1[13] = g0[13] | (p0[13] & g0[12]);
    assign p1[13] = p0[13] & p0[12];
    assign g1[14] = g0[14] | (p0[14] & g0[13]);
    assign p1[14] = p0[14] & p0[13];
    assign g1[15] = g0[15] | (p0[15] & g0[14]);
    assign p1[15] = p0[15] & p0[14];
    assign g1[16] = g0[16] | (p0[16] & g0[15]);
    assign p1[16] = p0[16] & p0[15];
    assign g1[17] = g0[17] | (p0[17] & g0[16]);
    assign p1[17] = p0[17] & p0[16];
    assign g1[18] = g0[18] | (p0[18] & g0[17]);
    assign p1[18] = p0[18] & p0[17];
    assign g1[19] = g0[19] | (p0[19] & g0[18]);
    assign p1[19] = p0[19] & p0[18];
    assign g1[20] = g0[20] | (p0[20] & g0[19]);
    assign p1[20] = p0[20] & p0[19];
    assign g1[21] = g0[21] | (p0[21] & g0[20]);
    assign p1[21] = p0[21] & p0[20];
    assign g1[22] = g0[22] | (p0[22] & g0[21]);
    assign p1[22] = p0[22] & p0[21];
    assign g1[23] = g0[23] | (p0[23] & g0[22]);
    assign p1[23] = p0[23] & p0[22];
    assign g1[24] = g0[24] | (p0[24] & g0[23]);
    assign p1[24] = p0[24] & p0[23];
    assign g1[25] = g0[25] | (p0[25] & g0[24]);
    assign p1[25] = p0[25] & p0[24];
    assign g1[26] = g0[26] | (p0[26] & g0[25]);
    assign p1[26] = p0[26] & p0[25];
    assign g1[27] = g0[27] | (p0[27] & g0[26]);
    assign p1[27] = p0[27] & p0[26];
    assign g1[28] = g0[28] | (p0[28] & g0[27]);
    assign p1[28] = p0[28] & p0[27];
    assign g1[29] = g0[29] | (p0[29] & g0[28]);
    assign p1[29] = p0[29] & p0[28];
    assign g1[30] = g0[30] | (p0[30] & g0[29]);
    assign p1[30] = p0[30] & p0[29];
    assign g1[31] = g0[31] | (p0[31] & g0[30]);
    assign p1[31] = p0[31] & p0[30];
    assign g1[32] = g0[32] | (p0[32] & g0[31]);
    assign p1[32] = p0[32] & p0[31];
    assign g1[33] = g0[33] | (p0[33] & g0[32]);
    assign p1[33] = p0[33] & p0[32];
    assign g1[34] = g0[34] | (p0[34] & g0[33]);
    assign p1[34] = p0[34] & p0[33];
    assign g1[35] = g0[35] | (p0[35] & g0[34]);
    assign p1[35] = p0[35] & p0[34];
    assign g1[36] = g0[36] | (p0[36] & g0[35]);
    assign p1[36] = p0[36] & p0[35];
    assign g1[37] = g0[37] | (p0[37] & g0[36]);
    assign p1[37] = p0[37] & p0[36];
    assign g1[38] = g0[38] | (p0[38] & g0[37]);
    assign p1[38] = p0[38] & p0[37];
    assign g1[39] = g0[39] | (p0[39] & g0[38]);
    assign p1[39] = p0[39] & p0[38];
    assign g1[40] = g0[40] | (p0[40] & g0[39]);
    assign p1[40] = p0[40] & p0[39];
    assign g1[41] = g0[41] | (p0[41] & g0[40]);
    assign p1[41] = p0[41] & p0[40];
    assign g1[42] = g0[42] | (p0[42] & g0[41]);
    assign p1[42] = p0[42] & p0[41];
    assign g1[43] = g0[43] | (p0[43] & g0[42]);
    assign p1[43] = p0[43] & p0[42];
    assign g1[44] = g0[44] | (p0[44] & g0[43]);
    assign p1[44] = p0[44] & p0[43];
    assign g1[45] = g0[45] | (p0[45] & g0[44]);
    assign p1[45] = p0[45] & p0[44];
    assign g1[46] = g0[46] | (p0[46] & g0[45]);
    assign p1[46] = p0[46] & p0[45];
    assign g1[47] = g0[47] | (p0[47] & g0[46]);
    assign p1[47] = p0[47] & p0[46];
    assign g1[48] = g0[48] | (p0[48] & g0[47]);
    assign p1[48] = p0[48] & p0[47];
    assign g1[49] = g0[49] | (p0[49] & g0[48]);
    assign p1[49] = p0[49] & p0[48];
    assign g1[50] = g0[50] | (p0[50] & g0[49]);
    assign p1[50] = p0[50] & p0[49];
    assign g1[51] = g0[51] | (p0[51] & g0[50]);
    assign p1[51] = p0[51] & p0[50];
    assign g1[52] = g0[52] | (p0[52] & g0[51]);
    assign p1[52] = p0[52] & p0[51];
    assign g1[53] = g0[53] | (p0[53] & g0[52]);
    assign p1[53] = p0[53] & p0[52];
    assign g1[54] = g0[54] | (p0[54] & g0[53]);
    assign p1[54] = p0[54] & p0[53];
    assign g1[55] = g0[55] | (p0[55] & g0[54]);
    assign p1[55] = p0[55] & p0[54];
    assign g1[56] = g0[56] | (p0[56] & g0[55]);
    assign p1[56] = p0[56] & p0[55];
    assign g1[57] = g0[57] | (p0[57] & g0[56]);
    assign p1[57] = p0[57] & p0[56];
    assign g1[58] = g0[58] | (p0[58] & g0[57]);
    assign p1[58] = p0[58] & p0[57];
    assign g1[59] = g0[59] | (p0[59] & g0[58]);
    assign p1[59] = p0[59] & p0[58];
    assign g1[60] = g0[60] | (p0[60] & g0[59]);
    assign p1[60] = p0[60] & p0[59];
    assign g1[61] = g0[61] | (p0[61] & g0[60]);
    assign p1[61] = p0[61] & p0[60];
    assign g1[62] = g0[62] | (p0[62] & g0[61]);
    assign p1[62] = p0[62] & p0[61];
    assign g1[63] = g0[63] | (p0[63] & g0[62]);
    assign p1[63] = p0[63] & p0[62];
    

    reg done0;
    reg state_done0;  // 1位状态寄存器
    reg [63:0] g1_, p1_;
    always @(posedge clk or posedge reset) begin
    if (reset) begin
	g1_<=64'b0;p1_<=64'b0;
        done0    <= 1'b0;
        state_done0 <= 1'b0;
    end else begin
	 case (state_done0)
            1'b0: begin
                if (reqst) begin
    			g1_<=g1;
			p1_<=p1;
			done0 <= 1'b1;
                        state_done0 <= 1'b1;
		end else begin
                    done0 <= 1'b0;
                end
            end
            1'b1: begin
                done0 <= 1'b0;
	    if (!reqst) begin
                  state_done0 <= 1'b0;
            end
            end
        endcase
    end
end

    // Stage 2: prefix with distance 2
    assign g2[0] = g1_[0];
    assign p2[0] = p1_[0];
    assign g2[1] = g1_[1];
    assign p2[1] = p1_[1];
    assign g2[2] = g1_[2] | (p1_[2] & g1_[0]);
    assign p2[2] = p1_[2] & p1_[0];
    assign g2[3] = g1_[3] | (p1_[3] & g1_[1]);
    assign p2[3] = p1_[3] & p1_[1];
    assign g2[4] = g1_[4] | (p1_[4] & g1_[2]);
    assign p2[4] = p1_[4] & p1_[2];
    assign g2[5] = g1_[5] | (p1_[5] & g1_[3]);
    assign p2[5] = p1_[5] & p1_[3];
    assign g2[6] = g1_[6] | (p1_[6] & g1_[4]);
    assign p2[6] = p1_[6] & p1_[4];
    assign g2[7] = g1_[7] | (p1_[7] & g1_[5]);
    assign p2[7] = p1_[7] & p1_[5];
    assign g2[8] = g1_[8] | (p1_[8] & g1_[6]);
    assign p2[8] = p1_[8] & p1_[6];
    assign g2[9] = g1_[9] | (p1_[9] & g1_[7]);
    assign p2[9] = p1_[9] & p1_[7];
    assign g2[10] = g1_[10] | (p1_[10] & g1_[8]);
    assign p2[10] = p1_[10] & p1_[8];
    assign g2[11] = g1_[11] | (p1_[11] & g1_[9]);
    assign p2[11] = p1_[11] & p1_[9];
    assign g2[12] = g1_[12] | (p1_[12] & g1_[10]);
    assign p2[12] = p1_[12] & p1_[10];
    assign g2[13] = g1_[13] | (p1_[13] & g1_[11]);
    assign p2[13] = p1_[13] & p1_[11];
    assign g2[14] = g1_[14] | (p1_[14] & g1_[12]);
    assign p2[14] = p1_[14] & p1_[12];
    assign g2[15] = g1_[15] | (p1_[15] & g1_[13]);
    assign p2[15] = p1_[15] & p1_[13];
    assign g2[16] = g1_[16] | (p1_[16] & g1_[14]);
    assign p2[16] = p1_[16] & p1_[14];
    assign g2[17] = g1_[17] | (p1_[17] & g1_[15]);
    assign p2[17] = p1_[17] & p1_[15];
    assign g2[18] = g1_[18] | (p1_[18] & g1_[16]);
    assign p2[18] = p1_[18] & p1_[16];
    assign g2[19] = g1_[19] | (p1_[19] & g1_[17]);
    assign p2[19] = p1_[19] & p1_[17];
    assign g2[20] = g1_[20] | (p1_[20] & g1_[18]);
    assign p2[20] = p1_[20] & p1_[18];
    assign g2[21] = g1_[21] | (p1_[21] & g1_[19]);
    assign p2[21] = p1_[21] & p1_[19];
    assign g2[22] = g1_[22] | (p1_[22] & g1_[20]);
    assign p2[22] = p1_[22] & p1_[20];
    assign g2[23] = g1_[23] | (p1_[23] & g1_[21]);
    assign p2[23] = p1_[23] & p1_[21];
    assign g2[24] = g1_[24] | (p1_[24] & g1_[22]);
    assign p2[24] = p1_[24] & p1_[22];
    assign g2[25] = g1_[25] | (p1_[25] & g1_[23]);
    assign p2[25] = p1_[25] & p1_[23];
    assign g2[26] = g1_[26] | (p1_[26] & g1_[24]);
    assign p2[26] = p1_[26] & p1_[24];
    assign g2[27] = g1_[27] | (p1_[27] & g1_[25]);
    assign p2[27] = p1_[27] & p1_[25];
    assign g2[28] = g1_[28] | (p1_[28] & g1_[26]);
    assign p2[28] = p1_[28] & p1_[26];
    assign g2[29] = g1_[29] | (p1_[29] & g1_[27]);
    assign p2[29] = p1_[29] & p1_[27];
    assign g2[30] = g1_[30] | (p1_[30] & g1_[28]);
    assign p2[30] = p1_[30] & p1_[28];
    assign g2[31] = g1_[31] | (p1_[31] & g1_[29]);
    assign p2[31] = p1_[31] & p1_[29];
    assign g2[32] = g1_[32] | (p1_[32] & g1_[30]);
    assign p2[32] = p1_[32] & p1_[30];
    assign g2[33] = g1_[33] | (p1_[33] & g1_[31]);
    assign p2[33] = p1_[33] & p1_[31];
    assign g2[34] = g1_[34] | (p1_[34] & g1_[32]);
    assign p2[34] = p1_[34] & p1_[32];
    assign g2[35] = g1_[35] | (p1_[35] & g1_[33]);
    assign p2[35] = p1_[35] & p1_[33];
    assign g2[36] = g1_[36] | (p1_[36] & g1_[34]);
    assign p2[36] = p1_[36] & p1_[34];
    assign g2[37] = g1_[37] | (p1_[37] & g1_[35]);
    assign p2[37] = p1_[37] & p1_[35];
    assign g2[38] = g1_[38] | (p1_[38] & g1_[36]);
    assign p2[38] = p1_[38] & p1_[36];
    assign g2[39] = g1_[39] | (p1_[39] & g1_[37]);
    assign p2[39] = p1_[39] & p1_[37];
    assign g2[40] = g1_[40] | (p1_[40] & g1_[38]);
    assign p2[40] = p1_[40] & p1_[38];
    assign g2[41] = g1_[41] | (p1_[41] & g1_[39]);
    assign p2[41] = p1_[41] & p1_[39];
    assign g2[42] = g1_[42] | (p1_[42] & g1_[40]);
    assign p2[42] = p1_[42] & p1_[40];
    assign g2[43] = g1_[43] | (p1_[43] & g1_[41]);
    assign p2[43] = p1_[43] & p1_[41];
    assign g2[44] = g1_[44] | (p1_[44] & g1_[42]);
    assign p2[44] = p1_[44] & p1_[42];
    assign g2[45] = g1_[45] | (p1_[45] & g1_[43]);
    assign p2[45] = p1_[45] & p1_[43];
    assign g2[46] = g1_[46] | (p1_[46] & g1_[44]);
    assign p2[46] = p1_[46] & p1_[44];
    assign g2[47] = g1_[47] | (p1_[47] & g1_[45]);
    assign p2[47] = p1_[47] & p1_[45];
    assign g2[48] = g1_[48] | (p1_[48] & g1_[46]);
    assign p2[48] = p1_[48] & p1_[46];
    assign g2[49] = g1_[49] | (p1_[49] & g1_[47]);
    assign p2[49] = p1_[49] & p1_[47];
    assign g2[50] = g1_[50] | (p1_[50] & g1_[48]);
    assign p2[50] = p1_[50] & p1_[48];
    assign g2[51] = g1_[51] | (p1_[51] & g1_[49]);
    assign p2[51] = p1_[51] & p1_[49];
    assign g2[52] = g1_[52] | (p1_[52] & g1_[50]);
    assign p2[52] = p1_[52] & p1_[50];
    assign g2[53] = g1_[53] | (p1_[53] & g1_[51]);
    assign p2[53] = p1_[53] & p1_[51];
    assign g2[54] = g1_[54] | (p1_[54] & g1_[52]);
    assign p2[54] = p1_[54] & p1_[52];
    assign g2[55] = g1_[55] | (p1_[55] & g1_[53]);
    assign p2[55] = p1_[55] & p1_[53];
    assign g2[56] = g1_[56] | (p1_[56] & g1_[54]);
    assign p2[56] = p1_[56] & p1_[54];
    assign g2[57] = g1_[57] | (p1_[57] & g1_[55]);
    assign p2[57] = p1_[57] & p1_[55];
    assign g2[58] = g1_[58] | (p1_[58] & g1_[56]);
    assign p2[58] = p1_[58] & p1_[56];
    assign g2[59] = g1_[59] | (p1_[59] & g1_[57]);
    assign p2[59] = p1_[59] & p1_[57];
    assign g2[60] = g1_[60] | (p1_[60] & g1_[58]);
    assign p2[60] = p1_[60] & p1_[58];
    assign g2[61] = g1_[61] | (p1_[61] & g1_[59]);
    assign p2[61] = p1_[61] & p1_[59];
    assign g2[62] = g1_[62] | (p1_[62] & g1_[60]);
    assign p2[62] = p1_[62] & p1_[60];
    assign g2[63] = g1_[63] | (p1_[63] & g1_[61]);
    assign p2[63] = p1_[63] & p1_[61];


reg done1;
reg state_done1;
reg [63:0] g2_, p2_;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        g2_ <= 64'b0;
        p2_ <= 64'b0;
        done1 <= 1'b0;
        state_done1 <= 1'b0;
    end else begin
        case (state_done1)
            1'b0: begin
                if (done0) begin  // 例如：if (done0) 或 if (start)
                    g2_ <= g2;
                    p2_ <= p2;
                    done1 <= 1'b1;
                    state_done1 <= 1'b1;
                end else begin
                    done1 <= 1'b0;
                end
            end
            1'b1: begin
                done1 <= 1'b0;
                if (!done0) begin  // 等待条件释放
                    state_done1 <= 1'b0;
                end
            end
        endcase
    end
end

    // Stage 3: prefix with distance 4
    assign g3[0] = g2_[0];
    assign p3[0] = p2_[0];
    assign g3[1] = g2_[1];
    assign p3[1] = p2_[1];
    assign g3[2] = g2_[2];
    assign p3[2] = p2_[2];
    assign g3[3] = g2_[3];
    assign p3[3] = p2_[3];
    assign g3[4] = g2_[4] | (p2_[4] & g2_[0]);
    assign p3[4] = p2_[4] & p2_[0];
    assign g3[5] = g2_[5] | (p2_[5] & g2_[1]);
    assign p3[5] = p2_[5] & p2_[1];
    assign g3[6] = g2_[6] | (p2_[6] & g2_[2]);
    assign p3[6] = p2_[6] & p2_[2];
    assign g3[7] = g2_[7] | (p2_[7] & g2_[3]);
    assign p3[7] = p2_[7] & p2_[3];
    assign g3[8] = g2_[8] | (p2_[8] & g2_[4]);
    assign p3[8] = p2_[8] & p2_[4];
    assign g3[9] = g2_[9] | (p2_[9] & g2_[5]);
    assign p3[9] = p2_[9] & p2_[5];
    assign g3[10] = g2_[10] | (p2_[10] & g2_[6]);
    assign p3[10] = p2_[10] & p2_[6];
    assign g3[11] = g2_[11] | (p2_[11] & g2_[7]);
    assign p3[11] = p2_[11] & p2_[7];
    assign g3[12] = g2_[12] | (p2_[12] & g2_[8]);
    assign p3[12] = p2_[12] & p2_[8];
    assign g3[13] = g2_[13] | (p2_[13] & g2_[9]);
    assign p3[13] = p2_[13] & p2_[9];
    assign g3[14] = g2_[14] | (p2_[14] & g2_[10]);
    assign p3[14] = p2_[14] & p2_[10];
    assign g3[15] = g2_[15] | (p2_[15] & g2_[11]);
    assign p3[15] = p2_[15] & p2_[11];
    assign g3[16] = g2_[16] | (p2_[16] & g2_[12]);
    assign p3[16] = p2_[16] & p2_[12];
    assign g3[17] = g2_[17] | (p2_[17] & g2_[13]);
    assign p3[17] = p2_[17] & p2_[13];
    assign g3[18] = g2_[18] | (p2_[18] & g2_[14]);
    assign p3[18] = p2_[18] & p2_[14];
    assign g3[19] = g2_[19] | (p2_[19] & g2_[15]);
    assign p3[19] = p2_[19] & p2_[15];
    assign g3[20] = g2_[20] | (p2_[20] & g2_[16]);
    assign p3[20] = p2_[20] & p2_[16];
    assign g3[21] = g2_[21] | (p2_[21] & g2_[17]);
    assign p3[21] = p2_[21] & p2_[17];
    assign g3[22] = g2_[22] | (p2_[22] & g2_[18]);
    assign p3[22] = p2_[22] & p2_[18];
    assign g3[23] = g2_[23] | (p2_[23] & g2_[19]);
    assign p3[23] = p2_[23] & p2_[19];
    assign g3[24] = g2_[24] | (p2_[24] & g2_[20]);
    assign p3[24] = p2_[24] & p2_[20];
    assign g3[25] = g2_[25] | (p2_[25] & g2_[21]);
    assign p3[25] = p2_[25] & p2_[21];
    assign g3[26] = g2_[26] | (p2_[26] & g2_[22]);
    assign p3[26] = p2_[26] & p2_[22];
    assign g3[27] = g2_[27] | (p2_[27] & g2_[23]);
    assign p3[27] = p2_[27] & p2_[23];
    assign g3[28] = g2_[28] | (p2_[28] & g2_[24]);
    assign p3[28] = p2_[28] & p2_[24];
    assign g3[29] = g2_[29] | (p2_[29] & g2_[25]);
    assign p3[29] = p2_[29] & p2_[25];
    assign g3[30] = g2_[30] | (p2_[30] & g2_[26]);
    assign p3[30] = p2_[30] & p2_[26];
    assign g3[31] = g2_[31] | (p2_[31] & g2_[27]);
    assign p3[31] = p2_[31] & p2_[27];
    assign g3[32] = g2_[32] | (p2_[32] & g2_[28]);
    assign p3[32] = p2_[32] & p2_[28];
    assign g3[33] = g2_[33] | (p2_[33] & g2_[29]);
    assign p3[33] = p2_[33] & p2_[29];
    assign g3[34] = g2_[34] | (p2_[34] & g2_[30]);
    assign p3[34] = p2_[34] & p2_[30];
    assign g3[35] = g2_[35] | (p2_[35] & g2_[31]);
    assign p3[35] = p2_[35] & p2_[31];
    assign g3[36] = g2_[36] | (p2_[36] & g2_[32]);
    assign p3[36] = p2_[36] & p2_[32];
    assign g3[37] = g2_[37] | (p2_[37] & g2_[33]);
    assign p3[37] = p2_[37] & p2_[33];
    assign g3[38] = g2_[38] | (p2_[38] & g2_[34]);
    assign p3[38] = p2_[38] & p2_[34];
    assign g3[39] = g2_[39] | (p2_[39] & g2_[35]);
    assign p3[39] = p2_[39] & p2_[35];
    assign g3[40] = g2_[40] | (p2_[40] & g2_[36]);
    assign p3[40] = p2_[40] & p2_[36];
    assign g3[41] = g2_[41] | (p2_[41] & g2_[37]);
    assign p3[41] = p2_[41] & p2_[37];
    assign g3[42] = g2_[42] | (p2_[42] & g2_[38]);
    assign p3[42] = p2_[42] & p2_[38];
    assign g3[43] = g2_[43] | (p2_[43] & g2_[39]);
    assign p3[43] = p2_[43] & p2_[39];
    assign g3[44] = g2_[44] | (p2_[44] & g2_[40]);
    assign p3[44] = p2_[44] & p2_[40];
    assign g3[45] = g2_[45] | (p2_[45] & g2_[41]);
    assign p3[45] = p2_[45] & p2_[41];
    assign g3[46] = g2_[46] | (p2_[46] & g2_[42]);
    assign p3[46] = p2_[46] & p2_[42];
    assign g3[47] = g2_[47] | (p2_[47] & g2_[43]);
    assign p3[47] = p2_[47] & p2_[43];
    assign g3[48] = g2_[48] | (p2_[48] & g2_[44]);
    assign p3[48] = p2_[48] & p2_[44];
    assign g3[49] = g2_[49] | (p2_[49] & g2_[45]);
    assign p3[49] = p2_[49] & p2_[45];
    assign g3[50] = g2_[50] | (p2_[50] & g2_[46]);
    assign p3[50] = p2_[50] & p2_[46];
    assign g3[51] = g2_[51] | (p2_[51] & g2_[47]);
    assign p3[51] = p2_[51] & p2_[47];
    assign g3[52] = g2_[52] | (p2_[52] & g2_[48]);
    assign p3[52] = p2_[52] & p2_[48];
    assign g3[53] = g2_[53] | (p2_[53] & g2_[49]);
    assign p3[53] = p2_[53] & p2_[49];
    assign g3[54] = g2_[54] | (p2_[54] & g2_[50]);
    assign p3[54] = p2_[54] & p2_[50];
    assign g3[55] = g2_[55] | (p2_[55] & g2_[51]);
    assign p3[55] = p2_[55] & p2_[51];
    assign g3[56] = g2_[56] | (p2_[56] & g2_[52]);
    assign p3[56] = p2_[56] & p2_[52];
    assign g3[57] = g2_[57] | (p2_[57] & g2_[53]);
    assign p3[57] = p2_[57] & p2_[53];
    assign g3[58] = g2_[58] | (p2_[58] & g2_[54]);
    assign p3[58] = p2_[58] & p2_[54];
    assign g3[59] = g2_[59] | (p2_[59] & g2_[55]);
    assign p3[59] = p2_[59] & p2_[55];
    assign g3[60] = g2_[60] | (p2_[60] & g2_[56]);
    assign p3[60] = p2_[60] & p2_[56];
    assign g3[61] = g2_[61] | (p2_[61] & g2_[57]);
    assign p3[61] = p2_[61] & p2_[57];
    assign g3[62] = g2_[62] | (p2_[62] & g2_[58]);
    assign p3[62] = p2_[62] & p2_[58];
    assign g3[63] = g2_[63] | (p2_[63] & g2_[59]);
    assign p3[63] = p2_[63] & p2_[59];


    reg done2;
    reg state_done2;
    reg [63:0] g3_, p3_;


always @(posedge clk or posedge reset) begin
    if (reset) begin
        g3_ <= 64'b0;
        p3_ <= 64'b0;
        done2 <= 1'b0;
        state_done2 <= 1'b0;
    end else begin
        case (state_done2)
            1'b0: begin
                if (done1) begin
                    g3_ <= g3;
                    p3_ <= p3;
                    done2 <= 1'b1;
                    state_done2 <= 1'b1;
                end else begin
                    done2 <= 1'b0;
                end
            end
            1'b1: begin
                done2 <= 1'b0;
                if (!done1) begin
                    state_done2 <= 1'b0;
                end
            end
        endcase
    end
end



    // Stage 4: prefix with distance 8
    assign g4[0] = g3_[0];
    assign p4[0] = p3_[0];
    assign g4[1] = g3_[1];
    assign p4[1] = p3_[1];
    assign g4[2] = g3_[2];
    assign p4[2] = p3_[2];
    assign g4[3] = g3_[3];
    assign p4[3] = p3_[3];
    assign g4[4] = g3_[4];
    assign p4[4] = p3_[4];
    assign g4[5] = g3_[5];
    assign p4[5] = p3_[5];
    assign g4[6] = g3_[6];
    assign p4[6] = p3_[6];
    assign g4[7] = g3_[7];
    assign p4[7] = p3_[7];
    assign g4[8] = g3_[8] | (p3_[8] & g3_[0]);
    assign p4[8] = p3_[8] & p3_[0];
    assign g4[9] = g3_[9] | (p3_[9] & g3_[1]);
    assign p4[9] = p3_[9] & p3_[1];
    assign g4[10] = g3_[10] | (p3_[10] & g3_[2]);
    assign p4[10] = p3_[10] & p3_[2];
    assign g4[11] = g3_[11] | (p3_[11] & g3_[3]);
    assign p4[11] = p3_[11] & p3_[3];
    assign g4[12] = g3_[12] | (p3_[12] & g3_[4]);
    assign p4[12] = p3_[12] & p3_[4];
    assign g4[13] = g3_[13] | (p3_[13] & g3_[5]);
    assign p4[13] = p3_[13] & p3_[5];
    assign g4[14] = g3_[14] | (p3_[14] & g3_[6]);
    assign p4[14] = p3_[14] & p3_[6];
    assign g4[15] = g3_[15] | (p3_[15] & g3_[7]);
    assign p4[15] = p3_[15] & p3_[7];
    assign g4[16] = g3_[16] | (p3_[16] & g3_[8]);
    assign p4[16] = p3_[16] & p3_[8];
    assign g4[17] = g3_[17] | (p3_[17] & g3_[9]);
    assign p4[17] = p3_[17] & p3_[9];
    assign g4[18] = g3_[18] | (p3_[18] & g3_[10]);
    assign p4[18] = p3_[18] & p3_[10];
    assign g4[19] = g3_[19] | (p3_[19] & g3_[11]);
    assign p4[19] = p3_[19] & p3_[11];
    assign g4[20] = g3_[20] | (p3_[20] & g3_[12]);
    assign p4[20] = p3_[20] & p3_[12];
    assign g4[21] = g3_[21] | (p3_[21] & g3_[13]);
    assign p4[21] = p3_[21] & p3_[13];
    assign g4[22] = g3_[22] | (p3_[22] & g3_[14]);
    assign p4[22] = p3_[22] & p3_[14];
    assign g4[23] = g3_[23] | (p3_[23] & g3_[15]);
    assign p4[23] = p3_[23] & p3_[15];
    assign g4[24] = g3_[24] | (p3_[24] & g3_[16]);
    assign p4[24] = p3_[24] & p3_[16];
    assign g4[25] = g3_[25] | (p3_[25] & g3_[17]);
    assign p4[25] = p3_[25] & p3_[17];
    assign g4[26] = g3_[26] | (p3_[26] & g3_[18]);
    assign p4[26] = p3_[26] & p3_[18];
    assign g4[27] = g3_[27] | (p3_[27] & g3_[19]);
    assign p4[27] = p3_[27] & p3_[19];
    assign g4[28] = g3_[28] | (p3_[28] & g3_[20]);
    assign p4[28] = p3_[28] & p3_[20];
    assign g4[29] = g3_[29] | (p3_[29] & g3_[21]);
    assign p4[29] = p3_[29] & p3_[21];
    assign g4[30] = g3_[30] | (p3_[30] & g3_[22]);
    assign p4[30] = p3_[30] & p3_[22];
    assign g4[31] = g3_[31] | (p3_[31] & g3_[23]);
    assign p4[31] = p3_[31] & p3_[23];
    assign g4[32] = g3_[32] | (p3_[32] & g3_[24]);
    assign p4[32] = p3_[32] & p3_[24];
    assign g4[33] = g3_[33] | (p3_[33] & g3_[25]);
    assign p4[33] = p3_[33] & p3_[25];
    assign g4[34] = g3_[34] | (p3_[34] & g3_[26]);
    assign p4[34] = p3_[34] & p3_[26];
    assign g4[35] = g3_[35] | (p3_[35] & g3_[27]);
    assign p4[35] = p3_[35] & p3_[27];
    assign g4[36] = g3_[36] | (p3_[36] & g3_[28]);
    assign p4[36] = p3_[36] & p3_[28];
    assign g4[37] = g3_[37] | (p3_[37] & g3_[29]);
    assign p4[37] = p3_[37] & p3_[29];
    assign g4[38] = g3_[38] | (p3_[38] & g3_[30]);
    assign p4[38] = p3_[38] & p3_[30];
    assign g4[39] = g3_[39] | (p3_[39] & g3_[31]);
    assign p4[39] = p3_[39] & p3_[31];
    assign g4[40] = g3_[40] | (p3_[40] & g3_[32]);
    assign p4[40] = p3_[40] & p3_[32];
    assign g4[41] = g3_[41] | (p3_[41] & g3_[33]);
    assign p4[41] = p3_[41] & p3_[33];
    assign g4[42] = g3_[42] | (p3_[42] & g3_[34]);
    assign p4[42] = p3_[42] & p3_[34];
    assign g4[43] = g3_[43] | (p3_[43] & g3_[35]);
    assign p4[43] = p3_[43] & p3_[35];
    assign g4[44] = g3_[44] | (p3_[44] & g3_[36]);
    assign p4[44] = p3_[44] & p3_[36];
    assign g4[45] = g3_[45] | (p3_[45] & g3_[37]);
    assign p4[45] = p3_[45] & p3_[37];
    assign g4[46] = g3_[46] | (p3_[46] & g3_[38]);
    assign p4[46] = p3_[46] & p3_[38];
    assign g4[47] = g3_[47] | (p3_[47] & g3_[39]);
    assign p4[47] = p3_[47] & p3_[39];
    assign g4[48] = g3_[48] | (p3_[48] & g3_[40]);
    assign p4[48] = p3_[48] & p3_[40];
    assign g4[49] = g3_[49] | (p3_[49] & g3_[41]);
    assign p4[49] = p3_[49] & p3_[41];
    assign g4[50] = g3_[50] | (p3_[50] & g3_[42]);
    assign p4[50] = p3_[50] & p3_[42];
    assign g4[51] = g3_[51] | (p3_[51] & g3_[43]);
    assign p4[51] = p3_[51] & p3_[43];
    assign g4[52] = g3_[52] | (p3_[52] & g3_[44]);
    assign p4[52] = p3_[52] & p3_[44];
    assign g4[53] = g3_[53] | (p3_[53] & g3_[45]);
    assign p4[53] = p3_[53] & p3_[45];
    assign g4[54] = g3_[54] | (p3_[54] & g3_[46]);
    assign p4[54] = p3_[54] & p3_[46];
    assign g4[55] = g3_[55] | (p3_[55] & g3_[47]);
    assign p4[55] = p3_[55] & p3_[47];
    assign g4[56] = g3_[56] | (p3_[56] & g3_[48]);
    assign p4[56] = p3_[56] & p3_[48];
    assign g4[57] = g3_[57] | (p3_[57] & g3_[49]);
    assign p4[57] = p3_[57] & p3_[49];
    assign g4[58] = g3_[58] | (p3_[58] & g3_[50]);
    assign p4[58] = p3_[58] & p3_[50];
    assign g4[59] = g3_[59] | (p3_[59] & g3_[51]);
    assign p4[59] = p3_[59] & p3_[51];
    assign g4[60] = g3_[60] | (p3_[60] & g3_[52]);
    assign p4[60] = p3_[60] & p3_[52];
    assign g4[61] = g3_[61] | (p3_[61] & g3_[53]);
    assign p4[61] = p3_[61] & p3_[53];
    assign g4[62] = g3_[62] | (p3_[62] & g3_[54]);
    assign p4[62] = p3_[62] & p3_[54];
    assign g4[63] = g3_[63] | (p3_[63] & g3_[55]);
    assign p4[63] = p3_[63] & p3_[55];




reg done3;
reg state_done3;
reg [63:0] g4_, p4_;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        g4_ <= 64'b0;
        p4_ <= 64'b0;
        done3 <= 1'b0;
        state_done3 <= 1'b0;
    end else begin
        case (state_done3)
            1'b0: begin
                if (done2) begin
                    g4_ <= g4;
                    p4_ <= p4;
                    done3 <= 1'b1;
                    state_done3 <= 1'b1;
                end else begin
                    done3 <= 1'b0;
                end
            end
            1'b1: begin
                done3 <= 1'b0;
                if (!done2) begin
                    state_done3 <= 1'b0;
                end
            end
        endcase
    end
end



    // Stage 5: prefix with distance 16
    assign g5[0] = g4_[0];
    assign p5[0] = p4_[0];
    assign g5[1] = g4_[1];
    assign p5[1] = p4_[1];
    assign g5[2] = g4_[2];
    assign p5[2] = p4_[2];
    assign g5[3] = g4_[3];
    assign p5[3] = p4_[3];
    assign g5[4] = g4_[4];
    assign p5[4] = p4_[4];
    assign g5[5] = g4_[5];
    assign p5[5] = p4_[5];
    assign g5[6] = g4_[6];
    assign p5[6] = p4_[6];
    assign g5[7] = g4_[7];
    assign p5[7] = p4_[7];
    assign g5[8] = g4_[8];
    assign p5[8] = p4_[8];
    assign g5[9] = g4_[9];
    assign p5[9] = p4_[9];
    assign g5[10] = g4_[10];
    assign p5[10] = p4_[10];
    assign g5[11] = g4_[11];
    assign p5[11] = p4_[11];
    assign g5[12] = g4_[12];
    assign p5[12] = p4_[12];
    assign g5[13] = g4_[13];
    assign p5[13] = p4_[13];
    assign g5[14] = g4_[14];
    assign p5[14] = p4_[14];
    assign g5[15] = g4_[15];
    assign p5[15] = p4_[15];
    assign g5[16] = g4_[16] | (p4_[16] & g4_[0]);
    assign p5[16] = p4_[16] & p4_[0];
    assign g5[17] = g4_[17] | (p4_[17] & g4_[1]);
    assign p5[17] = p4_[17] & p4_[1];
    assign g5[18] = g4_[18] | (p4_[18] & g4_[2]);
    assign p5[18] = p4_[18] & p4_[2];
    assign g5[19] = g4_[19] | (p4_[19] & g4_[3]);
    assign p5[19] = p4_[19] & p4_[3];
    assign g5[20] = g4_[20] | (p4_[20] & g4_[4]);
    assign p5[20] = p4_[20] & p4_[4];
    assign g5[21] = g4_[21] | (p4_[21] & g4_[5]);
    assign p5[21] = p4_[21] & p4_[5];
    assign g5[22] = g4_[22] | (p4_[22] & g4_[6]);
    assign p5[22] = p4_[22] & p4_[6];
    assign g5[23] = g4_[23] | (p4_[23] & g4_[7]);
    assign p5[23] = p4_[23] & p4_[7];
    assign g5[24] = g4_[24] | (p4_[24] & g4_[8]);
    assign p5[24] = p4_[24] & p4_[8];
    assign g5[25] = g4_[25] | (p4_[25] & g4_[9]);
    assign p5[25] = p4_[25] & p4_[9];
    assign g5[26] = g4_[26] | (p4_[26] & g4_[10]);
    assign p5[26] = p4_[26] & p4_[10];
    assign g5[27] = g4_[27] | (p4_[27] & g4_[11]);
    assign p5[27] = p4_[27] & p4_[11];
    assign g5[28] = g4_[28] | (p4_[28] & g4_[12]);
    assign p5[28] = p4_[28] & p4_[12];
    assign g5[29] = g4_[29] | (p4_[29] & g4_[13]);
    assign p5[29] = p4_[29] & p4_[13];
    assign g5[30] = g4_[30] | (p4_[30] & g4_[14]);
    assign p5[30] = p4_[30] & p4_[14];
    assign g5[31] = g4_[31] | (p4_[31] & g4_[15]);
    assign p5[31] = p4_[31] & p4_[15];
    assign g5[32] = g4_[32] | (p4_[32] & g4_[16]);
    assign p5[32] = p4_[32] & p4_[16];
    assign g5[33] = g4_[33] | (p4_[33] & g4_[17]);
    assign p5[33] = p4_[33] & p4_[17];
    assign g5[34] = g4_[34] | (p4_[34] & g4_[18]);
    assign p5[34] = p4_[34] & p4_[18];
    assign g5[35] = g4_[35] | (p4_[35] & g4_[19]);
    assign p5[35] = p4_[35] & p4_[19];
    assign g5[36] = g4_[36] | (p4_[36] & g4_[20]);
    assign p5[36] = p4_[36] & p4_[20];
    assign g5[37] = g4_[37] | (p4_[37] & g4_[21]);
    assign p5[37] = p4_[37] & p4_[21];
    assign g5[38] = g4_[38] | (p4_[38] & g4_[22]);
    assign p5[38] = p4_[38] & p4_[22];
    assign g5[39] = g4_[39] | (p4_[39] & g4_[23]);
    assign p5[39] = p4_[39] & p4_[23];
    assign g5[40] = g4_[40] | (p4_[40] & g4_[24]);
    assign p5[40] = p4_[40] & p4_[24];
    assign g5[41] = g4_[41] | (p4_[41] & g4_[25]);
    assign p5[41] = p4_[41] & p4_[25];
    assign g5[42] = g4_[42] | (p4_[42] & g4_[26]);
    assign p5[42] = p4_[42] & p4_[26];
    assign g5[43] = g4_[43] | (p4_[43] & g4_[27]);
    assign p5[43] = p4_[43] & p4_[27];
    assign g5[44] = g4_[44] | (p4_[44] & g4_[28]);
    assign p5[44] = p4_[44] & p4_[28];
    assign g5[45] = g4_[45] | (p4_[45] & g4_[29]);
    assign p5[45] = p4_[45] & p4_[29];
    assign g5[46] = g4_[46] | (p4_[46] & g4_[30]);
    assign p5[46] = p4_[46] & p4_[30];
    assign g5[47] = g4_[47] | (p4_[47] & g4_[31]);
    assign p5[47] = p4_[47] & p4_[31];
    assign g5[48] = g4_[48] | (p4_[48] & g4_[32]);
    assign p5[48] = p4_[48] & p4_[32];
    assign g5[49] = g4_[49] | (p4_[49] & g4_[33]);
    assign p5[49] = p4_[49] & p4_[33];
    assign g5[50] = g4_[50] | (p4_[50] & g4_[34]);
    assign p5[50] = p4_[50] & p4_[34];
    assign g5[51] = g4_[51] | (p4_[51] & g4_[35]);
    assign p5[51] = p4_[51] & p4_[35];
    assign g5[52] = g4_[52] | (p4_[52] & g4_[36]);
    assign p5[52] = p4_[52] & p4_[36];
    assign g5[53] = g4_[53] | (p4_[53] & g4_[37]);
    assign p5[53] = p4_[53] & p4_[37];
    assign g5[54] = g4_[54] | (p4_[54] & g4_[38]);
    assign p5[54] = p4_[54] & p4_[38];
    assign g5[55] = g4_[55] | (p4_[55] & g4_[39]);
    assign p5[55] = p4_[55] & p4_[39];
    assign g5[56] = g4_[56] | (p4_[56] & g4_[40]);
    assign p5[56] = p4_[56] & p4_[40];
    assign g5[57] = g4_[57] | (p4_[57] & g4_[41]);
    assign p5[57] = p4_[57] & p4_[41];
    assign g5[58] = g4_[58] | (p4_[58] & g4_[42]);
    assign p5[58] = p4_[58] & p4_[42];
    assign g5[59] = g4_[59] | (p4_[59] & g4_[43]);
    assign p5[59] = p4_[59] & p4_[43];
    assign g5[60] = g4_[60] | (p4_[60] & g4_[44]);
    assign p5[60] = p4_[60] & p4_[44];
    assign g5[61] = g4_[61] | (p4_[61] & g4_[45]);
    assign p5[61] = p4_[61] & p4_[45];
    assign g5[62] = g4_[62] | (p4_[62] & g4_[46]);
    assign p5[62] = p4_[62] & p4_[46];
    assign g5[63] = g4_[63] | (p4_[63] & g4_[47]);
    assign p5[63] = p4_[63] & p4_[47];


reg done4;
reg state_done4;
reg [63:0] g5_, p5_;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        g5_ <= 64'b0;
        p5_ <= 64'b0;
        done4 <= 1'b0;
        state_done4 <= 1'b0;
    end else begin
        case (state_done4)
            1'b0: begin
                if (done3) begin
                    g5_ <= g5;
                    p5_ <= p5;
                    done4 <= 1'b1;
                    state_done4 <= 1'b1;
                end else begin
                    done4 <= 1'b0;
                end
            end
            1'b1: begin
                done4 <= 1'b0;
                if (!done3) begin
                    state_done4 <= 1'b0;
                end
            end
        endcase
    end
end


   // Stage 6: prefix with distance 32
    assign g6[0] = g5_[0];
    assign p6[0] = p5_[0];
    assign g6[1] = g5_[1];
    assign p6[1] = p5_[1];
    assign g6[2] = g5_[2];
    assign p6[2] = p5_[2];
    assign g6[3] = g5_[3];
    assign p6[3] = p5_[3];
    assign g6[4] = g5_[4];
    assign p6[4] = p5_[4];
    assign g6[5] = g5_[5];
    assign p6[5] = p5_[5];
    assign g6[6] = g5_[6];
    assign p6[6] = p5_[6];
    assign g6[7] = g5_[7];
    assign p6[7] = p5_[7];
    assign g6[8] = g5_[8];
    assign p6[8] = p5_[8];
    assign g6[9] = g5_[9];
    assign p6[9] = p5_[9];
    assign g6[10] = g5_[10];
    assign p6[10] = p5_[10];
    assign g6[11] = g5_[11];
    assign p6[11] = p5_[11];
    assign g6[12] = g5_[12];
    assign p6[12] = p5_[12];
    assign g6[13] = g5_[13];
    assign p6[13] = p5_[13];
    assign g6[14] = g5_[14];
    assign p6[14] = p5_[14];
    assign g6[15] = g5_[15];
    assign p6[15] = p5_[15];
    assign g6[16] = g5_[16];
    assign p6[16] = p5_[16];
    assign g6[17] = g5_[17];
    assign p6[17] = p5_[17];
    assign g6[18] = g5_[18];
    assign p6[18] = p5_[18];
    assign g6[19] = g5_[19];
    assign p6[19] = p5_[19];
    assign g6[20] = g5_[20];
    assign p6[20] = p5_[20];
    assign g6[21] = g5_[21];
    assign p6[21] = p5_[21];
    assign g6[22] = g5_[22];
    assign p6[22] = p5_[22];
    assign g6[23] = g5_[23];
    assign p6[23] = p5_[23];
    assign g6[24] = g5_[24];
    assign p6[24] = p5_[24];
    assign g6[25] = g5_[25];
    assign p6[25] = p5_[25];
    assign g6[26] = g5_[26];
    assign p6[26] = p5_[26];
    assign g6[27] = g5_[27];
    assign p6[27] = p5_[27];
    assign g6[28] = g5_[28];
    assign p6[28] = p5_[28];
    assign g6[29] = g5_[29];
    assign p6[29] = p5_[29];
    assign g6[30] = g5_[30];
    assign p6[30] = p5_[30];
    assign g6[31] = g5_[31];
    assign p6[31] = p5_[31];
    assign g6[32] = g5_[32] | (p5_[32] & g5_[0]);
    assign p6[32] = p5_[32] & p5_[0];
    assign g6[33] = g5_[33] | (p5_[33] & g5_[1]);
    assign p6[33] = p5_[33] & p5_[1];
    assign g6[34] = g5_[34] | (p5_[34] & g5_[2]);
    assign p6[34] = p5_[34] & p5_[2];
    assign g6[35] = g5_[35] | (p5_[35] & g5_[3]);
    assign p6[35] = p5_[35] & p5_[3];
    assign g6[36] = g5_[36] | (p5_[36] & g5_[4]);
    assign p6[36] = p5_[36] & p5_[4];
    assign g6[37] = g5_[37] | (p5_[37] & g5_[5]);
    assign p6[37] = p5_[37] & p5_[5];
    assign g6[38] = g5_[38] | (p5_[38] & g5_[6]);
    assign p6[38] = p5_[38] & p5_[6];
    assign g6[39] = g5_[39] | (p5_[39] & g5_[7]);
    assign p6[39] = p5_[39] & p5_[7];
    assign g6[40] = g5_[40] | (p5_[40] & g5_[8]);
    assign p6[40] = p5_[40] & p5_[8];
    assign g6[41] = g5_[41] | (p5_[41] & g5_[9]);
    assign p6[41] = p5_[41] & p5_[9];
    assign g6[42] = g5_[42] | (p5_[42] & g5_[10]);
    assign p6[42] = p5_[42] & p5_[10];
    assign g6[43] = g5_[43] | (p5_[43] & g5_[11]);
    assign p6[43] = p5_[43] & p5_[11];
    assign g6[44] = g5_[44] | (p5_[44] & g5_[12]);
    assign p6[44] = p5_[44] & p5_[12];
    assign g6[45] = g5_[45] | (p5_[45] & g5_[13]);
    assign p6[45] = p5_[45] & p5_[13];
    assign g6[46] = g5_[46] | (p5_[46] & g5_[14]);
    assign p6[46] = p5_[46] & p5_[14];
    assign g6[47] = g5_[47] | (p5_[47] & g5_[15]);
    assign p6[47] = p5_[47] & p5_[15];
    assign g6[48] = g5_[48] | (p5_[48] & g5_[16]);
    assign p6[48] = p5_[48] & p5_[16];
    assign g6[49] = g5_[49] | (p5_[49] & g5_[17]);
    assign p6[49] = p5_[49] & p5_[17];
    assign g6[50] = g5_[50] | (p5_[50] & g5_[18]);
    assign p6[50] = p5_[50] & p5_[18];
    assign g6[51] = g5_[51] | (p5_[51] & g5_[19]);
    assign p6[51] = p5_[51] & p5_[19];
    assign g6[52] = g5_[52] | (p5_[52] & g5_[20]);
    assign p6[52] = p5_[52] & p5_[20];
    assign g6[53] = g5_[53] | (p5_[53] & g5_[21]);
    assign p6[53] = p5_[53] & p5_[21];
    assign g6[54] = g5_[54] | (p5_[54] & g5_[22]);
    assign p6[54] = p5_[54] & p5_[22];
    assign g6[55] = g5_[55] | (p5_[55] & g5_[23]);
    assign p6[55] = p5_[55] & p5_[23];
    assign g6[56] = g5_[56] | (p5_[56] & g5_[24]);
    assign p6[56] = p5_[56] & p5_[24];
    assign g6[57] = g5_[57] | (p5_[57] & g5_[25]);
    assign p6[57] = p5_[57] & p5_[25];
    assign g6[58] = g5_[58] | (p5_[58] & g5_[26]);
    assign p6[58] = p5_[58] & p5_[26];
    assign g6[59] = g5_[59] | (p5_[59] & g5_[27]);
    assign p6[59] = p5_[59] & p5_[27];
    assign g6[60] = g5_[60] | (p5_[60] & g5_[28]);
    assign p6[60] = p5_[60] & p5_[28];
    assign g6[61] = g5_[61] | (p5_[61] & g5_[29]);
    assign p6[61] = p5_[61] & p5_[29];
    assign g6[62] = g5_[62] | (p5_[62] & g5_[30]);
    assign p6[62] = p5_[62] & p5_[30];
    assign g6[63] = g5_[63] | (p5_[63] & g5_[31]);
    assign p6[63] = p5_[63] & p5_[31];

reg done5;
reg state_done5;
reg [63:0] g6_, p6_;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        g6_ <= 64'b0;
        p6_ <= 64'b0;
        done5 <= 1'b0;
        state_done5 <= 1'b0;
    end else begin
        case (state_done5)
            1'b0: begin
                if (done4) begin
                    g6_ <= g6;
                    p6_ <= p6;
                    done5 <= 1'b1;
                    state_done5 <= 1'b1;
                end else begin
                    done5 <= 1'b0;
                end
            end
            1'b1: begin
                done5 <= 1'b0;
                if (!done4)
                    state_done5 <= 1'b0;
            end
        endcase
    end
end

reg state_done;


// Final sum bits 1 to 63 and carry-out
always @(posedge clk or posedge reset) begin
    if (reset) begin
	sum<=64'b0;
	done<=1'b0;
        state_done<=1'b0;
    end
    else begin
        case(state_done)
	1'b0: begin
     if(done5) begin
     sum[0] <= p0[0] ^ cin;
     sum[1] <= p0[1] ^ g6_[0];
     sum[2] <= p0[2] ^ g6_[1];
     sum[3] <= p0[3] ^ g6_[2];
     sum[4] <= p0[4] ^ g6_[3];
     sum[5] <= p0[5] ^ g6_[4];
     sum[6] <= p0[6] ^ g6_[5];
     sum[7] <= p0[7] ^ g6_[6];
     sum[8] <= p0[8] ^ g6_[7];
     sum[9] <= p0[9] ^ g6_[8];
     sum[10] <= p0[10] ^ g6_[9];
     sum[11] <= p0[11] ^ g6_[10];
     sum[12] <= p0[12] ^ g6_[11];
     sum[13] <= p0[13] ^ g6_[12];
     sum[14] <= p0[14] ^ g6_[13];
     sum[15] <= p0[15] ^ g6_[14];
     sum[16] <= p0[16] ^ g6_[15];
     sum[17] <= p0[17] ^ g6_[16];
     sum[18] <= p0[18] ^ g6_[17];
     sum[19] <= p0[19] ^ g6_[18];
     sum[20] <= p0[20] ^ g6_[19];
     sum[21] <= p0[21] ^ g6_[20];
     sum[22] <= p0[22] ^ g6_[21];
     sum[23] <= p0[23] ^ g6_[22];
     sum[24] <= p0[24] ^ g6_[23];
     sum[25] <= p0[25] ^ g6_[24];
     sum[26] <= p0[26] ^ g6_[25];
     sum[27] <= p0[27] ^ g6_[26];
     sum[28] <= p0[28] ^ g6_[27];
     sum[29] <= p0[29] ^ g6_[28];
     sum[30] <= p0[30] ^ g6_[29];
     sum[31] <= p0[31] ^ g6_[30];
     sum[32] <= p0[32] ^ g6_[31];
     sum[33] <= p0[33] ^ g6_[32];
     sum[34] <= p0[34] ^ g6_[33];
     sum[35] <= p0[35] ^ g6_[34];
     sum[36] <= p0[36] ^ g6_[35];
     sum[37] <= p0[37] ^ g6_[36];
     sum[38] <= p0[38] ^ g6_[37];
     sum[39] <= p0[39] ^ g6_[38];
     sum[40] <= p0[40] ^ g6_[39];
     sum[41] <= p0[41] ^ g6_[40];
     sum[42] <= p0[42] ^ g6_[41];
     sum[43] <= p0[43] ^ g6_[42];
     sum[44] <= p0[44] ^ g6_[43];
     sum[45] <= p0[45] ^ g6_[44];
     sum[46] <= p0[46] ^ g6_[45];
     sum[47] <= p0[47] ^ g6_[46];
     sum[48] <= p0[48] ^ g6_[47];
     sum[49] <= p0[49] ^ g6_[48];
     sum[50] <= p0[50] ^ g6_[49];
     sum[51] <= p0[51] ^ g6_[50];
     sum[52] <= p0[52] ^ g6_[51];
     sum[53] <= p0[53] ^ g6_[52];
     sum[54] <= p0[54] ^ g6_[53];
     sum[55] <= p0[55] ^ g6_[54];
     sum[56] <= p0[56] ^ g6_[55];
     sum[57] <= p0[57] ^ g6_[56];
     sum[58] <= p0[58] ^ g6_[57];
     sum[59] <= p0[59] ^ g6_[58];
     sum[60] <= p0[60] ^ g6_[59];
     sum[61] <= p0[61] ^ g6_[60];
     sum[62] <= p0[62] ^ g6_[61];
     sum[63] <= p0[63] ^ g6_[62];
     cout     <= g6_[63];
     done <=1'b1;
end else begin
     done <=1'b0;
end
end
1'b1: begin
     done <=1'b0;
     if( !done5 )
	   state_done<=1'b0;
end
endcase
    end
end
endmodule
