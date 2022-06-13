FROM debezium/base

LABEL maintainer="Debezium Community"

#
# Set the version, home directory, and MD5 hash.
# MD5 hash taken from http://kafka.apache.org/downloads.html for this version of Kafka
# These argument defaults can be overruled during build time but compatibility cannot be guaranteed when the defaults are not used.
#
#ARG KAFKA_VERSION=2.5.1
#ARG SCALA_VERSION=2.13
#ARG SHA512HASH="B910C293766ED1880114595E3096F898ED6B66F3B961FB3AECAD44B17CB839B2B1FC89C7F37EAB20847798F5FC0074775FA495367E6FD005364FC35E4E428B1D"

#ARG KAFKA_VERSION=2.4.0
#ARG SCALA_VERSION=2.12
#ARG SHA512HASH="53B52F86EA56C9FAC62046524F03F75665A089EA2DAE554AEFE3A3D2694F2DA88B5BA8725D8BE55F198BA80695443559ED9DE7C0B2A2817F7A6141008FF79F49"

ARG KAFKA_VERSION=2.1.1
ARG SCALA_VERSION=2.12
ARG SHA512HASH="A2E8168E8DE6B45E8FCA1F2883F0744D3C5A939B70D8A47A5428B72188501D4C2FC11BC35759F2392680D4E8ECF2FA9D0E518E77FD28393AFBA22194AD018B10"

ENV KAFKA_VERSION=$KAFKA_VERSION \
    SCALA_VERSION=$SCALA_VERSION \
    KAFKA_HOME=/kafka \
    SHA512HASH=$SHA512HASH \
    KAFKA_URL_PATH=kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz

ENV KAFKA_DATA=$KAFKA_HOME/data

#
# Create a user and home directory for Kafka
#
USER root
RUN groupadd -r kafka -g 1001 && useradd -u 1001 -r -g kafka -m -d $KAFKA_HOME -s /sbin/nologin -c "Kafka user" kafka && \
    chmod 755 $KAFKA_HOME
RUN mkdir $KAFKA_DATA && \
    mkdir $KAFKA_HOME/logs

#
# Change ownership and switch user
#
RUN chown -R kafka $KAFKA_HOME && \
    chgrp -R kafka $KAFKA_HOME

#
# Download Kafka
#
RUN curl -fSL -o /tmp/kafka.tgz $(curl --stderr /dev/null https://www.apache.org/dyn/closer.cgi\?as_json\=1 | sed -rn 's/.*"preferred":.*"(.*)"/\1/p')$KAFKA_URL_PATH || curl -fSL -o /tmp/kafka.tgz https://archive.apache.org/dist/$KAFKA_URL_PATH

#
# Verify the contents and then install ...
#
RUN echo "$SHA512HASH /tmp/kafka.tgz" | sha512sum -c - &&\
    tar -xzf /tmp/kafka.tgz -C $KAFKA_HOME --strip-components 1 &&\
    rm -f /tmp/kafka.tgz

#
# Remove potentially exploitable classes
# CVE-2021-4104/DBZ-4447 CVE-2019-17571
# CVE-2022-23302 CVE-2022-23305 CVE-2020-9493
#
RUN zip -d /kafka/libs/log4j-1.2.17.jar org/apache/log4j/net/JMSAppender.class org/apache/log4j/net/SocketServer.class org/apache/log4j/net/JMSSink.class 'org/apache/log4j/jdbc/*' 'org/apache/log4j/chainsaw/*'

COPY ./log4j.properties $KAFKA_HOME/config/log4j.properties
RUN mkdir $KAFKA_HOME/config.orig &&\
    mv $KAFKA_HOME/config/* $KAFKA_HOME/config.orig &&\
    chown -R kafka:kafka $KAFKA_HOME/config.orig

# Remove unnecessary files
RUN rm -f $KAFKA_HOME/libs/*-{sources,javadoc,scaladoc}.jar* &&\
    rm -r $KAFKA_HOME/site-docs

#
# The kafka-run-class.sh script generates the classpath for launching Kafka-related JVM, with entries
# containing the pattern "/bin/../libs", which fails to be resolved properly in some
# environments; the CLASSPATH is filled from "base_dir" environment variable that contains the relative
# path so it it is modified to contain absolute path using "realpath" command.
#
RUN sed -i 's/base_dir=\$(dirname \$0)\/../base_dir=\$(realpath \$(dirname \$0)\/..)/' $KAFKA_HOME/bin/kafka-run-class.sh

#
# Allow random UID to use Kafka
#
RUN chmod -R g+w,o+w $KAFKA_HOME

USER kafka

# Set the working directory to the Kafka home directory
WORKDIR $KAFKA_HOME

#
# Expose the ports and set up volumes for the data and logs directories
#
EXPOSE 9092
VOLUME ["/kafka/data","/kafka/logs","/kafka/config"]

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]
