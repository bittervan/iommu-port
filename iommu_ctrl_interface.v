`timescale 1ns / 1ps

// This module controls 
module iommu_ctrl_interface(
    input  wire ctrl_clk,
    input  wire reset,
    input  wire [31:0]              ctrl_s_axi_awaddr,
    input  wire [7:0]               ctrl_s_axi_awlen,
    input  wire [2:0]               ctrl_s_axi_awsize,
    input  wire [1:0]               ctrl_s_axi_awburst,
    input  wire                     ctrl_s_axi_awlock,
    input  wire [3:0]               ctrl_s_axi_awcache,
    input  wire [2:0]               ctrl_s_axi_awprot,
    input  wire                     ctrl_s_axi_awvalid,
    output reg                      ctrl_s_axi_awready,
    
    input  wire [31:0]              ctrl_s_axi_wdata,
    input  wire [15:0]              ctrl_s_axi_wstrb,
    input  wire                     ctrl_s_axi_wlast,
    input  wire                     ctrl_s_axi_wvalid,
    output reg                      ctrl_s_axi_wready,
    
    output reg  [1:0]               ctrl_s_axi_bresp, // not used, always 0
    output reg                      ctrl_s_axi_bvalid,
    input  wire                     ctrl_s_axi_bready,
    
    input  wire [31:0]              ctrl_s_axi_araddr,
    input  wire [7:0]               ctrl_s_axi_arlen,
    input  wire [2:0]               ctrl_s_axi_arsize,
    input  wire [1:0]               ctrl_s_axi_arburst,
    input  wire                     ctrl_s_axi_arlock,
    input  wire [3:0]               ctrl_s_axi_arcache,
    input  wire [2:0]               ctrl_s_axi_arprot,
    input  wire                     ctrl_s_axi_arvalid,
    output reg                      ctrl_s_axi_arready,
   
    output reg  [31:0]              ctrl_s_axi_rdata,
    output reg  [1:0]               ctrl_s_axi_rresp, // not used, always 0
    output reg                      ctrl_s_axi_rlast,
    output reg                      ctrl_s_axi_rvalid,
    input  wire                     ctrl_s_axi_rready,

    output reg                      should_flush,
    output reg [63:0]               ddtp,

    input wire data_clk
    // input wire r_channel_flush_done,
    // input wire w_channel_flush_done
);

    localparam STATE_IDLE =             5'h0;
    localparam STATE_WRITE =            5'h1;
    localparam STATE_WRITE_1 =          5'h6;
    localparam STATE_READ =             5'h2;
    localparam STATE_RESP =             5'h3;
    localparam STATE_RESET =            5'h5;
    localparam STATE_SYNC =             5'h4;

    reg [4:0] state;
    reg [63:0] addr;

    reg [2:0] ctrl_sync_cnt;

    reg [4:0] data_state;
    reg [2:0] data_sync_cnt; // this clock is faster;
    reg [2:0] data_valid_cnt; // count the flush register;
    reg [31:0] flush;

    initial begin
        state <= STATE_IDLE;

        ctrl_s_axi_awready <= 0;
        ctrl_s_axi_wready <= 0;
        ctrl_s_axi_bresp <= 0;
        ctrl_s_axi_bvalid <= 0;
        ctrl_s_axi_arready <= 0;
        ctrl_s_axi_rdata <= 0;
        ctrl_s_axi_rresp <= 0;
        ctrl_s_axi_rlast <= 0;
        ctrl_s_axi_rvalid <= 0;

        ddtp <= 64'hdeadbeefcafebabe;
        flush <= 32'h0;

        should_flush <= 0;
        data_state <= 0;
        data_sync_cnt <= 0;
        ctrl_sync_cnt <= 0;
    end

    localparam DATA_STATE_IDLE   = 5'h0;
    localparam DATA_STATE_SAMPLE = 5'h1;

    always @ (posedge data_clk) begin
        case (data_state)
            DATA_STATE_IDLE: begin
                if (data_valid_cnt != 0) begin
                    should_flush <= 1;
                end else begin
                    should_flush <= 0;
                end
                data_valid_cnt <= 0;
                data_sync_cnt <= 0;
                data_state <= DATA_STATE_SAMPLE;
            end

            DATA_STATE_SAMPLE: begin
                if (data_sync_cnt == 8'h7) begin
                    data_state <= DATA_STATE_IDLE;
                end
                if (flush != 32'h0) begin
                    data_valid_cnt <= data_valid_cnt + 1;
                end
                data_sync_cnt <= data_sync_cnt + 1;
            end
        endcase
    end

    // support 1 data read/write only
    always @ (posedge ctrl_clk) begin
        case (state)

            STATE_IDLE: begin
                if (reset) begin
                    state <= STATE_RESET;
                end else if (ctrl_s_axi_awvalid) begin
                    state <= STATE_WRITE;
                    ctrl_s_axi_awready <= 1;
                    addr <= ctrl_s_axi_awaddr;
                end else if (ctrl_s_axi_arvalid) begin
                    state <= STATE_READ;
                    ctrl_s_axi_arready <= 1;
                    addr <= ctrl_s_axi_araddr;
                end
            end
            
            STATE_READ: begin
                ctrl_s_axi_arready <= 0;
                if (ctrl_s_axi_rready) begin
                    state <= STATE_RESET;
                    ctrl_s_axi_rvalid <= 1;
                    ctrl_s_axi_rresp <= 0;
                    ctrl_s_axi_rlast <= 1;

                    if (addr[4:0] == 5'hc) begin
                        ctrl_s_axi_rdata <= flush;
                    end else if (addr[4:0] == 5'h10) begin
                        ctrl_s_axi_rdata <= ddtp[31:0];
                    end else if (addr[4:0] == 5'h14) begin
                        ctrl_s_axi_rdata <= ddtp[63:32];
                    end else begin
                        ctrl_s_axi_rdata <= 32'h0d0e0a0d;
                    end
                end
            end

            STATE_WRITE: begin
                ctrl_s_axi_awready <= 0;
                ctrl_s_axi_wready <= 1;
                state <= STATE_WRITE_1;
            end

            STATE_WRITE_1: begin
                if (ctrl_s_axi_wvalid && ctrl_s_axi_wlast) begin
                    ctrl_s_axi_wready <= 0;

                    if (addr[4:0] == 5'hc) begin
                        flush <= ctrl_s_axi_wdata;
                        ctrl_sync_cnt <= 0;
                        state <= STATE_SYNC;
                    end else if (addr[4:0] == 5'h10) begin
                        ddtp[31:0] <= ctrl_s_axi_wdata;
                        state <= STATE_RESP;
                    end else if (addr[4:0] == 5'h14) begin
                        ddtp[63:32] <= ctrl_s_axi_wdata;
                        state <= STATE_RESP;
                    end else begin
                        state <= STATE_RESP;
                    end
 
                end
            end

            STATE_SYNC: begin
                ctrl_sync_cnt <= ctrl_sync_cnt + 1;
                if (ctrl_sync_cnt == 8'h7) begin
                    ctrl_sync_cnt <= 0;
                    state <= STATE_RESP;
                    flush <= 32'h0;
                end
            end

            STATE_RESP: begin
                if (ctrl_s_axi_bready) begin
                    ctrl_s_axi_bvalid <= 1;
                    state <= STATE_RESET;
                end
            end

            STATE_RESET: begin
                state <= STATE_IDLE;

                ctrl_s_axi_awready <= 0;
                ctrl_s_axi_wready <= 0;
                ctrl_s_axi_bresp <= 0;
                ctrl_s_axi_bvalid <= 0;
                ctrl_s_axi_arready <= 0;
                ctrl_s_axi_rdata <= 0;
                ctrl_s_axi_rresp <= 0;
                ctrl_s_axi_rlast <= 0;
                ctrl_s_axi_rvalid <= 0;
            end
                        
        endcase
    end

endmodule