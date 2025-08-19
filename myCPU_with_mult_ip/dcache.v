module dcache(
        input wire  clk,
        input wire  resetn,
        // to from CPU
        input wire  flush_sign_cancel,
        input wire  uncache_en,
        input wire  valid,  // 报表明请求有效
        input wire  op,     // 0: read, 1: write
        input wire  [2:0]  size,
        input wire  [19:0] tag,
        input wire  [7:0]  index,
        input wire  [3:0]  offset,
        input wire  [3:0]  wstrb,
        input wire  [31:0] wdata,

        // cacop
        input wire cacop_en,
        input wire [1:0] cacop_mode,

        output wire cacop_addr_ok,
        output wire cacop_data_ok,
        output wire busy,

        output wire addr_ok,
        output wire data_ok,
        output wire [31:0] rdata,

        //to from axi_bridge
        output wire rd_req,
        output wire [2:0]  rd_type, // 为了支持 uncache 访问
        output wire [31:0] rd_addr,
        input  wire rd_rdy,
        input  wire ret_valid,
        input  wire ret_last,
        input  wire [31:0] ret_data, // axi 返回的数据，这个数据 refill 到 4-way 表中

        output wire         wr_req,
        output wire [2:0]   wr_type, // 为了支持 uncache 访问
        output wire [31:0]  wr_addr,
        output wire [3:0]   wr_wstrb,
        output wire [127:0] wr_data, // 发射一个 cache line 到 axi 的 buffer
        input  wire         wr_rdy
    );
    // IFU 发送请求，这里返回数据或者通过 AXI 和 SRAM 交互完后返回数据

    // 状态机
    localparam main_idle         = 9'b000000001;
    localparam main_lookup       = 9'b000000010;
    localparam main_write_back   = 9'b000000100;
    localparam main_replace      = 9'b000001000;
    localparam main_refill       = 9'b000010000;
    localparam main_write        = 9'b000100000;
    localparam main_retry        = 9'b001000000;
    localparam main_cancel       = 9'b010000000;

    reg [8:0] main_state;

    wire main_state_is_idle    = main_state == main_idle;
    wire main_state_is_lookup  = main_state == main_lookup;
    wire main_state_is_write_back    = main_state == main_write_back;
    wire main_state_is_replace = main_state == main_replace;
    wire main_state_is_refill  = main_state == main_refill;
    wire main_state_is_write   = main_state == main_write;
    wire main_state_is_retry   = main_state == main_retry;
    wire main_state_is_cancel = main_state == main_cancel;

    // Request Buffer
    reg         request_buffer_op;
    reg [ 7:0]  request_buffer_index;
    reg [19:0]  request_buffer_tag;
    reg [ 3:0]  request_buffer_offset;
    reg [ 3:0]  request_buffer_wstrb;
    reg [31:0]  request_buffer_wdata;
    reg         request_buffer_uncache_en;
    reg [2:0]   request_buffer_size;

    reg         request_buffer_cacop_en;
    reg [1:0]   request_buffer_cacop_mode;

    // cacop_mode
    wire cacop_op_mode0 = request_buffer_cacop_en && (request_buffer_cacop_mode == 2'b00); // invalid
    wire cacop_op_mode1 = request_buffer_cacop_en && (request_buffer_cacop_mode == 2'b01); // Index Invalidate / Invalidate and Writeback
    wire cacop_op_mode2 = request_buffer_cacop_en && (request_buffer_cacop_mode == 2'b10); // Hit Invalidate / Invalidate and Writeback

    // Miss Buffer
    reg  [1:0]  miss_buffer_ret_num;      // 已经从 AXI 返回了几个字

    // 这里的 cache 为 4_way
    // V D Tag Data------> 1'bx  1'bx  20'bx  128'bx
    reg [148:0] cache_line_0[255:0]/*debug*/;
    reg [148:0] cache_line_1[255:0];
    // reg [149:0] cache_line_2[255:0];
    // reg [149:0] cache_line_3[255:0];

    reg [255:0] cache_line_0_V;
    reg [255:0] cache_line_1_V;

    reg [31:0] main_refill_data_buffer [3:0];

    // `define V      149
`define D      148
`define Tag    147:128
`define Data   127:0

    wire [1:0]   replace_way; // 1000、0100、0010、0001
    wire [19:0]  replace_tag;
    wire [127:0] replace_data;
    wire         replace_d;   // replaced 的 way 脏位 是否有效
    wire         replace_v;   // replaced 的 way 的有效位是否有效

    // cache_hit stuff
    wire [31:0]  load_result;  // load 结果
    wire [1:0]   way_hit;      // 1000、0100、0010、0001
    wire         cache_hit;

    wire [127:0]  refill_data;
    reg refill_done;

    // 确定 cacop_mode0 的信息
    // cacop_mode0_way 是 VA[1:0];
    // cache_line 是 index[7:0]，因此需要将 index[7:2] 作为 cache_line 的索引
    wire [1:0] cacop_mode0_1_way;
    assign cacop_mode0_1_way = request_buffer_offset[0] == 1'b0 ? 2'b01 :
           request_buffer_offset[0] == 1'b1 ? 2'b10 :
           //  request_buffer_offset[1:0] == 2'd2 ? 4'b0100 :
           //  request_buffer_offset[1:0] == 2'd3 ? 4'b1000 :
           2'b00;

    assign replace_way =
           cacop_op_mode1 ? cacop_mode0_1_way :
           cacop_op_mode2 ? way_hit :
           // V 优先
           (!cache_line_0_V[request_buffer_index]) ? 2'b01 :
           (!cache_line_1_V[request_buffer_index]) ? 2'b10 :
           //    (!cache_line_2[request_buffer_index][`V]) ? 4'b0100 :
           //    (!cache_line_3[request_buffer_index][`V]) ? 4'b1000 :
           // D
           (!cache_line_0[request_buffer_index][`D]) ? 2'b01 :
           (!cache_line_1[request_buffer_index][`D]) ? 2'b10 :
           //    (!cache_line_2[request_buffer_index][`D]) ? 4'b0100 :
           //    (!cache_line_3[request_buffer_index][`D]) ? 4'b1000 :
           2'b01; // 默认 way0

    assign replace_tag = replace_way[0] ? cache_line_0[request_buffer_index][`Tag] :
           replace_way[1] ? cache_line_1[request_buffer_index][`Tag] :
           //    replace_way[2] ? cache_line_2[request_buffer_index][`Tag] :
           //    replace_way[3] ? cache_line_3[request_buffer_index][`Tag] :
           20'd0;

    assign replace_data =
           replace_way[0] ? cache_line_0[request_buffer_index][`Data] :
           replace_way[1] ? cache_line_1[request_buffer_index][`Data] :
           //    replace_way[2] ? cache_line_2[request_buffer_index][`Data] :
           //    replace_way[3] ? cache_line_3[request_buffer_index][`Data] :

           128'd0;

    assign replace_d = replace_way[0] ? cache_line_0[request_buffer_index][`D] :
           replace_way[1] ? cache_line_1[request_buffer_index][`D] :
           //    replace_way[2] ? cache_line_2[request_buffer_index][`D] :
           //    replace_way[3] ? cache_line_3[request_buffer_index][`D] :
           1'b0;

    assign replace_v = replace_way[0] ? cache_line_0_V[request_buffer_index] :
           replace_way[1] ? cache_line_1_V[request_buffer_index]:
           //    replace_way[2] ? cache_line_2[request_buffer_index][`V] :
           //    replace_way[3] ? cache_line_3[request_buffer_index][`V] :
           1'b0;

    assign way_hit[0] = cache_line_0_V[request_buffer_index] && cache_line_0[request_buffer_index][`Tag] == request_buffer_tag;
    assign way_hit[1] = cache_line_1_V[request_buffer_index] && cache_line_1[request_buffer_index][`Tag] == request_buffer_tag;
    // assign way_hit[2] = cache_line_2[request_buffer_index][`V] && cache_line_2[request_buffer_index][`Tag] == request_buffer_tag;
    // assign way_hit[3] = cache_line_3[request_buffer_index][`V] && cache_line_3[request_buffer_index][`Tag] == request_buffer_tag;

    // 考虑到 uncache 访问，如果 uncache_en，那么不应该 hit，直接走 AXI 通道
    assign cache_hit = (|way_hit) && !request_buffer_uncache_en;

    wire [127:0] hit_line_data;
    assign hit_line_data = way_hit[0] ? cache_line_0[request_buffer_index][`Data] :
           way_hit[1] ? cache_line_1[request_buffer_index][`Data] :
           //  way_hit[2] ? cache_line_2[request_buffer_index][`Data] :
           //  way_hit[3] ? cache_line_3[request_buffer_index][`Data] :
           128'd0;

    // cache line 的读
    // 根据 index、offset、tag 就应该能立即读出数据
    assign addr_ok = main_state_is_lookup;
    assign rdata = request_buffer_uncache_en ? uncache_rdata_wire : hit_line_data[request_buffer_offset[3:2]*32+:32];
    // 如果 uncache 访存
    wire uncache_data_ok;
    assign uncache_data_ok = request_buffer_op ? main_state_is_write_back && wr_rdy : main_state_is_refill && ret_valid && ret_last;
    assign data_ok = request_buffer_uncache_en ? uncache_data_ok && !flush_sign_cancel : (main_state_is_lookup || main_state_is_retry) && cache_hit && !flush_sign_cancel;

    // 由于 read 占比高，因此优化优化 read

    assign wr_req = main_state_is_write_back && wr_rdy && !flush_sign_cancel;

    assign wr_type  = request_buffer_uncache_en && !request_buffer_cacop_en ? request_buffer_size : 3'b100;
    assign wr_addr  = request_buffer_uncache_en && !request_buffer_cacop_en ? {request_buffer_tag, request_buffer_index, request_buffer_offset} :
           {replace_tag, request_buffer_index, 4'b0};
    assign wr_wstrb = request_buffer_uncache_en && !request_buffer_cacop_en ? request_buffer_wstrb : 4'hf;
    assign wr_data  = request_buffer_uncache_en && !request_buffer_cacop_en ? {96'b0, request_buffer_wdata} : replace_data;



    // 否则，进入 main_replace
    // 如果是 uncache 访问，只有uncache read 的时候，才发送 rd_req 请求
    assign rd_req = main_state_is_replace && !flush_sign_cancel;
    assign rd_type = request_buffer_uncache_en && !request_buffer_cacop_en ? request_buffer_size : 3'b100;
    assign rd_addr = request_buffer_uncache_en && !request_buffer_cacop_en ? {request_buffer_tag, request_buffer_index, request_buffer_offset} : {request_buffer_tag, request_buffer_index, 4'b0};

    // 接着就可以回填了，main_refill
    // 这里要更新的数据有 tag、D、V、data 等等
    wire [31:
          0] buffer_3 = main_refill_data_buffer[3];
    wire [31:
          0] buffer_2 = main_refill_data_buffer[2];
    wire [31:
          0] buffer_1 = main_refill_data_buffer[1];
    wire [31:
          0] buffer_0 = main_refill_data_buffer[0];

    assign refill_data = {buffer_3, buffer_2, buffer_1, buffer_0};

    // hit_write data 的生成
    // 这里要考虑 tag、index、offset、wstrb

    wire [31:0] replaced_word;
    assign replaced_word = hit_line_data[request_buffer_offset[3:2]*32+:32];
    wire [31:0] final_word;
    assign final_word = {(request_buffer_wstrb[3] ? request_buffer_wdata[31:24] : replaced_word[31:24]),
                         (request_buffer_wstrb[2] ? request_buffer_wdata[23:16] : replaced_word[23:16]),
                         (request_buffer_wstrb[1] ? request_buffer_wdata[15: 8] : replaced_word[15: 8]),
                         (request_buffer_wstrb[0] ? request_buffer_wdata[ 7: 0] : replaced_word[ 7: 0])};

    wire [127:0] write_hit_data;
    assign write_hit_data = {
               ({request_buffer_offset[3:2],2'b0} == 4'hc) ? final_word : hit_line_data[127:96],
               ({request_buffer_offset[3:2],2'b0} == 4'h8) ? final_word : hit_line_data[95:64],
               ({request_buffer_offset[3:2],2'b0} == 4'h4) ? final_word : hit_line_data[63:32],
               ({request_buffer_offset[3:2],2'b0} == 4'h0) ? final_word : hit_line_data[31:0]
           };



    // 如果是 uncache，不更新 cache ，仅仅利用 axi_cache 读写通道就行
    always @(posedge clk) begin
        if(!resetn) begin
            // 复位，刷掉 V 信息
            cache_line_0_V <= 256'd0;
            cache_line_1_V <= 256'd0;
        end
        else begin
            // 如果重填完成，就可以就 refill_data 填到对应的 way 了
            if(refill_done && !request_buffer_uncache_en) begin
                cache_line_0[request_buffer_index][`Data] <= replace_way[0] ? refill_data : cache_line_0[request_buffer_index][`Data];
                cache_line_1[request_buffer_index][`Data] <= replace_way[1] ? refill_data : cache_line_1[request_buffer_index][`Data];
                // cache_line_2[request_buffer_index][`Data] <= replace_way[2] ? refill_data : cache_line_2[request_buffer_index][`Data];
                // cache_line_3[request_buffer_index][`Data] <= replace_way[3] ? refill_data : cache_line_3[request_buffer_index][`Data];

                cache_line_0[request_buffer_index][`Tag] <= replace_way[0] ? request_buffer_tag : cache_line_0[request_buffer_index][`Tag];
                cache_line_1[request_buffer_index][`Tag] <= replace_way[1] ? request_buffer_tag : cache_line_1[request_buffer_index][`Tag];
                // cache_line_2[request_buffer_index][`Tag] <= replace_way[2] ? request_buffer_tag : cache_line_2[request_buffer_index][`Tag];
                // cache_line_3[request_buffer_index][`Tag] <= replace_way[3] ? request_buffer_tag : cache_line_3[request_buffer_index][`Tag];

                cache_line_0_V[request_buffer_index]   <= replace_way[0] ? 1'b1 : cache_line_0_V[request_buffer_index];
                cache_line_1_V[request_buffer_index]   <= replace_way[1] ? 1'b1 : cache_line_1_V[request_buffer_index];
                // cache_line_2[request_buffer_index][`V]   <= replace_way[2] ? 1'b1 : cache_line_2[request_buffer_index][`V];
                // cache_line_3[request_buffer_index][`V]   <= replace_way[3] ? 1'b1 : cache_line_3[request_buffer_index][`V];

                cache_line_0[request_buffer_index][`D]   <= replace_way[0] ? 1'b0 : cache_line_0[request_buffer_index][`D];
                cache_line_1[request_buffer_index][`D]   <= replace_way[1] ? 1'b0 : cache_line_1[request_buffer_index][`D];
                // cache_line_2[request_buffer_index][`D]   <= replace_way[2] ? 1'b0 : cache_line_2[request_buffer_index][`D];
                // cache_line_3[request_buffer_index][`D]   <= replace_way[3] ? 1'b0 : cache_line_3[request_buffer_index][`D];
            end
            // 如果写命中， 只需要更新 data、D
            if(main_state_is_write && !request_buffer_uncache_en) begin
                cache_line_0[request_buffer_index][`Data] <= way_hit[0] ? write_hit_data : cache_line_0[request_buffer_index][`Data];
                cache_line_1[request_buffer_index][`Data] <= way_hit[1] ? write_hit_data : cache_line_1[request_buffer_index][`Data];
                // cache_line_2[request_buffer_index][`Data] <= way_hit[2] ? write_hit_data : cache_line_2[request_buffer_index][`Data];
                // cache_line_3[request_buffer_index][`Data] <= way_hit[3] ? write_hit_data : cache_line_3[request_buffer_index][`Data];

                cache_line_0[request_buffer_index][`D]   <= way_hit[0] ? 1'b1 : cache_line_0[request_buffer_index][`D];
                cache_line_1[request_buffer_index][`D]   <= way_hit[1] ? 1'b1 : cache_line_1[request_buffer_index][`D];
                // cache_line_2[request_buffer_index][`D]   <= way_hit[2] ? 1'b1 : cache_line_2[request_buffer_index][`D];
                // cache_line_3[request_buffer_index][`D]   <= way_hit[3] ? 1'b1 : cache_line_3[request_buffer_index][`D];
            end
            // cacop
            // 这里采用严格模式, 全部无效化
            // 将指定 cache line 的 tag 置为 0
            // mode_0 需要将 tag 置为 0
            if (main_state_is_lookup && cacop_op_mode0) begin
                case (cacop_mode0_1_way)
                    2'b01:
                        cache_line_0[request_buffer_index][`Tag] <= 20'd0;
                    2'b10:
                        cache_line_1[request_buffer_index][`Tag] <= 20'd0;
                    // // 4'b0100:
                    // cache_line_2[request_buffer_index][`Tag] <= 20'd0;
                    // // 4'b1000:
                    // cache_line_3[request_buffer_index][`Tag] <= 20'd0;
                    default: begin
                    end
                endcase
            end
            // mode_1 需要无效化
            else if(main_state_is_replace && cacop_op_mode1) begin
                case (cacop_mode0_1_way)
                    2'b01:
                        cache_line_0_V[request_buffer_index] <= 1'b0;
                    2'b10:
                        cache_line_1_V[request_buffer_index] <= 1'b0;
                    // 4'b0100:
                    //     cache_line_2[request_buffer_index][`V] <= 1'b0;
                    // 4'b1000:
                    //     cache_line_3[request_buffer_index][`V] <= 1'b0;
                    default: begin
                    end
                endcase
            end
            else if(main_state_is_replace && cache_hit && cacop_op_mode2) begin
                case (way_hit)
                    2'b01:
                        cache_line_0_V[request_buffer_index] <= 1'b0;
                    2'b10:
                        cache_line_1_V[request_buffer_index] <= 1'b0;
                    // 4'b0100:
                    //     cache_line_2[request_buffer_index][`V] <= 1'b0;
                    // 4'b1000:
                    //     cache_line_3[request_buffer_index][`V] <= 1'b0;
                    default: begin
                    end
                endcase
            end
        end
    end

    // 状态机

    wire req_or_inst_valid;
    assign req_or_inst_valid = valid || cacop_en;
    // 这个 buffer 是为了将最后返回的数据锁存起来以防止 axi_rdata 对 mem_rdata 的干扰
    reg [31:0]  uncache_data_buffer;
    wire [31:0] uncache_rdata_wire;
    assign uncache_rdata_wire = request_buffer_uncache_en && ret_valid && ret_last ? ret_data : uncache_data_buffer;


    // cancle 信号到来时的状态
    reg [8:0] when_cancel_state;

    always @(posedge clk) begin
        if(!resetn) begin
            main_state <= main_idle;
            request_buffer_op <= 1'b0;
            request_buffer_index      <=  8'b0;
            request_buffer_tag        <= 20'b0;
            request_buffer_offset     <=  4'b0;
            request_buffer_wstrb      <=  4'b0;
            request_buffer_wdata      <= 32'b0;
            request_buffer_uncache_en  <= 1'b0;
            request_buffer_size        <= 3'd0;
            request_buffer_cacop_en    <= 1'b0;
            request_buffer_cacop_mode  <= 2'b0;

            miss_buffer_ret_num        <= 2'd0;
            main_refill_data_buffer[0] <= 32'd0;
            main_refill_data_buffer[1] <= 32'd0;
            main_refill_data_buffer[2] <= 32'd0;
            main_refill_data_buffer[3] <= 32'd0;
            refill_done                <= 1'd0;
            uncache_data_buffer        <= 32'd0;
            when_cancel_state          <= 9'd0;
        end
        // 请求取消，进入请求取消状态
        else if (flush_sign_cancel && !(main_state_is_refill && ret_valid && ret_last)) begin
            // 请求取消
            when_cancel_state <= main_state;
            main_state <= main_cancel;
        end
        // 这种情况非常少见
        // 当取消的时候恰好返回，那么就可以直接终结事务了
        else if(flush_sign_cancel && (main_state_is_refill && ret_valid && ret_last)) begin
            main_state <= main_idle;
        end
        else begin
            case (main_state)
                main_idle: begin
                    if (req_or_inst_valid) begin
                        // 请求有效 且 无写后请求 冲突，就进入查询
                        main_state <= main_lookup;

                        request_buffer_op         <= op;
                        request_buffer_tag        <= tag;
                        request_buffer_index      <= index;
                        request_buffer_offset     <= offset;
                        request_buffer_wstrb      <= wstrb;
                        request_buffer_wdata      <= wdata;
                        // request_buffer_uncache_en  <= uncache_en;
                        request_buffer_uncache_en  <= uncache_en && !cacop_en;
                        request_buffer_size        <= size;

                        request_buffer_cacop_en    <= cacop_en;
                        request_buffer_cacop_mode  <= cacop_mode;
                    end
                end
                main_lookup: begin
                    if (cacop_op_mode0) begin
                        // invalid || icache Index Invalidate / just invalidate
                        main_state <= main_idle;
                    end
                    else if (cacop_op_mode1) begin
                        // dcache Index Invalidate / Invalidate and Writeback
                        main_state <= replace_v ? main_write_back : main_idle;
                    end

                    else if (cache_hit) begin
                        // 如果是 cacop_mode_2，切命中，这时候直接返回 idle，同时对命中的 cache_line 进行写会和无效化
                        if (cacop_op_mode2) begin
                            // Hit Invalidate / Invalidate and Writeback
                            main_state <=  main_write_back;
                        end
                        else if (!request_buffer_op) begin
                            // 如果是 read
                            main_state <= main_idle;
                        end
                        else begin
                            // 如果是 write
                            main_state <= main_write;
                        end
                    end
                    else if(!cache_hit) begin
                        // 如果这里是 uncache write, 应该 write/read through
                        if (request_buffer_uncache_en && !request_buffer_op) begin
                            // 复用 axi_cache 的读取通道
                            main_state <= main_replace;
                        end
                        else if (request_buffer_uncache_en && request_buffer_op) begin
                            // 复用 axi_cache 的写通道
                            main_state <= main_write_back;
                        end
                        // 如果没有命中，应该进行替换，但是替换前要判断 replace_d、replace_v 的状态
                        else if (replace_d && replace_v) begin
                            // 如果被替换的 way 脏位有效且有效位有效，就进入 main_write_back 状态
                            main_state <= main_write_back;
                        end
                        else begin
                            // 否则 直接替换就行
                            main_state <= main_replace;
                        end
                    end
                    else begin
                        main_state <= main_idle;
                    end
                end
                main_write_back: begin
                    if (wr_rdy) begin
                        // 如果写准备好
                        main_state <= main_replace;
                    end
                end
                main_replace: begin
                    // 对于 cacop_mode_1, cacop_mode_2 充填后直接返回
                    if(cacop_op_mode1 || cacop_op_mode2) begin
                        main_state <= main_idle;
                    end
                    // uncache 访问
                    // 取消写请求、状态机置到空闲
                    else if (request_buffer_uncache_en && request_buffer_op) begin
                        main_state <= main_idle;
                    end
                    // 回填 cache line 之前需要从 axi 获取 4 个字
                    else if(rd_rdy) begin
                        // 如果 axi 缓存准备好了数据，就可以进入 main_refill
                        main_state <= main_refill;
                        miss_buffer_ret_num <= 2'b0; // 开始计数
                    end
                end
                main_refill: begin
                    if (ret_valid && ret_last) begin
                        // 如果是 uncache 的 read，就可以返回了
                        if (request_buffer_uncache_en && !request_buffer_op) begin
                            main_state <= main_idle;
                            uncache_data_buffer <= ret_data;
                        end
                        else begin
                            // 如果传送完成，retry
                            main_state <= main_retry;
                            refill_done <= 1'b1;
                            main_refill_data_buffer[miss_buffer_ret_num] <= ret_data;
                        end
                    end
                    else begin
                        if (ret_valid) begin
                            miss_buffer_ret_num <= miss_buffer_ret_num + 2'b1;
                            main_refill_data_buffer[miss_buffer_ret_num] <= ret_data;
                        end
                    end
                end
                main_retry: begin
                    // 此时已经经过了重填，肯定 cache_hit
                    if(!request_buffer_op && cache_hit) begin
                        main_state <= main_idle;
                    end
                    else if(request_buffer_op && cache_hit) begin
                        main_state <= main_write;
                    end
                    refill_done <= 1'b0;
                end
                main_write: begin
                    main_state <= main_idle;
                end

                // 保存了 cancel 到来时的状态
                main_cancel: begin
                    // 如果是 idle, look_up, main_replace,此时拦截信号就行
                    if(when_cancel_state == main_idle ||
                            when_cancel_state == main_lookup ||
                            when_cancel_state == main_write_back ||
                            when_cancel_state == main_replace ||
                            when_cancel_state == main_retry ||
                            when_cancel_state == main_write
                      ) begin
                        main_state <= main_idle;
                        refill_done <= 1'b0;
                    end
                    // 此时拦截已经来不及，只能等这个事务执行完成
                    else if(when_cancel_state == main_refill) begin
                        if(ret_valid && ret_last) begin
                            main_state <= main_idle;
                        end
                    end
                    else begin
                        main_state <= main_idle;
                    end
                end
                default: begin
                    main_state <= main_idle;
                end
            endcase
        end
    end
    assign busy = !main_state_is_idle;
    assign cacop_addr_ok = main_state_is_lookup && request_buffer_cacop_en;
    assign cacop_data_ok = main_state_is_lookup && (cacop_op_mode0 || cacop_op_mode1 && !replace_v) ||
           main_state_is_replace && (cacop_op_mode1 || cacop_op_mode2);

endmodule
