#include "../../includes/tcpPkt.h"
#include "../../includes/socket.h"
#include "../../includes/packet.h"
#include "../../includes/channels.h"

#define NULL_SOCKET 255
#define ATTEMPT_CONNECT 0

module TransportP {
    provides {
        interface Transport;
    }
    uses {
        interface IP;
        interface Hashmap<socket_t> as SocketTable; // (dest, fd)
        interface List<uint8_t> as FDQueue;
        interface List<uint8_t> as CloseQueue;
        interface List<uint8_t> as AcceptSockets;
    }
}

implementation {
    socket_t global_fd;
    socket_store_t socketArray[MAX_NUM_OF_SOCKETS]; // index 0 is used as a global socket (only on server side)
    bool socketInUse[MAX_NUM_OF_SOCKETS];
    uint8_t socket_num = 0;

    void makeTCPPkt(tcpPkt_t* Package, socket_addr_t src, socket_addr_t dest, uint8_t seq, uint8_t ack_num, uint8_t flag, uint8_t ad_window, uint8_t* payload, uint16_t length);

    void receiveSYN(tcpPkt_t* payload, uint8_t from);

    void receiveSYNACK(tcpPkt_t* payload, uint8_t from);

    void receiveACK(tcpPkt_t* payload, uint8_t from);

    void receiveDATA(tcpPkt_t* payload, uint8_t from);

    void receiveFIN(tcpPkt_t* payload, uint8_t from);

    command void Transport.onBoot() {
        uint8_t i = 10;
        for (; i > 0; i--) {
            call FDQueue.pushback(i - 1);
            socketArray[i - 1].state = CLOSED;
            socketInUse[i - 1] = FALSE;
        }
    }

    command error_t Transport.initServer(uint8_t port) {
        socket_t fd = call Transport.socket();
        socket_addr_t src_addr;

        if (fd == NULL_SOCKET) {
            dbg(TRANSPORT_CHANNEL, "No available socket\n");
            return FAIL;
        }

        src_addr.addr = TOS_NODE_ID;
        src_addr.port = port;
        
        if (call Transport.bind(fd, &src_addr) == SUCCESS && call Transport.listen(fd) == SUCCESS) {
            global_fd = fd;
            printf("BINDING SUCCESS\n");
            return SUCCESS;
        }

        return FAIL;
    }

    command error_t Transport.initClientAndConnect(uint8_t dest, uint8_t srcPort, uint8_t destPort, uint16_t transfer) {
        socket_t fd = call Transport.socket();
        socket_addr_t src_addr;
        socket_addr_t dest_addr;

        if (fd == NULL_SOCKET) {
            dbg(TRANSPORT_CHANNEL, "No available socket\n");
            return FAIL;
        }

        src_addr.addr = TOS_NODE_ID;
        src_addr.port = srcPort;
        
        if (call Transport.bind(fd, &src_addr) == SUCCESS) {
            dest_addr.addr = dest;
            dest_addr.port = destPort;
            if (call Transport.connect(fd, &dest_addr) == SUCCESS) {
                call SocketTable.insert(dest, fd);
                printf("BINDING SUCCESS\n");
                return SUCCESS;
            } else {
                return FAIL;
            }
        }

        return FAIL;
    }

    command socket_t Transport.socket() {
        socket_t fd;
        if (call FDQueue.size() == 0) {
            fd = NULL_SOCKET;
        } else {
            fd = call FDQueue.popback();
        }
        return fd;
    }

    command error_t Transport.bind(socket_t fd, socket_addr_t *addr) {
        if (socketInUse[fd] == TRUE) {
            dbg(TRANSPORT_CHANNEL, "File descriptor id {%d} is already in-use\n", fd);
            return FAIL;
        } else {
            memcpy(&socketArray[fd].src, addr, sizeof(socket_addr_t));
            socketInUse[fd] = TRUE;
            return SUCCESS;
        }
    }

    command socket_t Transport.accept(socket_t fd) {

    }

    command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen) {}

    command error_t Transport.receive(pack* package) {}

    command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen) {}

    command error_t Transport.connect(socket_t fd, socket_addr_t* addr) {
        tcpPkt_t tcp_pkt;
        char payload[1] = " ";
        if (socketArray[fd].state == CLOSED) {
            memcpy(&socketArray[fd].dest, addr, sizeof(socket_addr_t));
            socketArray[fd].state = SYN_SENT;
            makeTCPPkt(&tcp_pkt, socketArray[fd].src, socketArray[fd].dest, 0, ATTEMPT_CONNECT, SYN, SOCKET_BUFFER_SIZE, (uint8_t*)&payload, 1);
            call IP.send(addr->addr, PROTOCOL_TCP, 50, (uint8_t*)&tcp_pkt, TCP_HEADER_LENDTH);
            return SUCCESS;
        }
        return FAIL;
    }
    
    command error_t Transport.close(socket_t fd) {}

    command error_t Transport.release(socket_t fd) {}

    command error_t Transport.listen(socket_t fd) {
        if (socketArray[fd].state == CLOSED) {
            socketArray[fd].state = LISTEN;
            return SUCCESS;
        }
        return FAIL;
    }

    void receiveSYN(tcpPkt_t* payload, uint8_t from) {}

    void receiveSYNACK(tcpPkt_t* payload, uint8_t from) {}

    void receiveACK(tcpPkt_t* payload, uint8_t from) {}

    void receiveDATA(tcpPkt_t* payload, uint8_t from) {}

    void receiveFIN(tcpPkt_t* payload, uint8_t from) {}

    void makeTCPPkt(tcpPkt_t* Package, socket_addr_t src, socket_addr_t dest, uint8_t seq, uint8_t ack_num, uint8_t flag, uint8_t ad_window, uint8_t* payload, uint16_t length) {
        Package->srcPort = src.port;
        Package->destPort = dest.port;
        Package->seq = seq;
        Package->ack_num = ack_num;
        Package->flag = flag;
        Package->ad_window = ad_window;
        memcpy(Package->payload, payload, length);
    }

    event void IP.gotTCP(uint8_t* incomingMsg, uint8_t from) {
        tcpPkt_t tcp_pkt;
        memcpy(&tcp_pkt, incomingMsg, sizeof(tcpPkt_t));
        // logTCPPkt(&tcp_pkt);
        switch(tcp_pkt.flag) {
            case SYN:
                if (tcp_pkt.ack_num == ATTEMPT_CONNECT) {
                    dbg(TRANSPORT_CHANNEL, "Port %d of Node %d receive { SYN } from Port %d of Node %d\n", tcp_pkt.destPort, TOS_NODE_ID, tcp_pkt.srcPort, from);
                    receiveSYN(&tcp_pkt, from);
                } else {
                    dbg(TRANSPORT_CHANNEL, "Port %d of Node %d receive { SYN + ACK } from Port %d of Node %d\n", tcp_pkt.destPort, TOS_NODE_ID,tcp_pkt.srcPort, from);
                    receiveSYNACK(&tcp_pkt, from);
                }
                break;
            case ACK:
                dbg(TRANSPORT_CHANNEL, "Port %d of Node %d receive { ACK } from Port %d of Node %d\n", tcp_pkt.destPort, TOS_NODE_ID, tcp_pkt.srcPort, from);
                receiveACK(&tcp_pkt, from);
                break;
            case FIN:
                dbg(TRANSPORT_CHANNEL, "Port %d of Node %d receive { FIN } from Port %d of Node %d\n", tcp_pkt.destPort, TOS_NODE_ID, tcp_pkt.srcPort, from);
                receiveFIN(&tcp_pkt, from);
                break;
            default:
                receiveDATA(&tcp_pkt, from);
                break;
        }
    }
}