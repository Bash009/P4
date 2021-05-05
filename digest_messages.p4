/* -*- P4_16 -*- */
#include <core.p4>
/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;
const bit<5>  IPV4_OPTION_INT = 31;
/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

#define MAX_INT_HEADERS 9




typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

typedef bit<13> switch_id_t;

typedef bit<13> queue_depth_t;

typedef bit<6>  output_port_t;

//typedef bit<48> interval_t;

typedef bit<48> ingress;

//typedef bit<48> difference;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    tos;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}


/*header ipv4_option_t {

    bit<1> copyFlag;

    bit<2> optClass;

    bit<5> option;

    bit<8> optionLength;

}*/

/* header int_count_t {

    bit<16>   num_switches;

}

header int_header_t {

    switch_id_t switch_id;

    queue_depth_t queue_depth;

    output_port_t output_port;

    // interval_t time;

    ingress in_ts;

  //  difference Diff;

    }*/

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}


struct parser_metadata_t {

    bit<16> num_headers_remaining;



}

struct learn_t {
    bit<8> digest;
   bit<32> srcIP;
   bit<32> dstIP;
   bit<64>  arrival_time;
   bit<8> sid;
}

struct learn_2{
bit<64> egress_time;
bit<16> qd;

}

struct metadata {
    learn_t learn;
    learn_2 learn2;
    parser_metadata_t  parser_metadata;
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    //ipv4_option_t ipv4_option;
   udp_t udp;

    //int_count_t   int_count;
    

   // int_header_t[MAX_INT_HEADERS] int_headers;
}


error { IPHeaderWithoutOptions }
/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {

        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType){

            TYPE_IPV4: parse_ipv4;
            default: accept;
        }

    }

state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            17  : parse_udp;
            default : accept;
        }
    }

state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
    }
}

     /*state parse_ipv4 {

        packet.extract(hdr.ipv4);

        //Check if ihl is bigger than 5. Packets without ip options set ihl to 5.

        verify(hdr.ipv4.ihl >= 5, error.IPHeaderWithoutOptions);

        transition select(hdr.ipv4.ihl) {

            5             : accept;

            //default       : parse_ipv4_option;
            default       : parse_ipv4_option;

        }

    }*/

 

   /* state parse_ipv4_option {

        packet.extract(hdr.ipv4_option);

        transition select(hdr.ipv4_option.option){



            IPV4_OPTION_INT:  parse_int;

            default: accept;



        }

     }



    state parse_int {

        packet.extract(hdr.int_count);

        meta.parser_metadata.num_headers_remaining = hdr.int_count.num_switches;

        transition select(meta.parser_metadata.num_headers_remaining){

            0: accept;

            default: parse_int_headers;

        }

    }



    state parse_int_headers {

        packet.extract(hdr.int_headers.next);

        meta.parser_metadata.num_headers_remaining = meta.parser_metadata.num_headers_remaining -1 ;

        transition select(meta.parser_metadata.num_headers_remaining){

            0: accept;

            default: parse_int_headers;

        }

    }*/





/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action drop() {
        mark_to_drop(standard_metadata);
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port,bit<8> swid) {

        //set the src mac address as the previous dst, this is not correct right?
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;

       //set the destination mac address that we got from the match in the table
        hdr.ethernet.dstAddr = dstAddr;

        //set the output port that we also get from the table
        standard_metadata.egress_spec = port;

        //decrease ttl by 1
        hdr.ipv4.ttl = hdr.ipv4.ttl -1;
        random(meta.learn.digest,(bit<8>) 0, (bit<8>) 255);
        meta.learn.srcIP = hdr.ipv4.srcAddr;
        meta.learn.dstIP = hdr.ipv4.dstAddr; 
        meta.learn.arrival_time = (bit<64>)standard_metadata.ingress_global_timestamp;
        meta.learn.sid = (bit<8>) swid;
       

        //digest packet
      digest(1, meta.learn); 
    }
