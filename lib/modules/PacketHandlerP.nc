#include "../../includes/packet.h"
#include "../../includes/neighborDiscoveryPkt.h"
#include "../../includes/floodingPkt.h"
#include "../../includes/protocol.h"

module PacketHandlerP{
    provides interface PacketHandler;
}


implementation{
    pack pkt;

    command void PacketHandler.handle(pack* incomingMsg){
        uint8_t* payload = (uint8_t*) incomingMsg->payload;

        switch(incomingMsg->protocol){
            case PROTOCOL_NEIGHBOR_DISCOVERY:
                signal PacketHandler.gotNDPkt(payload);
                break;
            case PROTOCOL_FLOODING:
                signal PacketHandler.gotFloodPkt(payload, incomingMsg->src);
                break;
            case PROTOCOL_IP:
                signal PacketHandler.gotIpPkt(payload);
                break;
            default:
                dbg(GENERAL_CHANNEL,"Unknown protocol %d from node %d to node %d, dropping packet.\n",
                incomingMsg->protocol, incomingMsg->src, incomingMsg->dest);
                break;
        }  
    }
}