// sram_like_to_axi_bridge.v

module sram_like_to_axi_bridge (
    input  wire        clk,
    input  wire        reset,

    // AXI Read Address Channel
    output reg  [3:0]   arid,
    output reg  [31:0]  araddr,
    output reg  [7:0]   arlen,
    output reg  [2:0]   arsize,
    output wire [1:0]   arburst,
    output wire [1:0]   arlock,
    output wire [3:0]   arcache,
    output wire [2:0]   arprot,
    output reg          arvalid,
    input  wire         arready,

    // AXI Read Data Channel
    input  wire [3:0]   rid,
    input  wire [31:0]  rdata,
    input  wire [1:0]   rresp,
    input  wire         rlast,
    input  wire         rvalid,
    output reg          rready,

    // AXI Write Address Channel
    output wire [3:0]   awid,
    output reg  [31:0]  awaddr,
    output reg  [7:0]   awlen,
    output reg  [2:0]   awsize,
    output wire [1:0]   awburst,
    output wire [1:0]   awlock,
    output wire [3:0]   awcache,
    output wire [2:0]   awprot,
    output reg          awvalid,
    input  wire         awready,

    // AXI Write Data Channel
    output wire [3:0]   wid,
    output reg  [31:0]  wdata,
    output reg  [3:0]   wstrb,
    output reg          wlast,
    output reg          wvalid,
    input  wire         wready,

    // AXI Write Response Channel
    input  wire [3:0]   bid,
    input  wire [1:0]   bresp,
    input  wire         bvalid,
    output reg          bready,

    // Cache request & response
    input  wire         icache_rd_req,
    input  wire [2:0]   icache_rd_type,
    input  wire [31:0]  icache_rd_addr,
    output wire         icache_rd_rdy,
    output wire         icache_ret_valid,
    output wire         icache_ret_last,
    output wire [31:0]  icache_ret_data,

    input  wire         dcache_rd_req,
    input  wire [2:0]   dcache_rd_type,
    input  wire [31:0]  dcache_rd_addr,
    output wire         dcache_rd_rdy,
    output wire         dcache_ret_valid,
    output wire         dcache_ret_last,
    output wire [31:0]  dcache_ret_data,

    input  wire         dcache_wr_req,
    input  wire [2:0]   dcache_wr_type,
    input  wire [31:0]  dcache_wr_addr,
    input  wire [3:0]   dcache_wr_wstrb,
    input  wire [127:0] dcache_wr_data,
    output wire         dcache_wr_rdy
);

// AXI fixed signals
assign arburst = 2'b01;
assign arlock  = 2'b00;
assign arcache = 4'b0000;
assign arprot  = 3'b000;
assign awid    = 4'b0001;
assign awburst = 2'b01;
assign awlock  = 2'b00;
assign awcache = 4'b0000;
assign awprot  = 3'b000;
assign wid     = 4'b0001;

// Internal state definitions
localparam RREQ_IDLE  = 1'b0, RREQ_ACTIVE = 1'b1;
localparam RRESP_IDLE = 1'b0, RRESP_BUSY  = 1'b1;
localparam WREQ_IDLE  = 3'd0, WADDR_READY = 3'd1, WDATA_WAIT = 3'd2, WDATA_SEND = 3'd3, WB_RESP = 3'd4;

reg        read_req_state;
reg        read_resp_state;
reg [2:0]  write_state;

reg [127:0] write_buf;
reg [2:0]   write_count;

wire write_in_progress = write_state != WREQ_IDLE;

// Read Cache Request Mux
assign dcache_rd_rdy = (read_req_state == RREQ_IDLE) && !write_in_progress;
assign icache_rd_rdy = !dcache_rd_req && dcache_rd_rdy;

// AXI read request packaging
wire use_dcache = dcache_rd_req;
wire [31:0] req_addr  = use_dcache ? dcache_rd_addr : icache_rd_addr;
wire [2:0]  req_size  = (use_dcache ? dcache_rd_type : icache_rd_type) == 3'b100 ? 3'b010 : (use_dcache ? dcache_rd_type : icache_rd_type);
wire [7:0]  req_len   = (use_dcache ? dcache_rd_type : icache_rd_type) == 3'b100 ? 8'd3   : 8'd0;
wire [3:0]  req_id    = use_dcache ? 4'b0001 : 4'b0000;

