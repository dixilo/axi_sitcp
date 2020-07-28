`timescale 1ns / 1ps

module axi_sitcp(
    // phy signals
    input wire phy_clk_p,
    input wire phy_clk_n,
    output wire phy_rst_n,
    input wire phy_rxp,
    input wire phy_rxn,
    output wire phy_txp,
    output wire phy_txn,

    // AXI master
    input wire m_axi_aclk,           // 200 MHz
    input wire m_axi_aresetn,        // reset

    output wire [31:0] m_axi_awaddr, // write address
    output wire [2:0]  m_axi_awprot, // write channel protection type
    output wire        m_axi_awvalid,// write address valid
    input  wire        m_axi_awready,// write address ready

    output wire [31:0] m_axi_wdata,  // write data channel
    output wire [3:0]  m_axi_wstrb,  // valid lanes
    output wire        m_axi_wvalid, // write valid
    input  wire        m_axi_wready, // write ready

    input  wire [1:0]  m_axi_bresp,  // write response channel
    input  wire        m_axi_bvalid, // write response channel valid
    output wire        m_axi_bready, // write response channel ready

    output wire [31:0] m_axi_araddr, // read address
    output wire [2:0]  m_axi_arprot, // read channel protection type
    output wire        m_axi_arvalid,// read address valid
    input  wire        m_axi_arready,// read address ready
    input  wire [31:0] m_axi_rdata,  // read data
    input  wire        m_axi_rvalid, // read valid
    output wire        m_axi_rready, // read ready
    input  wire [1:0]  m_axi_rresp   // read response

    );

    //////////////// Clock definitions
    // 125
    wire clk_125; // 125 MHz
    wire rst_125; // 125 MHz

    //////////////// GMII wires
    // gmii
    wire [7:0] gmii_txd;
    wire gmii_tx_en;
    wire gmii_tx_er;
    wire [7:0] gmii_rxd;
    wire gmii_rx_dv;
    wire gmii_rx_er;

    wire an_interrupt;
    wire [15:0] an_adv_config_vector;
    wire an_adv_config_val;
    wire an_restart_config;
    wire [15:0] pcspma_an_config_vector;
    wire mmcm_locked_out;

    assign an_adv_config_vector[15]    = 1'b1;    // SGMII link status
    assign an_adv_config_vector[14]    = 1'b1;    // SGMII Acknowledge
    assign an_adv_config_vector[13:12] = 2'b01;   // full duplex
    assign an_adv_config_vector[11:10] = 2'b10;   // SGMII speed
    assign an_adv_config_vector[9]     = 1'b0;    // reserved
    assign an_adv_config_vector[8:7]   = 2'b00;   // pause frames - SGMII reserved
    assign an_adv_config_vector[6]     = 1'b0;    // reserved
    assign an_adv_config_vector[5]     = 1'b0;    // full duplex - SGMII reserved
    assign an_adv_config_vector[4:1]   = 4'b0000; // reserved
    assign an_adv_config_vector[0]     = 1'b1;    // SGMII

    wire [15:0] status_vector;
    wire [1:0] status_speed = status_vector[11:10];

    gig_ethernet_pcs_pma gepp_inst (
        .txn(phy_txn),                     // output wire txn
        .txp(phy_txp),                     // output wire txp
        .rxn(phy_rxn),                     // input wire rxn
        .rxp(phy_rxp),                     // input wire rxp

        .mmcm_locked_out(mmcm_locked_out), // output wire mmcm_locked_out
        .sgmii_clk_r(),                    // output wire sgmii_clk_r
        .sgmii_clk_f(),                    // output wire sgmii_clk_f
        .sgmii_clk_en(),                   // output wire sgmii_clk_en
        .clk125_out(clk_125),              // output wire clk125_out
        .clk625_out(),                     // output wire clk625_out
        .clk312_out(),                     // output wire clk312_out
        .rst_125_out(rst_125),             // output wire rst_125_out
        .refclk625_n(phy_clk_n),           // input wire refclk625_n
        .refclk625_p(phy_clk_p),           // input wire refclk625_p
        .gmii_txd(gmii_txd),               // input wire [7 : 0] gmii_txd
        .gmii_tx_en(gmii_tx_en),           // input wire gmii_tx_en
        .gmii_tx_er(gmii_tx_er),           // input wire gmii_tx_er
        .gmii_rxd(gmii_rxd),               // output wire [7 : 0] gmii_rxd
        .gmii_rx_dv(gmii_rx_dv),           // output wire gmii_rx_dv
        .gmii_rx_er(gmii_rx_er),           // output wire gmii_rx_er
        .gmii_isolate(),                   // output wire gmii_isolate
        .configuration_vector(5'b10000),   // auto-negotiation enable
        .an_interrupt(an_interrupt),       // output wire an_interrupt
        .an_adv_config_vector(an_adv_config_vector),  // input wire [15 : 0] an_adv_config_vector
        .an_restart_config(1'b0),          // input wire an_restart_config
        .speed_is_10_100(status_speed != 2'b10), // input wire speed_is_10_100
        .speed_is_100(status_speed == 2'b01),// input wire speed_is_100
        .status_vector(status_vector),     // output wire [15 : 0] status_vector
        .reset(sys_rst),                   // input wire reset
        .signal_detect(1'b1),              // input wire signal_detect
        .idelay_rdy_out()                  // output wire idelay_rdy_out
    );

    wire eeprom_cs;
    wire eeprom_sk;
    wire eeprom_di;
    wire eeprom_do;

    wire tcp_open_ack;
    wire tcp_error;
    wire tcp_close_req;
    wire tcp_close_ack;

    wire tcp_rx_wr;
    wire [7:0] tcp_rxd;

    wire tcp_tx_full;
    wire tcp_tx_wr;
    wire [7:0] tcp_txd;

    assign tcp_close_ack = tcp_close_req;

    wire rbcp_act;
    wire [31:0] rbcp_addr;
    wire [7:0] rbcp_wd;
    wire rbcp_we;
    wire rbcp_re;
    wire rbcp_ack;
    wire [7:0] rbcp_rd;

    // SiTCP instantiation

    WRAP_SiTCP_GMII_XCKU_32K sitcp_inst(
        .CLK(m_axi_aclk),
        .RST(~m_axi_aresetn),
        // Configuration parameters
        .FORCE_DEFAULTn(), //: Load default parameters
        .EXT_IP_ADDR(32'd0),    // in: IP address[31:0]
        .EXT_TCP_PORT(16'd0),   // in: TCP port #[15:0]
        .EXT_RBCP_PORT(16'd0),  // in: RBCP port #[15:0]
        .PHY_ADDR(5'b00111),    // in: PHY-device MIF address[4:0]
        // EEPROM
        .EEPROM_CS(eeprom_cs),  // out: Chip select
        .EEPROM_SK(eeprom_sk),  // out: Serial data clock
        .EEPROM_DI(eeprom_di),  // out: Serial write data
        .EEPROM_DO(eeprom_do),  // in : Serial read data
        // user data, intialial values are stored in the EEPROM, 0xFFFF_FC3C-3F
        .USR_REG_X3C(),         // out: Stored at 0xFFFF_FF3C
        .USR_REG_X3D(),         // out: Stored at 0xFFFF_FF3D
        .USR_REG_X3E(),         // out: Stored at 0xFFFF_FF3E
        .USR_REG_X3F(),         // out: Stored at 0xFFFF_FF3F
        // MII interface
        .GMII_RSTn(phy_rst_n),  // out: PHY reset
        .GMII_1000M(1'b1),      // in : GMII mode (0:MII, 1:GMII)
        // TX
        .GMII_TX_CLK(clk_125),  // in : Tx clock
        .GMII_TX_EN(gmii_tx_en),// out: Tx enable
        .GMII_TXD(gmii_txd),    // out: Tx data[7:0]
        .GMII_TX_ER(gmii_tx_er),// out: TX error
        // RX
        .GMII_RX_CLK(clk_125),  // in : Rx clock
        .GMII_RX_DV(gmii_rx_dv),// in : Rx data valid
        .GMII_RXD(gmii_rxd),    // in : Rx data[7:0]
        .GMII_RX_ER(gmii_rx_er),// in : Rx error
        .GMII_CRS(1'b0),        // in : Carrier sense
        .GMII_COL(1'b0),        // in : Collision detected
        // Management IF
        .GMII_MDC(),            // out: Clock for MDIO
        .GMII_MDIO_IN(1'b1),    // in : Data
        .GMII_MDIO_OUT(),       // out: Data
        .GMII_MDIO_OE(),        // out: MDIO output enable
        // User I/F
        .SiTCP_RST(),           // out: Reset for SiTCP and related circuits
        // TCP connection control
        .TCP_OPEN_REQ(1'b0),          // in : Reserved input, shoud be 0
        .TCP_OPEN_ACK(tcp_open_ack),  // out: Acknowledge for open (=Socket busy)
        .TCP_ERROR(tcp_error),        // out	: TCP error, its active period is equal to MSL
        .TCP_CLOSE_REQ(tcp_close_req),// out	: Connection close request
        .TCP_CLOSE_ACK(tcp_close_ack),// in	: Acknowledge for closing
        // FIFO I/F
        .TCP_RX_WC(16'b0),             // in : Rx FIFO write count[15:0] (Unused bits should be set 1)
        .TCP_RX_WR(tcp_rx_wr),         // out: Write enable
        .TCP_RX_DATA(tcp_rxd),// out: Write data[7:0]
        .TCP_TX_FULL(tcp_tx_full),// out: Almost full flag
        .TCP_TX_WR(tcp_tx_wr),    // in : Write enable
        .TCP_TX_DATA(tcp_txd),    // in : Write data[7:0]
        // RBCP
        .RBCP_ACT(rbcp_act),      // out: RBCP active
        .RBCP_ADDR(rbcp_addr),    // out: Address[31:0]
        .RBCP_WD(rbcp_wd),        // out: Data[7:0]
        .RBCP_WE(rbcp_we),        // out: Write enable
        .RBCP_RE(rbcp_re),        // out: Read enable
        .RBCP_ACK(rbcp_ack),      // in : Access acknowledge
        .RBCP_RD(rbcp_rd)         // in : Read data[7:0]
    );

    wire [31:0] axi_awaddr_int ;
    wire [2:0]  axi_awprot_int ;
    wire        axi_awvalid_int;
    wire        axi_awready_int;
    wire [31:0] axi_wdata_int  ;
    wire [3:0]  axi_wstrb_int  ;
    wire        axi_wvalid_int ;
    wire        axi_wready_int ;
    wire [1:0]  axi_bresp_int  ;
    wire        axi_bvalid_int ;
    wire        axi_bready_int ;
    wire [31:0] axi_araddr_int ;
    wire [2:0]  axi_arprot_int ;
    wire        axi_arvalid_int;
    wire        axi_arready_int;
    wire [31:0] axi_rdata_int  ;
    wire        axi_rvalid_int ;
    wire        axi_rready_int ;
    wire [1:0]  axi_rresp_int  ;

    wire [3:0] araddr_res;

    rbcp_bridge bridge_inst(
        .clk(m_axi_aclk),
        .rst(~m_axi_aresetn),
        // RBCP
        .rbcp_act(rbcp_act),
        .rbcp_addr(rbcp_addr),
        .rbcp_wd(rbcp_wd),
        .rbcp_we(rbcp_we),
        .rbcp_re(rbcp_re),
        .rbcp_ack(rbcp_ack),
        .rbcp_rd(rbcp_rd),
        // AXI
        .m_axi_awaddr (axi_awaddr_int ),
        .m_axi_awprot (axi_awprot_int ),
        .m_axi_awvalid(axi_awvalid_int),
        .m_axi_awready(axi_awready_int),

        .m_axi_wdata  (axi_wdata_int  ),
        .m_axi_wstrb  (axi_wstrb_int  ),
        .m_axi_wvalid (axi_wvalid_int ),
        .m_axi_wready (axi_wready_int ),

        .m_axi_bresp  (axi_bresp_int  ),
        .m_axi_bvalid (axi_bvalid_int ),
        .m_axi_bready (axi_bready_int ),

        .m_axi_araddr (axi_araddr_int ),
        .m_axi_arprot (axi_arprot_int ),
        .m_axi_arvalid(axi_arvalid_int),
        .m_axi_arready(axi_arready_int),
        .m_axi_rdata  (axi_rdata_int  ),
        .m_axi_rvalid (axi_rvalid_int ),
        .m_axi_rready (axi_rready_int ),
        .m_axi_rresp  (axi_rresp_int  ),

        .araddr_res(araddr_res),

        .debug_rresp(),
        .debug_bresp()
    );

    adapter_8_32 adapter_inst(
        .clk(m_axi_aclk),
        .rst(~m_axi_aresetn),
        .s_axi_awaddr (axi_awaddr_int ),
        .s_axi_awprot (axi_awprot_int ),
        .s_axi_awvalid(axi_awvalid_int),
        .s_axi_awready(axi_awready_int),
        .s_axi_wdata  (axi_wdata_int  ),
        .s_axi_wstrb  (axi_wstrb_int  ),
        .s_axi_wvalid (axi_wvalid_int ),
        .s_axi_wready (axi_wready_int ),
        .s_axi_bresp  (axi_bresp_int  ),
        .s_axi_bvalid (axi_bvalid_int ),
        .s_axi_bready (axi_bready_int ),
        .s_axi_araddr (axi_araddr_int ),
        .s_axi_arprot (axi_arprot_int ),
        .s_axi_arvalid(axi_arvalid_int),
        .s_axi_arready(axi_arready_int),
        .s_axi_rdata  (axi_rdata_int  ),
        .s_axi_rvalid (axi_rvalid_int ),
        .s_axi_rready (axi_rready_int ),
        .s_axi_rresp  (axi_rresp_int  ),

        .m_axi_awaddr (m_axi_awaddr ),
        .m_axi_awprot (m_axi_awprot ),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata  (m_axi_wdata  ),
        .m_axi_wstrb  (m_axi_wstrb  ),
        .m_axi_wvalid (m_axi_wvalid ),
        .m_axi_wready (m_axi_wready ),
        .m_axi_bresp  (m_axi_bresp  ),
        .m_axi_bvalid (m_axi_bvalid ),
        .m_axi_bready (m_axi_bready ),
        .m_axi_araddr (m_axi_araddr ),
        .m_axi_arprot (m_axi_arprot ),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rdata  (m_axi_rdata  ),
        .m_axi_rvalid (m_axi_rvalid ),
        .m_axi_rready (m_axi_rready ),
        .m_axi_rresp  (m_axi_rresp  ),

        .araddr_res   (araddr_res   )
    );

endmodule
