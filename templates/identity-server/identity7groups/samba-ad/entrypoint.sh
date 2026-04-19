#!/bin/bash
set -e

REALM=${SAMBA_REALM:-TSTF.AXACOLPATRIA.CO}
DOMAIN=${SAMBA_DOMAIN:-TSTF}
ADMIN_PASS=${SAMBA_ADMIN_PASSWORD:-P@ssw0rd2024}
DNS_FORWARDER=${SAMBA_DNS_FORWARDER:-8.8.8.8}

# Check if already provisioned
if [ ! -f /var/lib/samba/private/sam.ldb ]; then
    echo "============================================"
    echo " Provisioning Samba AD DC"
    echo " Realm : ${REALM}"
    echo " Domain: ${DOMAIN}"
    echo "============================================"

    # Remove default smb.conf so samba-tool can create a new one
    rm -f /etc/samba/smb.conf

    samba-tool domain provision \
        --use-rfc2307 \
        --realm="${REALM}" \
        --domain="${DOMAIN}" \
        --server-role=dc \
        --dns-backend=SAMBA_INTERNAL \
        --adminpass="${ADMIN_PASS}" \
        --option="dns forwarder=${DNS_FORWARDER}"

    # Configure Kerberos
    cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

    # Allow simple LDAP binds without TLS (required for WSO2 IS connection)
    sed -i '/\[global\]/a\\tldap server require strong auth = no' /etc/samba/smb.conf

    # Persist smb.conf and krb5.conf in the volume so they survive container recreation
    cp /etc/samba/smb.conf /var/lib/samba/smb.conf.bak
    cp /etc/krb5.conf /var/lib/samba/krb5.conf.bak

    echo "Samba AD DC provisioned successfully."
else
    echo "Samba AD DC already provisioned, starting..."
    # Restore config files from volume
    if [ -f /var/lib/samba/smb.conf.bak ]; then
        cp /var/lib/samba/smb.conf.bak /etc/samba/smb.conf
    fi
    if [ -f /var/lib/samba/krb5.conf.bak ]; then
        cp /var/lib/samba/krb5.conf.bak /etc/krb5.conf
    fi
fi

# Run user initialization script in background after Samba starts
if [ -f /init-users.sh ]; then
    (
        echo "Waiting for Samba LDAP to be available..."
        sleep 12
        # Wait until LDAP port is responsive
        for i in $(seq 1 30); do
            if ldapsearch -x -H ldap://127.0.0.1:389 -b "" -s base namingContexts 2>/dev/null | grep -q "namingContexts"; then
                echo "LDAP is ready."
                break
            fi
            echo "  Attempt $i/30 - LDAP not ready yet..."
            sleep 3
        done
        bash /init-users.sh
    ) &
fi

# Start Samba in foreground
echo "Starting Samba AD DC..."
exec samba -i --debuglevel=1
