// `timescale 1ns / 1ps

// // Use device id = 0 for now
// module iommu_walker(
//     input wire clk,
//     input wire [63:0] iova,
//     input wire iova_ready,
//     output wire [63:0] pa,
//     output wire pa_ready,

//     input wire [63:0] ddtp,
//     input wire [31:0] flush,

//     output wire [33:0]              iommu_m_axi_araddr,
//     output wire [7:0]               iommu_m_axi_arlen,
//     output wire [2:0]               iommu_m_axi_arsize,
//     output wire [1:0]               iommu_m_axi_arburst,
//     output wire                     iommu_m_axi_arlock,
//     output wire [3:0]               iommu_m_axi_arcache,
//     output wire [2:0]               iommu_m_axi_arprot,
//     output wire                     iommu_m_axi_arvalid,
//     input  wire                     iommu_m_axi_arready,
//     output wire [2:0]               iommu_m_axi_arid,
    
//     input  wire [255:0]             iommu_m_axi_rdata,
//     input  wire [1:0]               iommu_m_axi_rresp,
//     input  wire                     iommu_m_axi_rlast,
//     input  wire                     iommu_m_axi_rvalid,
//     output wire                     iommu_m_axi_rready,
//     input  wire [2:0]               iommu_m_axi_rid
// );
 
//     localparam STATE_IDLE =             7'h0;
//     localparam STATE_TSLT_1 =           7'h1;

//     reg [63:0] current_iova;
//     reg [6:0] state;

//     reg [33:0] araddr;
//     reg [7:0]  arlen;
//     reg [2:0]  arsize;
//     reg [1:0]  arburst;
//     reg        arlock;
//     reg [3:0]  arcache;
//     reg [2:0]  arprot;
//     reg        arvalid;
//     reg [2:0]  arid;
//     reg        rready;

//     reg [255:0] cd;
//     reg [63:0] first_entry;
//     reg [63:0] second_entry;
//     reg [63:0] third_entry;

//     reg [1:0] layer;

//     initial begin
//         state <= 7'b0;
//         current_iova <= 64'b0;

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
//     end

//     assign iommu_m_axi_araddr = araddr;
//     assign iommu_m_axi_arlen = arlen;
//     assign iommu_m_axi_arsize = arsize;
//     assign iommu_m_axi_arburst = arburst;
//     assign iommu_m_axi_arlock = arlock;
//     assign iommu_m_axi_arcache = arcache;
//     assign iommu_m_axi_arprot = arprot;
//     assign iommu_m_axi_arvalid = arvalid;
//     assign iommu_m_axi_arid = arid;
//     assign iommu_m_axi_rready = rready;

//     always @(posedge clk) begin
//         case (state)
//             STATE_IDLE: begin
//                 pa_ready <= 0;
//                 layer <= 0;
//                 if (iova_ready) begin
//                     current_iova <= iova;
//                     state <= STATE_TSLT_1;
//                 end
//             end

//             STATE_TSLT_1: begin // from now on, get the device context table entry
//                 araddr <= {ddtp[53:10], 12'b0};
//                 arvalid <= 1'b1;
//                 arlen <= 8'b3;  // request 256 bits
//                 state <= STATE_TSLT_2;
//             end

//             STATE_TSLT_2: begin
//                 if (iommu_m_axi_arready) begin
//                     arvalid <= 1'b0;
//                     rready <= 1'b1;
//                     state <= STATE_TSLT_3;
//                 end
//             end

//             STATE_TSLT_3: begin
//                 if (iommu_m_axi_rvalid) begin
//                     cd[63:0] <= iommu_m_axi_rdata;
//                     state <= STATE_TSLT_4;
//                 end
//             end

//             STATE_TSLT_4: begin
//                 if (iommu_m_axi_rvalid) begin
//                     cd[127:64] <= iommu_m_axi_rdata;
//                     state <= STATE_TSLT_5;
//                 end
//             end

//             STATE_TSLT_5: begin
//                 if (iommu_m_axi_rvalid) begin
//                     cd[191:128] <= iommu_m_axi_rdata;
//                     state <= STATE_TSLT_5;
//                 end
//             end

//             STATE_TSLT_6: begin
//                 if (iommu_m_axi_rvalid) begin
//                     cd[255:192] <= iommu_m_axi_rdata;
//                     state <= STATE_TSLT_5;
//                     rready <= 1'b0;
//                 end
//             end

//             // from now on, the cd holds the device context table entry

//             STATE_TSLT_7: begin
//                 if (layer == 0) begin
//                     araddr <= {cd[43:0], current_iova[38:30], 3'b0}; // pdtp << 12
//                 end else if (layer == 1) begin
//                     araddr <= {first_entry[53:10], current_iova[29:21], 3'b0};
//                 end else if (layer == 2) begin
//                     araddr <= {second_entry[53:10], current_iova[20:12], 3'b0};
//                 end else if (layer == 3) begin
//                     layer <= 0;
//                     state <= STATE_LAST;
//                 end

//                 arlen <= 1'b0;  // request 64 bits
//                 arvalid <= 1'b1;
//                 // layer <= layer + 1; // save until finish the current layer
//                 state <= STATE_TSLT_8;
//             end

//             STATE_TSLT_8: begin
//                 if (iommu_m_axi_arready) begin
//                     arvalid <= 1'b0;
//                     rready <= 1'b1;
//                     state <= STATE_TSLT_9;
//                 end
//             end

//             STATE_TSLT_9: begin
//                 if (iommu_m_axi_rvalid) begin
//                     if (layer == 0) begin
//                         first_entry <= iommu_m_axi_rdata;
//                     end else if (layer == 1) begin
//                         second_entry <= iommu_m_axi_rdata;
//                     end else if (layer == 2) begin
//                         third_entry <= iommu_m_axi_rdata;
//                     end
//                     arready <= 0;
//                     layer <= layer + 1;
//                     state <= STATE_TSLT_7;
//                 end
//             end

//             STATE_LAST: begin
//                 pa <= {third_entry[53:12], current_iova[11:0]};
//                 pa_ready <= 1;
//                 state <= STATE_IDLE;
//             end
//         endcase
//     end

// endmodule