/*action add_int_header(switch_id_t swid){



        //increase int stack counter by one

        hdr.int_count.num_switches = hdr.int_count.num_switches + 1;



	



        hdr.int_headers.push_front(1);

        // This was not needed in older specs. Now by default pushed

        // invalid elements are

        hdr.int_headers[0].setValid();

       // hdr.int_headers[0].in_ts = (bit<48>)standard_metadata.ingress_global_timestamp;

        



        //update ip header length

        hdr.ipv4.ihl = hdr.ipv4.ihl + 1;

        hdr.ipv4.totalLen = hdr.ipv4.totalLen + 6;

        hdr.ipv4_option.optionLength = hdr.ipv4_option.optionLength +6;


      // random(meta.learn.digest,(bit<8>) 0, (bit<8>) 255);
      
        //meta.learn.arrival_time =  hdr.int_headers[0].in_ts;
        
        meta.learn.sid = (bit<16>)swid;

        //digest packet
       digest(1, meta.learn);


    }*/
 /*table int_table {

        actions = {

            add_int_header;

            NoAction;

        }

        default_action = add_int_header(1);

        

	

    }*/


    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
         
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

 /*table int_table {

        actions = {

            add_int_header;

            NoAction;

        }

        default_action = add_int_header(1);

        

	

    }





  table dummy2{

	key ={

		hdr.int_headers[0].in_ts : exact; 
                //hdr.int_headers[0].switch_id: exact; 
                 meta.learn.sid:exact;
                 

	}

	actions = {

		

	}

} */

    apply {
        //only if IPV4 the rule is applied. Therefore other packets will not be forwarded.
        if (hdr.ipv4.isValid()){
            ipv4_lpm.apply();

        }
/* if (hdr.int_count.isValid()){

            int_table.apply();

           }

        dummy2.apply();*/
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {



 action add_int_header(switch_id_t swid){
         meta.learn2.egress_time = (bit<64>)standard_metadata.egress_global_timestamp;
         meta.learn2.qd = (bit<16>)standard_metadata.deq_qdepth;



        //increase int stack counter by one

        //hdr.int_count.num_switches = hdr.int_count.num_switches + 1;



	



       // hdr.int_headers.push_front(1);

        // This was not needed in older specs. Now by default pushed

        // invalid elements are

        //hdr.int_headers[0].setValid();

        //hdr.int_headers[0].switch_id = (bit<13>)swid;

        //hdr.int_headers[0].queue_depth = (bit<13>)standard_metadata.deq_qdepth;

        //hdr.int_headers[0].output_port = (bit<6>)standard_metadata.egress_port;

        // hdr.int_headers[0].time = (bit<48>)standard_metadata.egress_global_timestamp;
       

      // meta.learn.sid = (bit<16>)swid;
         



        //update ip header length

       // hdr.ipv4.ihl = hdr.ipv4.ihl + 1;

     //   hdr.ipv4.totalLen = hdr.ipv4.totalLen + 4;

     //   hdr.ipv4_option.optionLength = hdr.ipv4_option.optionLength + 4;
     
     //   digest(2, meta.learn2);
    
       

    }




    table int_table {

        actions = {

            add_int_header;

            NoAction;

        }

        default_action = add_int_header(1);

        

	

    }

   

   table dummy{

	key ={

		//hdr.int_count.num_switches : exact;

		// hdr.int_headers[0].time : exact; 

                // hdr.int_headers[0].Diff: exact;
                meta.learn2.egress_time:exact;
                meta.learn2.qd:exact;
                

	}

	actions = {



	}

}

    apply {


  /*if (hdr.int_count.isValid()){

            int_table.apply();

        }*/
          int_table.apply();

	dummy.apply();

        /*@atomic{

            hdr.int_headers[0].Diff=hdr.int_headers[0].time - hdr.int_headers[0].in_ts;

        }*/

    }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
              hdr.ipv4.tos,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {

        //parsed headers have to be added again into the packet.
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
     //   packet.emit(hdr.ipv4_option);

      //  packet.emit(hdr.int_count);

     //   packet.emit(hdr.int_headers);
         
         packet.emit(hdr.udp);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

//switch architecture
V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
