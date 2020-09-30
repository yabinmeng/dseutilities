#! /bin/bash

# HashiCorp Vault version
VERSION="1.5.4"
VAULT_BIN_FILENAME="vault_$VERSION""_linux_amd64.zip"
VAULT_BIN_SRC_DWONLOAD_URL="https://releases.hashicorp.com/vault/$VERSION/$VAULT_BIN_FILENAME"

# Node IP
NODE_IP=$(hostname -i)

# Kafka folders
VAULT_HOMEDIR=/opt/hashi_vault
VAULT_BINDIR=$VAULT_HOMEDIR/bin
VAULT_DATADIR=$VAULT_HOMEDIR/data

#--------------------------------------------
echo "1. Create \"vault\" user and group"
VAULT_SRV_USER="vault"

USER_EXIST=$(id $VAULT_SRV_USER)
if [[ "$USER_EXIST" =~ "no such user" ]]; then
    sudo useradd $VAULT_SRV_USER
fi
echo

#--------------------------------------------
echo "2. Download Vault version $VERSION and extract it to \"$VAULT_HOMEDIR\" folder"

UNZIP_EXIST=$(which unzip)
if [[ "$UNZIP_EXIST" == "" ]]; then
    sudo apt update
    sudo apt install -y unzip
fi

CURL_EXIST=$(which curl)
if [[ "$CURL_EXIST" == "" ]]; then
    sudo apt install -y curl
fi

SCREEN_EXISTS=$(which screen)
if [[ "$SCREEN_EXISTS" == "" ]]; then
    sudo apt install -y screen
fi

if [[ ! -d "$VAULT_HOMEDIR" ]]; then
  sudo mkdir -p $VAULT_HOMEDIR
  sudo mkdir -p $VAULT_BINDIR
  sudo mkdir -p $VAULT_DATADIR
fi

if [[ ! -f "/tmp/$VAULT_BIN_FILENAME" ]]; then
  wget "$VAULT_BIN_SRC_DWONLOAD_URL" -P /tmp
fi

if [[ ! -f "$VAULT_BINDIR/vault" ]]; then
    unzip -o /tmp/$VAULT_BIN_FILENAME -d /tmp
    sudo mv /tmp/vault $VAULT_BINDIR
fi

echo

#--------------------------------------------
echo "3. Create a customized Vault configuration file"
VAULT_CFG_FILE=myvault.cfg

cat << EOF | sudo tee $VAULT_HOMEDIR/$VAULT_CFG_FILE > /dev/null
listener "tcp" {
    address = "$NODE_IP:8200"
    tls_disable = 1
}


storage "file" {
    path = "$VAULT_DATADIR"
}

api_addr = "http://$NODE_IP:8200"
EOF

cat << EOF | sudo tee $VAULT_BINDIR/startVault.sh > /dev/null
#! /bin/bash
$VAULT_BINDIR/vault server -config $VAULT_HOMEDIR/$VAULT_CFG_FILE
EOF

sudo chown -R $VAULT_SRV_USER:$VAULT_SRV_USER $VAULT_HOMEDIR
sudo chmod -R 775 $VAULT_DATADIR
sudo chmod 755 $VAULT_BINDIR/startVault.sh

echo

#--------------------------------------------
echo "4. Start Vault server"
export PATH=$PATH:$VAULT_BINDIR
export VAULT_ADDR="http://$NODE_IP:8200"

screen -dmS vault_srv $VAULT_BINDIR/startVault.sh

echo

#--------------------------------------------
echo "5. Add  the current user to Vault user group (make sure to relogin)"
sudo usermod -aG $VAULT_SRV_USER `whoami`

echo