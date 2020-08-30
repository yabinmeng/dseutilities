#! /bin/bash

# MongoDB version
MAJ_VER=4.2
MIN_VER=9
VERSION="$MAJ_VER"".""$MIN_VER"

# MongoDB RS name
RS_NAME=rs0

# MongoDB data directory home
DB_DATA_HOMEDIR=/opt/mongo_db_data

# MongoDB example data directory
EXMP_DATA_HOMEDIR=/opt/mongo_example_data

# MongoDB user and group
MONGO_DB_USER=mongodb
MONGO_DB_GRP=mongodb

# Current host instance IP
HOST_IP=$(hostname -i)

clear

#--------------------------------------------
echo "1. Install MongoDB binary if not done already."
WHICH_MONGO=$(which mongo)

if [[ -z "$WHICH_MONGO" ]]; then
  wget -qO - https://www.mongodb.org/static/pgp/server-$MAJ_VER.asc | sudo apt-key add -
  echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/$MAJ_VER multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-$MAJ_VER.list
    sudo apt update
    sudo apt install -y \
      mongodb-org=$VERSION \
      mongodb-org-server=$VERSION \
      mongodb-org-shell=$VERSION \
      mongodb-org-mongos=$VERSION \
      mongodb-org-tools=$VERSION \
      tree
else
  echo "   ... MongoDB is already installed."
fi
echo

#--------------------------------------------
echo "2. If needed, download example data and put it in example folder."
if [[ ! -f "$EXMP_DATA_HOMEDIR/mongodb_cases.json" ]]; then
  sudo mkdir -p "$EXMP_DATA_HOMEDIR"
  sudo wget https://community.jaspersoft.com/sites/default/files/wiki_attachments/mongodb_cases.json
  sudo mv mongodb_cases.json $EXMP_DATA_HOMEDIR
  sudo chown -R $MONGO_DB_USER:$MONGO_DB_GRP "$EXMP_DATA_HOMEDIR"
fi
if [[ ! -f "$EXMP_DATA_HOMEDIR/restaurants.json" ]]; then
  sudo wget https://raw.githubusercontent.com/mongodb/docs-assets/drivers/restaurants.json
  sudo mv restaurants.json $EXMP_DATA_HOMEDIR
fi
echo "   ... done."
echo

#--------------------------------------------
echo "3. If needed, create folder structures for holding DB data of 3 replica sets."
if [[ ! -d "$DB_DATA_HOMEDIR/$RS_NAME""-0" ]]; then
  sudo mkdir -p "$DB_DATA_HOMEDIR/$RS_NAME""-0"
fi
if [[ ! -d "$DB_DATA_HOMEDIR/$RS_NAME""-1" ]]; then
  sudo mkdir -p "$DB_DATA_HOMEDIR/$RS_NAME""-1"
fi
if [[ ! -d "$DB_DATA_HOMEDIR/$RS_NAME""-2" ]]; then
  sudo mkdir -p "$DB_DATA_HOMEDIR/$RS_NAME""-2"
fi
sudo chown -R $MONGO_DB_USER:$MONGO_DB_GRP "$DB_DATA_HOMEDIR"
echo "   ... done."
echo

#--------------------------------------------
echo "4. Start MongoDB Replica Set on the same host if not started."
echo "   >>> first member (port 27017)"
PORT_OPEN=$(sudo netstat -ntlp | grep 27017)
if [[ -z "$PORT_OPEN" ]]; then
  sudo -u $MONGO_DB_USER mongod --replSet rs0 --port 27017 \
                                --bind_ip localhost,"$HOST_IP" \
                                --dbpath "$DB_DATA_HOMEDIR/$RS_NAME""-0" \
                                --oplogSize 128 > "$RS_NAME""-0".cmd.log 2>&1 &
  echo "       ... done."
else
  echo "       ... port 27017 is already open."
fi

echo "   >>> second member (port 27018)"
PORT_OPEN=$(sudo netstat -ntlp | grep 27018)
if [[ -z "$PORT_OPEN" ]]; then
  sudo -u $MONGO_DB_USER mongod --replSet rs0 --port 27018 \
                                --bind_ip localhost,"$HOST_IP" \
                                --dbpath "$DB_DATA_HOMEDIR/$RS_NAME""-1" \
                                --oplogSize 128 > "$RS_NAME""-1".cmd.log 2>&1 &
  echo "       ... done."
else
  echo "       ... port 27018 is already open."
fi

echo "   >>> third member (port 27019)"
PORT_OPEN=$(sudo netstat -ntlp | grep 27019)
if [[ -z "$PORT_OPEN" ]]; then
  sudo -u $MONGO_DB_USER mongod --replSet rs0 --port 27019 \
                                --bind_ip localhost,"$HOST_IP" \
                                --dbpath "$DB_DATA_HOMEDIR/$RS_NAME""-2" \
                                --oplogSize 128 > "$RS_NAME""-2".cmd.log 2>&1 &
  echo "       ... done."
else
  echo "       ... port 27019 is already open."
fi

sleep 1

#--------------------------------------------
echo "5. Initialize replica set."
rsconf="{
  _id: '$RS_NAME',
  members: [
    { _id: 0, host: '$HOST_IP:27017' },
    { _id: 1, host: '$HOST_IP:27018' },
    { _id: 2, host: '$HOST_IP:27019' }
   ]
}"
sudo -u $MONGO_DB_USER mongo "$HOST_IP":27017 --eval "JSON.stringify(db.adminCommand({'replSetInitiate' : $rsconf}))"
