#! /bin/bash

PKG_HOME_DIR=/opt/packages

sudo mkdir -p $PKG_HOME_DIR
sudo mv ~/*.tar.gz $PKG_HOME_DIR

cd $PKG_HOME_DIR

# prepare DSE packages
for GZFILE in $(ls dse*.tar.gz); do
   PKG_NAME=$(echo $GZFILE | awk -F'-' '{print $1}')
   VER_NAME=$(echo $GZFILE | awk -F'-' '{print $2}')
   VER_NAME2=${VER_NAME//./}

   PKG_SUBDIR="$PKG_NAME""-""$VER_NAME"
   LINK_NAME="/opt/dse$VER_NAME2"

   if [[ ! -d $PKG_HOME_DIR/$PKG_SUBDIR ]]; then
      sudo tar -xzvf $GZFILE
   fi

   if [[ ! -f $LINK_NAME ]]; then
      sudo ln -s $PKG_HOME_DIR/$PKG_SUBDIR $LINK_NAME
   fi
done

# prepare opscenter packages
for GZFILE in $(ls opsc*.tar.gz); do
   PKG_NAME=$(echo $GZFILE | awk -F'-' '{print $1}')
   VER_NAME=$(echo $GZFILE | awk -F'-' '{print $2}' | awk -F".tar" '{print $1}')
   VER_NAME2=${VER_NAME//./}

   PKG_SUBDIR="$PKG_NAME""-""$VER_NAME"
   LINK_NAME="/opt/opsc$VER_NAME2"

   if [[ ! -d $PKG_HOME_DIR/$PKG_SUBDIR ]]; then
      sudo tar -xzvf $GZFILE
   fi

   if [[ ! -f $LINK_NAME ]]; then
      sudo ln -s $PKG_HOME_DIR/$PKG_SUBDIR $LINK_NAME
   fi
done

# prepare datastax-agent packages
for GZFILE in $(ls datastax*.tar.gz); do
   PKG_NAME=$(echo $GZFILE | awk -F'-' '{print $1 "-" $2}')
   VER_NAME=$(echo $GZFILE | awk -F'-' '{print $3}' | awk -F".tar" '{print $1}')
   VER_NAME2=${VER_NAME//./}

   PKG_SUBDIR="$PKG_NAME""-""$VER_NAME"
   LINK_NAME="/opt/dxagt$VER_NAME2"

   if [[ ! -d $PKG_HOME_DIR/$PKG_SUBDIR ]]; then
      sudo tar -xzvf $GZFILE
   fi

   if [[ ! -f $LINK_NAME ]]; then
      sudo ln -s $PKG_HOME_DIR/$PKG_SUBDIR $LINK_NAME
   fi
done

sudo chown -R cassandra:cassandra /opt/*