// AXI read response
assign icache_ret_valid = (rid == 4'b0000) && rvalid;
assign icache_ret_last  = (rid == 4'b0000) && rlast;
assign icache_ret_data  = rdata;
assign dcache_ret_valid = (rid == 4'b0001) && rvalid;
assign dcache_ret_last  = (rid == 4'b0001) && rlast;
assign dcache_ret_data  = rdata;

// Write Request Ready
assign dcache_wr_rdy = (write_state == WREQ_IDLE);

// Read request FSM
always @(posedge clk) begin
    if (reset) begin
        read_req_state <= RREQ_IDLE;
        arvalid <= 1'b0;
    end else begin
        case (read_req_state)
            RREQ_IDLE: begin
                if ((dcache_rd_req || icache_rd_req) && !write_in_progress) begin
                    arid    <= req_id;
                    araddr  <= req_addr;
                    arsize  <= req_size;
                    arlen   <= req_len;
                    arvalid <= 1'b1;
                    read_req_state <= RREQ_ACTIVE;
                end
            end
            RREQ_ACTIVE: begin
                if (arvalid && arready) begin
                    arvalid <= 1'b0;
                    read_req_state <= RREQ_IDLE;
                end
            end
        endcase
    end
end

// Read response FSM
always @(posedge clk) begin
    if (reset) begin
        read_resp_state <= RRESP_IDLE;
        rready <= 1'b1;
    end else begin
        case (read_resp_state)
            RRESP_IDLE: begin
                if (rvalid) read_resp_state <= RRESP_BUSY;
            end
            RRESP_BUSY: begin
                if (rvalid && rlast) read_resp_state <= RRESP_IDLE;
            end
        endcase
    end
end

// Write FSM
always @(posedge clk) begin
    if (reset) begin
        write_state    <= WREQ_IDLE;
        awvalid        <= 1'b0;
        wvalid         <= 1'b0;
        wlast          <= 1'b0;
        bready         <= 1'b0;
        write_buf      <= 128'd0;
        write_count    <= 3'd0;
    end else begin
        case (write_state)
            WREQ_IDLE: begin
                if (dcache_wr_req) begin
                    awaddr     <= dcache_wr_addr;
                    awsize     <= dcache_wr_type == 3'b100 ? 3'b010 : dcache_wr_type;
                    awlen      <= dcache_wr_type == 3'b100 ? 8'd3 : 8'd0;
                    awvalid    <= 1'b1;
                    wdata      <= dcache_wr_data[31:0];
                    wstrb      <= dcache_wr_wstrb;
                    write_buf  <= {32'd0, dcache_wr_data[127:32]};
                    write_count <= (dcache_wr_type == 3'b100) ? 3'd3 : 3'd0;
                    wlast      <= (dcache_wr_type != 3'b100);
                    write_state <= WADDR_READY;
                end
            end
            WADDR_READY: begin
                if (awready) begin
                    awvalid <= 1'b0;
                    wvalid  <= 1'b1;
                    write_state <= WDATA_SEND;
                end
            end
            WDATA_SEND: begin
                if (wready) begin
                    if (wlast) begin
                        wvalid <= 1'b0;
                        wlast  <= 1'b0;
                        bready <= 1'b1;
                        write_state <= WB_RESP;
                    end else begin
                        wdata  <= write_buf[31:0];
                        write_buf <= {32'd0, write_buf[127:32]};
                        write_count <= write_count - 3'd1;
                        wlast <= (write_count == 3'd1);
                    end
                end
            end
            WB_RESP: begin
                if (bvalid) begin
                    bready <= 1'b0;
                    write_state <= WREQ_IDLE;
                end
            end
            default: write_state <= WREQ_IDLE;
        endcase
    end
end

endmodule
