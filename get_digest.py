import nnpy
import struct
import sys
import ipaddress
from p4utils.utils.topology import Topology
from p4utils.utils.sswitch_API import SimpleSwitchAPI
import time
import json

class DigestController():

    def __init__(self, sw_name):

        self.sw_name = sw_name
        self.topo = Topology(db="topology.db")
        self.sw_name = sw_name
        self.thrift_port = self.topo.get_thrift_port(sw_name)
        self.controller = SimpleSwitchAPI(self.thrift_port)

    def recv_msg_digest(self, msg):

        topic, device_id, ctx_id, list_id, buffer_id, num = struct.unpack("<iQiiQi",
                                                                     msg[:32])
        #print num, len(msg)
        offset,offset2  = 18,26
         
        msg = msg[32:]
	i=0
        list1=[]
        sublist=[]
        
         
        buffer1,buffer2,buffer3=0,0,0 
        for sub_message in range(num):
            random_num, src, dst,times,switch_id= struct.unpack("!BIIqb", msg[0:offset])
            try:
            	  
            	_,_,_,_,_,etime=struct.unpack("!BIIqbQ", msg[0:offset2])
            except:
             	print "sniffing....."
            #random_num, time= struct.unpack("!BII", msg[0:offset])
            #sublist=[]
            if i%2:
                #print "random number:", random_num, "src ip:", str(ipaddress.IPv4Address(src)), "dst ip:", str(ipaddress.IPv4Address(dst)),"arrival_time:",times, "Switch_ID:",switch_id,"Egress time:",etime,"Buffer_Time:",abs(etime-times)
                print "Buffer_Time:",abs(etime-times),"Switch_ID:",switch_id
                '''if switch_id == 1:
                	buffer1+= abs(etime-times)
                elif switch_id == 2:
                	buffer2+=abs(etime-times)
                else:
                	buffer3+=abs(etime-times)'''
               # dict2 = {"Total buffer time at Switch 1":buffer1,"Total buffer time at Switch 2":buffer2,"Total buffer time at Switch 3":buffer3}

                
                #dict1={"random number": random_num, "src ip": str(ipaddress.IPv4Address(src)), "dst ip": str(ipaddress.IPv4Address(dst)),"arrival_time:":times, "Switch_ID":switch_id,"Egress time":etime,"Buffer_Time":abs(etime-times)}
                dict1={"Switch_ID":switch_id,"Buffer_Time":abs(etime-times)}
            	#list1.append(dict1.copy())
            	'''sublist.append(("random number:",  random_num))
                sublist.append(("src ip:", str(ipaddress.IPv4Address(src))))
                sublist.append(("dst ip:", str(ipaddress.IPv4Address(dst))))
               
                sublist.append(("Switch_ID:",switch_id))
                sublist.append(("arrival_time:",times)) '''
                '''with open("file.txt", "w") as output:
        		#output.write(str(times)+"\n")
                        output.write("Hello \n")'''
                gk = open('file3.txt', 'a')
                gk.write(str(dict1)+"\n")
                gk.close()
               # json_object = json.dumps(dict1,indent=4)
                '''with open("file3.json","a") as outfile:
                	json_object = json.dump(dict1,outfile)'''
                	
                
                
            
               
            i+=1
            #list1.append(sublist)
     
            
           

           #print "random number:", random_num,"time:",time 
       # print list1

        '''for i in range(len(sublist)):
        	with open("file.txt", "w") as output:
        		output.write(str(sublist[i]))'''

        self.controller.client.bm_learning_ack_buffer(ctx_id, list_id, buffer_id)

    def run_digest_loop(self):

        sub = nnpy.Socket(nnpy.AF_SP, nnpy.SUB)
        notifications_socket = self.controller.client.bm_mgmt_get_info().notifications_socket
        print "connecting to notification sub %s" % notifications_socket
        sub.connect(notifications_socket)
        sub.setsockopt(nnpy.SUB, nnpy.SUB_SUBSCRIBE, '')

        while True:
            msg = sub.recv()
            self.recv_msg_digest(msg)


def main():
    ''' print "~~~~~~~~~~~~Showing traffic/(per hop statistics) of packets passing through Switch-3~~~~~~~~~~~~~~~"
    	
    DigestController("s3").run_digest_loop() '''
    if int(sys.argv[1])==3:
       
    	print "~~~~~~~~~~~~Showing traffic/(per hop statistics) of packets passing through Switch-3~~~~~~~~~~~~~~~"
    	
    	DigestController("s3").run_digest_loop()
    if int(sys.argv[1])==2:
	print "~~~~~~~~~~~~Showing traffic/(per hop statistics) of packets passing through Switch-2~~~~~~~~~~~~~~~"
        DigestController("s2").run_digest_loop()
    if int(sys.argv[1])==1:
	print "~~~~~~~~~~~~Showing traffic/(per hop statistics) of packets passing through Switch-1~~~~~~~~~~~~~~~"
        DigestController("s1").run_digest_loop()
    else:
        print "Invalid switch id" 
if __name__ == "__main__":
    main()