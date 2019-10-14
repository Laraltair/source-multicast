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
    //varbit<2560> segmentlist;//at most 20 SIDs, only used for sending
}

header SM_h {
    bit<128> smidentifier;
    bit<128> smstart;
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



struct headers {
    Ethernet_h ethernet;
    IPv6_h ipv6;
    Srh_h srh;
    Address_h addresslist;
    AL_h alh;
    MS_h msh;
    SM_h smh;
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
parser mr_Parser(packet_in pkt, out headers hdr, 
                    inout metadata meta, inout standard_metadata_t stdmeta)
{
    bit<8> temp;
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
        temp = hdr.srh.segmentleft;
        parse_addresslist;
    }

    state parse_addresslist {
        pkt.extract(hdr.addresslist);
        parse_alh;
    }

    state parse_alh {
        pkt.extract(hdr.alh);
        parse_msh;
    }

    state parse_msh {
        pkt.extract(hdr.msh);
        parse_smh;
    }

    state parse_smh {
        pkt.extract(hdr.smh);
        accept;
    }

}

//the distri SIDs will be processed by the tables
control mr_Ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t stdmeta)
{

    
    apply {

    }


}



control mr_Egress(inout headers hdr, inout metadata meta, inout standard_metadata_t stdmeta)
{ 
    apply {
        
    }
}


control mr_VerifyChecksum(inout headers hdr, inout metadata meta) {
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

control mr_UpdateChecksum(inout headers hdr, inout metadata meta) {
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

control mr_Deparser(packet_out packet, in headers hdr) {

    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.srh);
        packet.emit(hdr.addresslist);
        packet.emit(hdr.alh);
        packet.emit(hdr.msh);
        packet.emit(hdr.smh);
    }

}

V1Switch<headers, metadata>(mr_Parser(), mr_VerifyChecksum(), mr_Ingress(), mr_Egress(), mr_UpdateChecksum(),mr_Deparser()) main;