#! /bin/bash

clear

# Kafka version
VERSION="2.6.0"

# Node IP
NODE_IP=$(hostname -i)

# Kafka binary source
KAFKA_BIN_SRC=kafka_2.13-2.6.0.tgz

# Kafka folders
KAFKA_HOMEDIR=/opt/kafka
KAFKA_DATA_DIR=$KAFKA_HOMEDIR/data/kafka-logs
ZOOKEEPER_DATA_DIR=$KAFKA_HOMEDIR/data/zookeeper

KD_REP_STR=${KAFKA_DATA_DIR//\//\\/}
ZK_REP_STR=${ZOOKEEPER_DATA_DIR//\//\\/}
#echo $KD_REP_STR
#echo $ZK_REP_STR

#--------------------------------------------
echo "1. Create \"kafka\" user and group"
sudo useradd kafka
echo

#--------------------------------------------
echo "2. Download kafka version $VERSION and extract it to \"/opt/kafka\" folder"

if [[ ! -f "/tmp/$KAFKA_BIN_SRC" ]]; then
  wget "http://apache.mirrors.pair.com/kafka/2.6.0/$KAFKA_BIN_SRC" -P /tmp
fi

if [[ ! -d "$KAFKA_HOMEDIR" ]]; then
  sudo mkdir -p $KAFKA_HOMEDIR
  sudo mkdir -p $KAFKA_DATA_DIR
  sudo mkdir -p $ZOOKEEPER_DATA_DIR
fi

if [[ ! -d "$KAFKA_HOMEDIR/bin" ]]; then
  sudo tar -zxvf "/tmp/$KAFKA_BIN_SRC" -C $KAFKA_HOMEDIR --strip-components=1
fi

sudo chown -R kafka:kafka $KAFKA_HOMEDIR

echo

#--------------------------------------------
echo "3. Customize Kafka and zookeeper data directories. Modify Kafka listener properties"
sudo sed -i "s/^dataDir=.*/dataDir=$ZK_REP_STR/" $KAFKA_HOMEDIR/config/zookeeper.properties
sudo sed -i "s/^#listeners=.*/listeners=PLAINTEXT\:\/\/$NODE_IP\:9092/" $KAFKA_HOMEDIR/config/server.properties
sudo sed -i "s/^#advertised\.listeners=.*/advertised\.listeners=PLAINTEXT\:\/\/$NODE_IP\:9092/" $KAFKA_HOMEDIR/config/server.properties

#- append a line "advertised.host.name = $NODE_IP" in the file only if doesn't exist
grep -qxF "advertised.host.name = $NODE_IP" $KAFKA_HOMEDIR/config/server.properties || \
  echo "advertised.host.name = $NODE_IP" | sudo tee -a  $KAFKA_HOMEDIR/config/server.properties > /dev/null

echo

#--------------------------------------------
echo "4. Set up Zookeeper and Kafka systemd unit files"
echo "   (reference: https://tecadmin.net/install-apache-kafka-ubuntu/)"
cat << EOF | sudo tee /etc/systemd/system/zookeeper.service > /dev/null
[Unit]
Description=Apache Zookeeper server
Documentation=http://zookeeper.apache.org
Requires=network.target remote-fs.target
After=network.target remote-fs.target

[Service]
Type=simple
User=kafka
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

cat << EOF | sudo tee /etc/systemd/system/kafka.service > /dev/null
[Unit]
Description=Apache Kafka Server
Documentation=http://kafka.apache.org/documentation.html
Requires=zookeeper.service

[Service]
Type=simple
User=kafka
Environment="JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64"
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
echo

#--------------------------------------------
echo "5. Start Zookeeper and Kafka servers"
sudo systemctl start zookeeper
sudo systemctl start kafka

CMDSTR="$KAFKA_HOMEDIR/bin/kafka-topics.sh --version"
KAFKA_VER=$(eval "$CMDSTR")
echo "   >> kafka version: $KAFKA_VER"
echo

#--------------------------------------------
echo "6. Modify PATH environment variable"
echo "   >>> MAKE SURE to pick up PATH environment change using \"source\" command or to relogin the current user"
PROFILE_PATH_STR="\$HOME/bin:\$HOME/.local/bin:\$PATH"
PROFILE_PATH_REP_STR=${PROFILE_PATH_STR//\//\\/}
sudo sed -i "s/^PATH=.*/PATH=$PROFILE_PATH_REP_STR\:$KB_REP_STR/" $HOME/.profile
echo

#--------------------------------------------
echo "7. Add the current user to \"kafka\" group"
echo "   >>> MAKE SURE to relogin the current user"
sudo usermod -aG kafka $(whoami)


#########
# Start Kafka Producer:
#    kafka-console-producer.sh --broker-list $(hostname -i):9092 --topic testTopic
#
# Start Kafka Consumer:
#    kafka-console-consumer.sh --bootstrap-server $(hostname -i):9092 --topic testTopic --from-beginning
