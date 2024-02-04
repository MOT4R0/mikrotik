# Mikrotik - RouterOS 6.45.9 compatible
# Basic LAN configuration

:delay 60
:log info "////\\\\                ////\\\\"
:log info "\\\\////                \\\\////"1
# Set timezone
/system clock
set time-zone-name=America/La_Paz

:log info "Zona horaria establecida"

# variables
:local interfaceCount 0;
:local wanInterfaces 1;
:local networkAddress "192.168.10.1/24";

# Detect ethernet ports and craete a LAN Bridge, add all the ports after ether1 to the bridge.

:foreach interface in=[/interface find] do={
    :local interfaceType [/interface get $interface type]
    :if ($interfaceType="ether") do={
        :set interfaceCount ($interfaceCount + 1)
    }
}

:log info "$interfaceCount Ethernet interfaces identified"

:if ($interfaceCount > 1) do={
    /interface bridge add name=bridgeLAN
    :log info "Bridge creado"
    :local currentInterface ($wanInterfaces + 1);
    :while ($currentInterface < $interfaceCount) do={
        /interface bridge port add bridge=bridgeLAN interface=("ether" . $currentInterface)
        :set currentInterface ($currentInterface + 1)
    }
} else={
    :put "There are not enough interfaces to create the bridge."
}

:log info "Ports added to the Bridge"

:local waninterfaceCount 1;

:while ($waninterfaceCount <= $wanInterfaces) do={
    /ip dhcp-client add comment=("WAN_" . $waninterfaceCount) dhcp-options=hostname,clientid disabled=no interface=("ether" . $waninterfaceCount)
    /interface ethernet set [ find default-name=("ether" . $waninterfaceCount) ] comment=("WAN_" . $waninterfaceCount)
    :log info "WAN $waninterfaceCount added"
    :set waninterfaceCount ($waninterfaceCount + 1)
}

:log info "DHCP Client for WAN added"

# Add the IP Addresses
/ip address
add address=($networkAddress) interface=bridgeLAN

:log info "Direccionamiento IP agregado en bridgeLAN"

# Add the IP Pool for DHCP Server
/ip pool
add name=dhcp_poolLAN ranges=($networkAddress . "50-" . $networkAddress . "254")

# Add DHCP Server
/ip dhcp-server
add address-pool=dhcp_poolLAN disabled=no interface=bridgeLAN name=dhcpLAN

# Add DHCP Network
/ip dhcp-server network
add address=($networkAddress . "0/24") dns-server=8.8.8.8,8.8.4.4 gateway=($networkAddress . "1")

:log info "DHCP Server agregado en bridgeLAN"

# Add DNS Server
/ip dns
set allow-remote-requests=yes servers=8.8.8.8,8.8.4.4

:log info "DNS Server agregado"

# Add Internet NAT
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1

:log info "Firewall NAT agregado"

:log info "////\\\\                ////\\\\"
:log info "\\\\////                \\\\////"
:log info "Script basic-lan ejecutado exitosamente."