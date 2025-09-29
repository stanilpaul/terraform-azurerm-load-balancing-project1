# Load Balancing

This module simulate a module would be created by the SRE/Infrastrucutre team for this architecture.
In this module, we will use to create 2 load balancers, with public ip and health prob for port 80

This is a very easy architecture but we will try to simulate real time IT team working and collaboration with good practice.

- In the testing ENV I open the port 22 in load balancer externe
- Now in the Production ENV, I commented that bloc but added a `BASTION` .