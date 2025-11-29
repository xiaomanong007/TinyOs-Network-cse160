#ifndef TCP_PKT_H
#define TCP_PKT_H

#include "ipPkt.h"

enum{
	TCP_HEADER_LENDTH = 8,
    MAX_TCP_PAYLOAD_SIZE = MAX_IP_PAYLOAD_SIZE - TCP_HEADER_LENDTH,

    DATA = 0,
    SYN = 1,
    ACK = 2,
    FIN = 3,
};

typedef struct tcpPkt{
    uint8_t srcPort;
    uint8_t destPort;
    uint8_t seq;
    uint8_t ack_num;
    uint8_t flag;
    uint8_t ad_window;
    uint8_t payload[MAX_TCP_PAYLOAD_SIZE];
}tcpPkt_t;


void logTCPPkt(tcpPkt_t *input){
	dbg(TRANSPORT_CHANNEL, "srcPort: %hhu destPort: %hhu seq:%hhu ack_num:%hhu flag:%hhu ad_window:%hhu Payload: %s\n",
	input->srcPort, input->destPort, input->seq, input->ack_num, input->flag, input->ad_window, input->payload);
}

#endif