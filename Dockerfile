FROM jelastic/javaengine:zulujdk-11.0.13

ARG STACK_NAME="Kafka"
ARG STACK_VERSION=2.8.0
# ARG STACK_VERSION=2.8.1
# ARG STACK_VERSION=3.0.0
ARG SCALA_VERSION=2.13
ENV JAVA_VERSION=11.0.13

ENV STACK_USER=kafka \
    STACK_PATH="/opt/kafka" \
    HOME_DIR="/home/jelastic" \
    JAVA_OPTS_CONFFILE="/home/jelastic/conf/variables.conf" \
    JAVA_ARGS="" \
    JELASTIC_EXPOSE=9092

USER root

RUN groupmod -n ${STACK_USER} jvm; usermod -l ${STACK_USER} jvm; \
    cd /opt && curl -O https://archive.apache.org/dist/kafka/${STACK_VERSION}/kafka_${SCALA_VERSION}-${STACK_VERSION}.tgz && \
    tar -xf kafka_${SCALA_VERSION}-${STACK_VERSION}.tgz && rm -f kafka_${SCALA_VERSION}-${STACK_VERSION}.tgz && \
    mv kafka_${SCALA_VERSION}-${STACK_VERSION} kafka && \
    mkdir -p /opt/kafka/{zookeeper,kafka-logs,logs}; chown -R kafka:kafka /opt/kafka; ln -sfT /opt/kafka/logs /var/log/kafka; \
    echo -e "COMPUTE_TYPE=${STACK_USER}\n\
    COMPUTE_TYPE_VERSION=${STACK_VERSION%%.*}\n\
    COMPUTE_TYPE_FULL_VERSION=${STACK_VERSION}\n\
    CERTIFIED_VERSION=2\n\
    " > /etc/jelastic/metainf.conf; \
    rm -rf /etc/rc.d/init.d/{jvm,java} && \
    rm -rf /home/jelastic/APP && \
    rm -rf /var/lib/jelastic/overrides/jvm-common-deploy.lib; \
    sed -i 's|^log.dirs=.*|log.dirs=/opt/kafka/kafka-logs|g' /opt/kafka/config/server.properties; \
    sed -i 's|^dataDir=.*|dataDir=/opt/kafka/zookeeper|g' /opt/kafka/config/zookeeper.properties; \
    mv /var/spool/cron/jvm /var/spool/cron/kafka;

ADD src/. /

# update JAVA_VERSION in systemd services & enable the services
RUN sed -i "s|Environment='JAVA_VERSION=[^']*'|Environment='JAVA_VERSION=${JAVA_VERSION}'|" /etc/systemd/system/zookeeper.service; \
    sed -i "s|Environment='JAVA_VERSION=[^']*'|Environment='JAVA_VERSION=${JAVA_VERSION}'|" /etc/systemd/system/kafka.service; \
    ln -s /etc/systemd/system/zookeeper.service /etc/systemd/system/multi-user.target.wants/zookeeper.service; \
    ln -s /etc/systemd/system/kafka.service /etc/systemd/system/multi-user.target.wants/kafka.service;

EXPOSE 9092

VOLUME /opt/kafka/kafka-logs /opt/kafka/zookeeper

LABEL appUser=${STACK_USER} \
    description="Jelastic ${STACK_NAME}" \
    cloudletsCount=16 \
    cloudletsMinCount=8 \
    name=${STACK_NAME} \
    nodeType=kafka \
    nodeVersion=${STACK_VERSION} \
    nodeMission=extra \
    sourceUrl="https://raw.githubusercontent.com/jelastic/icons/master/kafka/"

WORKDIR /opt/kafka
ENTRYPOINT []
CMD ["/usr/sbin/init", "-z"]
