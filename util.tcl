set intc_cntr 0

proc latest_ip {i_ip} {
    return [get_ipdefs -all -filter "VLNV =~ *:${i_ip}:* && \
    design_tool_contexts =~ *IPI* && UPGRADE_VERSIONS == \"\""]
}

proc intc_expand { } {
    global intc_cntr
    set_property CONFIG.NUM_MI [expr $intc_cntr + 1] [get_bd_cells axi_cpu_interconnect]
}

proc axi_connect {p_address p_name} {
    global intc_cntr

    set i_str "M$intc_cntr"
    if {$intc_cntr < 10} {
        set i_str "M0$intc_cntr"
    }
    set p_cell [get_bd_cells $p_name]

    set p_intf [get_bd_intf_pins -filter "MODE == Slave && VLNV == xilinx.com:interface:aximm_rtl:1.0"\
    -of_objects $p_cell]

    set p_intf_name [lrange [split $p_intf "/"] end end]

    set p_intf_clock [get_bd_pins -filter "TYPE == clk && \
                        (CONFIG.ASSOCIATED_BUSIF == ${p_intf_name} || \
                         CONFIG.ASSOCIATED_BUSIF =~ ${p_intf_name}:* || \
                         CONFIG.ASSOCIATED_BUSIF =~ *:${p_intf_name} || \
                         CONFIG.ASSOCIATED_BUSIF =~ *:${p_intf_name}:*)" \
                        -of_objects $p_cell]
    set p_intf_reset [get_bd_pins -filter "TYPE == rst && \
                        (CONFIG.ASSOCIATED_BUSIF == ${p_intf_name} || 
                         CONFIG.ASSOCIATED_BUSIF =~ ${p_intf_name}:* || \
                         CONFIG.ASSOCIATED_BUSIF =~ *:${p_intf_name} || \
                         CONFIG.ASSOCIATED_BUSIF =~ *:${p_intf_name}:*)" \
                       -of_objects $p_cell]

    if {($p_intf_clock ne "") && ($p_intf_reset eq "")} {
        set p_intf_reset [get_property CONFIG.ASSOCIATED_RESET ${p_intf_clock}]
        if {$p_intf_reset ne ""} {
            set p_intf_reset [get_bd_pins -filter "NAME == $p_intf_reset" -of_objects $p_cell]
        }
    }

    intc_expand
    connect_bd_net -net [get_bd_nets sys_cpu_clk] [get_bd_pins axi_cpu_interconnect/${i_str}_ACLK]
    connect_bd_net -net [get_bd_nets sys_cpu_clk] ${p_intf_clock}
    connect_bd_net -net [get_bd_nets sys_cpu_resetn] [get_bd_pins axi_cpu_interconnect/${i_str}_ARESETN]
    connect_bd_net -net [get_bd_nets sys_cpu_resetn] ${p_intf_reset}
    connect_bd_intf_net [get_bd_intf_pins axi_cpu_interconnect/${i_str}_AXI] ${p_intf}

    set sys_addr_cntrl_space [get_bd_addr_spaces sys_mb/Data]
    set p_seg [get_bd_addr_segs -of_objects $p_cell]
    set p_seg_range [get_property range $p_seg]

    if {$p_seg_range < 0x1000} {
        set p_seg_range 0x1000
    }

    create_bd_addr_seg -range $p_seg_range \
        -offset $p_address $sys_addr_cntrl_space \
        $p_seg "SEG_data_${p_name}"

    set intc_cntr [expr $intc_cntr + 1]
}
