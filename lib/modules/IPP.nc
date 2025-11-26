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
        interface List<uint8_t> as TimeoutQueue;
    }
}

implementation {
    enum {
        MAX_NUM_PENDING = 10,

        FRAGMENT_SIZE = 16,
    };

    uint8_t local_seq = 1;

    pendingPayload_t pending[MAX_NUM_PENDING];
    
    bool look_up[MAX_NUM_PENDING];

    void makeIPPkt(ipPkt_t* Package, uint8_t dest, uint8_t protocol, uint8_t TTL, uint8_t flag, uint8_t offset, uint8_t* payload, uint16_t length);

    void forward(ipPkt_t* incomingMsg);

    void check_payload(ipPkt_t* incomingMsg);

    void pending_payload(ipPkt_t* incomingMsg);

    command void IP.onBoot() {
        uint8_t i = 0;
        for (; i < MAX_NUM_PENDING; i++) {
            call PendingQueue.pushback(i);
        }
    }

    command void IP.send(uint8_t dest, uint8_t protocol, uint8_t TTL, uint8_t* payload, uint16_t length) {
        pack pkt;
        ipPkt_t ip_pkt;
        uint8_t offset, flag;
        uint8_t i = 0;
        uint8_t next_hop = call LinkStateRouting.nextHop(dest);
        uint8_t k = length / (4 * 4);
        uint8_t r = length - (4 * 4 * k);

        for (; i < k; i++) {
            if (i == k - 1 && r == 0) {
                offset = 4 * i;
                flag = (k == 1) ? 0 : (128 + local_seq);
                makeIPPkt(&ip_pkt, dest, protocol, TTL, flag, offset, payload + i * FRAGMENT_SIZE, FRAGMENT_SIZE);
                call SimpleSend.makePack(&pkt, TOS_NODE_ID, next_hop, PROTOCOL_IP, (uint8_t*)&ip_pkt, sizeof(ipPkt_t));
                call SimpleSend.send(pkt, next_hop);
                return;
            }

            offset = 4 * i;
            flag = 192 + local_seq;
            makeIPPkt(&ip_pkt, dest, protocol, TTL, flag, offset, payload + i * FRAGMENT_SIZE, FRAGMENT_SIZE);
            call SimpleSend.makePack(&pkt, TOS_NODE_ID, next_hop, PROTOCOL_IP, (uint8_t*)&ip_pkt, sizeof(ipPkt_t));
            call SimpleSend.send(pkt, next_hop);
        }

        offset = 4 * k;
        flag = (k == 0) ? 0 : (128 + local_seq);
        makeIPPkt(&ip_pkt, dest, protocol, TTL, flag, offset, payload + k * FRAGMENT_SIZE, FRAGMENT_SIZE);
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
        if (incomingMsg->flag == 0) {
            switch(incomingMsg->protocol) {
                case PROTOCOL_TCP:
                    signal IP.gotTCP(incomingMsg->payload);
                    break;
                default:
                    return;
            }
        } else {
            pending_payload(incomingMsg);
        }
    }

    void pending_payload(ipPkt_t* incomingMsg) {
        printf("PNEDING\n");
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