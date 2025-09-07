#!/usr/bin/env bash
set -euo pipefail

# Detect OpenSSL flavor and set correct flag
OPENSSL_REQ_NOENC_FLAG="-noenc"
if openssl version 2>/dev/null | grep -qi "LibreSSL"; then
    # macOS (LibreSSL doesn't support -noenc)
    OPENSSL_REQ_NOENC_FLAG="-nodes"
fi

# If certs/root does NOT exist, create it
if [ ! -d certs/root ]
then
    mkdir -p certs/root
fi

# Create a Root Certificate and self-sign it
# If certs/rootCA.key does NOT exist, create it
if [ ! -f certs/root/rootCA.key ]
then
    # Create the root key
    openssl genrsa -out certs/root/rootCA.key 4096
fi

# If certs/rootCA.crt does NOT exist, create it
if [ ! -f certs/root/rootCA.crt ]
then
    # Generate the Root Certificate.
    openssl req -x509 -sha256 -new $OPENSSL_REQ_NOENC_FLAG \
        -key certs/root/rootCA.key \
        -out certs/root/rootCA.crt \
        -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION CA/OU=$ORGANIZATIONAL_UNIT/CN=$ROOT_CN" \
        -days 800
fi

# If certs/servers does NOT exist, create it
if [ ! -d certs/servers ]
then
    mkdir -p certs/servers
fi

# Function to gather all system hostnames + IPs (macOS + Linux)
get_all_hosts_ipv4() {
    # Collect addresses (IPv4)
    if command -v ip >/dev/null 2>&1; then
        ipv4_addrs="$(ip -o -4 addr show | awk '{print $4}' | cut -d/ -f1)"
    else
        ipv4_addrs="$(ifconfig | awk '/inet /{print $2}')"
    fi
    printf "%s\n" "$ipv4_addrs" | sort -u | xargs
}

get_all_hosts_ipv6() {
    # Collect addresses (IPv6)
    if command -v ip >/dev/null 2>&1; then
        ipv6_addrs="$(ip -o -6 addr show | awk '{print $4}' | cut -d/ -f1)"
    else
        ipv6_addrs="$(ifconfig | awk '/inet6 /{print $2}')"
    fi
    printf "%s\n" "$ipv6_addrs" | sort -u | xargs
}

get_all_hosts_hostname() {
    # Collect hostnames
    hostnames="$(hostname -s) $(hostname -f) $(hostname)"
    printf "%s\n" "$hostnames" | sort -u | xargs
}

get_all_hosts() {
    # Deduplicate each group
    hostnames="$(get_all_hosts_hostname)"
    ipv4_addrs="$(get_all_hosts_ipv4)"
    ipv6_addrs="$(get_all_hosts_ipv6)"
    printf "%s\n" "$hostnames $ipv4_addrs $ipv6_addrs" | sort -u | xargs
}

# Function to gather all system hostnames + IPs (macOS + Linux)
generate_server_cert_key() {
      local server="$1"

    # If certs/servers/$server does NOT exist, create it
    if [ ! -d "certs/servers/$server" ]
    then
        mkdir "certs/servers/$server"
    fi

    # Create the certificate's key if it doesn't exist
    if [ ! -f "certs/servers/$server/key.pem" ]
    then
        openssl genpkey -algorithm RSA \
            -out "certs/servers/$server/key.pem" \
            -pkeyopt rsa_keygen_bits:4096
    fi

    # Generate the Certificate Signing Request (CSR)
    openssl req -new \
        -key "certs/servers/$server/key.pem" \
        -out "certs/servers/$server.csr" \
        -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION certificate/OU=$ORGANIZATIONAL_UNIT/CN=$server"

    # Configure extensions so browsers don't yell
    cat > "certs/servers/$server.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $server
EOF

    # Finally create the certificate for the server and sign it using CA
    openssl x509 -req \
        -in "certs/servers/$server.csr" \
        -CA certs/root/rootCA.crt \
        -CAkey certs/root/rootCA.key \
        -CAcreateserial \
        -out "certs/servers/$server/cert.pem" \
        -days 825 -sha256 \
        -extfile "certs/servers/$server.ext"

    # Remove unnecessary files: Certificate Signing Request (CSR).
    rm "certs/servers/$server.csr" "certs/servers/$server.ext" certs/root/rootCA.srl

    # Verify the newly created certificate
    echo "Created a certificate and a key for '$server' at certs/servers/$server/cert.pem and certs/servers/$server/key.pem"
    openssl x509 -in "certs/servers/$server/cert.pem" -text -noout
}


# Create certificates for servers
for server in "$@"
do
    if [ "$server" = "all" ]; then
        for h in $(get_all_hosts); do
            generate_server_cert_key "$h"
        done
    elif [ "$server" = "all-ipv4" ]; then
        for h in $(get_all_hosts_ipv4); do
            generate_server_cert_key "$h"
        done
    elif [ "$server" = "all-ipv6" ]; then
        for h in $(get_all_hosts_ipv6); do
            generate_server_cert_key "$h"
        done
    elif [ "$server" = "all-hostname" ]; then
        for h in $(get_all_hosts_hostname); do
            generate_server_cert_key "$h"
        done
    else
        generate_server_cert_key $server
    fi
done
