# reset
set_property -dict  {PACKAGE_PIN  J23   IOSTANDARD  LVCMOS18}  [get_ports phy_rst_n]

set_property BOARD_PIN {SGMII_RX_P} [get_ports phy_rxp]
set_property BOARD_PIN {SGMII_RX_N} [get_ports phy_rxn]
set_property BOARD_PIN {SGMII_TX_P} [get_ports phy_txp]
set_property BOARD_PIN {SGMII_TX_N} [get_ports phy_txn]
set_property BOARD_PIN {SGMIICLK_P} [get_ports phy_clk_p]
set_property BOARD_PIN {SGMIICLK_N} [get_ports phy_clk_n]

# clock
#set_property PACKAGE_PIN P26 [get_ports phy_clk_p]
#set_property PACKAGE_PIN N26 [get_ports phy_clk_n]

#set_property IOSTANDARD LVDS_25 [get_ports phy_clk_p]
#set_property IOSTANDARD LVDS_25 [get_ports phy_clk_n]
create_clock -name phy_clk_p -period 1.600 [get_ports phy_clk_p]
#create_clock -name default_sysclk_300_clk_p -period 3.333 [get_ports default_sysclk_300_clk_p]
