import os
from mininet.net import Mininet
from mininet.topo import Topo
from mininet.log import setLogLevel, info
from mininet.cli import CLI
from mininet.node import RemoteController

from p4_mininet import P4Switch, P4Host

import argparse
from time import sleep

parser = argparse.ArgumentParser(description='Mininet demo')
parser.add_argument('--behavioral-exe', help='Path to behavioral executable',
                    type=str, action="store", required=True)
parser.add_argument('--thrift-port', help='Thrift server port for table updates',
                    type=int, action="store", default=9090)
parser.add_argument('--num-hosts', help='Number of hosts to connect to switch',
                    type=int, action="store", default=2)
parser.add_argument('--mode', choices=['l2', 'l3'], type=str, default='l3')
parser.add_argument('--json', help='Path to JSON config file',
                    type=str, action="store", required=True)
parser.add_argument('--pcap-dump', help='Dump packets on interfaces to pcap files',
                    type=str, action="store", required=False, default=False)


args = parser.parse_args()


class SingleSwitchTopo(Topo):
    def __init__(self, sw_path, json_path, thrift_port, pcap_dump, **opts):
        Topo.__init__(self, **opts)

        switch1 = self.addSwitch('s1', sw_path = sw_path, json_path = json_path, thrift_port = thrift_port,cls = P4Switch ,pcap_dump = pcap_dump)
        
        host1 = self.addHost('h1', mac = '00:00:00:00:00:01')
        host2 = self.addHost('h2', mac = '00:00:00:00:00:02')
        host3 = self.addHost('h3', mac = '00:00:00:00:00:03')

        host4 = self.addHost('h4')
        host5 = self.addHost('h5')
        host6 = self.addHost('h6')
        host7 = self.addHost('h7')
        host8 = self.addHost('h8')
        host9 = self.addHost('h9')
        host10 = self.addHost('h10')
        host11 = self.addHost('h11')
        host12 = self.addHost('h12')
        host13 = self.addHost('h13')
        host14 = self.addHost('h14')
        host15 = self.addHost('h15')
        host16 = self.addHost('h16')
        host17 = self.addHost('h17')
        host18 = self.addHost('h18')
        host19 = self.addHost('h19')
        host20 = self.addHost('h20')
        host21 = self.addHost('h21')
        
        

        self.addLink(host1, switch1, port1 = 0, port2 = 1)
        self.addLink(host2, switch1, port1 = 0, port2 = 2)
        self.addLink(host3, switch1, port1 = 0, port2 = 3)
        
        self.addLink(host4, switch1, port1 = 0, port2 = 4)
        self.addLink(host5, switch1, port1 = 0, port2 = 5)
        self.addLink(host6, switch1, port1 = 0, port2 = 6)
        self.addLink(host7, switch1, port1 = 0, port2 = 7)
        self.addLink(host8, switch1, port1 = 0, port2 = 8)
        self.addLink(host9, switch1, port1 = 0, port2 = 9)
        self.addLink(host10, switch1, port1 = 0, port2 = 10)
        self.addLink(host11, switch1, port1 = 0, port2 = 11)
        self.addLink(host12, switch1, port1 = 0, port2 = 12)
        self.addLink(host13, switch1, port1 = 0, port2 = 13)
        self.addLink(host14, switch1, port1 = 0, port2 = 14)
        self.addLink(host15, switch1, port1 = 0, port2 = 15)
        self.addLink(host16, switch1, port1 = 0, port2 = 16)
        self.addLink(host17, switch1, port1 = 0, port2 = 17)
        self.addLink(host18, switch1, port1 = 0, port2 = 18)
        self.addLink(host19, switch1, port1 = 0, port2 = 19)
        self.addLink(host20, switch1, port1 = 0, port2 = 20)
        self.addLink(host21, switch1, port1 = 0, port2 = 21)


def main():
    topo = SingleSwitchTopo(args.behavioral_exe, args.json, args.thrift_port, args.pcap_dump)
    #controller1 = RemoteController('controller1', ip = '10.108.148.148')
    net = Mininet(topo = topo, host = P4Host, controller = None)
    net.start()
    net.get('h1').cmd('ip addr add 2001::1/64 dev eth0')
    net.get('h1').cmd('ip -6 route add 2003::1 dev eth0')
    net.get('h1').cmd('ip -6 route add 2002::1 encap seg6 mode inline segs ff02:1111:1111:1111:1111:1111:1111:1111,2021::1,2020::1,2019::1,2018::1,2017::1,2016::1,2015::1,2014::1,2013::1,2012::1,2011::1,2010::1,2009::1,2008::1,2007::1,2006::1,2005::1,2004::1,2003::1 dev eth0')
    net.get('h1').cmd('ip sr tunsrc set 2001::1')
    net.get('h1').cmd('ip -6 route add ff02:1111:1111:1111:1111:1111:1111:1111 via 2002::1 dev eth0')

    net.get('h2').cmd('ip addr add 2002::1/64 dev eth0')
    net.get('h2').cmd('ip -6 route add 2001::1 dev eth0')

    net.get('h3').cmd('ip addr add 2003::1/64 dev eth0')
    net.get('h3').cmd('ip -6 route add 2001::1 dev eth0')

    sleep(1)

    print('\033[0;32m'),
    print "Gotcha!"
    print('\033[0m')

    CLI(net)
    try:
        net.stop()
    except:
        print('\033[0;31m'),
        print('Stop error! Trying sudo mn -c')
        print('\033[0m')
        os.system('sudo mn -c')
        print('\033[0;32m'),
        print ('Stop successfully!')
        print('\033[0m')

if __name__ == '__main__':
    setLogLevel('info')
    main()

    


