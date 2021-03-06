# script
set ip_name "axi_sitcp"

## Device setting (KCU105)
set p_device "xcku040-ffva1156-2-e"
set p_board "xilinx.com:kcu105:part0:1.5"

create_project $ip_name . -force -part $p_device
set_property board_part $p_board [current_project]


source ./util.tcl

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
#add_files -fileset constrs_1 -norecurse ../SiTCP_Netlist_for_Kintex_UltraScale/EDF_SiTCP_constraints.xdc

# ip package

ipx::package_project -root_dir . -vendor kuhep -library user -taxonomy /kuhep
set_property name $ip_name [ipx::current_core]
set_property vendor_display_name {kuhep} [ipx::current_core]
ipx::save_core [ipx::current_core]

# core
create_ip -vlnv [latest_ip gig_ethernet_pcs_pma] -module_name gig_ethernet_pcs_pma
set_property -dict [list \
    CONFIG.ETHERNET_BOARD_INTERFACE {sgmii_lvds} \
    CONFIG.DIFFCLK_BOARD_INTERFACE {sgmii_phyclk} \
    CONFIG.Standard {SGMII} \
    CONFIG.Physical_Interface {LVDS} \
    CONFIG.Management_Interface {false} \
    CONFIG.SupportLevel {Include_Shared_Logic_in_Core} \
    CONFIG.LvdsRefClk {625} \
    CONFIG.GT_Location {X0Y0}] [get_ips gig_ethernet_pcs_pma]

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


ipx::add_file ./axi_sitcp.srcs/sources_1/ip/gig_ethernet_pcs_pma/gig_ethernet_pcs_pma.xci \
[ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]

ipx::reorder_files -before ../SiTCP_Netlist_for_Kintex_UltraScale/SiTCP_XCKU_32K_BBT_V110.edf \
./axi_sitcp.srcs/sources_1/ip/gig_ethernet_pcs_pma/gig_ethernet_pcs_pma.xci \
[ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]

ipx::add_address_space m_axi [ipx::current_core]
set_property master_address_space_ref m_axi [ipx::get_bus_interfaces m_axi -of_objects [ipx::current_core]]

# SGMII bus
ipx::add_bus_interface phy [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:sgmii_rtl:1.0 [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:sgmii:1.0 [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]
ipx::add_port_map RXN [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]
set_property physical_name phy_rxn [ipx::get_port_maps RXN -of_objects [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]]
ipx::add_port_map TXN [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]
set_property physical_name phy_txn [ipx::get_port_maps TXN -of_objects [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]]
ipx::add_port_map RXP [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]
set_property physical_name phy_rxp [ipx::get_port_maps RXP -of_objects [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]]
ipx::add_port_map TXP [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]
set_property physical_name phy_txp [ipx::get_port_maps TXP -of_objects [ipx::get_bus_interfaces phy -of_objects [ipx::current_core]]]

# PHY clk

ipx::add_bus_interface phy_clk [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:diff_clock_rtl:1.0 [ipx::get_bus_interfaces phy_clk -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:diff_clock:1.0 [ipx::get_bus_interfaces phy_clk -of_objects [ipx::current_core]]
ipx::add_port_map CLK_P [ipx::get_bus_interfaces phy_clk -of_objects [ipx::current_core]]
set_property physical_name phy_clk_p [ipx::get_port_maps CLK_P -of_objects [ipx::get_bus_interfaces phy_clk -of_objects [ipx::current_core]]]
ipx::add_port_map CLK_N [ipx::get_bus_interfaces phy_clk -of_objects [ipx::current_core]]
set_property physical_name phy_clk_n [ipx::get_port_maps CLK_N -of_objects [ipx::get_bus_interfaces phy_clk -of_objects [ipx::current_core]]]


# TCP
ipx::add_bus_interface tcp_rx [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:fifo_write_rtl:1.0 [ipx::get_bus_interfaces tcp_rx -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:fifo_write:1.0 [ipx::get_bus_interfaces tcp_rx -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces tcp_rx -of_objects [ipx::current_core]]
ipx::add_port_map WR_DATA [ipx::get_bus_interfaces tcp_rx -of_objects [ipx::current_core]]
set_property physical_name tcp_rxd [ipx::get_port_maps WR_DATA -of_objects [ipx::get_bus_interfaces tcp_rx -of_objects [ipx::current_core]]]
ipx::add_port_map WR_EN [ipx::get_bus_interfaces tcp_rx -of_objects [ipx::current_core]]
set_property physical_name tcp_rx_wr [ipx::get_port_maps WR_EN -of_objects [ipx::get_bus_interfaces tcp_rx -of_objects [ipx::current_core]]]

ipx::add_bus_interface tcp_tx [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:fifo_write_rtl:1.0 [ipx::get_bus_interfaces tcp_tx -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:fifo_write:1.0 [ipx::get_bus_interfaces tcp_tx -of_objects [ipx::current_core]]
ipx::add_port_map WR_DATA [ipx::get_bus_interfaces tcp_tx -of_objects [ipx::current_core]]
set_property physical_name tcp_txd [ipx::get_port_maps WR_DATA -of_objects [ipx::get_bus_interfaces tcp_tx -of_objects [ipx::current_core]]]
ipx::add_port_map WR_EN [ipx::get_bus_interfaces tcp_tx -of_objects [ipx::current_core]]
set_property physical_name tcp_tx_wr [ipx::get_port_maps WR_EN -of_objects [ipx::get_bus_interfaces tcp_tx -of_objects [ipx::current_core]]]
ipx::add_port_map ALMOST_FULL [ipx::get_bus_interfaces tcp_tx -of_objects [ipx::current_core]]
set_property physical_name tcp_tx_full [ipx::get_port_maps ALMOST_FULL -of_objects [ipx::get_bus_interfaces tcp_tx -of_objects [ipx::current_core]]]

update_compile_order -fileset sources_1
ipx::save_core [ipx::current_core]
