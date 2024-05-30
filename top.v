`timescale 1 ps / 1 ps

module top
   (ddr4_act_n,
    ddr4_adr,
    ddr4_ba,
    ddr4_bg,
    ddr4_ck_c,
    ddr4_ck_t,
    ddr4_cke,
    ddr4_cs_n,
    ddr4_dm_n,
    ddr4_dq,
    ddr4_dqs_c,
    ddr4_dqs_t,
    ddr4_odt,
    ddr4_reset_n,
    fan_en,
    mem_ok,
    pcie_rxn,
    pcie_rxp,
    pcie_txn,
    pcie_txp,
    pcie_refclk_clk_p,
    pcie_refclk_clk_n,
    sdio_cdn,
    sdio_clk,
    sdio_cmd,
    sdio_dat,
    sys_clk_clk_n,
    sys_clk_clk_p,
    sys_rstn,
    uart_rxd,
    uart_txd,
    disable_ssdb,
    reset_ssdb
    );
  output disable_ssdb;
  output reset_ssdb;
  output ddr4_act_n;
  output [16:0]ddr4_adr;
  output [1:0]ddr4_ba;
  output [0:0]ddr4_bg;
  output [0:0]ddr4_ck_c;
  output [0:0]ddr4_ck_t;
  output [0:0]ddr4_cke;
  output [0:0]ddr4_cs_n;
  inout [7:0]ddr4_dm_n;
  inout [63:0]ddr4_dq;
  inout [7:0]ddr4_dqs_c;
  inout [7:0]ddr4_dqs_t;
  output [0:0]ddr4_odt;
  output ddr4_reset_n;
  output [0:0]fan_en;
  output mem_ok;
  input [3:0]pcie_rxn;
  input [3:0]pcie_rxp;
  output [3:0]pcie_txn;
  output [3:0]pcie_txp;
  input pcie_refclk_clk_p;
  input pcie_refclk_clk_n;
  input sdio_cdn;
  output sdio_clk;
  inout sdio_cmd;
  inout [3:0]sdio_dat;
  input [0:0]sys_clk_clk_n;
  input [0:0]sys_clk_clk_p;
  input sys_rstn;
  input uart_rxd;
  output uart_txd;
  
  wire refclk;
  wire sys_clk_gt;
  wire disable_ssdb;
  wire reset_ssdb;
  
  assign disable_ssdb = 1'b0;
  assign reset_ssdb = 1'b0;
  
  IBUFDS_GTE3 # (.REFCLK_HROW_CK_SEL(2'b00)) refclk_ibuf (.O(sys_clk_gt), .ODIV2(refclk), .I(pcie_refclk_clk_p), .CEB(1'b0), .IB(pcie_refclk_clk_n));

  wire ddr4_act_n;
  wire [16:0]ddr4_adr;
  wire [1:0]ddr4_ba;
  wire [0:0]ddr4_bg;
  wire [0:0]ddr4_ck_c;
  wire [0:0]ddr4_ck_t;
  wire [0:0]ddr4_cke;
  wire [0:0]ddr4_cs_n;
  wire [7:0]ddr4_dm_n;
  wire [63:0]ddr4_dq;
  wire [7:0]ddr4_dqs_c;
  wire [7:0]ddr4_dqs_t;
  wire [0:0]ddr4_odt;
  wire ddr4_reset_n;
  wire [0:0]fan_en;
  wire mem_ok;
  wire [3:0]pcie_rxn;
  wire [3:0]pcie_rxp;
  wire [3:0]pcie_txn;
  wire [3:0]pcie_txp;
  
  wire sdio_cdn;
  wire sdio_clk;
  wire sdio_cmd;
  wire [3:0]sdio_dat;
  wire [0:0]sys_clk_clk_n;
  wire [0:0]sys_clk_clk_p;
  
  
  wire sys_rstn;
  wire uart_rxd;
  wire uart_txd;

  riscv riscv_i
       (.ddr4_act_n(ddr4_act_n),
        .ddr4_adr(ddr4_adr),
        .ddr4_ba(ddr4_ba),
        .ddr4_bg(ddr4_bg),
        .ddr4_ck_c(ddr4_ck_c),
        .ddr4_ck_t(ddr4_ck_t),
        .ddr4_cke(ddr4_cke),
        .ddr4_cs_n(ddr4_cs_n),
        .ddr4_dm_n(ddr4_dm_n),
        .ddr4_dq(ddr4_dq),
        .ddr4_dqs_c(ddr4_dqs_c),
        .ddr4_dqs_t(ddr4_dqs_t),
        .ddr4_odt(ddr4_odt),
        .ddr4_reset_n(ddr4_reset_n),
        .fan_en(fan_en),
        .mem_ok(mem_ok),
        .pcie_rxn(pcie_rxn),
        .pcie_rxp(pcie_rxp),
        .pcie_txn(pcie_txn),
        .pcie_txp(pcie_txp),
        .refclk(refclk),
        .sdio_cdn(sdio_cdn),
        .sdio_clk(sdio_clk),
        .sdio_cmd(sdio_cmd),
        .sdio_dat(sdio_dat),
        .sys_clk_clk_n(sys_clk_clk_n),
        .sys_clk_clk_p(sys_clk_clk_p),
        .sys_clk_gt(sys_clk_gt),
        .sys_rstn(sys_rstn),
        .uart_rxd(uart_rxd),
        .uart_txd(uart_txd));
endmodule