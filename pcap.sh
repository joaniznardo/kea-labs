#!/bin/sh
# call this script as
# pcap.sh <containerlab-host> <container-name> <interface-name>
# example: pcap.sh clab-vm srl e1-1

# to support multiple interfaces, pass them as comma separated list
# split $3 separate by comma as -i <interface1> -i <interface2> -i <interface3>
IFS=',' read -ra ADDR <<< "$3"
IFACES=""
for i in "${ADDR[@]}"; do
    IFACES+=" -i $i"
done

#ssh $1 "sudo ip netns exec $2 tshark -l ${IFACES} -w -" | wireshark -k -i -
sudo ip netns exec $2 tshark -l ${IFACES} -w - | wireshark -k -i -
