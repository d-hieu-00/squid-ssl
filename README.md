There is custom squid with enable `ssl-bump` and `https_port` see here for more details: http://www.squid-cache.org/Doc/config/

## Simple usage with docker compose or docker run

Docker run: `docker run -p3128:3128 -p3129:3129 -p3126:3126 -p3127:3127 --rm -it eraa/squid-ssl:v6`
My default rootCA: [rootCA.crt](https://drive.usercontent.google.com/download?id=1fWd6_hY3mqNTu8Tau79iynQetW5KmLpw&export=download)

### 1. compose.yml
```
services:
  squid:
    image: eraa/squid-ssl:v6
    ports:
      - "3128:3128"
      - "3129:3129"
      - "3126:3126"
      - "3127:3127"
    volumes:
      - "${PWD}/squid.conf:/opt/squid/etc/squid.conf"
      - "${PWD}/certs:/opt/squid/ssl_cert"
```

### 2. squid.conf
```
# Temporary allow all traffic
http_access allow all

# SSL Bump
ssl_bump bump all

# Ignore cert error
sslproxy_cert_error allow all

# http proxy
http_port 3128

# http proxy with ssl-bump
http_port 3129 ssl-bump cert=/opt/squid/ssl_cert/myRootCA.pem

# https proxy
https_port 3126 cert=/opt/squid/ssl_cert/myRootCA.pem

# https proxy with ssl-bump
https_port 3127 intercept ssl-bump cert=/opt/squid/ssl_cert/myRootCA.pem

# Setup ssl-db
sslcrtd_program /opt/squid/libexec/security_file_certgen -s /opt/squid/ssl_db -M 4MB
sslcrtd_children 3 startup=1 idle=1
```

### 3. Generate root CA doc: [Microsoft-self-signed-certificates](https://learn.microsoft.com/en-us/azure/application-gateway/self-signed-certificates)
Create private key:
```
openssl ecparam -out myRootCA.key -name prime256v1 -genkey
```
Create certificate sign request
```
openssl req -new -sha256 -key myRootCA.key -out myRootCA.csr
```
Create certificate
```
openssl x509 -req -sha256 -days 365 -in myRootCA.csr -signkey myRootCA.key -out myRootCA.crt
```
Prepare root CA pem file:
```
cat myRootCA.key > myRootCA.pem
cat myRootCA.crt >> myRootCA.pem
```
