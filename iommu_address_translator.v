`timescale 1ns / 1ps

module iommu_address_translator (
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

    output wire [63:0]              dbg_tslt_addr,
    output wire [7:0]               dbg_walker_state,
    output wire [7:0]               dbg_translator_state,
    output wire dbg_walker_arvalid,
    output wire dbg_translator_tle,
    output wire dbg_walker_bug,
    output wire dbg_walker_reset,
    output wire dbg_atc_flush_done,
    output wire dbg_translator_should_flush
);
    reg [11:0] cnt;
    reg tslt_done;
    reg [63:0] tslt_addr;
    reg [7:0] state;

    reg [63:0] atc_iova;
    reg atc_iova_ready;
    wire [63:0] atc_pa;
    wire atc_done;
    wire atc_hit;
    reg [63:0] atc_new_pa;
    reg [63:0] atc_new_iova;
    reg atc_update_ready;
    wire atc_update_done;
    reg atc_flush;
    wire atc_flush_done;
    assign dbg_atc_flush_done = atc_flush_done;

    reg [63:0] walker_iova;
    reg walker_iova_ready;
    reg walker_reset;
    wire [63:0] walker_pa;
    wire walker_pa_ready;

    localparam S_IDLE = 8'h0;
    localparam S_IOATC_1 = 8'h1;
    localparam S_IOATC_2 = 8'h2;
    localparam S_WALK_1 = 8'h3;
    localparam S_UPDT_1 = 8'h4;
    localparam S_UPDT_2 = 8'h5;
    localparam S_DONE = 8'h6;
    localparam S_FLUSH_CHECK = 8'h7;
    localparam S_FLUSH_START = 8'h8;
    localparam S_FLUSH_WAIT = 8'h9;

    reg translator_tle;
    reg should_flush;

    assign dbg_translator_state = state;
    assign dbg_translator_tle = translator_tle;
    assign dbg_translator_should_flush = should_flush;

    initial begin
        cnt <= 0;        
        tslt_done <= 0;
        tslt_addr <= 64'b0;

        state <= S_IDLE;

        atc_iova <= 0;
        atc_iova_ready <= 0;
        atc_new_pa <= 0;
        atc_new_iova <= 0;
        atc_update_ready <= 0;

        walker_iova <= 0;
        walker_iova_ready <= 0;
        // walker_flush <= 0;
        walker_reset <= 0;
        translator_tle <= 0;
        atc_flush <= 0;
        should_flush <= 0;
    end

    assign pa_ready = tslt_done;
    assign pa = tslt_addr;
    assign dbg_tslt_addr = tslt_addr;

    // always @ (posedge clk) begin
    //     if (iova_ready) begin
    //         cnt <= 1;
    //         tslt_addr <= iova;
    //     end else if (cnt > 0) begin
    //         cnt <= cnt + 1;
    //     end else begin
    //         cnt <= 0;
    //     end
    // end

    // always @ (posedge clk) begin
    //     if (cnt == 9'h1ff) begin
    //         tslt_done <= 1;
    //     end else begin
    //         tslt_done <= 0;
    //     end
    // end

    

    iommu_ioatc ioatc (
        .clk(clk),
        .iova(atc_iova),
        .iova_ready(atc_iova_ready),
        .pa(atc_pa),
        .done(atc_done),
        .hit(atc_hit),
        .new_pa(atc_new_pa),
        .new_iova(atc_new_iova),
        .update_ready(atc_update_ready),
        .update_done(atc_update_done),
        .flush(atc_flush),
        .flush_done(atc_flush_done)
    );

    iommu_walker walker (
        .clk(clk),
        .iova(walker_iova),
        .iova_ready(walker_iova_ready),
        .pa(walker_pa),
        .pa_ready(walker_pa_ready),
        .ddtp(ddtp),
        .flush(flush),
        .reset(walker_reset),
        .iommu_m_axi_araddr(iommu_m_axi_araddr),
        .iommu_m_axi_arlen(iommu_m_axi_arlen),
        .iommu_m_axi_arsize(iommu_m_axi_arsize),
        .iommu_m_axi_arburst(iommu_m_axi_arburst),
        .iommu_m_axi_arlock(iommu_m_axi_arlock),
        .iommu_m_axi_arcache(iommu_m_axi_arcache),
        .iommu_m_axi_arprot(iommu_m_axi_arprot),
        .iommu_m_axi_arvalid(iommu_m_axi_arvalid),
        .iommu_m_axi_arready(iommu_m_axi_arready),
        .iommu_m_axi_arid(iommu_m_axi_arid),
        .iommu_m_axi_rdata(iommu_m_axi_rdata),
        .iommu_m_axi_rresp(iommu_m_axi_rresp),
        .iommu_m_axi_rlast(iommu_m_axi_rlast),
        .iommu_m_axi_rvalid(iommu_m_axi_rvalid),
        .iommu_m_axi_rready(iommu_m_axi_rready),
        .iommu_m_axi_rid(iommu_m_axi_rid),

        .dbg_walker_state(dbg_walker_state),
        .dbg_walker_arvalid(dbg_walker_arvalid),
        .dbg_walker_bug(dbg_walker_bug),
        .dbg_walker_reset(dbg_walker_reset)
    );

    always @ (posedge clk) begin
        if (flush) begin
            should_flush <= 1'b1;
        end else if (state == S_FLUSH_START) begin
            should_flush <= 1'b0;
        end
    end

    always @ (posedge clk) begin
        case (state)
            S_IDLE: begin
                tslt_done <= 1'b0;
                translator_tle <= 1'b0;
                atc_flush <= 1'b0;
                if (iova_ready) begin
                    atc_iova <= iova;
                    walker_iova <= iova;
                    // state <= S_IOATC_1;
                    state <= S_FLUSH_CHECK;
                    walker_reset <= 1'b1;
                end
            end

            S_FLUSH_CHECK: begin
                walker_reset <= 0;
                if (should_flush) begin
                    state <= S_FLUSH_START;
                end else begin
                    state <= S_IOATC_1;
                end
            end

            S_FLUSH_START: begin
                atc_flush <= 1'b1;
                state <= S_FLUSH_WAIT;
            end

            S_FLUSH_WAIT: begin
                atc_flush <= 1'b0;
                if (atc_flush_done) begin
                    state <= S_IOATC_1;
                end
            end

            S_IOATC_1: begin
                atc_iova_ready <= 1;
                walker_reset <= 0;
                state <= S_IOATC_2;
            end

            S_IOATC_2: begin
                atc_iova_ready <= 0;
                if (atc_done) begin
                    if (atc_hit) begin
                        tslt_addr <= atc_pa;
                        state <= S_DONE;
                    end else begin
                        cnt <= 0;
                        walker_iova_ready <= 1'b1;
                        state <= S_WALK_1;
                    end
                end
            end

            S_WALK_1: begin
                walker_iova_ready <= 1'b0;
                if (cnt == 12'hfff) begin // timeout situation
                // TODO: This is dangerous in slow systems, since the timeout is not guaranteed to be long enough. This can be directly removed if not debugging.
                    tslt_addr <= walker_iova;
                    translator_tle <= 1'b1;
                    state <= S_UPDT_1;
                end else if (walker_pa_ready) begin
                    // tslt_addr <= walker_iova[31:0];
                    tslt_addr <= walker_pa;
                    state <= S_UPDT_1;
                end else begin
                    cnt <= cnt + 1;
                end
                // if (walker_pa_ready) begin
                //     tslt_addr <= walker_pa;
                //     state <= S_UPDT_1;
                // end
            end

            S_UPDT_1: begin
                atc_new_iova <= walker_iova;
                atc_new_pa <= tslt_addr;
                atc_update_ready <= 1;
                state <= S_UPDT_2;
            end

            S_UPDT_2: begin
                atc_update_ready <= 0;
                if (atc_update_done) begin
                    state <= S_DONE;
                end
            end

            S_DONE: begin
                tslt_done <= 1'b1;
                state <= S_IDLE;
            end

        endcase
    end

    // assign all iommu read signals to zero
    // assign iommu_m_axi_araddr = 34'b0;
    // assign iommu_m_axi_arlen = 8'b0;
    // assign iommu_m_axi_arsize = 3'b0;
    // assign iommu_m_axi_arburst = 2'b0;
    // assign iommu_m_axi_arlock = 1'b0;
    // assign iommu_m_axi_arcache = 4'b0;
    // assign iommu_m_axi_arprot = 3'b0;
    // assign iommu_m_axi_arvalid = 1'b0;
    // assign iommu_m_axi_arid = 3'b0;

    // assign iommu_m_axi_rready = 1'b0;


 

endmodule
