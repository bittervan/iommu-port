`timescale 1ns / 1ps

// Use device id = 0 for now
module iommu_walker(
    input wire clk,
    input wire [63:0] iova,
    input wire iova_ready,
    output wire [63:0] pa,
    output wire pa_ready,

    input wire [63:0] ddtp,
    input wire [31:0] flush,

    input wire reset,

    output wire [33:0]              iommu_m_axi_araddr,
    output wire [7:0]               iommu_m_axi_arlen,
    output wire [2:0]               iommu_m_axi_arsize,
    output wire [1:0]               iommu_m_axi_arburst,
    output wire                     iommu_m_axi_arlock,
    output wire [3:0]               iommu_m_axi_arcache,
    output wire [2:0]               iommu_m_axi_arprot,
    output wire                     iommu_m_axi_arvalid,
    input  wire                     iommu_m_axi_arready,
    output wire [2:0]               iommu_m_axi_arid,
    
    input  wire [255:0]             iommu_m_axi_rdata,
    input  wire [1:0]               iommu_m_axi_rresp,
    input  wire                     iommu_m_axi_rlast,
    input  wire                     iommu_m_axi_rvalid,
    output wire                     iommu_m_axi_rready,
    input  wire [2:0]               iommu_m_axi_rid,

    // output wire [255:0] dbg_cd,
    // output wire [63:0] dbg_first_entry,
    // output wire [63:0] dbg_second_entry,
    // output wire [63:0] dbg_third_entry,
    // output wire [6:0] dbg_state,
    // output wire [63:0] dbg_pa,
    // output wire dbg_pa_ready,
    // output wire [1:0] dbg_layer,
    // output wire dbg_reset
    output wire [256:0]             dbg_walker_cd,
    output wire [63:0]              dbg_first_entry,
    output wire [63:0]              dbg_second_entry,
    output wire [63:0]              dbg_third_entry,
    output wire [7:0]               dbg_walker_state,
    output wire dbg_walker_arvalid,
    output wire dbg_walker_bug,
    output wire dbg_walker_reset
);
 
    localparam STATE_IDLE =             7'h0;
    localparam STATE_TSLT_1 =           7'h1;
    localparam STATE_TSLT_2 =           7'h2;
    localparam STATE_TSLT_3 =           7'h3;
    localparam STATE_TSLT_4 =           7'h4;
    localparam STATE_TSLT_5 =           7'h5;
    localparam STATE_TSLT_6 =           7'h6;
    localparam STATE_TSLT_7 =           7'h7;
    localparam STATE_TSLT_8 =           7'h8;
    localparam STATE_TSLT_9 =           7'h9;
    localparam STATE_LAST =             7'hA;
    localparam STATE_BEFORE =           7'hB;
    localparam STATE_AFTER =            7'hC;

    reg [63:0] current_iova;
    reg [7:0] state;

    reg [33:0] araddr;
    reg [7:0]  arlen;
    reg [2:0]  arsize;
    reg [1:0]  arburst;
    reg        arlock;
    reg [3:0]  arcache;
    reg [2:0]  arprot;
    reg        arvalid;
    reg [2:0]  arid;
    reg        rready;

    assign dbg_walker_arvalid = arvalid;

    reg [255:0] cd;
    reg [63:0] first_entry;
    reg [63:0] second_entry;
    reg [63:0] third_entry;
;
    assign dbg_walker_cd = cd;
    assign dbg_first_entry = first_entry;
    assign dbg_second_entry = second_entry;
    assign dbg_third_entry = third_entry;

    reg [1:0] layer;
    reg [63:0] pa;
    reg pa_ready;

    reg walker_bug;
    assign dbg_walker_bug = walker_bug;

    reg [320:0] ddtc [0:3];
    reg [128:0] pdtc [0:3];

    initial begin
        state <= 7'b0;
        current_iova <= 64'b0;

        araddr <= 34'b0;
        arlen <= 8'b0;
        arsize <= 3'h3; // 64 bytes
        arburst <= 2'b1; // INCR
        arlock <= 1'b0;
        arcache <= 4'b0;
        arprot <= 3'b0;
        arvalid <= 1'b0;
        arid <= 3'b0;
        rready <= 1'b0;

        pa_ready <= 1'b0;
        pa <= 64'b0;

        cd <= 256'b0;
        first_entry <= 64'b0;
        second_entry <= 64'b0;
        third_entry <= 64'b0;

        walker_bug <= 1'b0;
        ddtc[0] <= 0;
        ddtc[1] <= 0;
        ddtc[2] <= 0;
        ddtc[3] <= 0;
        pdtc[0] <= 0;
        pdtc[1] <= 0;
        pdtc[2] <= 0;
        pdtc[3] <= 0;
    end

    assign iommu_m_axi_araddr = araddr;
    assign iommu_m_axi_arlen = arlen;
    assign iommu_m_axi_arsize = arsize;
    assign iommu_m_axi_arburst = arburst;
    assign iommu_m_axi_arlock = arlock;
    assign iommu_m_axi_arcache = arcache;
    assign iommu_m_axi_arprot = arprot;
    assign iommu_m_axi_arvalid = arvalid;
    assign iommu_m_axi_arid = arid;
    assign iommu_m_axi_rready = rready;

    assign dbg_walker_state = state;
    assign dbg_walker_reset = reset;

    always @ (posedge clk) begin
        if (reset) begin
            state <= 7'b0;
            current_iova <= 64'b0;

            araddr <= 34'b0;
            arlen <= 8'b0;
            arsize <= 3'h3; // 64 bytes
            arburst <= 2'b1; // INCR
            arlock <= 1'b0;
            arcache <= 4'b0;
            arprot <= 3'b0;
            arvalid <= 1'b0;
            arid <= 3'b0;
            rready <= 1'b0;

            pa_ready <= 1'b0;
            pa <= 64'b0;

            cd <= 256'b0;
            first_entry <= 64'b0;
            second_entry <= 64'b0;
            third_entry <= 64'b0;           
            walker_bug <= 1'b0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    cd <= 256'b0;
                    first_entry <= 64'b0;
                    second_entry <= 64'b0;
                    third_entry <= 64'b0;
                    pa_ready <= 0;
                    pa <= 0;
                    layer <= 0;
                    rready <= 0;
                    walker_bug <= 1'b0;
                    if (iova_ready) begin
                        state <= STATE_TSLT_1;
                        current_iova <= iova;
                    end
                    if (flush) begin
                        ddtc[0] <= 0;
                        ddtc[1] <= 0;
                        ddtc[2] <= 0;
                        ddtc[3] <= 0;
                        pdtc[0] <= 0;
                        pdtc[1] <= 0;
                        pdtc[2] <= 0;
                        pdtc[3] <= 0;
                    end
                end

                STATE_TSLT_1: begin // from now on, get the device context table entry
                    if (ddtc[0][320] == 1 && (ddtc[0][319:256] == {ddtp[53:10], 12'b0})) begin
                        cd <= ddtc[0][255:0];
                        state <= STATE_TSLT_7;
                    end else begin
                        araddr <= {ddtp[53:10], 12'b0};
                        arvalid <= 1'b1;
                        arlen <= 8'h3;  // request 256 bits
                        state <= STATE_TSLT_2;
                    end
                end

                STATE_TSLT_2: begin
                    if (iommu_m_axi_arready) begin
                        arvalid <= 1'b0;
                        rready <= 1'b1;
                        state <= STATE_TSLT_3;
                    end
                end

                STATE_TSLT_3: begin
                    if (iommu_m_axi_rvalid) begin
                        cd[63:0] <= iommu_m_axi_rdata;
                        state <= STATE_TSLT_4;
                    end
                end

                STATE_TSLT_4: begin
                    if (iommu_m_axi_rvalid) begin
                        cd[127:64] <= iommu_m_axi_rdata;
                        state <= STATE_TSLT_5;
                    end
                end

                STATE_TSLT_5: begin
                    if (iommu_m_axi_rvalid) begin
                        cd[191:128] <= iommu_m_axi_rdata;
                        state <= STATE_TSLT_6;
                    end
                end

                STATE_TSLT_6: begin
                    if (iommu_m_axi_rvalid) begin
                        cd[255:192] <= iommu_m_axi_rdata;
                        state <= STATE_TSLT_7;
                        rready <= 1'b0;
                        ddtc[0][320] <= 1;
                        ddtc[0][319:256] <= {ddtp[53:10], 12'b0};
                        ddtc[0][255:0] <= {iommu_m_axi_rdata, cd[191:0]};
                        if (iommu_m_axi_rlast) begin
                            walker_bug <= 1'b1;
                        end
                    end
                end

                // from now on, the cd holds the device context table entry

                STATE_TSLT_7: begin
                    if (layer == 0) begin
                        araddr <= {cd[43:0], current_iova[38:30], 3'b0}; // pdtp << 12
                        state <= STATE_BEFORE;
                    end else if (layer == 1) begin
                        araddr <= {first_entry[53:10], current_iova[29:21], 3'b0};
                        state <= STATE_BEFORE;
                    end else if (layer == 2) begin
                        araddr <= {second_entry[53:10], current_iova[20:12], 3'b0};
                        state <= STATE_BEFORE;
                    end else begin
                        state <= STATE_TSLT_7;
                    end
                    //  else if (layer == 3) begin
                    //     layer <= 0;
                    //     state <= STATE_LAST;
                    // end

                    arlen <= 1'b0;  // request 64 bits
                    // arvalid <= 1'b1;
                    // layer <= layer + 1; // save until finish the current layer
                end

                STATE_BEFORE: begin
                    if (pdtc[araddr[4:3]][128] == 1 && (pdtc[araddr[4:3]][127:64] == araddr[33:0])) begin
                        if (layer == 0) begin
                            first_entry <= pdtc[araddr[4:3]][63:0];
                        end else if (layer == 1) begin
                            second_entry <= pdtc[araddr[4:3]][63:0];
                        end else if (layer == 2) begin
                            third_entry <= pdtc[araddr[4:3]][63:0];
                        end
                        layer <= layer + 1;
                        state <= STATE_TSLT_7;
                    end else begin
                        state <= STATE_AFTER;
                    end
                end

                STATE_AFTER: begin
                    state <= STATE_TSLT_8;
                    arvalid <= 1'b1;
                end

                STATE_TSLT_8: begin
                    if (iommu_m_axi_arready) begin
                        arvalid <= 1'b0;
                        rready <= 1'b1;
                        state <= STATE_TSLT_9;
                    end else begin
                        arvalid <= 1'b1;
                        rready <= 1'b0;
                        state <= STATE_TSLT_9;
                    end
                end

                STATE_TSLT_9: begin
                    if (iommu_m_axi_rvalid) begin
                        if (layer == 0) begin
                            first_entry <= iommu_m_axi_rdata;
                            state <= STATE_TSLT_7;
                        end else if (layer == 1) begin
                            second_entry <= iommu_m_axi_rdata;
                            state <= STATE_TSLT_7;
                        end else if (layer == 2) begin
                            third_entry <= iommu_m_axi_rdata;
                            state <= STATE_LAST;
                        end
                        pdtc[araddr[4:3]][128] <= 1;
                        pdtc[araddr[4:3]][127:64] <= araddr[33:0];
                        pdtc[araddr[4:3]][63:0] <= iommu_m_axi_rdata;
                        arvalid <= 0;
                        layer <= layer + 1;
                    end
                end

                STATE_LAST: begin
                    pa <= {third_entry[53:10], current_iova[11:0]};
                    pa_ready <= 1;
                    state <= STATE_IDLE;
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
    // always @(posedge clk) begin
    //     if (reset) begin
    //         state <= STATE_IDLE;
    //         current_iova <= 64'b0;
    //         cd <= 256'b0;
    //         first_entry <= 64'b0;
    //         second_entry <= 64'b0;
    //         third_entry <= 64'b0;
    //         pa_ready <= 0;
    //         pa <= 0;
    //         layer <= 0;

    //         araddr <= 34'b0;
    //         arlen <= 8'b0;
    //         arsize <= 3'h3; // 64 bytes
    //         arburst <= 2'b1; // INCR
    //         arlock <= 1'b0;
    //         arcache <= 4'b0;
    //         arprot <= 3'b0;
    //         arvalid <= 1'b0;
    //         arid <= 3'b0;
    //         rready <= 1'b0;
    //     end else if (state == STATE_IDLE) begin
    //         cd <= 256'b0;
    //         first_entry <= 64'b0;
    //         second_entry <= 64'b0;
    //         third_entry <= 64'b0;
    //         pa_ready <= 0;
    //         pa <= 0;
    //         layer <= 0;
    //         rready <= 0;
    //         if (iova_ready) begin
    //             state <= STATE_TSLT_1;
    //             current_iova <= iova;
    //         end else begin
    //             state <= STATE_IDLE;
    //             current_iova <= current_iova;
    //         end
    //     end else if (state == STATE_TSLT_1) begin
    //         araddr <= {ddtp[53:10], 12'b0};
    //         arvalid <= 1'b1;
    //         arlen <= 8'h3;  // request 256 bits
    //         state <= STATE_TSLT_2;
    //     end else if (state == STATE_TSLT_2) begin
    //         if (iommu_m_axi_arready) begin
    //             arvalid <= 1'b0;
    //             rready <= 1'b1;
    //             state <= STATE_TSLT_3;
    //         end else begin
    //             arvalid <= 1'b1;
    //             rready <= 1'b0;
    //             state <= STATE_TSLT_2;
    //         end
    //     end else if (state == STATE_TSLT_3) begin
    //         if (iommu_m_axi_rvalid) begin
    //             cd[63:0] <= iommu_m_axi_rdata;
    //             state <= STATE_TSLT_4;
    //         end else begin
    //             cd[63:0] <= 64'b0;
    //             state <= STATE_TSLT_3;
    //         end
    //     end else if (state == STATE_TSLT_4) begin
    //         if (iommu_m_axi_rvalid) begin
    //             cd[127:64] <= iommu_m_axi_rdata;
    //             state <= STATE_TSLT_5;
    //         end else begin
    //             cd[127:64] <= 64'b0;
    //             state <= STATE_TSLT_4;
    //         end
    //     end else if (state == STATE_TSLT_5) begin
    //         if (iommu_m_axi_rvalid) begin
    //             cd[191:128] <= iommu_m_axi_rdata;
    //             state <= STATE_TSLT_6;
    //         end else begin
    //             cd[191:128] <= 64'b0;
    //             state <= STATE_TSLT_5;
    //         end
    //     end else if (state == STATE_TSLT_6) begin
    //         if (iommu_m_axi_rvalid) begin
    //             cd[255:192] <= iommu_m_axi_rdata;
    //             state <= STATE_TSLT_7;
    //             rready <= 1'b0;
    //         end else begin
    //             cd[255:192] <= 64'b0;
    //             state <= STATE_TSLT_6;
    //         end
    //     end else if (state == STATE_TSLT_7) begin
    //         if (layer == 0) begin
    //             araddr <= {cd[43:0], current_iova[38:30], 3'b0}; // pdtp << 12
    //             state <= STATE_TSLT_8;
    //             layer <= layer + 1;
    //         end else if (layer == 1) begin
    //             araddr <= {first_entry[53:10], current_iova[29:21], 3'b0};
    //             state <= STATE_TSLT_8;
    //             layer <= layer + 1;
    //         end else if (layer == 2) begin
    //             araddr <= {second_entry[53:10], current_iova[20:12], 3'b0};
    //             state <= STATE_TSLT_8;
    //             layer <= layer + 1;
    //         end else begin
    //             araddr <= 64'b0;
    //             state <= STATE_TSLT_7;
    //             layer <= layer;
    //         end
    //         arlen <= 1'b0;  // request 64 bits
    //         arvalid <= 1'b1;
    //     end else if (state == STATE_TSLT_8) begin
    //         if (iommu_m_axi_arready) begin
    //             arvalid <= 1'b0;
    //             rready <= 1'b1;
    //             state <= STATE_TSLT_9;
    //         end else begin
    //             arvalid <= 1'b1;
    //             rready <= 1'b0;
    //             state <= STATE_TSLT_8;
    //         end
    //     end else if (state == STATE_TSLT_9) begin
    //         if (iommu_m_axi_rvalid) begin
    //             if (layer == 1) begin
    //                 first_entry <= iommu_m_axi_rdata;
    //                 state <= STATE_TSLT_7;
    //             end else if (layer == 2) begin
    //                 second_entry <= iommu_m_axi_rdata;
    //                 state <= STATE_TSLT_7;
    //             end else if (layer == 3) begin
    //                 third_entry <= iommu_m_axi_rdata;
    //                 state <= STATE_LAST;
    //             end else begin
    //                 first_entry <= first_entry;
    //                 second_entry <= second_entry;
    //                 third_entry <= third_entry;
    //                 state <= STATE_IDLE;
    //             end
    //         end else begin
    //             first_entry <= first_entry;
    //             second_entry <= second_entry;
    //             third_entry <= third_entry;
    //             state <= STATE_TSLT_9;
    //         end
    //     end else if (state == STATE_LAST) begin
    //         pa <= {third_entry[53:10], current_iova[11:0]};
    //         pa_ready <= 1;
    //         state <= STATE_IDLE;
    //     end else begin
    //         state <= STATE_IDLE;
    //     end
    // end

    // assign dbg_cd = cd;
    // assign dbg_first_entry = first_entry;
    // assign dbg_second_entry = second_entry;
    // assign dbg_third_entry = third_entry;
    // assign dbg_state = state;
    // assign dbg_pa = pa;
    // assign dbg_pa_ready = pa_ready;
    // assign dbg_layer = layer;
    // assign dbg_reset = reset;

    // always @(posedge clk) begin
    //     case (state)
    //         STATE_IDLE: begin
    //             cd <= 256'b0;
    //             first_entry <= 64'b0;
    //             second_entry <= 64'b0;
    //             third_entry <= 64'b0;
    //             pa_ready <= 0;
    //             pa <= 0;
    //             layer <= 0;
    //             rready <= 0;
    //             if (iova_ready) begin
    //                 current_iova <= iova;
    //                 state <= STATE_TSLT_1;
    //             end else begin
    //                 state <= STATE_IDLE;
    //             end
    //         end

    //         STATE_TSLT_1: begin // from now on, get the device context table entry
    //             araddr <= {ddtp[53:10], 12'b0};
    //             arvalid <= 1'b1;
    //             arlen <= 8'h3;  // request 256 bits
    //             state <= STATE_TSLT_2;
    //         end

    //         STATE_TSLT_2: begin
    //             if (iommu_m_axi_arready) begin
    //                 arvalid <= 1'b0;
    //                 rready <= 1'b1;
    //                 state <= STATE_TSLT_3;
    //             end else begin
    //                 state <= STATE_TSLT_2;
    //             end
    //         end

    //         STATE_TSLT_3: begin
    //             if (iommu_m_axi_rvalid) begin
    //                 cd[63:0] <= iommu_m_axi_rdata;
    //                 state <= STATE_TSLT_4;
    //             end else begin
    //                 state <= STATE_TSLT_3;
    //             end
    //         end

    //         STATE_TSLT_4: begin
    //             if (iommu_m_axi_rvalid) begin
    //                 cd[127:64] <= iommu_m_axi_rdata;
    //                 state <= STATE_TSLT_5;
    //             end else begin
    //                 state <= STATE_TSLT_4;
    //             end
    //         end

    //         STATE_TSLT_5: begin
    //             if (iommu_m_axi_rvalid) begin
    //                 cd[191:128] <= iommu_m_axi_rdata;
    //                 state <= STATE_TSLT_6;
    //             end else begin
    //                 state <= STATE_TSLT_5;
    //             end
    //         end

    //         STATE_TSLT_6: begin
    //             if (iommu_m_axi_rvalid) begin
    //                 cd[255:192] <= iommu_m_axi_rdata;
    //                 state <= STATE_TSLT_7;
    //                 rready <= 1'b0;
    //             end else begin
    //                 state <= STATE_TSLT_6;
    //             end
    //         end

    //         // from now on, the cd holds the device context table entry

    //         STATE_TSLT_7: begin
    //             if (layer == 0) begin
    //                 araddr <= {cd[43:0], current_iova[38:30], 3'b0}; // pdtp << 12
    //                 state <= STATE_TSLT_8;
    //             end else if (layer == 1) begin
    //                 araddr <= {first_entry[53:10], current_iova[29:21], 3'b0};
    //                 state <= STATE_TSLT_8;
    //             end else if (layer == 2) begin
    //                 araddr <= {second_entry[53:10], current_iova[20:12], 3'b0};
    //                 state <= STATE_TSLT_8;
    //             end else begin
    //                 state <= STATE_TSLT_7;
    //             end
    //             //  else if (layer == 3) begin
    //             //     layer <= 0;
    //             //     state <= STATE_LAST;
    //             // end

    //             arlen <= 1'b0;  // request 64 bits
    //             arvalid <= 1'b1;
    //             // layer <= layer + 1; // save until finish the current layer
    //         end

    //         STATE_TSLT_8: begin
    //             if (iommu_m_axi_arready) begin
    //                 arvalid <= 1'b0;
    //                 rready <= 1'b1;
    //                 state <= STATE_TSLT_9;
    //             end else begin
    //                 arvalid <= 1'b1;
    //                 rready <= 1'b0;
    //                 state <= STATE_TSLT_9;
    //             end
    //         end

    //         STATE_TSLT_9: begin
    //             if (iommu_m_axi_rvalid) begin
    //                 if (layer == 0) begin
    //                     first_entry <= iommu_m_axi_rdata;
    //                     state <= STATE_TSLT_7;
    //                 end else if (layer == 1) begin
    //                     second_entry <= iommu_m_axi_rdata;
    //                     state <= STATE_TSLT_7;
    //                 end else if (layer == 2) begin
    //                     third_entry <= iommu_m_axi_rdata;
    //                     state <= STATE_LAST;
    //                 end
    //                 arvalid <= 0;
    //                 layer <= layer + 1;
    //             end
    //         end

    //         STATE_LAST: begin
    //             pa <= {third_entry[53:10], current_iova[11:0]};
    //             pa_ready <= 1;
    //             state <= STATE_IDLE;
    //         end

    //         default: begin
    //             state <= state;
    //         end
    //     endcase
    // end


endmodule

