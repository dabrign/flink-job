################################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
################################################################################

FROM openjdk:8-jre-alpine

# Install requirements
RUN apk update && apk add --no-cache bash snappy libc6-compat shadow

# Flink environment variables
ENV FLINK_INSTALL_PATH=/opt
ENV FLINK_HOME $FLINK_INSTALL_PATH/flink
ENV FLINK_LIB_DIR $FLINK_HOME/lib
ENV FLINK_PLUGINS_DIR $FLINK_HOME/plugins
ENV FLINK_OPT_DIR $FLINK_HOME/opt
ENV FLINK_JOB_ARTIFACTS_DIR $FLINK_INSTALL_PATH/artifacts
ENV FLINK_USR_LIB_DIR $FLINK_HOME/usrlib
ENV PATH $PATH:$FLINK_HOME/bin

# flink-dist can point to a directory or a tarball on the local system
ARG flink_dist=flink-1.9.1-bin-scala_2.12.tgz
ARG job_artifacts=./target
ARG python_version=NOT_SET
# hadoop jar is optional
# ARG hadoop_jar=NOT_SET*

ARG UID=1000610000
ARG GID=1000610000

ADD http://www.apache.org/dist/flink/flink-1.9.1/flink-1.9.1-bin-scala_2.12.tgz $FLINK_INSTALL_PATH

# COPY flink-1.9.1-bin-scala_2.12.tgz $FLINK_INSTALL_PATH/

WORKDIR $FLINK_INSTALL_PATH


RUN tar -xzvf $FLINK_INSTALL_PATH/flink-1.9.1-bin-scala_2.12.tgz && rm -f $FLINK_INSTALL_PATH/flink-1.9.1-bin-scala_2.12.tgz

# Install Python
RUN \
  if [ "$python_version" = "2" ]; then \
    apk add --no-cache python; \
  elif [ "$python_version" = "3" ]; then \
    apk add --no-cache python3 && ln -s /usr/bin/python3 /usr/bin/python; \
  fi

# Install build dependencies and flink
# ADD $flink_dist $hadoop_jar $FLINK_INSTALL_PATH/
ADD $job_artifacts/* $FLINK_JOB_ARTIFACTS_DIR/

RUN set -x && \
  ln -s $FLINK_INSTALL_PATH/flink-[0-9]* $FLINK_HOME && \
  ln -s $FLINK_JOB_ARTIFACTS_DIR $FLINK_USR_LIB_DIR && \
  if [ -n "$python_version" ]; then ln -s $FLINK_OPT_DIR/flink-python*.jar $FLINK_LIB_DIR; fi && \
  if [ -f ${FLINK_INSTALL_PATH}/flink-shaded-hadoop* ]; then ln -s ${FLINK_INSTALL_PATH}/flink-shaded-hadoop* $FLINK_LIB_DIR; fi && \
  /usr/sbin/groupadd -g $GID -r flink  && \
  /usr/sbin/useradd --system --no-create-home --gid 1000610000 --uid 1000610000 --no-log-init flink && \
  chown -R flink:flink ${FLINK_INSTALL_PATH}/flink-* && \
  chown -R flink:flink ${FLINK_JOB_ARTIFACTS_DIR}/ && \
  chown -h flink:flink $FLINK_HOME

COPY docker-entrypoint.sh /

RUN chmod 755 /docker-entrypoint.sh
# Needed on OpenShift for the entrypoint script to work
RUN chmod -R 777 /opt/flink

RUN chmod -R 777 /opt

USER flink
EXPOSE 8081 6123

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--help"]
