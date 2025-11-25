#include "../../includes/ipPkt.h"
#include "../../includes/packet.h"
#include "../../includes/channels.h"

module IPP {
    provides {
        interface IP;
    }

    uses {
        interface SimpleSend;
        interface PacketHandler;
        interface LinkStateRouting;
        interface List<uint8_t> as PendingQueue;
    }
}

implementation {
    enum {
        MAX_NUM_PENDING = 10,
    };

    uint8_t local_seq = 1;

    pendingPayload_t pending[MAX_NUM_PENDING];
    
    bool look_up[MAX_NUM_PENDING];

    void makeIPPkt(ipPkt_t* Package, uint8_t dest, uint8_t protocol, uint8_t TTL, uint8_t flag, uint8_t offset, uint8_t* payload, uint16_t length);

    void forward(ipPkt_t* incomingMsg);

    void check_payload(ipPkt_t* incomingMsg);

    command void IP.onBoot() {
        uint8_t i = 0;
        for (; i < MAX_NUM_PENDING; i++) {
            call PendingQueue.pushback(i);
        }
    }

    command void IP.send(uint8_t dest, uint8_t protocol, uint8_t TTL, uint8_t* payload, uint16_t length) {
        pack pkt;
        ipPkt_t ip_pkt;
        uint8_t next_hop = call LinkStateRouting.nextHop(dest);
        makeIPPkt(&ip_pkt, dest, protocol, TTL, 0, 0, payload, length);
        call SimpleSend.makePack(&pkt, TOS_NODE_ID, next_hop, PROTOCOL_IP, (uint8_t*)&ip_pkt, sizeof(ipPkt_t));
        call SimpleSend.send(pkt, next_hop);
        return;
    }

    event void PacketHandler.gotIpPkt(uint8_t* incomingMsg){
        ipPkt_t ip_pkt;
        memcpy(&ip_pkt, incomingMsg, sizeof(ipPkt_t));
        if (ip_pkt.dest == TOS_NODE_ID) {
            check_payload(&ip_pkt);
        } else {
            forward(&ip_pkt);
        }
    }

    void forward(ipPkt_t* incomingMsg) {
        pack pkt;
        uint8_t next_hop = call LinkStateRouting.nextHop(incomingMsg->dest);
        if (call LinkStateRouting.pathCost(incomingMsg->dest) != 65535) {
            call SimpleSend.makePack(&pkt, TOS_NODE_ID, next_hop, PROTOCOL_IP, (uint8_t*)incomingMsg, sizeof(ipPkt_t));
            call SimpleSend.send(pkt, next_hop);
        }
    }

    void check_payload(ipPkt_t* incomingMsg) {
        printf("Node %d receive from node %d, payload = %s\n", TOS_NODE_ID, incomingMsg->src, incomingMsg->payload);
    }

    void makeIPPkt(ipPkt_t* Package, uint8_t dest, uint8_t protocol, uint8_t TTL, uint8_t flag, uint8_t offset, uint8_t* payload, uint16_t length) {
        Package->src = TOS_NODE_ID;
        Package->dest = dest;
        Package->protocol = protocol;
        Package->TTL = TTL;
        Package->flag = flag;
        Package->offset = offset;
        memcpy(Package->payload, payload, length);
    }

    event void PacketHandler.gotFloodPkt(uint8_t* incomingMsg, uint8_t from){}
    event void PacketHandler.gotNDPkt(uint8_t* _) { }

}