`timescale 1ns / 1ps

module iommu_ioatc (
    input wire clk,
    input wire [63:0] iova,
    input wire iova_ready,
    output reg [63:0] pa,
    output reg done,
    output reg hit,

    input wire [63:0] new_pa,
    input wire [63:0] new_iova,
    input wire update_ready,
    output reg update_done,

    input wire flush,
    output reg flush_done
);

    // entry format
    // |  71 |    70 - 44  |   43 - 0  |
    // |  V  | IOVA[38:12] | PA[55:12] |
    reg [71:0] atc [0:127];
    reg [6:0] index;
    reg [3:0] state;
    reg [63:0] current_iova;
    reg [63:0] current_pa;

    localparam S_IDLE = 4'h0;
    localparam S_TSLT = 4'h1;
    localparam S_UPDT = 4'h2;
    localparam S_FLUSH= 4'h3;

    always @ (posedge clk) begin
        case (state)
            S_IDLE: begin
                done <= 0;
                hit <= 0;
                update_done <= 0;
                flush_done <= 1'b0;
                if (iova_ready) begin
                    current_iova <= iova;
                    index <= iova[18:12];
                    state <= S_TSLT;
                end else if (update_ready) begin
                    current_iova <= new_iova;
                    index <= iova[18:12];
                    current_pa <= new_pa;
                    state <= S_UPDT;
                end else if (flush) begin
                    index <= 0;
                    state <= S_FLUSH;
                end
            end

            S_FLUSH: begin
                if (index == 127) begin
                    flush_done <= 1;
                    state <= S_IDLE;
                    atc[index] <= 72'b0;
                end else begin
                    atc[index] <= 72'b0;
                    index <= index + 1;
                end
            end

            S_TSLT: begin
                if (atc[index][71] && (atc[index][70:44] == current_iova[38:12])) begin
                    pa <= {atc[index][43:0], iova[11:0]};
                    done <= 1;
                    hit <= 1;
                end else begin
                    pa <= 64'h0102030405060708;
                    done <= 1;
                    hit <= 0;
                end
                state <= S_IDLE;
            end

            S_UPDT: begin
                atc[index] <= {1'b1, new_iova[38:12], new_pa[55:12]};
                update_done <= 1;
                state <= S_IDLE;
            end

            default: state <= S_IDLE;
        endcase
    end

    initial begin
        index <= 0;
        state <= S_IDLE;
        done <= 0;
        hit <= 0;

        update_done <= 0;
        pa <= 0;

        flush_done <= 1'b0;

        // set all entries to zero, without for loop
        atc[0] <= 72'b0;
        atc[1] <= 72'b0;
        atc[2] <= 72'b0;
        atc[3] <= 72'b0;
        atc[4] <= 72'b0;
        atc[5] <= 72'b0;
        atc[6] <= 72'b0;
        atc[7] <= 72'b0;
        atc[8] <= 72'b0;
        atc[9] <= 72'b0;
        atc[10] <= 72'b0;
        atc[11] <= 72'b0;
        atc[12] <= 72'b0;
        atc[13] <= 72'b0;
        atc[14] <= 72'b0;
        atc[15] <= 72'b0;
        atc[16] <= 72'b0;
        atc[17] <= 72'b0;
        atc[18] <= 72'b0;
        atc[19] <= 72'b0;
        atc[20] <= 72'b0;
        atc[21] <= 72'b0;
        atc[22] <= 72'b0;
        atc[23] <= 72'b0;
        atc[24] <= 72'b0;
        atc[25] <= 72'b0;
        atc[26] <= 72'b0;
        atc[27] <= 72'b0;
        atc[28] <= 72'b0;
        atc[29] <= 72'b0;
        atc[30] <= 72'b0;
        atc[31] <= 72'b0;
        atc[32] <= 72'b0;
        atc[33] <= 72'b0;
        atc[34] <= 72'b0;
        atc[35] <= 72'b0;
        atc[36] <= 72'b0;
        atc[37] <= 72'b0;
        atc[38] <= 72'b0;
        atc[39] <= 72'b0;
        atc[40] <= 72'b0;
        atc[41] <= 72'b0;
        atc[42] <= 72'b0;
        atc[43] <= 72'b0;
        atc[44] <= 72'b0;
        atc[45] <= 72'b0;
        atc[46] <= 72'b0;
        atc[47] <= 72'b0;
        atc[48] <= 72'b0;
        atc[49] <= 72'b0;
        atc[50] <= 72'b0;
        atc[51] <= 72'b0;
        atc[52] <= 72'b0;
        atc[53] <= 72'b0;
        atc[54] <= 72'b0;
        atc[55] <= 72'b0;
        atc[56] <= 72'b0;
        atc[57] <= 72'b0;
        atc[58] <= 72'b0;
        atc[59] <= 72'b0;
        atc[60] <= 72'b0;
        atc[61] <= 72'b0;
        atc[62] <= 72'b0;
        atc[63] <= 72'b0;
        atc[64] <= 72'b0;
        atc[65] <= 72'b0;
        atc[66] <= 72'b0;
        atc[67] <= 72'b0;
        atc[68] <= 72'b0;
        atc[69] <= 72'b0;
        atc[70] <= 72'b0;
        atc[71] <= 72'b0;
        atc[72] <= 72'b0;
        atc[73] <= 72'b0;
        atc[74] <= 72'b0;
        atc[75] <= 72'b0;
        atc[76] <= 72'b0;
        atc[77] <= 72'b0;
        atc[78] <= 72'b0;
        atc[79] <= 72'b0;
        atc[80] <= 72'b0;
        atc[81] <= 72'b0;
        atc[82] <= 72'b0;
        atc[83] <= 72'b0;
        atc[84] <= 72'b0;
        atc[85] <= 72'b0;
        atc[86] <= 72'b0;
        atc[87] <= 72'b0;
        atc[88] <= 72'b0;
        atc[89] <= 72'b0;
        atc[90] <= 72'b0;
        atc[91] <= 72'b0;
        atc[92] <= 72'b0;
        atc[93] <= 72'b0;
        atc[94] <= 72'b0;
        atc[95] <= 72'b0;
        atc[96] <= 72'b0;
        atc[97] <= 72'b0;
        atc[98] <= 72'b0;
        atc[99] <= 72'b0;
        atc[100] <= 72'b0;
        atc[101] <= 72'b0;
        atc[102] <= 72'b0;
        atc[103] <= 72'b0;
        atc[104] <= 72'b0;
        atc[105] <= 72'b0;
        atc[106] <= 72'b0;
        atc[107] <= 72'b0;
        atc[108] <= 72'b0;
        atc[109] <= 72'b0;
        atc[110] <= 72'b0;
        atc[111] <= 72'b0;
        atc[112] <= 72'b0;
        atc[113] <= 72'b0;
        atc[114] <= 72'b0;
        atc[115] <= 72'b0;
        atc[116] <= 72'b0;
        atc[117] <= 72'b0;
        atc[118] <= 72'b0;
        atc[119] <= 72'b0;
        atc[120] <= 72'b0;
        atc[121] <= 72'b0;
        atc[122] <= 72'b0;
        atc[123] <= 72'b0;
        atc[124] <= 72'b0;
        atc[125] <= 72'b0;
        atc[126] <= 72'b0;
        atc[127] <= 72'b0;
    end

endmodule
