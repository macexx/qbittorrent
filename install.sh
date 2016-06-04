#!/bin/bash

#########################################
##       ENVIRONMENTAL CONFIG          ##
#########################################


# Disable SSH
rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh


#########################################
##    REPOSITORIES AND DEPENDENCIES    ##
#########################################

# Repositories
echo 'deb http://archive.ubuntu.com/ubuntu trusty main universe restricted' > /etc/apt/sources.list
echo 'deb http://archive.ubuntu.com/ubuntu trusty-updates main universe restricted' >> /etc/apt/sources.list


# Install Dependencies
apt-get update -qq
apt-get install -qy wget libboost-system1.54.0 libboost-chrono1.54.0 libboost-random1.54.0 libqt5network5 libqt5xml5 libgeoip1

#########################################
## FILES, SERVICES AND CONFIGURATION   ##
#########################################

# Initiate config directory
mkdir -p /default /config /downloads /watched


# Config user permissions
cat <<'EOT' > /etc/my_init.d/05_user.sh
#!/bin/bash
AUSER=${AUSER:-65534}
AGROUP=${AGROUP:-100}
echo "Setting user permissions to match host"
if [ ! "$(id -u nobody)" -eq "$AUSER" ]; then
  usermod -o -u "$AUSER" nobody
fi
if [ ! "$(getent group users | cut -d: -f3)" -eq "$AGROUP" ]; then
  groupmod -g "$AGROUP" users && usermod -g "$AGROUP" nobody
else
  usermod -g 100 nobody
fi
usermod -d /config nobody
EOT


# Generate ssl cert to be used with webui
cat <<'EOT' > /etc/my_init.d/06_config.sh
#!/bin/bash
echo "Generating ssl certs for webui"
if [ ! -f /config/https_cert.txt ]; then
  openssl req -nodes -new -x509 -keyout /default/server.key -out /default/server.cert -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.com"
  cat /default/server.key > /config/https_cert.txt && cat /default/server.cert >> /config/https_cert.txt
fi
EOT


cat <<'EOT' > /etc/my_init.d/10_config.sh
#!/bin/bash
echo "Checking if Torrent config exist, if not creating it"

if [ ! -d /config/.config/qBittorrent ]; then
  mkdir -p /config/.config/qBittorrent
fi

if [ ! -f /config/.config/qBittorrent/qBittorrent.conf ]; then
  cp /default/qBittorrent.conf /config/.config/qBittorrent/qBittorrent.conf
fi

chown -R nobody:users /config /downloads /watched /default
EOT

# QbitTorrent Service
mkdir -p /etc/service/qbittorrent

cat <<'EOT' > /etc/service/qbittorrent/run
#!/bin/bash
# qbittorrent startup service
if [ -v PIPEWORK ]; then
  echo "Pipework is enabled waiting for network to come up..."
  pipework --wait
fi
  start-stop-daemon -c nobody -g users -b --start --quiet --exec /usr/bin/qbittorrent-nox
EOT



#########################################
##             INTALLATION             ##
#########################################

# Download pipework
wget -O /usr/local/bin/pipework https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework
chmod +x /usr/local/bin/pipework

# Install Qbittorrent
cd /tmp
wget https://github.com/macexx/ubuntu-builds/blob/master/libtorrent-rasterbar_1.1.0-2_amd64.deb?raw=true -O libtorrent-rasterbar_1.1.0-2_amd64.deb
wget https://github.com/macexx/ubuntu-builds/blob/master/qbittorrent_3.3.4-2_amd64.deb?raw=true -O qbittorrent_3.3.4-2_amd64.deb
dpkg -i libtorrent-rasterbar_1.1.0-2_amd64.deb 
dpkg -i qbittorrent_3.3.4-2_amd64.deb

# Qbittorrent default config
cat <<'EOT' > /default/qBittorrent.conf
[Preferences]
General\Locale=en_US
WebUI\Port=8082
Downloads\SavePath=/downloads
Connection\PortRangeMin=6881

[LegalNotice]
Accepted=true

[General]
ported_to_new_savepath_system=true
EOT

# Make start scripts executable
chmod -R +x /etc/my_init.d/ /etc/service/


#########################################
##              CLEANUP                ##
#########################################

# Clean APT install files
apt-get clean -y
rm -rf /var/lib/apt/lists/* /var/cache/* /var/tmp/*
