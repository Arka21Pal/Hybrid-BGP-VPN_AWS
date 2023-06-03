#!/bin/sh

# Define profile and region variables
profile=""
region=""

# Will give the cleaned up XML for client configuration for ON-PREM-ROUTER1
# Change "[CustomerGatewayConfiguration][0]" to "[CustomerGatewayConfiguration][1]" for ON-PREM-ROUTER2

DescribeVpnConnections1() {
    aws ec2 describe-vpn-connections --profile "${profile}" --region "${region}" --output json --query "VpnConnections[?contains(State,\`available\`) == \`true\`].[CustomerGatewayConfiguration][0]" |  sed -e "s/\\\n/\n/g;s/\[//g;s/\]//g;s/\"</\</g;s/>\"/\>/g;/^$/d" | grep -v "xml" | sed 's/vpn_connection\sid=\\\"/vpn_connection id=\"\\/'
}

describe_vpn_connections_format_1=$(DescribeVpnConnections1)

# ----------

DescribeVpnConnections2() {
    aws ec2 describe-vpn-connections --profile "${profile}" --region "${region}" --output json --query "VpnConnections[?contains(State,\`available\`) == \`true\`].[CustomerGatewayConfiguration][1]" |  sed -e "s/\\\n/\n/g;s/\[//g;s/\]//g;s/\"</\</g;s/>\"/\>/g;/^$/d" | grep -v "xml" | sed 's/vpn_connection\sid=\\\"/vpn_connection id=\"\\/'
}

describe_vpn_connections_format_2=$(DescribeVpnConnections2)

# ----------

vpnconnectionid_command() {
aws ec2 describe-vpn-connections --profile "${profile}" --region "${region}" --output json --query "VpnConnections[?contains(State,\`available\`) == \`true\`].{VpnConnectionId: VpnConnectionId}" | grep "VpnConnectionId" | sed "s/.*\:\s\"\(.*\)\"/\1/"
}

# Get VPN connection ID:

VPN_CONNECTION_ID_1=$(vpnconnectionid_command | head -1)
VPN_CONNECTION_ID_2=$(vpnconnectionid_command | tail -1)


# ----------------------
# Preshared keys

CONN1_TUNNEL1_PresharedKey=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/ike/pre_shared_key --nl | head -1)

CONN1_TUNNEL2_PresharedKey=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/ike/pre_shared_key --nl | tail -1)

CONN2_TUNNEL1_PresharedKey=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/ike/pre_shared_key --nl | head -1)

CONN2_TUNNEL2_PresharedKey=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/ike/pre_shared_key --nl | tail -1)


# CustomerGateway Outside IPs

CONN1_TUNNEL1_ONPREM_OUTSIDE_IP=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/customer_gateway/tunnel_outside_address/ip_address --nl | head -1)

CONN1_TUNNEL2_ONPREM_OUTSIDE_IP="${CONN1_TUNNEL1_ONPREM_OUTSIDE_IP}"

CONN2_TUNNEL1_ONPREM_OUTSIDE_IP=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/customer_gateway/tunnel_outside_address/ip_address --nl | head -1)

CONN2_TUNNEL2_ONPREM_OUTSIDE_IP="${CONN2_TUNNEL1_ONPREM_OUTSIDE_IP}"


# VPN Gateway Outside IP addresses

CONN1_TUNNEL1_AWS_OUTSIDE_IP=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_outside_address/ip_address --nl | head -1)

CONN1_TUNNEL2_AWS_OUTSIDE_IP=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_outside_address/ip_address --nl | tail -1)

CONN2_TUNNEL1_AWS_OUTSIDE_IP=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_outside_address/ip_address --nl | head -1)

CONN2_TUNNEL2_AWS_OUTSIDE_IP=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_outside_address/ip_address --nl | tail -1)


# ON-PREM Inside IP addresses

CONN1_TUNNEL1_ONPREM_INSIDE_IP_ADDRESS=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/customer_gateway/tunnel_inside_address/ip_address --nl | head -1)
CONN1_TUNNEL1_ONPREM_INSIDE_IP_CIDR=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/customer_gateway/tunnel_inside_address/network_cidr --nl | head -1)
CONN1_TUNNEL1_ONPREM_INSIDE_IP="${CONN1_TUNNEL1_ONPREM_INSIDE_IP_ADDRESS}/${CONN1_TUNNEL1_ONPREM_INSIDE_IP_CIDR}"

