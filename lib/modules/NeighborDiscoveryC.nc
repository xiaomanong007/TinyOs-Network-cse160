configuration NeighborDiscoveryC {
   provides interface NeighborDiscovery;
}

implementation {
    components NeighborDiscoveryP;
    NeighborDiscovery = NeighborDiscoveryP;

    components new SimpleSendC(AM_PACK);
    NeighborDiscoveryP.SimpleSend -> SimpleSendC;

    components new TimerMilliC() as discoverTimer;
    components new TimerMilliC() as notifyTimer;
    components RandomC as Random;
    NeighborDiscoveryP.discoverTimer -> discoverTimer;
    NeighborDiscoveryP.notifyTimer -> notifyTimer;
    NeighborDiscoveryP.Random -> Random;

    components PacketHandlerC;
    NeighborDiscoveryP.PacketHandler -> PacketHandlerC;

    components new HashmapC(neighborInfo_t, 30);
    NeighborDiscoveryP.NeighborTable -> HashmapC;
}