`timescale 1ns / 1ps

module adapter_8_32(
    input wire clk,
    input wire rst,

    // S AXI
    input  wire [31:0] s_axi_awaddr, // write address
    input  wire [2:0]  s_axi_awprot, // write channel protection type
    input  wire        s_axi_awvalid,// write address valid
    output wire        s_axi_awready,// write address ready

    input  wire [31:0] s_axi_wdata,  // write data channel
    input  wire [3:0]  s_axi_wstrb,  // valid lanes
    input  wire        s_axi_wvalid, // write valid
    output wire        s_axi_wready, // write ready

    output wire [1:0]  s_axi_bresp,  // write response channel
    output wire        s_axi_bvalid, // write response channel valid
    input  wire        s_axi_bready, // write response channel ready

    input  wire [31:0] s_axi_araddr, // read address
    input  wire [2:0]  s_axi_arprot, // read channel protection type
    input  wire        s_axi_arvalid,// read address valid
    output wire        s_axi_arready,// read address ready
    output wire [31:0] s_axi_rdata,  // read data
    output wire        s_axi_rvalid, // read valid
    input  wire        s_axi_rready, // read ready
    output wire [1:0]  s_axi_rresp,  // read response

    // M AXI
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
    input  wire [1:0]  m_axi_rresp,  // read response

    // control
    input  wire [3:0]  araddr_res      // address residual
);

    adapter_8_32_w w_inst(
        .clk(clk),
        .rst(rst),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awprot(s_axi_awprot),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awprot(m_axi_awprot),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),

        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),

        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready)
    );

    adapter_8_32_r r_inst(
        .clk(clk),
        .rst(rst),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arprot(s_axi_arprot),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .s_axi_rresp(s_axi_rresp),

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
