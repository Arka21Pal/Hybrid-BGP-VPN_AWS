# Creating a Hybrid BGP VPN on AWS
*Please let me know if my scripts break. I will attempt to fix them as long as there are no significant changes "upstream"*.

This project is based off of Adrian Cantrill's wonderful lab on creating a Hybrid IPSEC VPN on redundant BGP tunnels. Most of the work in this project has been to automate the work that would have to be done by hand otherwise.

Link: https://github.com/acantril/learn-cantrill-io-labs/tree/master/aws-hybrid-bgpvpn

There are some quirks with this automation setup that I will mention first:
1. TGW VPN attachments aren't invoked as attachments on the `aws cli` application. Instead, they are considered VPN connections which are then attached to the TGW endpoint in the Cloudformation template.
2. There might be an issue where `vtysh -c show ip route` on any of the "on-premises routers" might not yield a BGP route. This does not happen every time and cannot be replicated reliably. Also, the static kernel path shows up every time, as a result of which one could ping both servers (which are in a separate VPC - [refer to picture](https://raw.githubusercontent.com/acantril/learn-cantrill-io-labs/master/aws-hybrid-bgpvpn/02_INSTRUCTIONS/STAGE4%20-%20FINAL%20BGP%20Architecture.png)) from the on-premises routers.
3. The commands take time to run. To configure FFRouting on the on-premises routers can take anywhere from 15-20 minutes. Do not shutdown/interrupt their progress during this time or the routing protocol might break during installation.

The command to run the project is (from `/bin`): 
```
./ADVANCEDVPNDEMO.sh -d && ./CGWTGWAttach.sh -d && ./CONFIGURATION_IPSEC_BGP.sh
```
The `-d` flag signifies "deploy". This command deploys the "ADVANCEDVPNDEMO" template, then the "CGWTGWAttach" template, and then configures the on-prem routers from commands in `CONFIGURATION_IPSEC_BGP.sh`.

After the configuration is complete (to check, go into ON-PREM ROUTER1 or ON-PREM ROUTER 2) and check the last reboot timestamp with `last reboot`. If it has already rebooted once, type `vtysh -c 'show ip route'` to check if the BGP routes are up. Do not forget to substitute the variables "region" and "profile" in the cloudformation templates with your own values.

`draft.sh` is an empty template which I used for the two other shell scripts for deployment.

To destroy all online (available) resources, I use
```
i=0; while [ $i -le 25 ]; do ./../CGWTGWAttach.sh -D && ./../ADVANCEDVPNDEMO.sh -D; printf "%s\n" "round ${i}"; i=$(( i + 1 )); sleep 5; done
```
I have to do this because the stack `ADVANCEDVPNDEMO` won't delete itself until the stack `CGWTGWAttach` has been completely deleted.
