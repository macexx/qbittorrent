#!/bin/bash

#########################################
##       ENVIRONMENTAL CONFIG          ##
#########################################

# Configure user permissions
addgroup --gid 1000 tgroup
adduser --home /config --uid 1000 --ingroup tgroup  --disabled-password --gecos "" tuser
chown -R tuser:tgroup /config


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
apt-get install -qy wget sendmail libio-socket-inet6-perl libio-socket-ssl-perl libnet-libidn-perl libnet-ssleay-perl libsocket6-perl ssl-cert libio-socket-ip-perl libjson-any-perl

#########################################
## FILES, SERVICES AND CONFIGURATION   ##
#########################################

# Initiate config directory
mkdir -p /config
mkdir -p /ddclient


# Config
cat <<'EOT' > /etc/my_init.d/00_config.sh
#!/bin/bash

# Set cache directory

mkdir -p /config/cache

# Checking if sample configuration exists

if [ -f "/config/sample-etc_ddclient.conf" ]; then
  echo "Sample config exists, nothing to do!"
else
  echo "Sample config dosent exist, creating a new one."
  cp /ddclient/sample-etc_ddclient.conf /config/sample-etc_ddclient.conf
fi
EOT

# Config
cat <<'EOT' > /etc/my_init.d/05_user.sh
#!/bin/bash

# Set user permissions to match host
if [ -v "TGID" ]; then
  echo "Setting user permissions to match host (UID / GID)..."
  groupmod -g $TGID tgroup
  usermod -u $TUID tuser
  usermod -g $TGID tuser
  usermod -d /config tuser
  chown -R tuser:tgroup /config
fi
EOT



# QbitTorrent Service
mkdir -p /etc/service/ddclient

cat <<'EOT' > /etc/service/ddclient/run
#!/bin/bash
# ddclient startup service

if [ -f "/ddclient/pid/ddclient.pid" ]; then
  rm /ddclient/pid/ddclient.pid
fi

if [ -v "PIPEWORK" ]; then
  echo "Pipework is enabled waiting for network to come up..."
  pipework --wait
fi

if [ ! -f "/config/ddclient.conf" ]; then
  echo "ddclient.conf does not exist in host directory!!!"
  echo "Rename sample-etc_ddclient.conf to ddclient.conf and configure it or create a new file..."
else
  echo "Configuration exists starting ddclient"
  su nobody -s /bin/bash -c "ddclient -foreground -syslog -pid /ddclient/pid/ddclient.pid -file /config/ddclient.conf -cache /config/cache/ddclient.cache"
fi
EOT



#########################################
##             INTALLATION             ##
#########################################

# Download pipework
wget -O /usr/local/bin/pipework https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework
chmod +x /usr/local/bin/pipework

# Install ddclient
cd /tmp/
wget "http://sourceforge.net/projects/ddclient/files/ddclient/ddclient-3.8.3/ddclient-3.8.3.tar.bz2"
tar -xvf ddclient-3.8.3.tar.bz2
mv ddclient-3.8.3/* /ddclient/
chown -R nobody:users /ddclient
cp /ddclient/ddclient /usr/sbin/

# Make start scripts executable
chmod -R +x /etc/my_init.d/ /etc/service/



#########################################
##              CLEANUP                ##
#########################################

# Clean APT install files
apt-get clean -y
rm -rf /var/lib/apt/lists/* /var/cache/* /var/tmp/*
