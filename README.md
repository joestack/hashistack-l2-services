# hashistack-l2-services

Once we have access to the Layer 1 Platforms (Consul and Vault), we need to setup and configure the necessary Platform-Services for the final workload.

Waterfall Model:   
-> 1st Platform  
--> 2nd **Platform-Service**  
---> 3rd Workload

This repo provides the Vault Secrets backend for Consul that can be used by a specific workload to retrieve a Consul ACL token that is used to register the workload node and services on the Consul Control Plane.