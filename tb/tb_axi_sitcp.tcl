## Device setting (KCU105)
set p_device "xcku040-ffva1156-2-e"
set p_board "xilinx.com:kcu105:part0:1.5"

set project_name "tb_axi_sitcp"
set project_system_dir "./tb_axi_sitcp/$project_name.srcs/sources_1/bd/system"

create_project -force $project_name ./${project_name} -part $p_device
set_property board_part $p_board [current_project]

set_property  ip_repo_paths  .. [current_project]
update_ip_catalog

source ../util.tcl

add_files -fileset constrs_1 -norecurse "./tb_axi_sitcp.xdc"
add_files -fileset constrs_1 -norecurse "../../SiTCP_Netlist_for_Kintex_UltraScale/EDF_SiTCP_constraints.xdc"


## IP integrator
create_bd_design "system"

### board cell instantiation
#### axi_sitcp
create_bd_cell -type ip -vlnv [latest_ip axi_sitcp] axi_sitcp

#### gpio
create_bd_cell -type ip -vlnv [latest_ip axi_gpio] axi_gpio
set_property -dict [list \
    CONFIG.C_IS_DUAL {1} \
    CONFIG.C_ALL_INPUTS_2 {1} \
    CONFIG.C_ALL_OUTPUTS {1}\
    ] [get_bd_cells axi_gpio]

#### interconnect
create_bd_cell -type ip -vlnv [latest_ip axi_interconnect] axi_interconnect
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect]


#### Clock
create_bd_cell -type ip -vlnv [latest_ip clk_wiz] clk_wiz
apply_board_connection -board_interface "default_sysclk_300" \
    -ip_intf "clk_wiz/CLK_IN1_D" -diagram "system" 

set_property -dict [list \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200} \
    CONFIG.MMCM_DIVCLK_DIVIDE {3} \
    CONFIG.MMCM_CLKOUT0_DIVIDE_F {5.000} \
    CONFIG.CLKOUT1_JITTER {113.676}] [get_bd_cells clk_wiz]


#### reset
apply_board_connection -board_interface "reset" -ip_intf "clk_wiz/reset" -diagram "system" 
create_bd_cell -type ip -vlnv [latest_ip proc_sys_reset] proc_sys_reset



### connection
#### clock
connect_bd_net [get_bd_pins axi_sitcp/m_axi_aclk] [get_bd_pins clk_wiz/clk_out1]
connect_bd_net [get_bd_pins axi_interconnect/ACLK] [get_bd_pins clk_wiz/clk_out1]
connect_bd_net [get_bd_pins axi_interconnect/S00_ACLK] [get_bd_pins clk_wiz/clk_out1]
connect_bd_net [get_bd_pins axi_gpio/s_axi_aclk] [get_bd_pins clk_wiz/clk_out1]
connect_bd_net [get_bd_pins axi_interconnect/M00_ACLK] [get_bd_pins clk_wiz/clk_out1]

#### reset
connect_bd_net [get_bd_pins clk_wiz/clk_out1] [get_bd_pins proc_sys_reset/slowest_sync_clk]
connect_bd_net [get_bd_pins clk_wiz/locked] [get_bd_pins proc_sys_reset/dcm_locked]
connect_bd_net [get_bd_ports reset] [get_bd_pins proc_sys_reset/ext_reset_in]

connect_bd_net [get_bd_pins axi_sitcp/m_axi_aresetn] [get_bd_pins proc_sys_reset/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_interconnect/ARESETN] [get_bd_pins proc_sys_reset/interconnect_aresetn]
connect_bd_net [get_bd_pins axi_interconnect/S00_ARESETN] [get_bd_pins proc_sys_reset/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_gpio/s_axi_aresetn] [get_bd_pins proc_sys_reset/peripheral_aresetn]
connect_bd_net [get_bd_pins axi_interconnect/M00_ARESETN] [get_bd_pins proc_sys_reset/peripheral_aresetn]


#### sitcp -> interconnect
connect_bd_intf_net [get_bd_intf_pins axi_sitcp/m_axi] \
    -boundary_type upper [get_bd_intf_pins axi_interconnect/S00_AXI]

#### interconnect -> gpio
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect/M00_AXI] [get_bd_intf_pins axi_gpio/S_AXI]

#### external
make_bd_pins_external -name phy_clk_p [get_bd_pins axi_sitcp/phy_clk_p]
make_bd_pins_external -name phy_clk_n [get_bd_pins axi_sitcp/phy_clk_n]
make_bd_pins_external -name phy_rxp [get_bd_pins axi_sitcp/phy_rxp]
make_bd_pins_external -name phy_rxn [get_bd_pins axi_sitcp/phy_rxn]
make_bd_pins_external -name phy_txp [get_bd_pins axi_sitcp/phy_txp]
make_bd_pins_external -name phy_txn [get_bd_pins axi_sitcp/phy_txn]
make_bd_pins_external -name phy_rst_n [get_bd_pins axi_sitcp/phy_rst_n]

#### gpio loopback
connect_bd_net [get_bd_pins axi_gpio/gpio_io_o] [get_bd_pins axi_gpio/gpio2_io_i]

#### debug
set_property HDL_ATTRIBUTE.DEBUG true [get_bd_intf_nets {axi_sitcp_m_axi}]
apply_bd_automation -rule xilinx.com:bd_rule:debug -dict [list \
    [get_bd_intf_nets axi_sitcp_m_axi] \
    {AXI_R_ADDRESS "Data and Trigger" \
     AXI_R_DATA "Data and Trigger" \
     AXI_W_ADDRESS "Data and Trigger" \
     AXI_W_DATA "Data and Trigger" \
     AXI_W_RESPONSE "Data and Trigger" \
     CLK_SRC "/clk_wiz/clk_out1" \
     SYSTEM_ILA "Auto" \
     APC_EN "0" } \
]

assign_bd_address
save_bd_design
validate_bd_design


## File
set_property synth_checkpoint_mode None [get_files  $project_system_dir/system.bd]
generate_target {synthesis implementation} [get_files  $project_system_dir/system.bd]
make_wrapper -files [get_files $project_system_dir/system.bd] -top
import_files -force -norecurse -fileset sources_1 $project_system_dir/hdl/system_wrapper.v

# Run
## Synthesis
launch_runs synth_1
wait_on_run synth_1
open_run synth_1
report_timing_summary -file timing_synth.log

## Implementation
set_property strategy Performance_Retiming [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
open_run impl_1
report_timing_summary -file timing_impl.log
