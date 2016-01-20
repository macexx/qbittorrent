qBittorrent
==========================


qBittorrent - http://www.qbittorrent.org/



Running on the latest Phusion release (ubuntu 14.04), with qBittorrent 3.3.3 (Built from source)

**Pull image**

```
docker pull mace/qbittorrent
```


**Run container**

```
docker run -d --net="bridge" -p 8080:8080 -p 6881:6881 --name=<container name> -v <path for qbit config files>:/config -v /etc/localtime:/etc/localtime:ro -v <path for download files>:/downloads -v <path for torrent watched files>:/downloads -e AUSER=<host user UID> -e AGROUP=<host user GID> mace/qbittorrent
```
Please replace all user variables in the above command defined by <> with the correct values.
```
-e AUSER=<host user UID> (match with the host users UID)
-e AGROUP=<host user GID> (match with the host users GID)
-e PIPEWORK=<yes> can be added to wait for network connection
```

**Example**

```
docker run -d --net="bridge" -p 8080:8080 -p 6881:6881 --name=qbittorrent -v /local_directory/downloads:/downloads -v /local_directory/config:/config -v /local_directory/watched:/watched -v /etc/localtime:/etc/localtime:ro -e AUSER=1000 -e AGROUP=1000 mace/ddclient
```



**Additional notes**

* WebUI http://localhost:8082 (admin / adminadmin)
* SSL certs are generated and can be found in /config/https_certs.txt (copy paste them in webgui if you want "https")
* The owner of the config directory needs sufficent permissions.
* If AUSER / AGROUP is not selected UID and GID will default to ("65534"/"100" Ubuntu defaults for user "nobody" and group "users")
