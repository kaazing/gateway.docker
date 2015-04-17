# Pull base image
FROM ubuntu:14.04

# Install Zulu Open JDK
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0x219BD9C9
RUN echo "deb http://repos.azulsystems.com/ubuntu `lsb_release -cs` main" >> /etc/apt/sources.list.d/zulu.list
RUN apt-get -qq update
RUN apt-get -qqy install zulu-8=8.6.0.1

# Install utilities
RUN apt-get install -y curl

# Add the latest version of gateway, in the future this should pull from a deb installer
RUN curl -L -o gateway.tar.gz https://oss.sonatype.org/content/repositories/releases/org/kaazing/gateway.distribution/5.0.1.21/gateway.distribution-5.0.1.21.tar.gz
RUN tar -xvf gateway.tar.gz
RUN rm gateway.tar.gz
RUN mv kaazing-gateway-* kaazing-gateway

# Add Log4J settings to redirect to STDOUT
ADD log4j-config.xml /kaazing-gateway/conf/

# Expose Ports
EXPOSE 8000

# Set Working Dir
WORKDIR kaazing-gateway

# Define default command
CMD ["bin/gateway.start"]

