configuration LinkStateRoutingC {
    provides interface LinkStateRouting;
}

implementation {
    components LinkStateRoutingP;
    LinkStateRouting = LinkStateRoutingP;
    
    components PacketHandlerC;
    LinkStateRoutingP.PacketHandler -> PacketHandlerC;
    
    components FloodingC;
    LinkStateRoutingP.Flooding -> FloodingC;

    components NeighborDiscoveryC;
    LinkStateRoutingP.NeighborDiscovery -> NeighborDiscoveryC;

    components new TimerMilliC() as ShareTimer;
    components RandomC as Random;

    LinkStateRoutingP.ShareTimer -> ShareTimer;
    LinkStateRoutingP.Random -> Random;

    components new TimerMilliC() as DijstraTimer;
    LinkStateRoutingP.DijstraTimer -> DijstraTimer;
}