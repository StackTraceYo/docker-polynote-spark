ARG BASE=debian:stretch
FROM $BASE

ENV SPARK_VERSION 2.4.3
ENV HADOOP_VERSION 3.0.0
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Polynote  env
ENV POLYNOTE_VERSION 0.2.8
ENV POLYNOTE_NAME polynote
ENV POLYNOTE_URL https://github.com/polynote/polynote/releases/download/$POLYNOTE_VERSION/${POLYNOTE_NAME}-dist.tar.gz
ENV POLYNOTE_HOME /opt/$POLYNOTE_NAME


RUN apt-get update \
 && apt-get install -y locales \
 && dpkg-reconfigure -f noninteractive locales \
 && locale-gen C.UTF-8 \
 && /usr/sbin/update-locale LANG=C.UTF-8 \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Java / Python
RUN apt-get update \
 && apt-get install -y curl wget unzip \
    python3 python3-setuptools python3-dev build-essential \
    openjdk-8-jdk \
 && ln -s /usr/bin/python3 /usr/bin/python \
 && easy_install3 pip py4j \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN export JAVA_HOME
RUN pip3 install jep jedi pyspark virtualenv

# HADOOP
ENV HADOOP_HOME /usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH $PATH:$HADOOP_HOME/bin
RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /usr/ \
 && rm -rf $HADOOP_HOME/share/doc \
 && chown -R root:root $HADOOP_HOME

# SPARK
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN curl -sL --retry 3 \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME



RUN cd /opt \
 && curl -L $POLYNOTE_URL | tar -xzf -

WORKDIR $POLYNOTE_HOME

COPY ["entrypoint", "/entrypoint"]
RUN chmod 755 /entrypoint
ENTRYPOINT ["/entrypoint"]

CMD ./polynote

