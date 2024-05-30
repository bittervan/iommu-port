`timescale 1ns / 1ps

module iommu_w_channel (
    input wire clk,
    input  wire [63:0]              data_s_axi_awaddr,
    input  wire [7:0]               data_s_axi_awlen,
    input  wire [2:0]               data_s_axi_awsize,
    input  wire [1:0]               data_s_axi_awburst,
    input  wire                     data_s_axi_awlock,
    input  wire [3:0]               data_s_axi_awcache,
    input  wire [2:0]               data_s_axi_awprot,
    input  wire                     data_s_axi_awvalid,
    output wire                     data_s_axi_awready,
    input  wire [2:0]               data_s_axi_awid,
    
    input  wire [255:0]             data_s_axi_wdata,
    input  wire [31:0]              data_s_axi_wstrb,
    input  wire                     data_s_axi_wlast,
    input  wire                     data_s_axi_wvalid,
    output wire                     data_s_axi_wready,
    
    output wire [1:0]               data_s_axi_bresp,
    output wire                     data_s_axi_bvalid,
    input  wire                     data_s_axi_bready,
    output wire [2:0]               data_s_axi_bid,
 
    output wire [33:0]              data_m_axi_awaddr,
    output wire [7:0]               data_m_axi_awlen,
    output wire [2:0]               data_m_axi_awsize,
    output wire [1:0]               data_m_axi_awburst,
    output wire                     data_m_axi_awlock,
    output wire [3:0]               data_m_axi_awcache,
    output wire [2:0]               data_m_axi_awprot,
    output wire                     data_m_axi_awvalid,
    input  wire                     data_m_axi_awready,
    output wire [2:0]               data_m_axi_awid,
    
    output wire [255:0]             data_m_axi_wdata,
    output wire [31:0]              data_m_axi_wstrb,
    output wire                     data_m_axi_wlast,
    output wire                     data_m_axi_wvalid,
    input  wire                     data_m_axi_wready,
    
    input  wire [1:0]               data_m_axi_bresp,
    input  wire                     data_m_axi_bvalid,
    output wire                     data_m_axi_bready,
    input  wire [2:0]               data_m_axi_bid,

    // The write walker port
    output wire [33:0]              iommu_write_m_axi_araddr,
    output wire [7:0]               iommu_write_m_axi_arlen,
    output wire [2:0]               iommu_write_m_axi_arsize,
    output wire [1:0]               iommu_write_m_axi_arburst,
    output wire                     iommu_write_m_axi_arlock,
    output wire [3:0]               iommu_write_m_axi_arcache,
    output wire [2:0]               iommu_write_m_axi_arprot,
    output wire                     iommu_write_m_axi_arvalid,
    input  wire                     iommu_write_m_axi_arready,
    output wire [2:0]               iommu_write_m_axi_arid,
    
    input  wire [255:0]             iommu_write_m_axi_rdata,
    input  wire [1:0]               iommu_write_m_axi_rresp,
    input  wire                     iommu_write_m_axi_rlast,
    input  wire                     iommu_write_m_axi_rvalid,
    output wire                     iommu_write_m_axi_rready,
    input  wire [2:0]               iommu_write_m_axi_rid,

    input wire [63:0]               ddtp,
    input wire [31:0]               flush,
    output wire dbg_atc_flush_done,
    output wire dbg_translator_should_flush
 
);

    // ** 2.29 modification

    reg [8:0] wait_cnt;
    reg m_axi_awvalid;
    reg s_axi_awready;
    reg [63:0] iova;
    reg iova_ready;
    reg prev_data_s_axi_awvalid;
    reg [63:0] m_axi_awaddr;

    wire [63:0] pa;
    wire pa_ready;

    initial begin
        wait_cnt <= 9'b0;
        m_axi_awvalid <= 1'b0;
        s_axi_awready <= 1'b0;
        iova <= 64'b0;
        iova_ready <= 1'b0;
        prev_data_s_axi_awvalid <= 1'b0;
        m_axi_awaddr <= 64'b0;
    end

    // always @ (posedge clk) begin
    //     if ((m_axi_awvalid == 1'b1) && (data_m_axi_awready == 1'b1)) begin
    //         wait_cnt <= 9'b0;
    //     end else if (data_s_axi_awvalid == 1'b1) begin
    //         wait_cnt <= wait_cnt + 1'b1;
    //     end else begin
    //         wait_cnt <= 9'b0;
    //     end
    // end

    always @ (posedge clk) begin
        prev_data_s_axi_awvalid <= data_s_axi_awvalid;
    end

    always @ (posedge clk) begin
        if (prev_data_s_axi_awvalid == 1'b0 && data_s_axi_awvalid == 1'b1) begin
            iova <= data_s_axi_awaddr;
            iova_ready <= 1'b1;
        end else begin
            iova_ready <= 1'b0;
        end
    end

    always @ (posedge clk) begin
        if (pa_ready == 1'b1) begin
            m_axi_awaddr <= pa;
            m_axi_awvalid <= 1'b1;
            s_axi_awready <= 1'b0;
        end else if ((m_axi_awvalid == 1'b1) && (data_m_axi_awready == 1'b1)) begin
            m_axi_awvalid <= 1'b0;
            s_axi_awready <= 1'b1;
        end else begin
            m_axi_awvalid <= 1'b0;
            s_axi_awready <= 1'b0;
        end
    end

    // assign data_m_axi_awaddr =  data_s_axi_awaddr;
    assign data_m_axi_awaddr =  m_axi_awaddr;
    assign data_m_axi_awlen =   data_s_axi_awlen; 
    assign data_m_axi_awsize =  data_s_axi_awsize;
    assign data_m_axi_awburst = data_s_axi_awburst;
    assign data_m_axi_awlock =  data_s_axi_awlock;
    assign data_m_axi_awcache = data_s_axi_awcache;
    assign data_m_axi_awprot =  data_s_axi_awprot;
    assign data_m_axi_awvalid = m_axi_awvalid;
    assign data_s_axi_awready = s_axi_awready;
    assign data_m_axi_awid =    data_s_axi_awid;
    
    assign data_m_axi_wdata =   data_s_axi_wdata;
    assign data_m_axi_wstrb =   data_s_axi_wstrb;
    assign data_m_axi_wlast =   data_s_axi_wlast;
    assign data_m_axi_wvalid =  data_s_axi_wvalid;
    assign data_s_axi_wready =  data_m_axi_wready;
    
    assign data_s_axi_bresp =   data_m_axi_bresp;
    assign data_s_axi_bvalid =  data_m_axi_bvalid;
    assign data_m_axi_bready =  data_s_axi_bready;
    assign data_s_axi_bid =     data_m_axi_bid;

    iommu_address_translator translator (
        .clk(clk),
        .iova(iova),
        .iova_ready(iova_ready),
        .pa(pa),
        .pa_ready(pa_ready),
        .ddtp(ddtp),
        .flush(flush),
        .reset(0),

        .iommu_m_axi_araddr(iommu_write_m_axi_araddr),
        .iommu_m_axi_arlen(iommu_write_m_axi_arlen),
        .iommu_m_axi_arsize(iommu_write_m_axi_arsize),
        .iommu_m_axi_arburst(iommu_write_m_axi_arburst),
        .iommu_m_axi_arlock(iommu_write_m_axi_arlock),
        .iommu_m_axi_arcache(iommu_write_m_axi_arcache),
        .iommu_m_axi_arprot(iommu_write_m_axi_arprot),
        .iommu_m_axi_arvalid(iommu_write_m_axi_arvalid),
        .iommu_m_axi_arready(iommu_write_m_axi_arready),
        .iommu_m_axi_arid(iommu_write_m_axi_arid),

        .iommu_m_axi_rdata(iommu_write_m_axi_rdata),
        .iommu_m_axi_rresp(iommu_write_m_axi_rresp),
        .iommu_m_axi_rlast(iommu_write_m_axi_rlast),
        .iommu_m_axi_rvalid(iommu_write_m_axi_rvalid),
        .iommu_m_axi_rready(iommu_write_m_axi_rready),
        .iommu_m_axi_rid(iommu_write_m_axi_rid),
        
        .dbg_atc_flush_done(dbg_atc_flush_done),
        .dbg_translator_should_flush(dbg_translator_should_flush)
    );
    // ** 2.29 modification done
    
    // assign iommu_write_m_axi_araddr = 34'b0;
    // assign iommu_write_m_axi_arlen = 8'b0;
    // assign iommu_write_m_axi_arsize = 3'b0;
    // assign iommu_write_m_axi_arburst = 2'b0;
    // assign iommu_write_m_axi_arlock = 1'b0;
    // assign iommu_write_m_axi_arcache = 4'b0;
    // assign iommu_write_m_axi_arprot = 3'b0;
    // assign iommu_write_m_axi_arvalid = 1'b0;
    // assign iommu_write_m_axi_arid = 3'b0;

    // assign iommu_write_m_axi_rready = 1'b0;

    // reg [3:0] established_count;

    // // define the m regs
    // reg [33:0] m_awaddr;
    // reg [7:0] m_awlen;
    // reg [2:0] m_awsize;
    // reg [1:0] m_awburst;
    // reg m_awlock;
    // reg [3:0] m_awcache;
    // reg [2:0] m_awprot;
    // reg m_awvalid;
    // reg [2:0] m_awid;

    // // and cache the other aw signals
    // reg [7:0] awlen_cache [0:7];
    // reg [2:0] awsize_cache [0:7];
    // reg [1:0] awburst_cache [0:7];
    // reg awlock_cache [0:7];
    // reg [3:0] awcache_cache [0:7];
    // reg [2:0] awprot_cache [0:7];

    // reg [63:0] iova_cache [0:7];
    // reg [7:0]  iova_valid;
    // reg [63:0] phys_cache [0:7];

    // // assign data_m_axi_awaddr =  data_s_axi_awaddr[33:0];
    // assign data_m_axi_awaddr =  m_awaddr;
    // // assign data_m_axi_awlen =   data_s_axi_awlen; 
    // assign data_m_axi_awlen =   m_awlen;
    // // assign data_m_axi_awsize =  data_s_axi_awsize;
    // assign data_m_axi_awsize =  m_awsize;
    // // assign data_m_axi_awburst = data_s_axi_awburst;
    // assign data_m_axi_awburst = m_awburst;
    // // assign data_m_axi_awlock =  data_s_axi_awlock;
    // assign data_m_axi_awlock = m_awlock;
    // // assign data_m_axi_awcache = data_s_axi_awcache;
    // assign data_m_axi_awcache = m_awcache;
    // // assign data_m_axi_awprot =  data_s_axi_awprot;
    // assign data_m_axi_awprot = m_awprot;
    // // assign data_m_axi_awvalid = data_s_axi_awvalid;
    // assign data_m_axi_awvalid = m_awvalid;
    // // assign data_s_axi_awready = data_m_axi_awready;
    // // assign data_s_axi_awready = s_awready;
    // assign data_s_axi_awready = data_s_axi_awvalid && (iova_valid[data_s_axi_awid] == 1'b0); // cache it!
    // // assign data_m_axi_awid =    data_s_axi_awid;
    // assign data_m_axi_awid =    m_awid;
    
    // assign data_m_axi_wdata =   data_s_axi_wdata;
    // assign data_m_axi_wstrb =   data_s_axi_wstrb;
    // assign data_m_axi_wlast =   data_s_axi_wlast;
    // assign data_m_axi_wvalid =  data_s_axi_wvalid;
    // assign data_s_axi_wready =  data_m_axi_wready && (established_count != 0);
    
    // assign data_s_axi_bresp =   data_m_axi_bresp;
    // assign data_s_axi_bvalid =  data_m_axi_bvalid;
    // assign data_m_axi_bready =  data_s_axi_bready;
    // assign data_s_axi_bid =     data_m_axi_bid;
    
    // wire s_handshake;
    // wire m_handshake;
    // assign s_handshake = data_s_axi_awvalid && data_s_axi_awready;
    // assign m_handshake = data_m_axi_awvalid && data_m_axi_awready;

    // wire data_finish;
    // assign data_finish = data_s_axi_wlast && data_s_axi_wvalid && data_s_axi_wready;
    
    // reg [2:0] current_id;
    // reg [7:0] state;
    // reg [63:0] iova;
    // reg iova_ready;
    // wire [63:0] pa;
    // wire pa_ready;

    // localparam STATE_IDLE = 8'h0;
    // localparam STATE_TSLT = 8'h1;
    // localparam STATE_WAIT = 8'h2;
    // localparam STATE_HDSK = 8'h3;

    // initial begin 
    //     current_id <= 3'b0;
    //     state <= 8'b0;
    //     iova_valid <= 0;
    //     established_count <= 0;
    // end

    // always @ (posedge clk) begin
    //     if (s_handshake) begin
    //         iova_cache[data_s_axi_awid] <= data_s_axi_awaddr;
    //         iova_valid[data_s_axi_awid] <= 1;
    //         // cache the other signals
    //         awlen_cache[data_s_axi_awid] <= data_s_axi_awlen;
    //         awsize_cache[data_s_axi_awid] <= data_s_axi_awsize;
    //         awburst_cache[data_s_axi_awid] <= data_s_axi_awburst;
    //         awlock_cache[data_s_axi_awid] <= data_s_axi_awlock;
    //         awcache_cache[data_s_axi_awid] <= data_s_axi_awcache;
    //         awprot_cache[data_s_axi_awid] <= data_s_axi_awprot;
    //     end else if (m_handshake) begin
    //         iova_valid[data_m_axi_awid] <= 0;
    //     end
    // end

    // always @ (posedge clk) begin
    //     case (state)
    //         STATE_IDLE: begin
    //             m_awvalid <= 0;
    //             if (iova_valid[current_id] == 1) begin
    //                 state <= STATE_TSLT;
    //             end else begin
    //                 current_id <= current_id + 1;
    //             end
    //         end

    //         STATE_TSLT: begin
    //             iova <= iova_cache[current_id];
    //             iova_ready <= 1;
    //             state <= STATE_WAIT;
    //         end

    //         STATE_WAIT: begin
    //             iova_ready <= 0;
    //             if (pa_ready) begin
    //                 phys_cache[current_id] <= pa;
    //                 state <= STATE_HDSK;
    //             end
    //         end

    //         STATE_HDSK: begin
    //             m_awaddr <= phys_cache[current_id];
    //             m_awlen <= awlen_cache[current_id];
    //             m_awsize <= awsize_cache[current_id];
    //             m_awburst <= awburst_cache[current_id];
    //             m_awlock <= awlock_cache[current_id];
    //             m_awcache <= awcache_cache[current_id];
    //             m_awprot <= awprot_cache[current_id];
    //             m_awvalid <= 1;

    //             if (m_handshake) begin
    //                 state <= STATE_IDLE;
    //                 current_id <= current_id + 1;
    //             end
    //         end
    //     endcase

    //     if (m_handshake) begin
    //         if (~data_finish) begin
    //             established_count <= established_count + 1;
    //         end
    //     end else if (data_finish) begin
    //         established_count <= established_count - 1;
    //     end
    // end

    // iommu_walker w_walker (
    //     .clk(clk),
    //     .iova_ready(iova_ready),
    //     .iova(iova),
    //     .pa_ready(pa_ready),
    //     .pa(pa),
    //     .ddtp(ddtp),
    //     .flush(flush),
    //     .reset(0),

    //     .iommu_m_axi_araddr(iommu_write_m_axi_araddr),
    //     .iommu_m_axi_arlen(iommu_write_m_axi_arlen),
    //     .iommu_m_axi_arsize(iommu_write_m_axi_arsize),
    //     .iommu_m_axi_arburst(iommu_write_m_axi_arburst),
    //     .iommu_m_axi_arlock(iommu_write_m_axi_arlock),
    //     .iommu_m_axi_arcache(iommu_write_m_axi_arcache),
    //     .iommu_m_axi_arprot(iommu_write_m_axi_arprot),
    //     .iommu_m_axi_arvalid(iommu_write_m_axi_arvalid),
    //     .iommu_m_axi_arready(iommu_write_m_axi_arready),
    //     .iommu_m_axi_arid(iommu_write_m_axi_arid),

    //     .iommu_m_axi_rdata(iommu_write_m_axi_rdata),
    //     .iommu_m_axi_rresp(iommu_write_m_axi_rresp),
    //     .iommu_m_axi_rlast(iommu_write_m_axi_rlast),
    //     .iommu_m_axi_rvalid(iommu_write_m_axi_rvalid),
    //     .iommu_m_axi_rready(iommu_write_m_axi_rready),
    //     .iommu_m_axi_rid(iommu_write_m_axi_rid)
    // );

endmodule

