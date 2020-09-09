####################################
# Install docker (latest version)
sudo apt update
sudo apt install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

# Install a specific version of docker
# docker release URL: https://docs.docker.com/engine/release-notes/
# -----------------
# sudo apt-get install docker-ce=<version> docker-ce-cli=<version> containerd.io


####################################
# Install docker-compose
VERSION=1.27.0
sudo curl -L "https://github.com/docker/compose/releases/download/$VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


####################################
# Add the current user to the docker group
sudo usermod -aG docker `whoami`