CONN1_TUNNEL2_ONPREM_INSIDE_IP_ADDRESS=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/customer_gateway/tunnel_inside_address/ip_address --nl | tail -1)
CONN1_TUNNEL2_ONPREM_INSIDE_IP_CIDR=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/customer_gateway/tunnel_inside_address/network_cidr --nl | tail -1)
CONN1_TUNNEL2_ONPREM_INSIDE_IP="${CONN1_TUNNEL2_ONPREM_INSIDE_IP_ADDRESS}/${CONN1_TUNNEL2_ONPREM_INSIDE_IP_CIDR}"

CONN2_TUNNEL1_ONPREM_INSIDE_IP_ADDRESS=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/customer_gateway/tunnel_inside_address/ip_address --nl | head -1)
CONN2_TUNNEL1_ONPREM_INSIDE_IP_CIDR=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/customer_gateway/tunnel_inside_address/network_cidr --nl | head -1)
CONN2_TUNNEL1_ONPREM_INSIDE_IP="${CONN2_TUNNEL1_ONPREM_INSIDE_IP_ADDRESS}/${CONN2_TUNNEL1_ONPREM_INSIDE_IP_CIDR}"

CONN2_TUNNEL2_ONPREM_INSIDE_IP_ADDRESS=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/customer_gateway/tunnel_inside_address/ip_address --nl | tail -1)
CONN2_TUNNEL2_ONPREM_INSIDE_IP_CIDR=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/customer_gateway/tunnel_inside_address/network_cidr --nl | tail -1)
CONN2_TUNNEL2_ONPREM_INSIDE_IP="${CONN2_TUNNEL2_ONPREM_INSIDE_IP_ADDRESS}/${CONN2_TUNNEL2_ONPREM_INSIDE_IP_CIDR}"


# VPN Inside IPs

CONN1_TUNNEL1_AWS_INSIDE_IP_ADDRESS=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_inside_address/ip_address --nl | head -1)
CONN1_TUNNEL1_AWS_INSIDE_IP_CIDR=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_inside_address/network_cidr --nl | head -1)
CONN1_TUNNEL1_AWS_INSIDE_IP="${CONN1_TUNNEL1_AWS_INSIDE_IP_ADDRESS}/${CONN1_TUNNEL1_AWS_INSIDE_IP_CIDR}"

CONN1_TUNNEL2_AWS_INSIDE_IP_ADDRESS=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_inside_address/ip_address --nl | tail -1)
CONN1_TUNNEL2_AWS_INSIDE_IP_CIDR=$(printf "%s" "${describe_vpn_connections_format_1}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_inside_address/network_cidr --nl | tail -1)
CONN1_TUNNEL2_AWS_INSIDE_IP="${CONN1_TUNNEL2_AWS_INSIDE_IP_ADDRESS}/${CONN1_TUNNEL2_AWS_INSIDE_IP_CIDR}"

CONN2_TUNNEL1_AWS_INSIDE_IP_ADDRESS=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_inside_address/ip_address --nl | head -1)
CONN2_TUNNEL1_AWS_INSIDE_IP_CIDR=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_inside_address/network_cidr --nl | head -1)
CONN2_TUNNEL1_AWS_INSIDE_IP="${CONN2_TUNNEL1_AWS_INSIDE_IP_ADDRESS}/${CONN2_TUNNEL1_AWS_INSIDE_IP_CIDR}"

CONN2_TUNNEL2_AWS_INSIDE_IP_ADDRESS=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_inside_address/ip_address --nl | tail -1)
CONN2_TUNNEL2_AWS_INSIDE_IP_CIDR=$(printf "%s" "${describe_vpn_connections_format_2}" | xmlstarlet select --template --value-of /vpn_connection/ipsec_tunnel/vpn_gateway/tunnel_inside_address/network_cidr --nl | tail -1)
CONN2_TUNNEL2_AWS_INSIDE_IP="${CONN2_TUNNEL2_AWS_INSIDE_IP_ADDRESS}/${CONN2_TUNNEL2_AWS_INSIDE_IP_CIDR}"


