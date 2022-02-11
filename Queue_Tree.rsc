:local lanInterface "bridge-LAN";
:local wanInterface "ether6-WAN";
:local upload "17M"
:local download "35M"

/ip firewall mangle
add action=mark-connection chain=prerouting comment=ICMP new-connection-mark=\
    ICMP_Conn passthrough=yes protocol=icmp
add action=mark-packet chain=prerouting connection-mark=ICMP_Conn \
    in-interface=$lanInterface new-packet-mark=ICMP_Up passthrough=no
add action=mark-packet chain=prerouting connection-mark=ICMP_Conn \
    in-interface=$wanInterface new-packet-mark=ICMP_Down passthrough=no
add action=mark-connection chain=prerouting comment=DNS dst-port=53 \
    new-connection-mark=DNS_Conn passthrough=yes protocol=tcp
add action=mark-connection chain=prerouting dst-port=53 new-connection-mark=\
    DNS_Conn passthrough=yes protocol=udp
add action=mark-packet chain=prerouting connection-mark=DNS_Conn \
    in-interface=$lanInterface new-packet-mark=DNS_Up passthrough=no
add action=mark-packet chain=prerouting connection-mark=DNS_Conn \
    in-interface=$wanInterface new-packet-mark=DNS_Down passthrough=no
add action=mark-connection chain=prerouting comment="Quic Protocol" \
    connection-state=new dst-port=80,443 new-connection-mark=Quic_Conn \
    passthrough=yes port="" protocol=udp
add action=mark-packet chain=prerouting connection-mark=Quic_Conn \
    in-interface=$lanInterface new-packet-mark=Quic_Up passthrough=no
add action=mark-packet chain=prerouting connection-mark=Quic_Conn \
    in-interface=$wanInterface new-packet-mark=Quic_Down passthrough=no
add action=mark-connection chain=prerouting comment="Web (Http+Https)" \
    dst-port=80,443 new-connection-mark=Web_Conn passthrough=yes protocol=tcp
add action=mark-connection chain=prerouting dst-port=80,443 \
    new-connection-mark=Web_Conn passthrough=yes protocol=udp
add action=mark-packet chain=prerouting connection-mark=Web_Conn \
    in-interface=$lanInterface new-packet-mark=Web_Up passthrough=no
add action=mark-packet chain=prerouting connection-mark=Web_Conn \
    in-interface=$wanInterface new-packet-mark=Web_Down passthrough=no
add action=mark-connection chain=prerouting comment=Videocall dst-port=\
    5090,5091,8801,8802 new-connection-mark=Zoom_Conn passthrough=yes \
    protocol=tcp
add action=mark-connection chain=prerouting dst-port=3478,3479,5090,8801-8810 \
    new-connection-mark=Zoom_Conn passthrough=yes protocol=udp
add action=mark-packet chain=prerouting connection-mark=Zoom_Conn \
    in-interface=$lanInterface new-packet-mark=Zoom_Up passthrough=no
add action=mark-packet chain=prerouting connection-mark=Zoom_Conn \
    in-interface=$wanInterface new-packet-mark=Zoom_Down passthrough=no

/queue tree
add limit-at=$download max-limit=$download name=Down_Total parent=$lanInterface priority=1 queue=\
    pcq-download-default
add limit-at=$upload max-limit=$upload name=Up_Total parent=global priority=1 queue=\
    pcq-upload-default
add max-limit=$download name=ICMP_Down packet-mark=ICMP_Down parent=Down_Total \
    priority=1 queue=default
add max-limit=$upload name=ICMP_Up packet-mark=ICMP_Up parent=Up_Total priority=1 \
    queue=default
add max-limit=$download name=DNS_Down packet-mark=DNS_Down parent=Down_Total \
    priority=2 queue=default
add max-limit=$upload name=DNS_Up packet-mark=DNS_Up parent=Up_Total priority=2
add max-limit=$download name=Web_Down packet-mark=Web_Down parent=Down_Total \
    priority=4 queue=default
add max-limit=$upload name=Web_Up packet-mark=Web_Up parent=Up_Total priority=4 \
    queue=default
add max-limit=$download name=Quic_Down packet-mark=Quic_Down parent=Down_Total \
    queue=default
add max-limit=$upload name=Quic_Up packet-mark=Quic_Up parent=Up_Total queue=\
    default
add max-limit=$download name=Zoom_Down packet-mark=Zoom_Down parent=Down_Total \
    priority=3 queue=default
add max-limit=$upload name=Zoom_Up packet-mark=Zoom_Up parent=Up_Total priority=3
