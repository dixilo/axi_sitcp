# script
set ip_name "axi_sitcp"
create_project $ip_name . -force

# file
set proj_fileset [get_filesets sources_1]
add_files -norecurse -scan_for_includes -fileset $proj_fileset [list \
    "axi_sitcp.v" \
    "rbcp_bridge.v" \
    "adapter_8_32.v" \
    "adapter_8_32_r.v" \
    "adapter_8_32_w.v" \
    ../SiTCP_Netlist_for_Kintex_UltraScale/TIMER.v \
    ../SiTCP_Netlist_for_Kintex_UltraScale/WRAP_SiTCP_GMII_XCKU_32K.V \
    ../SiTCP_Netlist_for_Kintex_UltraScale/SiTCP_XCKU_32K_BBT_V110.edf \
    ../SiTCP_Netlist_for_Kintex_UltraScale/SiTCP_XCKU_32K_BBT_V110.V \
]
set_property "top" "axi_sitcp" $proj_fileset


# ip package

ipx::package_project -root_dir . -vendor kuhep -library user -taxonomy /kuhep
set_property name $ip_name [ipx::current_core]
set_property vendor_display_name {kuhep} [ipx::current_core]
ipx::save_core [ipx::current_core]

# interfaces

ipx::remove_all_bus_interface [ipx::current_core]
set memory_maps [ipx::get_memory_maps * -of_objects [ipx::current_core]]
foreach map $memory_maps {
    ipx::remove_memory_map [lindex $map 2] [ipx::current_core ]
}
ipx::save_core

# dev_clk

ipx::infer_bus_interface m_axi_aclk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]

# M_AXI

ipx::infer_bus_interface {\
    m_axi_awvalid \
    m_axi_awaddr \
    m_axi_awprot \
    m_axi_awready \
    m_axi_wvalid \
    m_axi_wdata \
    m_axi_wstrb \
    m_axi_wready \
    m_axi_bvalid \
    m_axi_bresp \
    m_axi_bready \
    m_axi_arvalid \
    m_axi_araddr \
    m_axi_arprot \
    m_axi_arready \
    m_axi_rvalid \
    m_axi_rdata \
    m_axi_rresp \
    m_axi_rready} \
xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

ipx::infer_bus_interface m_axi_aclk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface m_axi_aresetn xilinx.com:signal:reset_rtl:1.0 [ipx::current_core]


ipx::save_core [ipx::current_core]
