module Booth_Unsigned32 (
    input  [31:0] M,       // Multiplicand (unsigned)
    input  [31:0] R,       // Multiplier (unsigned)

    output [31:0] pp0,  pp1,  pp2,  pp3,
                  pp4,  pp5,  pp6,  pp7,
                  pp8,  pp9,  pp10, pp11,
                  pp12, pp13, pp14, pp15,
                  pp16, pp17, pp18, pp19,
                  pp20, pp21, pp22, pp23,
                  pp24, pp25, pp26, pp27,
                  pp28, pp29, pp30, pp31
);
    assign pp0  = R[0 ] ? M : 32'd0;
    assign     pp1  = R[1 ] ? M : 32'd0;
        assign pp2  = R[2 ] ? M : 32'd0;
       assign  pp3  = R[3 ] ? M : 32'd0;
      assign   pp4  = R[4 ] ? M : 32'd0;
      assign   pp5  = R[5 ] ? M : 32'd0;
      assign   pp6  = R[6 ] ? M : 32'd0;
      assign   pp7  = R[7 ] ? M : 32'd0;
      assign   pp8  = R[8 ] ? M : 32'd0;
      assign   pp9  = R[9 ] ? M : 32'd0;
      assign   pp10 = R[10] ? M : 32'd0;
       assign  pp11 = R[11] ? M : 32'd0;
     assign    pp12 = R[12] ? M : 32'd0;
      assign   pp13 = R[13] ? M : 32'd0;
      assign   pp14 = R[14] ? M : 32'd0;
     assign    pp15 = R[15] ? M : 32'd0;
      assign   pp16 = R[16] ? M : 32'd0;
     assign    pp17 = R[17] ? M : 32'd0;
       assign  pp18 = R[18] ? M : 32'd0;
      assign   pp19 = R[19] ? M : 32'd0;
       assign  pp20 = R[20] ? M : 32'd0;
      assign   pp21 = R[21] ? M : 32'd0;
      assign   pp22 = R[22] ? M : 32'd0;
      assign   pp23 = R[23] ? M : 32'd0;
      assign   pp24 = R[24] ? M : 32'd0;
      assign   pp25 = R[25] ? M : 32'd0;
     assign    pp26 = R[26] ? M : 32'd0;
     assign    pp27 = R[27] ? M : 32'd0;
     assign    pp28 = R[28] ? M : 32'd0;
     assign    pp29 = R[29] ? M : 32'd0;
     assign    pp30 = R[30] ? M : 32'd0;
      assign   pp31 = R[31] ? M : 32'd0;
endmodule
