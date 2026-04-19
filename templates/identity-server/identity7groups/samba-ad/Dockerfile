FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    samba \
    smbclient \
    krb5-user \
    krb5-config \
    winbind \
    libpam-winbind \
    libnss-winbind \
    dnsutils \
    ldap-utils \
    procps \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
COPY init-users.sh /init-users.sh
RUN chmod +x /entrypoint.sh /init-users.sh

EXPOSE 53 88 135 139 389 445 464 636 3268 3269

ENTRYPOINT ["/entrypoint.sh"]
