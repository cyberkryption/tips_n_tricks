Install Prerequisites - We have a ubuntu server 18.04 with a "kafka" user
It is nice that confluent dont tell you which version to install with their products, you should use either jdk8 or 11.04. If you use 11.04 and need the HDFS connector then you are scr**d
```
sudo apt-get install openjdk-8-jdk
nano /etc/environment
JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/"
source /etc/environment
```
Scala
See https://docs.scala-lang.org/overviews/jdk-compatibility/overview.html#:~:text=We%20generally%20recommend%20JDK%208,experimental%E2%80%9D%20or%20%E2%80%9Cunsafe%E2%80%9D.
```
sudo apt-get install scala
Confluent
wget -qO - https://packages.confluent.io/deb/6.1/archive.key | sudo apt-key add -
sudo add-apt-repository "deb \[arch=amd64\] https://packages.confluent.io/deb/6.1 stable main"
sudo apt-get update && sudo apt-get install confluent-community-2.13
```
Now the fun begins
Zookeeper configuration
```
tickTime=2000
clientPort=2181
initLimit=5
syncLimit=2
server.1=zookkeeper:2888:3888
autopurge.snapRetainCount=3
autopurge.purgeInterval=24
```

Next edit /etc/hosts and add ip for zookeeper
```
192.168.1.82 zookeeper
```
This will make it listen on an ip address rather than local host
 
Service files
In the zookeeper service files, there is a data dir that does not exist so we need to create it. The service file also specifies a user cp-kafka that does not exist

List of service file locations
```
/lib/systemd/system/confluent-kafka-connect.service
/lib/systemd/system/confluent-kafka-rest.service
/lib/systemd/system/confluent-kafka.service
/lib/systemd/system/confluent-ksqldb.service
/lib/systemd/system/confluent-schema-registry.service
/lib/systemd/system/confluent-zookeeper.service
```
```
sudo mkdir /var/lib/zookeeper
sudo chown kafka:confluent /var/lib/zookeeper
```
Create the my id file
```
cd /var/lib/zookeeper
touch myid
echo "1" > myid
sudo chown kafka:confluent myid
```
If we try to statr the service using systemd it fails but if you manually start it it will work, the issue is the systemd path which has it's own path which is not the system path. Fixed service file below
```
[Unit]
Description=Apache Kafka - ZooKeeper
Documentation=http://docs.confluent.io/
After=network.target

[Service]
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-11-openjdk-amd64
Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
Type=simple
User=kafka
Group=confluent
ExecStart=/usr/bin/zookeeper-server-start /etc/kafka/zookeeper.properties
LimitNOFILE=100000
TimeoutStopSec=180
Restart=no

[Install]
WantedBy=multi-user.target
```
Try to statr it and it fails with permissions on data directory /var/lib
There is another directory called versin-2 with root only perms so we have to
```
sudo chown -R kafka:confluent /var/lib/zookeeper
```
Now the zookeeper service runs.. onto next service

/etc/kafka/server.properties
```
zookeeper.connect=zookeeper:2181
```
Kafka Service File - Has non existant user cp-kafka as well as missing java stuff

```
[Unit]
Description=Apache Kafka - broker
Documentation=http://docs.confluent.io/
After=network.target confluent-zookeeper.target

[Service]
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-11-openjdk-amd64
Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
Type=simple
User=kafka
Group=confluent
ExecStart=/usr/bin/kafka-server-start /etc/kafka/server.properties
LimitNOFILE=1000000
TimeoutStopSec=180
Restart=no

[Install]
WantedBy=multi-user.target
```
Service still fails to statr because logging directory /var/lib/kafka does not exist
```
sudo mkdir /var/lib/kafka
sudo chown -R kafka:confluent /var/lib/kafka
```

Confluent Kafka-rest service
Add java entries to service file

Kafka-Connect
Again a user that does not exist, so change to Kafka user and add java stuff
```
[Unit]
Description=Apache Kafka Connect - distributed
Documentation=http://docs.confluent.io/
After=network.target confluent-kafka.target

[Service]
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-11-openjdk-amd64
Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
Type=simple
User=kafka
Group=confluent
ExecStart=/usr/bin/connect-distributed /etc/kafka/connect-distributed.properties
TimeoutStopSec=180
Restart=no

[Install]
WantedBy=multi-user.target
```
You can now start all the services using systemctl

Lastly, we need to set the confluent_home environmanet variable

set it to /usr in /etc/environment
```
CONFLUENT_HOME="/usr"
```
You can then try and run confluent local services start but it will fail, you need to copy various files to /usr/etc/ to the correct directories

```
drwxr-xr-x  6 kafka confluent 4096 Feb 13 09:16 .
drwxr-xr-x 12 root  root      4096 Feb 13 09:03 ..
drwxr-xr-x  2 kafka confluent 4096 Feb 13 09:13 kafka
drwxr-xr-x  2 root  root      4096 Feb 13 09:14 kafka-rest
drwxr-xr-x  2 root  root      4096 Feb 13 09:16 ksqldb
drwxr-xr-x  2 root  root      4096 Feb 13 09:15 schema-registry
```

Lastly change the ownerships to kafka:confluent

I can only say that confluent- you really need to fix your documentation!!!!
