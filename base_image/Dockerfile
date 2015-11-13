FROM ubuntu:trusty
MAINTAINER Mikaël Gibert <mikael.gibert@gmail.com>

RUN apt-get install -y unzip dnsutils

ENV CONSUL_VERSION 0.5.2
ENV CONSUL_SHA256 171cf4074bfca3b1e46112105738985783f19c47f4408377241b868affa9d445

# Install and expose consul-agent
ADD https://dl.bintray.com/mitchellh/consul/${CONSUL_VERSION}_linux_amd64.zip /tmp/consul.zip
RUN echo "${CONSUL_SHA256} /tmp/consul.zip" > /tmp/consul.sha256 && sha256sum -c /tmp/consul.sha256
RUN cd /bin && unzip /tmp/consul.zip && chmod +x /bin/consul && rm /tmp/consul.zip
ADD ./config/consul /config/consul
EXPOSE 8300 8301 8301/udp 8302 8302/udp 8400 8500 8600 8600/udp

# Prepare entrypoint
ADD run.sh /run.sh
#ENTRYPOINT ["/run.sh"]
