`timescale 1ns / 1ps

module iommu_data_interface(
    input wire data_clk, 
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
    
    input  wire [63:0]              data_s_axi_araddr,
    input  wire [7:0]               data_s_axi_arlen,
    input  wire [2:0]               data_s_axi_arsize,
    input  wire [1:0]               data_s_axi_arburst,
    input  wire                     data_s_axi_arlock,
    input  wire [3:0]               data_s_axi_arcache,
    input  wire [2:0]               data_s_axi_arprot,
    input  wire                     data_s_axi_arvalid,
    output wire                     data_s_axi_arready,
    input  wire [2:0]               data_s_axi_arid,
   
    output wire [255:0]             data_s_axi_rdata,
    output wire [1:0]               data_s_axi_rresp,
    output wire                     data_s_axi_rlast,
    output wire                     data_s_axi_rvalid,
    input  wire                     data_s_axi_rready,
    output wire [2:0]               data_s_axi_rid,

    // The master port
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
    
    output wire [33:0]              data_m_axi_araddr,
    output wire [7:0]               data_m_axi_arlen,
    output wire [2:0]               data_m_axi_arsize,
    output wire [1:0]               data_m_axi_arburst,
    output wire                     data_m_axi_arlock,
    output wire [3:0]               data_m_axi_arcache,
    output wire [2:0]               data_m_axi_arprot,
    output wire                     data_m_axi_arvalid,
    input  wire                     data_m_axi_arready,
    output wire [2:0]               data_m_axi_arid,
    
    input  wire [255:0]             data_m_axi_rdata,
    input  wire [1:0]               data_m_axi_rresp,
    input  wire                     data_m_axi_rlast,
    input  wire                     data_m_axi_rvalid,
    output wire                     data_m_axi_rready,
    input  wire [2:0]               data_m_axi_rid,

    // The read walker port
    output wire [33:0]              iommu_read_m_axi_araddr,
    output wire [7:0]               iommu_read_m_axi_arlen,
    output wire [2:0]               iommu_read_m_axi_arsize,
    output wire [1:0]               iommu_read_m_axi_arburst,
    output wire                     iommu_read_m_axi_arlock,
    output wire [3:0]               iommu_read_m_axi_arcache,
    output wire [2:0]               iommu_read_m_axi_arprot,
    output wire                     iommu_read_m_axi_arvalid,
    input  wire                     iommu_read_m_axi_arready,
    output wire [2:0]               iommu_read_m_axi_arid,
    
    input  wire [255:0]             iommu_read_m_axi_rdata,
    input  wire [1:0]               iommu_read_m_axi_rresp,
    input  wire                     iommu_read_m_axi_rlast,
    input  wire                     iommu_read_m_axi_rvalid,
    output wire                     iommu_read_m_axi_rready,
    input  wire [2:0]               iommu_read_m_axi_rid,

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

    output reg                      interrupt,

    output wire [255:0] dbg_cd,
    output wire [63:0] dbg_first_entry,
    output wire [63:0] dbg_second_entry,
    output wire [63:0] dbg_third_entry,
    output wire [6:0] dbg_state,
    output wire [63:0] dbg_pa,
    output wire dbg_pa_ready,
    output wire [1:0] dbg_layer,
    output wire dbg_reset
);

    initial begin
        interrupt <= 0;
    end
    
    // instantiate the read and write channels
    iommu_r_channel r_channel (
        .clk(data_clk),
        .data_s_axi_araddr(data_s_axi_araddr),
        .data_s_axi_arlen(data_s_axi_arlen),
        .data_s_axi_arsize(data_s_axi_arsize),
        .data_s_axi_arburst(data_s_axi_arburst),
        .data_s_axi_arlock(data_s_axi_arlock),
        .data_s_axi_arcache(data_s_axi_arcache),
        .data_s_axi_arprot(data_s_axi_arprot),
        .data_s_axi_arvalid(data_s_axi_arvalid),
        .data_s_axi_arready(data_s_axi_arready),
        .data_s_axi_arid(data_s_axi_arid),
        
        .data_s_axi_rdata(data_s_axi_rdata),
        .data_s_axi_rresp(data_s_axi_rresp),
        .data_s_axi_rlast(data_s_axi_rlast),
        .data_s_axi_rvalid(data_s_axi_rvalid),
        .data_s_axi_rready(data_s_axi_rready),
        .data_s_axi_rid(data_s_axi_rid),

        .data_m_axi_araddr(data_m_axi_araddr),
        .data_m_axi_arlen(data_m_axi_arlen),
        .data_m_axi_arsize(data_m_axi_arsize),
        .data_m_axi_arburst(data_m_axi_arburst),
        .data_m_axi_arlock(data_m_axi_arlock),
        .data_m_axi_arcache(data_m_axi_arcache),
        .data_m_axi_arprot(data_m_axi_arprot),
        .data_m_axi_arvalid(data_m_axi_arvalid),
        .data_m_axi_arready(data_m_axi_arready),
        .data_m_axi_arid(data_m_axi_arid),

        .data_m_axi_rdata(data_m_axi_rdata),
        .data_m_axi_rresp(data_m_axi_rresp),
        .data_m_axi_rlast(data_m_axi_rlast),
        .data_m_axi_rvalid(data_m_axi_rvalid),
        .data_m_axi_rready(data_m_axi_rready),
        .data_m_axi_rid(data_m_axi_rid),

        .iommu_read_m_axi_araddr(iommu_read_m_axi_araddr),
        .iommu_read_m_axi_arlen(iommu_read_m_axi_arlen),
        .iommu_read_m_axi_arsize(iommu_read_m_axi_arsize),
        .iommu_read_m_axi_arburst(iommu_read_m_axi_arburst),
        .iommu_read_m_axi_arlock(iommu_read_m_axi_arlock),
        .iommu_read_m_axi_arcache(iommu_read_m_axi_arcache),
        .iommu_read_m_axi_arprot(iommu_read_m_axi_arprot),
        .iommu_read_m_axi_arvalid(iommu_read_m_axi_arvalid),
        .iommu_read_m_axi_arready(iommu_read_m_axi_arready),
        .iommu_read_m_axi_arid(iommu_read_m_axi_arid),

        .iommu_read_m_axi_rdata(iommu_read_m_axi_rdata),
        .iommu_read_m_axi_rresp(iommu_read_m_axi_rresp),
        .iommu_read_m_axi_rlast(iommu_read_m_axi_rlast),
        .iommu_read_m_axi_rvalid(iommu_read_m_axi_rvalid),
        .iommu_read_m_axi_rready(iommu_read_m_axi_rready),
        .iommu_read_m_axi_rid(iommu_read_m_axi_rid),

        .ddtp(ddtp),
        .flush(flush),

        .dbg_cd(dbg_cd),
        .dbg_first_entry(dbg_first_entry),
        .dbg_second_entry(dbg_second_entry),
        .dbg_third_entry(dbg_third_entry),
        .dbg_state(dbg_state),
        .dbg_pa(dbg_pa),
        .dbg_pa_ready(dbg_pa_ready),
        .dbg_layer(dbg_layer),
        .dbg_reset(dbg_reset)
    );

    // directly pass the write channel signals first
    assign data_m_axi_awaddr = data_s_axi_awaddr;
    assign data_m_axi_awlen = data_s_axi_awlen;
    assign data_m_axi_awsize = data_s_axi_awsize;
    assign data_m_axi_awburst = data_s_axi_awburst;
    assign data_m_axi_awlock = data_s_axi_awlock;
    assign data_m_axi_awcache = data_s_axi_awcache;
    assign data_m_axi_awprot = data_s_axi_awprot;
    assign data_m_axi_awvalid = data_s_axi_awvalid;
    assign data_s_axi_awready = data_m_axi_awready;
    assign data_m_axi_awid = data_s_axi_awid;

    assign data_m_axi_wdata = data_s_axi_wdata;
    assign data_m_axi_wstrb = data_s_axi_wstrb;
    assign data_m_axi_wlast = data_s_axi_wlast;
    assign data_m_axi_wvalid = data_s_axi_wvalid;
    assign data_s_axi_wready = data_m_axi_wready;

    assign data_s_axi_bresp = data_m_axi_bresp;
    assign data_s_axi_bvalid = data_m_axi_bvalid;
    assign data_m_axi_bready = data_s_axi_bready;
    assign data_s_axi_bid = data_m_axi_bid;


    // iommu_w_channel w_channel (
    //     .clk(data_clk),
    //     .data_s_axi_awaddr(data_s_axi_awaddr),
    //     .data_s_axi_awlen(data_s_axi_awlen),
    //     .data_s_axi_awsize(data_s_axi_awsize),
    //     .data_s_axi_awburst(data_s_axi_awburst),
    //     .data_s_axi_awlock(data_s_axi_awlock),
    //     .data_s_axi_awcache(data_s_axi_awcache),
    //     .data_s_axi_awprot(data_s_axi_awprot),
    //     .data_s_axi_awvalid(data_s_axi_awvalid),
    //     .data_s_axi_awready(data_s_axi_awready),
    //     .data_s_axi_awid(data_s_axi_awid),
        
    //     .data_s_axi_wdata(data_s_axi_wdata),
    //     .data_s_axi_wstrb(data_s_axi_wstrb),
    //     .data_s_axi_wlast(data_s_axi_wlast),
    //     .data_s_axi_wvalid(data_s_axi_wvalid),
    //     .data_s_axi_wready(data_s_axi_wready),
        
    //     .data_s_axi_bresp(data_s_axi_bresp),
    //     .data_s_axi_bvalid(data_s_axi_bvalid),
    //     .data_s_axi_bready(data_s_axi_bready),
    //     .data_s_axi_bid(data_s_axi_bid),
        
    //     .data_m_axi_awaddr(data_smaxi_awaddr),
    //     .data_m_axi_awlen(data_m_axi_awlen),
    //     .data_m_axi_awsize(data_m_axi_awsize),
    //     .data_m_axi_awburst(data_m_axi_awburst),
    //     .data_m_axi_awlock(data_m_axi_awlock),
    //     .data_m_axi_awcache(data_m_axi_awcache),
    //     .data_m_axi_awprot(data_m_axi_awprot),
    //     .data_m_axi_awvalid(data_m_axi_awvalid),
    //     .data_m_axi_awready(data_m_axi_awready),
    //     .data_m_axi_awid(data_m_axi_awid),

    //     .data_m_axi_wdata(data_m_axi_wdata),
    //     .data_m_axi_wstrb(data_m_axi_wstrb),
    //     .data_m_axi_wlast(data_m_axi_wlast),
    //     .data_m_axi_wvalid(data_m_axi_wvalid),
    //     .data_m_axi_wready(data_m_axi_wready),

    //     .data_m_axi_bresp(data_m_axi_bresp),
    //     .data_m_axi_bvalid(data_m_axi_bvalid),
    //     .data_m_axi_bready(data_m_axi_bready),
    //     .data_m_axi_bid(data_m_axi_bid),

    //     .iommu_write_m_axi_araddr(iommu_write_m_axi_araddr),
    //     .iommu_write_m_axi_arlen(iommu_write_m_axi_arlen),
    //     .iommu_write_m_axi_arsize(iommu_write_m_axi_arsize),
    //     .iommu_write_m_axi_arburst(iommu_write_m_axi_arburst),
    //     .iommu_write_m_axi_arlock(iommu_write_m_axi_arlock),
    //     .iommu_write_m_axi_arcache(iommu_write_m_axi_arcache),
    //     .iommu_write_m_axi_arprot(iommu_write_m_axi_arprot),
    //     .iommu_write_m_axi_arvalid(iommu_write_m_axi_arvalid),
    //     .iommu_write_m_axi_arready(iommu_write_m_axi_arready),
    //     .iommu_write_m_axi_arid(iommu_write_m_axi_arid),

    //     .iommu_write_m_axi_rdata(iommu_write_m_axi_rdata),
    //     .iommu_write_m_axi_rresp(iommu_write_m_axi_rresp),
    //     .iommu_write_m_axi_rlast(iommu_write_m_axi_rlast),
    //     .iommu_write_m_axi_rvalid(iommu_write_m_axi_rvalid),
    //     .iommu_write_m_axi_rready(iommu_write_m_axi_rready),
    //     .iommu_write_m_axi_rid(iommu_write_m_axi_rid),

    //     .ddtp(ddtp),
    //     .flush(flush)
    // );

endmodule
