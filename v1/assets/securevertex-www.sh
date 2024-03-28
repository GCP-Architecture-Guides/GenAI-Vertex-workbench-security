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
sudo a2ensite default-ssl
sudo a2enmod ssl
echo "Page served from securevertex webserver" | sudo tee /var/www/html/index.html
sudo systemctl restart apache2
