# Pull base image
FROM java:openjdk-8-jdk

MAINTAINER Kaazing Docker Maintainers, contact via github issues: https://github.com/kaazing/gateway.docker/issues

# pub   2048R/24BD9545 2014-07-18 [expires: 2018-07-18]
#       Key fingerprint = 409E F88E 5386 FE7C 68FC  0B77 B795 92BE 24BD 9545
# uid                  David Witherspoon <dpwspoon@gmail.com>
# sub   2048R/9B801C59 2014-07-18 [expires: 2018-07-18]
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 409EF88E5386FE7C68FC0B77B79592BE24BD9545

ENV KAAZING_GATEWAY_VERSION 5.0.1.21
ENV KAAZING_GATEWAY_URL https://oss.sonatype.org/content/repositories/releases/org/kaazing/gateway.distribution/${KAAZING_GATEWAY_VERSION}/gateway.distribution-${KAAZING_GATEWAY_VERSION}.tar.gz

# Set Working Dir
WORKDIR /kaazing-gateway

# Get the latest stable version of gateway
RUN curl -fSL -o gateway.tar.gz $KAAZING_GATEWAY_URL \
	&& curl -fSL -o gateway.tar.gz.asc ${KAAZING_GATEWAY_URL}.asc \
	&& gpg --verify gateway.tar.gz.asc \
	&& tar -xvf gateway.tar.gz --strip-components=1 \
	&& rm gateway.tar.gz*

# By default, Java uses /dev/random to gather entropy data for cryptographic
# needs. However, using /dev/random can cause delays during Gateway startup,
# especially in virtualized environments. /dev/urandom does not require
# collection of entropy data in subsequent runs.
# See: https://github.com/kaazing/gateway/issues/167
ENV GATEWAY_OPTS="-Xmx512m -Djava.security.egd=file:/dev/urandom"

# add new files to the path
ENV PATH=$PATH:/kaazing-gateway/bin

# Expose Ports
EXPOSE 8000

# Define default command
CMD ["gateway.start"]

