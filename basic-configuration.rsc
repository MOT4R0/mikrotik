# Basic mikrotik RouterOS configuration

:local timezone;
:set timezone "America/La_Paz";

/system clock
set time-zone-name=$timezone

# Set WAN interface name
/interface ethernet
set [ find default-name=ether2 ] name=ether2_WAN speed=100Mbps

# Create a Bridge with name LAN
/interface bridge
add fast-forward=no name=bridge_LAN

# Add ports to bridge
/interface bridge port
add bridge=LAN hw=no interface=ether1
add bridge=LAN hw=no interface=ether3
add bridge=LAN hw=no interface=ether4
add bridge=LAN hw=no interface=ether5

# DHCP client WAN
/ip dhcp-client
add disabled=no interface=ether2_WAN

# LAN network
/ip address
add address=10.10.0.1/24 interface=LAN network=10.10.0.0


# LAN DHCP server
/ip pool
add name=dhcp_pool1 ranges=10.10.0.150-10.10.0.240
/ip dhcp-server
add address-pool=dhcp_pool1 authoritative=after-2sec-delay disabled=no interface=LAN name=dhcp_LAN
/ip dhcp-server network
add address=10.10.0.0/24 gateway=10.10.0.1 dns-server=10.10.0.1

/ip dns
set servers=8.8.8.8,8.8.4.4 allow-remote-requests=yes

# Firewall NAT
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether2_WAN
