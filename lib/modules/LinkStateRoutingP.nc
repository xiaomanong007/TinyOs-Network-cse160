#include "../../includes/lsaPkt.h"
#include "../../includes/protocol.h"

#define INFINITE 65535

module LinkStateRoutingP {
    provides {
        interface LinkStateRouting;
    }
    uses {
        interface PacketHandler;
        interface Flooding;
        interface NeighborDiscovery;
        interface Random;
        interface Timer<TMilli> as ShareTimer;
        interface Timer<TMilli> as DijstraTimer;
    }
}

implementation {
    enum {
        // Each cylce should take approximately 60 to complete all sharings, 100 second to construct a table

        // Start Timer = 180 - 185 second
        START_DELAY_LOWER = 295000 * 3,
        START_DELAY_UPPER = 300000 * 3,

        // Construct Routing Table = 85 - 90 second
        CONSTRUCT_R_TABLE_LOWER = 85000,
        CONSTRUCT_R_TABLE_UPPER = 90000,
    };

    uint8_t local_seq = 1;
    bool init = FALSE;

    uint8_t n = 0;

    void makeLSAPack(linkStateAdPkt_t *Package, uint8_t seq, uint8_t num_entries, uint8_t tag, uint8_t* payload, uint8_t length) {
        Package->seq = seq;
        Package->num_entries = num_entries;
        Package->tag = tag;
        memcpy(Package->payload, payload, length);
    }

    void initShare() {
        uint16_t i = 0;
        uint8_t counter = 0;
        linkStateAdPkt_t lsa_pkt;
        uint16_t num_neighbors = call NeighborDiscovery.numNeighbors();
        uint32_t neighbors[num_neighbors];
        uint8_t max_entries = LSA_PKT_MAX_PAYLOAD_SIZE / sizeof(tuple_t);
        tuple_t info[max_entries];
        memcpy(neighbors, call NeighborDiscovery.neighbors(), num_neighbors * sizeof(uint32_t));

        for (; i < num_neighbors; i++) {
            if (max_entries - counter == 0) {
                makeLSAPack(&lsa_pkt, local_seq, counter, INIT, (uint8_t*)&info, max_entries * sizeof(tuple_t));
                call Flooding.flood(GLOBAL_SHARE, PROTOCOL_LINKSTATE, 30, (uint8_t *)&lsa_pkt, sizeof(linkStateAdPkt_t));
                counter = 0;
                n++;
            }
            info[counter].id = neighbors[i];
            info[counter].cost = call NeighborDiscovery.getLinkCost(neighbors[i]);
            counter++;
        }

        if (counter != 0) {
            makeLSAPack(&lsa_pkt, local_seq, counter, INIT, (uint8_t*)&info, counter * sizeof(tuple_t));
            call Flooding.flood(GLOBAL_SHARE, PROTOCOL_LINKSTATE, 30, (uint8_t *)&lsa_pkt, sizeof(linkStateAdPkt_t));
            n++;
        }

        init = TRUE;
    }

    command void LinkStateRouting.onBoot() {
        call ShareTimer.startOneShot(
            START_DELAY_LOWER + (call Random.rand32() % (START_DELAY_UPPER - START_DELAY_LOWER))
        );
    }

    command uint8_t LinkStateRouting.nextHop(uint8_t dest) {}

    command uint16_t LinkStateRouting.pathCost(uint8_t dest) {}

    command void LinkStateRouting.printRoutingTable() {}

    event void ShareTimer.fired() {
        initShare();
    }
    
    event void DijstraTimer.fired() {}

    event void Flooding.gotLSA(uint8_t* incomingMsg, uint8_t from) {
        uint8_t i = 0;
        linkStateAdPkt_t lsa_pkt;
        tuple_t entry[3];
        memcpy(&lsa_pkt, incomingMsg, sizeof(linkStateAdPkt_t));
        memcpy(&entry, lsa_pkt.payload, 3 * sizeof(tuple_t));
        n++;
        printf("Node %d get %d lsa's, tag = %d\n", TOS_NODE_ID, n, lsa_pkt.tag);
    }

    event void NeighborDiscovery.neighborChange(uint8_t id, uint8_t tag) {
        if (init) {
            linkStateAdPkt_t lsa_pkt;
            tuple_t info;
            info.id = id;
            info.cost = call NeighborDiscovery.getLinkCost(id);
            makeLSAPack(&lsa_pkt, local_seq, 1, tag, (uint8_t*)&info, sizeof(tuple_t));
            call Flooding.flood(GLOBAL_SHARE, PROTOCOL_LINKSTATE, 30, (uint8_t *)&lsa_pkt, sizeof(linkStateAdPkt_t));
        }
    }

    event void PacketHandler.getReliableAckPkt(uint8_t _) {}
    event void PacketHandler.getReliablePkt(pack* _) {}
    event void PacketHandler.gotNDPkt(uint8_t* _){}
    event void PacketHandler.gotFloodPkt(uint8_t* incomingMsg, uint8_t from){}
    event void PacketHandler.gotIpPkt(uint8_t* _){}
}