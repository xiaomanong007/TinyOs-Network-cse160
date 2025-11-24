generic configuration GraphC(int n){
   provides interface Graph;
}

implementation{
    components new GraphP(n);
    Graph = GraphP;
}