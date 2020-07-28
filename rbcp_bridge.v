`timescale 1ns / 1ps

module rbcp_bridge(
    input wire clk,
    input wire rst,
    // RBCP
    input  wire        rbcp_act,
    input  wire [31:0] rbcp_addr,
    input  wire [7:0]  rbcp_wd,
    input  wire        rbcp_we,
    input  wire        rbcp_re,
    output wire        rbcp_ack,
    output wire [7:0]  rbcp_rd,
    // AXI
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

    // control signal
    output wire [3:0] araddr_res, // residual

    output wire [1:0] debug_rresp,
    output wire [1:0] debug_bresp
);
    // debug
    assign debug_rresp = m_axi_rresp;
    assign debug_bresp = m_axi_bresp;

    /////////////////////////////////// Address handling
    // address buffer
    reg [31:0] addr_buf;
    wire [1:0] addr_res;
    always @(posedge clk) begin
        if (rst) begin
            addr_buf <= 32'd0;
        end else begin
            if (rbcp_we || rbcp_re) begin
                addr_buf <= rbcp_addr;
            end
        end
    end

    assign m_axi_awaddr = {addr_buf[31:2], 2'b00};
    assign m_axi_araddr = {addr_buf[31:2], 2'b00};

    assign addr_res = addr_buf[1:0];

    // Assuming big endian
    assign m_axi_wstrb[3] = (addr_res == 2'd0);
    assign m_axi_wstrb[2] = (addr_res == 2'd1);
    assign m_axi_wstrb[1] = (addr_res == 2'd2);
    assign m_axi_wstrb[0] = (addr_res == 2'd3);

    assign araddr_res = m_axi_wstrb;

    // awvalid
    reg awvalid_buf;
    always @(posedge clk) begin
        if (rst) begin
            awvalid_buf <= 1'b0;
        end else begin
            if (rbcp_we) begin
                awvalid_buf <= 1'b1;
            end else if (awvalid_buf && m_axi_awready) begin
                // Address transaction finish
                awvalid_buf <= 1'b0;
            end
        end
    end
    assign m_axi_awvalid = awvalid_buf;

    // arvalid
    reg arvalid_buf;
    always @(posedge clk) begin
        if (rst) begin
            arvalid_buf <= 1'b0;
        end else begin
            if (rbcp_re) begin
                arvalid_buf <= 1'b1;
            end else if (arvalid_buf && m_axi_arready) begin
                // Address transaction finish
                arvalid_buf <= 1'b0;
            end
        end
    end
    assign m_axi_arvalid = arvalid_buf;

    /////////////////////////////////// Write data handling
    reg [7:0] wdata_buf;
    always @(posedge clk) begin
        if (rst) begin
            wdata_buf <= 32'd0;
        end else begin
            wdata_buf <= rbcp_wd;
        end
    end
    assign m_axi_wdata = {4{wdata_buf}};

    reg wvalid_buf;
    always @(posedge clk) begin
        if (rst) begin
            wvalid_buf <= 1'b0;
        end else begin
            if (rbcp_we) begin
                wvalid_buf <= 1'b1;
            end else if (wvalid_buf && m_axi_wready) begin
                wvalid_buf <= 1'b0;
            end
        end
    end
    assign m_axi_wvalid = wvalid_buf;

    /////////////////////////////////// Write response handling
    reg bready_buf;
    always @(posedge clk) begin
        if (rst) begin
            bready_buf <= 1'b0;
        end else begin
            if (m_axi_bvalid && ~bready_buf) begin
                bready_buf <= 1'b1;
            end else if (bready_buf) begin
                bready_buf <= 1'b0;
            end else begin
                bready_buf <= bready_buf;
            end
        end
    end
    assign m_axi_bready = bready_buf;

    /////////////////////////////////// Read data handling
    reg [7:0] rdata_buf;
    always @(posedge clk) begin
        if (rst) begin
            rdata_buf <= 8'd0;
        end else begin
            if (m_axi_rvalid) begin
                case (addr_res)// Big endian
                2'b00: rdata_buf <= m_axi_rdata[31:24];
                2'b01: rdata_buf <= m_axi_rdata[23:16];
                2'b10: rdata_buf <= m_axi_rdata[15:8];
                2'b11: rdata_buf <= m_axi_rdata[7:0];
                default: rdata_buf <= 0;
                endcase
            end
        end
    end
    assign rbcp_rd = rdata_buf;

    /////////////////////////////////// Read response handling
    reg rready_buf;
    always @(posedge clk) begin
        if (rst) begin
            rready_buf <= 1'b0;
        end else begin
            if (m_axi_rvalid && ~rready_buf) begin
                rready_buf <= 1'b1;
            end else if (rready_buf) begin
                rready_buf <= 1'b0;
            end else begin
                rready_buf <= rready_buf;
            end
        end
    end
    assign m_axi_rready = rready_buf;

    /////////////////////////////////// RBCP acknowledge
    assign rbcp_ack = m_axi_rready | m_axi_bready;

    /////////////////////////////////// Protection type
    assign m_axi_awprot = 3'b000;
    assign m_axi_arprot = 3'b000;


endmodule
