`timescale 1ns / 1ps

module adapter_8_32_w(
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
    output wire        m_axi_bready  // write response channel ready
);

    // Master busy
    wire m_busy;
    /*********************
        SLAVE INTERFACE
    *********************/

    /////////////////////////////////// Write address handling
    reg s_awready_buf;
    reg s_aw_en; // AW enable
    reg s_bvalid_buf;

    wire aw_acc = ~s_awready_buf && s_axi_awvalid && s_axi_wvalid && s_aw_en && ~m_busy;

    always @(posedge clk) begin
        if (rst) begin
            s_awready_buf <= 1'b0;
            s_aw_en <= 1'b1;
        end else begin
            if (aw_acc) begin
                // Accept address if AWVALID and WVALID
                s_awready_buf <= 1'b1;
                s_aw_en <= 1'b0;
            end else if (s_axi_bready && s_bvalid_buf) begin
                s_aw_en <= 1'b1;
                s_awready_buf <= 1'b0;
            end else begin
                s_awready_buf <= 1'b0;
            end
        end
    end

    assign s_axi_awready = s_awready_buf;

    reg [31:0] s_awaddr_buf;
    wire s_awaddr_change = s_aw_en ? (s_awaddr_buf != s_axi_awaddr): 0;
    integer byte_index;

    always @(posedge clk) begin
        if (rst) begin
            s_awaddr_buf <= 32'd0;
        end else begin
            if (aw_acc) begin
                s_awaddr_buf <= s_axi_awaddr;
            end
        end
    end

    /////////////////////////////////// Write data handling
    reg s_wready_buf;
    wire w_acc = ~s_wready_buf && s_axi_awvalid && s_axi_wvalid && s_aw_en && ~m_busy;

    always @(posedge clk) begin
        if (rst) begin
            s_wready_buf <= 1'b0;
        end else begin
            if (w_acc) begin
                s_wready_buf <= 1'b1;
            end else begin
                s_wready_buf <= 1'b0;
            end
        end
    end
    assign s_axi_wready = s_wready_buf;

    reg [31:0] wdata_buf;
    always @(posedge clk) begin
        if (rst) begin
            wdata_buf <= 32'd0;
        end else begin
            if (w_acc) begin
                for (byte_index = 0; byte_index <= 3; byte_index = byte_index + 1)
                    if( s_axi_wstrb[byte_index] == 1 ) begin
                        wdata_buf[(byte_index*8) +: 8] <= s_axi_wdata[(byte_index*8) +: 8];
                    end
            end
        end
    end

    reg [3:0] wstrb_sum;
    wire wstrb_full = (wstrb_sum == 4'b1111);
    always @(posedge clk) begin
        if (rst) begin
            wstrb_sum <= 4'b0000;
        end else begin
            if (w_acc) begin
                if (s_awaddr_change) begin
                    wstrb_sum <= 4'b0000 | s_axi_wstrb;
                end else begin
                    wstrb_sum <= wstrb_sum | s_axi_wstrb;
                end
            end else if (wstrb_full) begin
                wstrb_sum <= 4'b0000;
            end
        end
    end

    /////////////////////////////////// Write response handling
    assign s_axi_bresp = 2'b0; // not implemented yet
    wire b_acc = s_awready_buf && s_axi_awvalid && ~s_bvalid_buf && s_wready_buf && s_axi_wvalid;

    always @(posedge clk) begin
        if (rst) begin
            s_bvalid_buf <= 1'b0;
        end else begin
            if (b_acc) begin
                s_bvalid_buf <= 1'b1;
            end else begin
               if (s_axi_bready && s_bvalid_buf) begin
                   s_bvalid_buf <= 1'b0;
               end
            end
        end
    end

    assign s_axi_bvalid = s_bvalid_buf;

    /*
        MASTER INTERFACE
    */

    /////////////////////////////////// Address handling
    // address buffer

    assign m_axi_awaddr = s_awaddr_buf;
    assign m_axi_wstrb = 4'b1111;

    // awvalid
    reg m_awvalid_buf;
    always @(posedge clk) begin
        if (rst) begin
            m_awvalid_buf <= 1'b0;
        end else begin
            if (m_awvalid_buf) begin
                if (m_axi_wready) begin
                    m_awvalid_buf <= 1'b0;
                end
            end else begin
                if (wstrb_full) begin
                    m_awvalid_buf <= 1'b1;
                end
            end
        end
    end
    assign m_axi_awvalid = m_awvalid_buf;

    /////////////////////////////////// Write data handling
    assign m_axi_wdata = wdata_buf;

    reg m_wvalid_buf;
    always @(posedge clk) begin
        if (rst) begin
            m_wvalid_buf <= 1'b0;
        end else begin
            if (m_wvalid_buf) begin
                if (m_axi_wready) begin
                    m_wvalid_buf <= 1'b0;
                end
            end else begin
                if (wstrb_full) begin
                    m_wvalid_buf <= 1'b1;
                end
            end
        end
    end
    assign m_axi_wvalid = m_wvalid_buf;

    /////////////////////////////////// Write response handling
    reg m_bready_buf;
    always @(posedge clk) begin
        if (rst) begin
            m_bready_buf <= 1'b0;
        end else begin
            if (m_axi_bvalid && ~m_bready_buf) begin
                m_bready_buf <= 1'b1;
            end else if (m_bready_buf) begin
                m_bready_buf <= 1'b0;
            end else begin
                m_bready_buf <= m_bready_buf;
            end
        end
    end

    assign m_axi_bready = m_bready_buf;
    assign m_axi_awprot = 3'b000;

    /////////////////////////////////// m_busy
    reg m_busy_buf;
    always @(posedge clk) begin
        if (rst) begin
            m_busy_buf <= 1'b0;
        end else begin
            if (wstrb_full) begin
                m_busy_buf <= 1'b1;
            end else begin
                if (m_bready_buf) begin
                    m_busy_buf <= 1'b0;
                end
            end
        end
    end
    assign m_busy = m_busy_buf;

endmodule
