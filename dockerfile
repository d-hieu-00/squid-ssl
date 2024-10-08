# Args
ARG BUILD_IMAGE=alpine:3.20.2
ARG BASE_IMAGE=alpine:3.20.2

# Build step
FROM ${BUILD_IMAGE} AS builder

# Setup squid version
ARG SQUID_MAJOR_VER=v6
ARG SQUID_VER=6.9

# Install dependencies for building Squid
RUN apk add g++ make perl linux-headers openssl-dev

# Download and extract the Squid source code
RUN wget https://www.squid-cache.org/Versions/${SQUID_MAJOR_VER}/squid-${SQUID_VER}.tar.gz && \
    tar xzf squid-${SQUID_VER}.tar.gz

# Building squid
WORKDIR /squid-${SQUID_VER}

RUN MAKE=gmake \
    ./configure --prefix=/opt/squid      \
                --enable-ssl             \
                --enable-ssl-crtd        \
                --with-openssl           \
                --enable-linux-netfilter \
                --enable-icap-client  && \
    gmake -j$(nproc) && \
    gmake install 

# Copy to final image
FROM ${BASE_IMAGE}

# Install dependencies for app
RUN apk add libstdc++ && \
    mkdir /opt/squid -p

# Copy form the builder
COPY --from=builder /opt/squid /opt/squid

# Copy the Squid configuration file & SSL certs
COPY docker-run.sh /opt/squid/docker-run.sh
COPY squid.conf /opt/squid/etc/squid.conf
COPY certs/ /opt/squid/ssl_cert/

# Expose Squid's default HTTP and HTTPS ports
EXPOSE 3128 3129 3127 3126

# Set the entrypoint to Squid
CMD ["/bin/sh", "/opt/squid/docker-run.sh"]
