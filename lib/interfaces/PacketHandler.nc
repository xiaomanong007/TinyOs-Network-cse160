interface PacketHandler{
    command void handle(pack* msg);
    
    event void gotNDPkt(uint8_t* incomingMsg);
    event void gotFloodPkt(uint8_t* incomingMsg, uint8_t from);
    event void gotIpPkt(uint8_t* incomingMsg);
}