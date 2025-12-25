# Cloud Networking & Traffic Orchestration

## Overview
This document describes the networking architecture implemented to expose the Microservices Platform to the public internet. The goal was to move beyond basic port-forwarding to a production-grade **Ingress-based architecture** that supports name-based virtual hosting and Layer 7 routing.



## 1. Networking Components
- **Kubernetes Services (ClusterIP):** Internal-only stable endpoints used for service-to-service communication (e.g., `Frontend` talking to `CurrencyService`).
- **Nginx Ingress Controller:** Acting as the "Reverse Proxy" and "Load Balancer" at the edge of the cluster.
- **Ingress Resources:** Defined rules that map external DNS names (`shop.local`) to specific internal services.
- **Local DNS Mapping:** Configured via the `/etc/hosts` file to simulate real-world domain resolution to the Minikube IP.

## 2. Traffic Flow Architecture
I designed the flow to follow a secure, centralized entry-point model:
1. **Request:** A user visits `http://shop.local`.
2. **DNS Resolution:** The request is routed to the **Ingress Controller's** IP address.
3. **Layer 7 Routing:** The Nginx Controller inspects the "Host" header. Based on the rules defined in `shop-ingress.yaml`, it identifies that the traffic belongs to the `frontend-external` service.
4. **Load Balancing:** The Service distributes the traffic across the active **Pod Replicas** using a round-robin strategy.

## 3. Configuration Highlights (Ingress Rulebook)
By using an Ingress Controller, I was able to manage multiple microservices behind a single entry point, reducing cost and management complexity.

```yaml
spec:
  rules:
  - host: shop.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-external
            port:
              number: 80