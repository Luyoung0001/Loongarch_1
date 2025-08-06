module divider(
        input div_clk,
        input reset,
        input div,
        input div_signed,
        input [31:0] x, y,
        output [31:0] s, r,
        output  complete
    );

    wire busy;

    Divider32 o(
                  .clk(div_clk),
                  .reset(reset),
                  .div(div),
                  .div_signed(div_signed),
                  .x(x),
                  .y(y),
                  .q(s),
                  .r(r),
                  .busy(busy),
                  .done(complete)
              );


endmodule
