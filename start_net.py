import os
#p4c -b bmv2-ss-p4org distriswitch.p4 -o distriswitch.json
#sudo ./simple_switch_CLI --thrift-port 9090
#ip -6 route add DSTADDR dev DEVICE
# tshark -r test_result.pcapng -t a -S ',' -P -T fields -e icmpv6.echo.sequence_number -e frame.interface_id -e frame.time_relative > result.txt
os.system("sudo python topology.py --behavioral-exe /home/wu/behavioral-model/targets/simple_switch/simple_switch --json sourcemulticast.json/sourcemulticast.json")