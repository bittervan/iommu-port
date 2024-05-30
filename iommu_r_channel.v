`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/23/2024 10:22:59 AM
// Design Name: 
// Module Name: iommu_r_channel
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module iommu_r_channel (
    input wire clk,
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

    input wire [63:0]               ddtp,
    input wire [31:0]               flush,

    // output wire [7:0]               dbg_channel_state,
    // output wire [7:0]               dbg_walker_state,
    // output wire                     dbg_channel_iova_valid,
    // output wire                     dbg_channel_iova_ready,
    // output wire [256:0]             dbg_walker_cd,
    // output wire [63:0]              dbg_first_entry,
    // output wire [63:0]              dbg_second_entry,
    // output wire [63:0]              dbg_third_entry,
    output wire [7:0] dbg_wait_cnt,
    output wire [1:0] dbg_condition,
    output wire [63:0]              dbg_tslt_addr,
    output reg  dbg_addr_not_match,
    output wire [7:0] dbg_translator_state,
    output wire [7:0] dbg_walker_state,
    output wire dbg_walker_arvalid,
    output wire dbg_walker_bug,
    output wire dbg_translator_tle,
    output wire dbg_walker_reset,
    output wire dbg_atc_flush_done,
    output wire dbg_translator_should_flush
);

    // ** 2.29 modification

    reg [8:0] wait_cnt;
    reg m_axi_arvalid;
    reg s_axi_arready;
    reg [63:0] m_axi_araddr;
    reg [1:0] condition;
    reg [63:0] iova;
    reg iova_ready;
    reg prev_data_s_axi_arvalid;

    assign dbg_wait_cnt = wait_cnt;
    assign dbg_condition = condition;

    wire [63:0] pa;
    wire pa_ready;

    initial begin
        wait_cnt <= 8'b0;
        m_axi_arvalid <= 1'b0;
        condition <= 2'b00;
        s_axi_arready <= 1'b0;
        iova <= 63'b0;
        iova_ready <= 1'b0;
        prev_data_s_axi_arvalid <= 1'b0;
        dbg_addr_not_match <= 1'b0;
    end

    // always @ (posedge clk) begin
    //     if ((m_axi_arvalid == 1'b1) && (data_m_axi_arready == 1'b1)) begin
    //         wait_cnt <= 9'h0;
    //         condition <= 2'b01;
    //     end else if ((data_s_axi_arvalid == 1'b1)) begin
    //         wait_cnt <= wait_cnt + 9'h1;
    //         condition <= 2'b10;
    //     end else begin
    //         wait_cnt <= 9'h0;
    //         condition <= 2'b11;
    //     end
    // end

    always @ (posedge clk) begin
        prev_data_s_axi_arvalid <= data_s_axi_arvalid;
    end

    always @ (posedge clk) begin
        if ((prev_data_s_axi_arvalid == 1'b0) && (data_s_axi_arvalid == 1'b1)) begin
            iova <= data_s_axi_araddr;
            iova_ready <= 1'b1;
        end else begin
            iova_ready <= 1'b0;
        end
    end

    always @ (posedge clk) begin
        if (pa_ready == 1'b1) begin
            if (iova != pa) begin
                dbg_addr_not_match <= 1'b1;
            end
            m_axi_araddr <= pa;
            m_axi_arvalid <= 1'b1;
            s_axi_arready <= 1'b0;
        end else if ((m_axi_arvalid == 1'b1) && (data_m_axi_arready == 1'b1)) begin
            m_axi_arvalid <= 1'b0;
            s_axi_arready <= 1'b1;
        end else begin
            m_axi_arvalid <= 1'b0;
            s_axi_arready <= 1'b0;
        end
    end

    // directly send s signals to m signals
    // assign data_m_axi_araddr = data_s_axi_araddr;
    assign data_m_axi_araddr = m_axi_araddr;
    assign data_m_axi_arlen = data_s_axi_arlen;
    assign data_m_axi_arsize = data_s_axi_arsize;
    assign data_m_axi_arburst = data_s_axi_arburst;
    assign data_m_axi_arlock = data_s_axi_arlock;
    assign data_m_axi_arcache = data_s_axi_arcache;
    assign data_m_axi_arprot = data_s_axi_arprot;
    // assign data_m_axi_arvalid = data_s_axi_arvalid;
    assign data_m_axi_arvalid = m_axi_arvalid;
    // assign data_s_axi_arready = data_m_axi_arready;
    assign data_s_axi_arready = s_axi_arready;
    assign data_m_axi_arid = data_s_axi_arid;

    assign data_s_axi_rdata = data_m_axi_rdata;
    assign data_s_axi_rresp = data_m_axi_rresp;
    assign data_s_axi_rlast = data_m_axi_rlast;
    assign data_s_axi_rvalid = data_m_axi_rvalid;
    assign data_m_axi_rready = data_s_axi_rready;
    assign data_s_axi_rid = data_m_axi_rid;

    iommu_address_translator translator (
        .clk(clk),
        .iova(iova),
        .iova_ready(iova_ready),
        .pa(pa),
        .pa_ready(pa_ready),
        .ddtp(ddtp),
        .flush(flush),
        .reset(0),

        .iommu_m_axi_araddr(iommu_read_m_axi_araddr),
        .iommu_m_axi_arlen(iommu_read_m_axi_arlen),
        .iommu_m_axi_arsize(iommu_read_m_axi_arsize),
        .iommu_m_axi_arburst(iommu_read_m_axi_arburst),
        .iommu_m_axi_arlock(iommu_read_m_axi_arlock),
        .iommu_m_axi_arcache(iommu_read_m_axi_arcache),
        .iommu_m_axi_arprot(iommu_read_m_axi_arprot),
        .iommu_m_axi_arvalid(iommu_read_m_axi_arvalid),
        .iommu_m_axi_arready(iommu_read_m_axi_arready),
        .iommu_m_axi_arid(iommu_read_m_axi_arid),

        .iommu_m_axi_rdata(iommu_read_m_axi_rdata),
        .iommu_m_axi_rresp(iommu_read_m_axi_rresp),
        .iommu_m_axi_rlast(iommu_read_m_axi_rlast),
        .iommu_m_axi_rvalid(iommu_read_m_axi_rvalid),
        .iommu_m_axi_rready(iommu_read_m_axi_rready),
        .iommu_m_axi_rid(iommu_read_m_axi_rid),

        .dbg_tslt_addr(dbg_tslt_addr),
        .dbg_translator_state(dbg_translator_state),
        .dbg_walker_state(dbg_walker_state),
        .dbg_walker_arvalid(dbg_walker_arvalid),

        .dbg_walker_bug(dbg_walker_bug),
        .dbg_translator_tle(dbg_translator_tle),
        .dbg_walker_reset(dbg_walker_reset),
        .dbg_atc_flush_done(dbg_atc_flush_done),
        .dbg_translator_should_flush(dbg_translator_should_flush)
    );
    // ** 2.29 modification done


    // reg [63:0]  iova;
    // reg [63:0]  phys;
    // reg iova_valid;

    // reg [63:0] m_araddr;
    // reg [7:0] m_arlen;
    // reg [2:0] m_arsize;
    // reg [1:0] m_arburst;
    // reg m_arlock;
    // reg [3:0] m_arcache;
    // reg [2:0] m_arprot;
    // reg m_arvalid;
    // reg s_arready;
    // reg [2:0] m_arid;

    // // also have to cache the other ar signals
    // reg [7:0] arlen_cache;
    // reg [2:0] arsize_cache;
    // reg [1:0] arburst_cache;
    // reg arlock_cache;
    // reg [3:0] arcache_cache;
    // reg [2:0] arprot_cache;
    // reg [2:0] arid_cache;

    // // assign data_m_axi_araddr =  data_s_daxi_araddr[33:0];
    // assign data_m_axi_araddr =  m_araddr;
    // // assign data_m_axi_arlen =   data_s_axi_arlen;
    // assign data_m_axi_arlen =   m_arlen;
    // // assign data_m_axi_arsize =  data_s_axi_arsize;
    // assign data_m_axi_arsize =  m_arsize;
    // // assign data_m_axi_arburst = data_s_axi_arburst;
    // assign data_m_axi_arburst = m_arburst;
    // // assign data_m_axi_arlock =  data_s_axi_arlock;
    // assign data_m_axi_arlock = m_arlock;
    // // assign data_m_axi_arcache = data_s_axi_arcache;
    // assign data_m_axi_arcache = m_arcache;
    // // assign data_m_axi_arprot =  data_s_axi_arprot;
    // assign data_m_axi_arprot = m_arprot;
    // // assign data_m_axi_arvalid = data_s_axi_arvalid;
    // assign data_m_axi_arvalid = m_arvalid;
    // // assign data_s_axi_arready = data_m_axi_arready;
    // assign data_s_axi_arready = s_arready;
    // // assign data_s_axi_arready = data_s_axi_arvalid && (iova_valid[data_s_axi_arid] == 1'b0); // cache it!
    // // assign data_m_axi_arid =    data_s_axi_arid;
    // assign data_m_axi_arid = m_arid;
    
    // assign data_s_axi_rdata =   data_m_axi_rdata;
    // assign data_s_axi_rresp =   data_m_axi_rresp;
    // assign data_s_axi_rlast =   data_m_axi_rlast;
    // assign data_s_axi_rvalid =  data_m_axi_rvalid;
    // assign data_m_axi_rready =  data_s_axi_rready;
    // // This doesn't have to be postponed, because the master may assert rready before the handshake is finished, but the slave will not response
    // assign data_s_axi_rid =     data_m_axi_rid;

    // // initialize the m registers to 0
    // initial begin
    //     m_araddr <= 34'b0;
    //     m_arlen <= 8'b0;
    //     m_arsize <= 3'h0;
    //     m_arburst <= 2'b0;
    //     m_arlock <= 1'b0;
    //     m_arcache <= 4'b0;
    //     m_arprot <= 3'b0;
    //     m_arvalid <= 1'b0;
    //     s_arready <= 1'b0;
    //     m_arid <= 3'b0;
    // end

    // // wire s_handshake;
    // // wire m_handshake;
    // // assign s_handshake = data_s_axi_arvalid & data_s_axi_arready;
    // // assign m_handshake = data_m_axi_arvalid & data_m_axi_arready;

    // // reg [2:0] current_id;
    // reg [7:0] state;
    // // reg [63:0] iova;
    // reg iova_ready;
    // wire [63:0] pa;
    // wire pa_ready;

    // localparam STATE_IDLE = 8'h0;
    // localparam STATE_TSLT = 8'h1;
    // localparam STATE_WAIT = 8'h2;
    // localparam STATE_HDSK = 8'h3;

    // assign dbg_channel_state = state;
    // assign dbg_channel_iova_ready = iova_ready;

    // initial begin 
    //     // current_id <= 3'b0;
    //     state <= 8'b0;
    //     iova_valid <= 0;
    //     iova_ready <= 0;
    // end

    // always @ (posedge clk) begin
    //     if (iova_valid == 0 && data_s_axi_arvalid == 1 && s_arready == 0) begin // the arvalid is not ready
    //         s_arready <= 1;
    //     end else begin
    //         s_arready <= 0;
    //     end
    // end

    // always @ (posedge clk) begin
    //     if (data_s_axi_arvalid && data_s_axi_arready) begin
    //         iova <= data_s_axi_araddr;
    //         iova_valid <= 1;
    //         // cache the other signals
    //         arlen_cache <= data_s_axi_arlen;
    //         arsize_cache <= data_s_axi_arsize;
    //         arburst_cache <= data_s_axi_arburst;
    //         arlock_cache <= data_s_axi_arlock;
    //         arcache_cache <= data_s_axi_arcache;
    //         arprot_cache <= data_s_axi_arprot;
    //         arid_cache <= data_s_axi_arid;
    //     end else begin
    //         iova_valid <= 0;
    //     end
    // end

    // assign dbg_channel_iova_valid = iova_valid;

    // always @ (posedge clk) begin
    //     // state <= 8'h0;
    //     if (state == STATE_IDLE) begin
    //         m_arvalid <= 0;
    //         if (iova_valid == 1) begin
    //             state <= STATE_TSLT;
    //         end else begin
    //             state <= STATE_IDLE;
    //         end
    //     end else if (state == STATE_TSLT) begin
    //         iova_ready <= 1;
    //         state <= STATE_WAIT;
    //     end else if (state == STATE_WAIT) begin
    //         iova_ready <= 0;
    //         if (pa_ready) begin
    //             phys <= pa;
    //             state <= STATE_HDSK;
    //         end else begin
    //             phys <= 64'b0;
    //             state <= STATE_WAIT;
    //         end
    //     end else if (state == STATE_HDSK) begin
    //         m_araddr <= iova;
    //         m_arlen <= arlen_cache;
    //         m_arsize <= arsize_cache;
    //         m_arburst <= arburst_cache;
    //         m_arlock <= arlock_cache;
    //         m_arcache <= arcache_cache;
    //         m_arprot <= arprot_cache;
    //         m_arid <= arid_cache;
    //         m_arvalid <= 1;
    //         if (data_m_axi_arready) begin
    //             state <= STATE_IDLE;
    //         end else begin
    //             state <= STATE_HDSK;
    //         end
    //     end else begin
    //         state <= STATE_IDLE;
    //     end
    // end
    // // always @ (posedge clk) begin
    // //     case (state)
    // //         STATE_IDLE: begin
    // //             m_arvalid <= 0;
    // //             if (iova_valid == 1) begin
    // //                 state <= STATE_TSLT;
    // //             end
    // //         end

    // //         STATE_TSLT: begin
    // //             iova_ready <= 1;
    // //             state <= STATE_WAIT;
    // //         end

    // //         STATE_WAIT: begin
    // //             iova_ready <= 0;
    // //             if (pa_ready) begin
    // //                 phys <= pa;
    // //                 state <= STATE_HDSK;
    // //             end else begin

    // //             end
    // //         end

    // //         STATE_HDSK: begin
    // //             m_araddr <= phys;
    // //             m_arlen <= arlen_cache;
    // //             m_arsize <= arsize_cache;
    // //             m_arburst <= arburst_cache;
    // //             m_arlock <= arlock_cache;
    // //             m_arcache <= arcache_cache;
    // //             m_arprot <= arprot_cache;
    // //             m_arid <= arid_cache;
    // //             // m_arvalid <= 1 & ((data_m_axi_arready == 1) || (data_m_axi_arvalid == 0));

    // //             if (m_arvalid && data_m_axi_arready) begin
    // //                 state <= STATE_IDLE;
    // //             end else begin

    // //             end
    // //         end

    // //         default: begin
    // //             state <= STATE_IDLE;
    // //         end
    // //     endcase
    // // end

    // iommu_walker r_walker (
    //     .clk(clk),
    //     .iova(iova),
    //     .iova_ready(iova_ready),
    //     .pa(pa),
    //     .pa_ready(pa_ready),
    //     .ddtp(ddtp),
    //     .flush(flush),
    //     .reset(0),

    //     .iommu_m_axi_araddr(iommu_read_m_axi_araddr),
    //     .iommu_m_axi_arlen(iommu_read_m_axi_arlen),
    //     .iommu_m_axi_arsize(iommu_read_m_axi_arsize),
    //     .iommu_m_axi_arburst(iommu_read_m_axi_arburst),
    //     .iommu_m_axi_arlock(iommu_read_m_axi_arlock),
    //     .iommu_m_axi_arcache(iommu_read_m_axi_arcache),
    //     .iommu_m_axi_arprot(iommu_read_m_axi_arprot),
    //     .iommu_m_axi_arvalid(iommu_read_m_axi_arvalid),
    //     .iommu_m_axi_arready(iommu_read_m_axi_arready),
    //     .iommu_m_axi_arid(iommu_read_m_axi_arid),

    //     .iommu_m_axi_rdata(iommu_read_m_axi_rdata),
    //     .iommu_m_axi_rresp(iommu_read_m_axi_rresp),
    //     .iommu_m_axi_rlast(iommu_read_m_axi_rlast),
    //     .iommu_m_axi_rvalid(iommu_read_m_axi_rvalid),
    //     .iommu_m_axi_rready(iommu_read_m_axi_rready),
    //     .iommu_m_axi_rid(iommu_read_m_axi_rid),

    //     .dbg_walker_state(dbg_walker_state),
    //     .dbg_walker_cd(dbg_walker_cd),
    //     .dbg_first_entry(dbg_first_entry),
    //     .dbg_second_entry(dbg_second_entry),
    //     .dbg_third_entry(dbg_third_entry)
    // );

endmodule