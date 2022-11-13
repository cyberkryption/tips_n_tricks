#!/bin/bash

echo -e "[+] Updating...\r\n"
sudo apt-get update 
sudo apt-get upgrade -y
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y 

echo -e "[+] Installing Docker...\r\n"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce
sudo systemctl status docker
sudo usermod -aG docker ${USER}
su - ${USER}

echo -e "[+] Appending .local/bin to path...\r\n"
cd
echo "export PATH=~/.local/bin:$PATH" >> .bashrc
echo "" >> .bashrc
echo "if [[ `id -gn` != "docker" ]]" >> .bashrc
ecoh "then" >> .bashrc
echo "    newgrp docker" >> .bashrc
echo "    exit" >> .bashrc
echo "fi" >> .bashrc
source .bashrc

echo -e "[+] Installing Exegol from sources...\r\n"
sudo apt-get install -y git python3 python3-pip
git clone https://github.com/ShutdownRepo/Exegol
cd Exegol
python3 -m pip install --user --requirement requirements.txt
sudo ln -s $(pwd)/exegol.py /usr/local/bin/exegol
exegol
