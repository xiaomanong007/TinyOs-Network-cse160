# Network Stack Simulation

## Overview

This project (adapted from CSE160: Computer Network) implements a layered network stack in a simulated sensor-network environment using TinyOS. The objective is to design and evaluate core networking abstractions under constrained conditions, with emphasis on correctness, modularity, and protocol interaction.

The system models communication across multiple nodes and implements functionality across the link, network, and transport layers. Particular attention is given to routing convergence, reliability mechanisms, congestion behavior, and distributed state management.

---

## Architecture

The stack follows a layered structure:

Application  
↓  
Transport Layer  
↓  
Network Layer  
↓  
Link Layer  

Each layer is implemented as a modular component with clearly defined interfaces. Communication between layers is event-driven, reflecting TinyOS’s split-phase programming model.

---

## Implemented Components

### 1. Neighbor Discovery

- Periodic HELLO broadcasts  
- EWMA-based link-quality estimation  
- Timeout-based neighbor expiration  
- Dynamic neighbor table maintenance  

### 2. Flooding

- Controlled broadcast propagation  
- Duplicate suppression via sequence tracking  
- TTL handling  

### 3. Link-State Routing

- Periodic dissemination of link-state advertisements (LSAs)  
- Global topology reconstruction  
- Dijkstra-based shortest-path computation  
- Routing table generation  

### 4. Network Layer (IP)

- Packet encapsulation and decapsulation  
- Fragmentation and reassembly  
- Forwarding logic based on routing table  

### 5. Transport Protocol

- Connection establishment and teardown  
- Sliding window mechanism  
- Congestion window management  
- Retransmission timers  
- ACK handling and loss recovery  

---

## Design Principles

- Deterministic state transitions  
- Explicit timer management  
- Separation of control and data logic  
- Defensive handling of packet duplication and reordering  
- Minimal shared mutable state  

The implementation emphasizes reasoning about distributed state evolution rather than relying on implicit behavior.

---

## Simulation Environment

- TinyOS-based multi-node simulation  
- Event-driven execution model  
- Structured debug logging  
- Timer-driven protocol scheduling  

The system has been evaluated under varying node counts and message loads to observe:

- Routing convergence behavior  
- Congestion window dynamics  
- Retransmission stability  
- Failure recovery characteristics  

---

## Future Work

- Adaptive congestion control refinement  
- Dynamic timer tuning strategies  
- Link-quality-driven routing cost optimization  
- Formal reasoning about safety and liveness properties  
- Performance benchmarking under adversarial network conditions  