FROM bitnami/zookeeper:3.8.3-debian-11-r1

# Environment variables for ZooKeeper
ENV ALLOW_ANONYMOUS_LOGIN=yes
ENV ZOO_PORT_NUMBER=2181
ENV ZOO_SERVER_ID=1
ENV ZOO_SERVERS=zookeeper.railway.internal:2888:3888

EXPOSE 2181 2888 3888
