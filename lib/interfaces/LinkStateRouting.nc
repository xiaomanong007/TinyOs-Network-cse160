interface LinkStateRouting {
    command void onBoot();
    command uint8_t nextHop(uint8_t dest);
    command uint16_t pathCost(uint8_t dest);
    command void printRoutingTable();
}