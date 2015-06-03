# Pull base image
FROM java:openjdk-8u45-jdk

MAINTAINER Kaazing Docker Maintainers, contact via github issues: https://github.com/kaazing/gateway.docker/issues

# Install utilities
RUN apt-get install -y curl

# Get the latest stable version of gateway
RUN curl -L -o gateway.tar.gz https://oss.sonatype.org/content/repositories/releases/org/kaazing/gateway.distribution/5.0.1.21/gateway.distribution-5.0.1.21.tar.gz
RUN tar -xvf gateway.tar.gz
RUN rm gateway.tar.gz
RUN mv kaazing-gateway-* kaazing-gateway

# Add Log4J settings to redirect to STDOUT
COPY log4j-config.xml /kaazing-gateway/conf/

# Copy gateway.start
COPY gateway.start /kaazing-gateway/bin/

# Expose Ports
EXPOSE 8000

# Set Working Dir
WORKDIR kaazing-gateway

# Define default command
CMD ["bin/gateway.start"]

