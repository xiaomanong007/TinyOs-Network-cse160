#ifndef LINK_STATE_AD_PKT_H
#define LINK_STATE_AD_PKT_H

#include "floodingPkt.h"

enum {
    LSA_PKT_HEADER_LENGTH = 3,
	LSA_PKT_MAX_PAYLOAD_SIZE = FLOOD_PKT_MAX_PAYLOAD_SIZE - LSA_PKT_HEADER_LENGTH,
};

typedef struct linkStateAdPkt{
    uint8_t seq;
    uint8_t num_entries;
    uint8_t tag;
    uint8_t payload[0];
}linkStateAdPkt_t;

typedef struct tuple{
    uint8_t id;
    uint16_t cost;
}tuple_t;

#endif