# BGP Peer IPs

CONN1_TUNNEL1_AWS_BGP_IP="${CONN1_TUNNEL1_AWS_INSIDE_IP_ADDRESS}"
CONN1_TUNNEL2_AWS_BGP_IP="${CONN1_TUNNEL2_AWS_INSIDE_IP_ADDRESS}"
CONN2_TUNNEL1_AWS_BGP_IP="${CONN2_TUNNEL1_AWS_INSIDE_IP_ADDRESS}"
CONN2_TUNNEL2_AWS_BGP_IP="${CONN2_TUNNEL2_AWS_INSIDE_IP_ADDRESS}"

# Private IPs for ONPREM Routers

ROUTER1_PRIVATE_IP=$(aws ec2 describe-instances --profile "${profile}" --region "${region}" --filters "Name=tag:Name,Values=ONPREM-ROUTER1" --output text --query "Reservations[*].Instances[*].PrivateIpAddress")
ROUTER1_INSTANCEID=$(aws ec2 describe-instances --profile "${profile}" --region "${region}" --filters "Name=tag:Name,Values=ONPREM-ROUTER1" --output text --query "Reservations[*].Instances[?State.Name==\`running\`].InstanceId")
ROUTER2_PRIVATE_IP=$(aws ec2 describe-instances --profile "${profile}" --region "${region}" --filters "Name=tag:Name,Values=ONPREM-ROUTER2" --output text --query "Reservations[*].Instances[*].PrivateIpAddress")
ROUTER2_INSTANCEID=$(aws ec2 describe-instances --profile "${profile}" --region "${region}" --filters "Name=tag:Name,Values=ONPREM-ROUTER2" --output text --query "Reservations[*].Instances[?State.Name==\`running\`].InstanceId")


# ---------------------
# OUTPUTS

