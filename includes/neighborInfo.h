#ifndef NEIGHBOR_INFO_H
#define NEIGHBOR_INFO_H

typedef struct neighborInfo{
    uint16_t last_seq;
    uint16_t link_quality; // link quality should be between 0 to 1, 
                            // but since uint16_t is used, values are mutiplied by 1000
}neighborInfo_t;

#endif