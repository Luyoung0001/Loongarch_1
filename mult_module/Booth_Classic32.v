///////////////////////////////////////////////////////////////////////////////
//	Description:	The partial products (PP) generator based on the Classic Booth
//					algorithm. This module generates 32 PPs, each one with 32 bits.
//					Both inputs are signed 2's complement.
//
///////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module Booth_Classic32 (
    input  [31:0] M,       // Multiplicand
    input  [31:0] R,       // Multiplier

    output [31:0] pp0,  pp1,  pp2,  pp3,
                  pp4,  pp5,  pp6,  pp7,
                  pp8,  pp9,  pp10, pp11,
                  pp12, pp13, pp14, pp15,
                  pp16, pp17, pp18, pp19,
                  pp20, pp21, pp22, pp23,
                  pp24, pp25, pp26, pp27,
                  pp28, pp29, pp30, pp31,

    output [31:0] S         // Sign bit of each PP
);

wire [32:0] tmp;
assign tmp = {R, 1'b0};

// pp0
assign pp0  = (tmp[1:0]   == 2'b01) ?  M 
               : (tmp[1:0]   == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[0] = pp0[31];

// pp1
assign pp1  = (tmp[2:1]   == 2'b01) ?  M 
               : (tmp[2:1]   == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[1] = pp1[31];

// pp2
assign pp2  = (tmp[3:2]   == 2'b01) ?  M 
               : (tmp[3:2]   == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[2] = pp2[31];

// pp3
assign pp3  = (tmp[4:3]   == 2'b01) ?  M 
               : (tmp[4:3]   == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[3] = pp3[31];

// pp4
assign pp4  = (tmp[5:4]   == 2'b01) ?  M 
               : (tmp[5:4]   == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[4] = pp4[31];

// pp5
assign pp5  = (tmp[6:5]   == 2'b01) ?  M 
               : (tmp[6:5]   == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[5] = pp5[31];

// pp6
assign pp6  = (tmp[7:6]   == 2'b01) ?  M 
               : (tmp[7:6]   == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[6] = pp6[31];

// pp7
assign pp7  = (tmp[8:7]   == 2'b01) ?  M 
               : (tmp[8:7]   == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[7] = pp7[31];

// pp8
assign pp8  = (tmp[9:8]   == 2'b01) ?  M 
               : (tmp[9:8]   == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[8] = pp8[31];

// pp9
assign pp9  = (tmp[10:9]  == 2'b01) ?  M 
               : (tmp[10:9]  == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[9] = pp9[31];

// pp10
assign pp10 = (tmp[11:10] == 2'b01) ?  M 
               : (tmp[11:10] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[10] = pp10[31];

// pp11
assign pp11 = (tmp[12:11] == 2'b01) ?  M 
               : (tmp[12:11] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[11] = pp11[31];

// pp12
assign pp12 = (tmp[13:12] == 2'b01) ?  M 
               : (tmp[13:12] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[12] = pp12[31];

// pp13
assign pp13 = (tmp[14:13] == 2'b01) ?  M 
               : (tmp[14:13] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[13] = pp13[31];

// pp14
assign pp14 = (tmp[15:14] == 2'b01) ?  M 
               : (tmp[15:14] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[14] = pp14[31];

// pp15
assign pp15 = (tmp[16:15] == 2'b01) ?  M 
               : (tmp[16:15] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[15] = pp15[31];

// pp16
assign pp16 = (tmp[17:16] == 2'b01) ?  M 
               : (tmp[17:16] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[16] = pp16[31];

// pp17
assign pp17 = (tmp[18:17] == 2'b01) ?  M 
               : (tmp[18:17] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[17] = pp17[31];

// pp18
assign pp18 = (tmp[19:18] == 2'b01) ?  M 
               : (tmp[19:18] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[18] = pp18[31];

// pp19
assign pp19 = (tmp[20:19] == 2'b01) ?  M 
               : (tmp[20:19] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[19] = pp19[31];

// pp20
assign pp20 = (tmp[21:20] == 2'b01) ?  M 
               : (tmp[21:20] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[20] = pp20[31];

// pp21
assign pp21 = (tmp[22:21] == 2'b01) ?  M 
               : (tmp[22:21] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[21] = pp21[31];

// pp22
assign pp22 = (tmp[23:22] == 2'b01) ?  M 
               : (tmp[23:22] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[22] = pp22[31];

// pp23
assign pp23 = (tmp[24:23] == 2'b01) ?  M 
               : (tmp[24:23] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[23] = pp23[31];

// pp24
assign pp24 = (tmp[25:24] == 2'b01) ?  M 
               : (tmp[25:24] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[24] = pp24[31];

// pp25
assign pp25 = (tmp[26:25] == 2'b01) ?  M 
               : (tmp[26:25] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[25] = pp25[31];

// pp26
assign pp26 = (tmp[27:26] == 2'b01) ?  M 
               : (tmp[27:26] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[26] = pp26[31];

// pp27
assign pp27 = (tmp[28:27] == 2'b01) ?  M 
               : (tmp[28:27] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[27] = pp27[31];

// pp28
assign pp28 = (tmp[29:28] == 2'b01) ?  M 
               : (tmp[29:28] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[28] = pp28[31];

// pp29
assign pp29 = (tmp[30:29] == 2'b01) ?  M 
               : (tmp[30:29] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[29] = pp29[31];

// pp30
assign pp30 = (tmp[31:30] == 2'b01) ?  M 
               : (tmp[31:30] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[30] = pp30[31];

// pp31
assign pp31 = (tmp[32:31] == 2'b01) ?  M 
               : (tmp[32:31] == 2'b10) ? (~M + 1'b1) 
               : 32'b0;
assign S[31] = pp31[31];

endmodule