outputs() {
    printf "%s%s" "ROUTER1_PRIVATE_IP: " "${ROUTER1_PRIVATE_IP}"
    printf "\n"
    printf "%s%s" "ROUTER1_INSTANCEID: " "${ROUTER1_INSTANCEID}"
    printf "\n"
    printf "%s%s" "ROUTER2_PRIVATE_IP: " "${ROUTER2_PRIVATE_IP}"
    printf "\n"
    printf "%s%s" "ROUTER2_INSTANCEID: " "${ROUTER2_INSTANCEID}"
    printf "\n"
    printf "\n"
    printf "%s" "# --------------- #"
    printf "\n"
    printf "\n"
    printf "%s%s" "VPN_CONNECTION_ID_1: " "${VPN_CONNECTION_ID_1}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL1_PresharedKey: " "${CONN1_TUNNEL1_PresharedKey}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL1_ONPREM_OUTSIDE_IP: " "${CONN1_TUNNEL1_ONPREM_OUTSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL1_AWS_OUTSIDE_IP: " "${CONN1_TUNNEL1_AWS_OUTSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL1_ONPREM_INSIDE_IP: " "${CONN1_TUNNEL1_ONPREM_INSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL1_AWS_INSIDE_IP: " "${CONN1_TUNNEL1_AWS_INSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL1_AWS_BGP_IP: " "${CONN1_TUNNEL1_AWS_BGP_IP}"
    printf "\n"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL2_PresharedKey: " "${CONN1_TUNNEL2_PresharedKey}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL2_ONPREM_OUTSIDE_IP: " "${CONN1_TUNNEL2_ONPREM_OUTSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL2_AWS_OUTSIDE_IP: " "${CONN1_TUNNEL2_AWS_OUTSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL2_ONPREM_INSIDE_IP: " "${CONN1_TUNNEL2_ONPREM_INSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL2_AWS_INSIDE_IP: " "${CONN1_TUNNEL2_AWS_INSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN1_TUNNEL2_AWS_BGP_IP: " "${CONN1_TUNNEL2_AWS_BGP_IP}"
    printf "\n"
    printf "\n"
    printf "%s" "# --------------- #"
    printf "\n"
    printf "\n"
    printf "%s%s" "VPN_CONNECTION_ID_2: " "${VPN_CONNECTION_ID_2}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL1_PresharedKey: " "${CONN2_TUNNEL1_PresharedKey}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL1_ONPREM_OUTSIDE_IP: " "${CONN2_TUNNEL1_ONPREM_OUTSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL1_AWS_OUTSIDE_IP: " "${CONN2_TUNNEL1_AWS_OUTSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL1_ONPREM_INSIDE_IP: " "${CONN2_TUNNEL1_ONPREM_INSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL1_AWS_INSIDE_IP: " "${CONN2_TUNNEL1_AWS_INSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL1_AWS_BGP_IP: " "${CONN2_TUNNEL1_AWS_BGP_IP}"
    printf "\n"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL2_PresharedKey: " "${CONN2_TUNNEL2_PresharedKey}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL2_ONPREM_OUTSIDE_IP: " "${CONN2_TUNNEL2_ONPREM_OUTSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL2_AWS_OUTSIDE_IP: " "${CONN2_TUNNEL2_AWS_OUTSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL2_ONPREM_INSIDE_IP: " "${CONN2_TUNNEL2_ONPREM_INSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL2_AWS_INSIDE_IP: " "${CONN2_TUNNEL2_AWS_INSIDE_IP}"
    printf "\n"
    printf "%s%s" "CONN2_TUNNEL2_AWS_BGP_IP: " "${CONN2_TUNNEL2_AWS_BGP_IP}"
}

# outputs | less -FXR

# -----------------------------
# Edit IP addresses to escape fullstop in sed

CONN1_TUNNEL1_ONPREM_INSIDE_IP_FORMAT=$(printf "%s" "${CONN1_TUNNEL1_ONPREM_INSIDE_IP}" | sed 's/\//\\\//g')
CONN1_TUNNEL2_ONPREM_INSIDE_IP_FORMAT=$(printf "%s" "${CONN1_TUNNEL2_ONPREM_INSIDE_IP}" | sed 's/\//\\\//g')
CONN1_TUNNEL1_AWS_INSIDE_IP_FORMAT=$(printf "%s" "${CONN1_TUNNEL1_AWS_INSIDE_IP}" | sed 's/\//\\\//g')
CONN1_TUNNEL2_AWS_INSIDE_IP_FORMAT=$(printf "%s" "${CONN1_TUNNEL2_AWS_INSIDE_IP}" | sed 's/\//\\\//g')

CONN2_TUNNEL1_ONPREM_INSIDE_IP_FORMAT=$(printf "%s" "${CONN2_TUNNEL1_ONPREM_INSIDE_IP}" | sed 's/\//\\\//g')
CONN2_TUNNEL2_ONPREM_INSIDE_IP_FORMAT=$(printf "%s" "${CONN2_TUNNEL2_ONPREM_INSIDE_IP}" | sed 's/\//\\\//g')
CONN2_TUNNEL1_AWS_INSIDE_IP_FORMAT=$(printf "%s" "${CONN2_TUNNEL1_AWS_INSIDE_IP}" | sed 's/\//\\\//g')
CONN2_TUNNEL2_AWS_INSIDE_IP_FORMAT=$(printf "%s" "${CONN2_TUNNEL2_AWS_INSIDE_IP}" | sed 's/\//\\\//g')

# -----------------------------
# https://stackoverflow.com/questions/23929235/multi-line-string-with-extra-space-preserved-indentation

# The method to run multiple `vtysh` commands from a different shell (`sh` in this case)
# Is to use the same method one would use to run shell commands from a different shell
# i.e., "vtysh -c '' -c '' -c ''..... and so on"
# I can't believe this didn't hit me before this, this is so obvious
# https://marc.info/?l=quagga-users&m=115384972324406
# https://quagga-users.quagga.narkive.com/nBMNbaHI/7308-vtysh-c-with-multi-line-commands
# https://groups.google.com/g/sonicproject/c/WXeWHPDFY18?pli=1
# '-c' option in https://linux.die.net/man/1/vtysh

parameterfile1="editparametersBGP1.json"

cat > ${parameterfile1} <<- EOM
{
    "Parameters": {
        "commands": [
            "sed -i 's/ROUTER1_PRIVATE_IP/${ROUTER1_PRIVATE_IP}/g' /home/ubuntu/demo_assets/ipsec.conf",
            "sed -i 's/CONN1_TUNNEL1_ONPREM_OUTSIDE_IP/${CONN1_TUNNEL1_ONPREM_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.conf",
            "sed -i 's/CONN1_TUNNEL1_AWS_OUTSIDE_IP/${CONN1_TUNNEL1_AWS_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.conf",
            "sed -i 's/CONN1_TUNNEL2_ONPREM_OUTSIDE_IP/${CONN1_TUNNEL2_ONPREM_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.conf",
            "sed -i 's/CONN1_TUNNEL2_AWS_OUTSIDE_IP/${CONN1_TUNNEL2_AWS_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.conf",
            "sed -i 's/CONN1_TUNNEL1_ONPREM_OUTSIDE_IP/${CONN1_TUNNEL1_ONPREM_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN1_TUNNEL1_AWS_OUTSIDE_IP/${CONN1_TUNNEL1_AWS_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN1_TUNNEL1_PresharedKey/${CONN1_TUNNEL1_PresharedKey}/g' home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN1_TUNNEL2_ONPREM_OUTSIDE_IP/${CONN1_TUNNEL2_ONPREM_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN1_TUNNEL2_AWS_OUTSIDE_IP/${CONN1_TUNNEL2_AWS_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN1_TUNNEL2_PresharedKey/${CONN1_TUNNEL2_PresharedKey}/g' /home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN1_TUNNEL1_ONPREM_INSIDE_IP/${CONN1_TUNNEL1_ONPREM_INSIDE_IP_FORMAT}/g' /home/ubuntu/demo_assets/ipsec-vti.sh",
            "sed -i 's/CONN1_TUNNEL1_AWS_INSIDE_IP/${CONN1_TUNNEL1_AWS_INSIDE_IP_FORMAT}/g' /home/ubuntu/demo_assets/ipsec-vti.sh",
            "sed -i 's/CONN1_TUNNEL2_ONPREM_INSIDE_IP/${CONN1_TUNNEL2_ONPREM_INSIDE_IP_FORMAT}/g' /home/ubuntu/demo_assets/ipsec-vti.sh",
            "sed -i 's/CONN1_TUNNEL2_AWS_INSIDE_IP/${CONN1_TUNNEL2_AWS_INSIDE_IP_FORMAT}/g' /home/ubuntu/demo_assets/ipsec-vti.sh",
            "cp /home/ubuntu/demo_assets/ipsec* /etc/",
            "bash -c 'chmod +x /etc/ipsec-vti.sh'",
            "bash -c 'systemctl restart strongswan'",
            "bash -c 'chmod +x /home/ubuntu/demo_assets/ffrouting-install.sh'",
            "bash -c 'cd /home/ubuntu/demo_assets/ && ./ffrouting-install.sh'",
            "vtysh -E -c 'conf t' \
            -c 'frr defaults traditional' \
            -c 'router bgp 65016' \
            -c 'neighbor ${CONN1_TUNNEL1_AWS_BGP_IP} remote-as 64512' \
            -c 'neighbor ${CONN1_TUNNEL2_AWS_BGP_IP} remote-as 64512' \
            -c 'no bgp ebgp-requires-policy' \
            -c 'address-family ipv4 unicast' \
            -c 'redistribute connected' \
            -c 'exit-address-family' \
            -c exit \
            -c exit \
            -c wr \
            -c exit",
            "sudo reboot"
        ]
    }
}
EOM


# https://marc.info/?l=quagga-users&m=115384972324406
# https://quagga-users.quagga.narkive.com/nBMNbaHI/7308-vtysh-c-with-multi-line-commands
# https://groups.google.com/g/sonicproject/c/WXeWHPDFY18?pli=1
# '-c' option in https://linux.die.net/man/1/vtysh

parameterfile2="editparametersBGP2.json"

cat > ${parameterfile2} <<- EOM
{
    "Parameters": {
        "commands": [
            "sed -i 's/ROUTER2_PRIVATE_IP/${ROUTER2_PRIVATE_IP}/g' /home/ubuntu/demo_assets/ipsec.conf",
            "sed -i 's/CONN2_TUNNEL1_ONPREM_OUTSIDE_IP/${CONN2_TUNNEL1_ONPREM_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.conf",
            "sed -i 's/CONN2_TUNNEL1_AWS_OUTSIDE_IP/${CONN2_TUNNEL1_AWS_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.conf",
            "sed -i 's/CONN2_TUNNEL2_ONPREM_OUTSIDE_IP/${CONN2_TUNNEL2_ONPREM_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.conf",
            "sed -i 's/CONN2_TUNNEL2_AWS_OUTSIDE_IP/${CONN2_TUNNEL2_AWS_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.conf",
            "sed -i 's/CONN2_TUNNEL1_ONPREM_OUTSIDE_IP/${CONN2_TUNNEL1_ONPREM_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN2_TUNNEL1_AWS_OUTSIDE_IP/${CONN2_TUNNEL1_AWS_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN2_TUNNEL1_PresharedKey/${CONN2_TUNNEL1_PresharedKey}/g' home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN2_TUNNEL2_ONPREM_OUTSIDE_IP/${CONN2_TUNNEL2_ONPREM_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN2_TUNNEL2_AWS_OUTSIDE_IP/${CONN2_TUNNEL2_AWS_OUTSIDE_IP}/g' /home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN2_TUNNEL2_PresharedKey/${CONN2_TUNNEL2_PresharedKey}/g' /home/ubuntu/demo_assets/ipsec.secrets",
            "sed -i 's/CONN2_TUNNEL1_ONPREM_INSIDE_IP/${CONN2_TUNNEL1_ONPREM_INSIDE_IP_FORMAT}/g' /home/ubuntu/demo_assets/ipsec-vti.sh",
            "sed -i 's/CONN2_TUNNEL1_AWS_INSIDE_IP/${CONN2_TUNNEL1_AWS_INSIDE_IP_FORMAT}/g' /home/ubuntu/demo_assets/ipsec-vti.sh",
            "sed -i 's/CONN2_TUNNEL2_ONPREM_INSIDE_IP/${CONN2_TUNNEL2_ONPREM_INSIDE_IP_FORMAT}/g' /home/ubuntu/demo_assets/ipsec-vti.sh",
            "sed -i 's/CONN2_TUNNEL2_AWS_INSIDE_IP/${CONN2_TUNNEL2_AWS_INSIDE_IP_FORMAT}/g' /home/ubuntu/demo_assets/ipsec-vti.sh",
            "cp /home/ubuntu/demo_assets/ipsec* /etc/",
            "bash -c 'chmod +x /etc/ipsec-vti.sh'",
            "bash -c 'systemctl restart strongswan'",
            "bash -c 'chmod +x /home/ubuntu/demo_assets/ffrouting-install.sh'",
            "bash -c 'cd /home/ubuntu/demo_assets/ && ./ffrouting-install.sh'",
            "vtysh -E -c 'conf t' \
            -c 'frr defaults traditional' \
            -c 'router bgp 65016' \
            -c 'neighbor ${CONN2_TUNNEL1_AWS_BGP_IP} remote-as 64512' \
            -c 'neighbor ${CONN2_TUNNEL2_AWS_BGP_IP} remote-as 64512' \
            -c 'no bgp ebgp-requires-policy' \
            -c 'address-family ipv4 unicast' \
            -c 'redistribute connected' \
            -c 'exit-address-family' \
            -c exit \
            -c exit \
            -c wr \
            -c exit",
            "sudo reboot"
        ]
    }
}
EOM

# ------------------------

# Edit parameterfile1 and parameterfile2 again because '\' are being translated to escaping the current expression, when I need for it to carry over as a final command

sed -i 's/\/30/\\\/30/' "${parameterfile1}"
sed -i 's/\/30/\\\/30/' "${parameterfile2}"


# -------------------------
# Run commands on EC2 instance

aws ssm send-command --document-name "AWS-RunShellScript" --targets "Key=InstanceIds,Values=${ROUTER1_INSTANCEID}" --cli-input-json file://"${parameterfile1}" --profile "${profile}" --region "${region}"

aws ssm send-command --document-name "AWS-RunShellScript" --targets "Key=InstanceIds,Values=${ROUTER2_INSTANCEID}" --cli-input-json file://"${parameterfile2}" --profile "${profile}" --region "${region}"

# ------------------------
# Delete residual JSON files used to send commands to EC2 instances

rm "${parameterfile1}"; rm "${parameterfile2}"
