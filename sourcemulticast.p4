#include <core.p4>
#include <v1model.p4>

struct intrinsic_metadata_t {
    bit<4>  mcast_grp;
    bit<4>  egress_rid;
    bit<16> mcast_hash;
    bit<32> lf_field_list;
    bit<16> resubmit_flag;
}

typedef bit<48> EthernetAddress;
typedef bit<32> IPv4Address;
typedef bit<128> IPv6Address;

header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16> ethernetType;
}


header IPv4_h {
    bit<4> version;
    bit<4> ihl;
    bit<8> diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3> flags;
    bit<13> fragOffset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdrChecksum;
    IPv4Address srcAddr;
    IPv4Address dstAddr;
    //varbit<320>  options;
}

header IPv6_h {
    bit<4> version;
    bit<8> class;
    bit<20> flowlabel;
    bit<16> payloadlength;
    bit<8> nextheader;
    bit<8> hoplimit;
    IPv6Address srcAddr;
    IPv6Address dstAddr;
}

header Srh_h {
    bit<8> nextheader;
    bit<8> hdrextlen;
    bit<8> routingtype;
    bit<8> segmentleft;
    bit<8> lastentry;
    bit<8> flags;
    bit<16> tag;
}

header SMI_h {
    bit<128> smidentifier;
}

header SMS_h {
    bit<128> smstart;
}

header BR_h {
    bit<128> brbitstring;
}

header MS_h {
    bit<128> msheader;
}

header AL_h {
    bit<128> alheader_ab;
    bit<128> alheader;
}

header Address_h {
    bit<128> address1;
    bit<128> address2;
}

//header timedelta_h {
//    bit<128> deq_timedelta;
//}



struct headers {
    Ethernet_h ethernet;
    IPv6_h ipv6;
    Srh_h srh;
    Address_h addresslist;
    AL_h alh;
    MS_h msh;
    SMI_h smih;
    BR_h brh;
    SMS_h smsh;
    //timedelta_h timedelta;
}


struct mystruct_idx {
    bit<32> idx;
}


struct metadata {
    mystruct_idx mystruct1;
}

typedef tuple<bit<4>, bit<4>, bit<8>, varbit<56>> myTuple1;


error {
    Ipv4ChecksumError
}

//parse all the fields in the header firstly, without processing the distri SIDs
parser sm_Parser(packet_in pkt, out headers hdr, 
                    inout metadata meta, inout standard_metadata_t stdmeta)
{
    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ethernetType) {
            0x86dd : parse_ipv6;
            default : accept;
        }
    }

    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextheader) {
            43 : parse_srh;
            default : accept;
        }
    }

    state parse_srh {
        pkt.extract(hdr.srh);
        transition parse_addresslist;
    }

    state parse_addresslist {
        pkt.extract(hdr.addresslist);
        transition parse_alh;
    }

    state parse_alh {
        pkt.extract(hdr.alh);
        transition parse_msh;
    }

    state parse_msh {
        pkt.extract(hdr.msh);
        transition parse_smih;
    }

    state parse_smih {
        pkt.extract(hdr.smih);
        transition accept;
    }

    state parse_smsh {
        pkt.extract(hdr.smsh);
        transition accept;
    }

}

control sm_Ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t stdmeta)
{
    //tuple1 for SM.Identifier and BR.BitString, whose index is 0 and 1 respectively. tuple2 for Verification Mark
    register<bit<128>>(2) scr_statustuple1;
    register<bit<64>>(1) scr_statustuple2;

    action calculate_vm() {
        //get the random Verification Mark
        bit<32> random1;
        bit<32> random2;
        random(random1, 1, 4200000000);
        random(random2, 1, 4200000000);
        //save and insert the Verification Mark
        scr_statustuple2.write(0,random1++random2);
        hdr.msh.msheader = hdr.msh.msheader[127:96] ++ random1 ++ random2 ++ hdr.msh.msheader[31:0];
    }
    action forward(bit<9> port) {
        stdmeta.egress_spec = port;
    }

    action tuple1_save(bit<128> bitstring) {
        scr_statustuple1.write(0,hdr.smih.smidentifier);
        //for debug only, the terminal cannot print the register correctly
        //statustuple1.read(hdr.ipv6.srcAddr,0);
        scr_statustuple1.write(1,bitstring);
    }

    action write_bitstring() {
        hdr.brh.setValid();
        scr_statustuple1.read(hdr.brh.brbitstring, 1);
        hdr.ipv6.payloadlength = hdr.ipv6.payloadlength + 16;
        hdr.srh.lastentry = hdr.srh.lastentry + 1;
    }

    action read_write_vm() {
        bit<64> temp;
        scr_statustuple2.read(temp, 0);
        hdr.msh.msheader = hdr.msh.msheader[127:96] ++ temp ++ hdr.msh.msheader[31:0];
    }

    table match_inport {
        key = {
            stdmeta.ingress_port : exact;
        }
        actions = {forward;}
    }

    table match_ipv6 {
        key = {
            hdr.ipv6.dstAddr : lpm;
        }
        actions = {forward;}        
    }

    table generate_vm {
        actions = {calculate_vm;}
    }

    table save_sid {
        actions = {tuple1_save;}
    }

    table insert_bit {
        actions = {write_bitstring;}
    }

    table insert_vm {
        actions = {read_write_vm;} 
    }

    //for base inport processing
    
    apply {
        match_inport.apply();
    }

    //for ipv6 processing
    /*
    apply {
        match_inport.apply();
        match_ipv6.apply();
    }*/


    //for SCR process in Address Notification
    /*
    apply {
        generate_vm.apply();
        save_sid.apply();
        insert_bit.apply();
        match_inport.apply();
        match_ipv6.apply();
    }*/


    //for SCR process in Member Management
    /*
    apply {
        insert_vm.apply();
        insert_bit.apply();
        match_inport.apply();
        match_ipv6.apply();
    }*/




}



control sm_Egress(inout headers hdr, inout metadata meta, inout standard_metadata_t stdmeta)
{

    action write_rgt() {
        bit<16> buf = 0;
        //utilize the source MAC address to carry the processing time delta
        hdr.ethernet.srcAddr = buf ++ stdmeta.deq_timedelta;
        //for debug only
        //rgt.write(0, stdmeta.deq_timedelta);
    }

    table write_time {
        actions = {write_rgt;}
    }
    apply {
        write_time.apply();
    }

}

//checksum is useless in IPv6
control sm_VerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        /*verify_checksum(true,
        {   hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.totalLen,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.fragOffset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.srcAddr,
            hdr.ipv4.dstAddr//,hdr.ipv4.options
        },hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);*/
    }
}

control sm_UpdateChecksum(inout headers hdr, inout metadata meta) {
    apply {
        /*update_checksum(true,
        {   hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.totalLen,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.fragOffset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.srcAddr,
            hdr.ipv4.dstAddr//,hdr.ipv4.options
        },hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);*/
    }    
}

control sm_Deparser(packet_out packet, in headers hdr) {

    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.srh);
        packet.emit(hdr.addresslist);
        packet.emit(hdr.alh);
        packet.emit(hdr.msh);
        packet.emit(hdr.brh);
        packet.emit(hdr.smih);
        packet.emit(hdr.smsh);
        //packet.emit(hdr.timedelta);
    }

}

V1Switch<headers, metadata>(sm_Parser(), sm_VerifyChecksum(), sm_Ingress(), sm_Egress(), sm_UpdateChecksum(),sm_Deparser()) main;