#!/usr/bin/env sh

set -e

# Defaults
FORCE=0
CERTS_DIR="certs"

# Subject fields (CLI args override ENV)
ARG_COUNTRY=""
ARG_STATE=""
ARG_LOCALITY=""
ARG_ORGANIZATION=""
ARG_ORG_UNIT=""
ARG_ROOT_CN=""

usage() {
  echo "Usage: $0 [-f] [-o certs_dir] [--country C] [--state S] [--locality L] [--org O] [--ou OU] [--cn CN] [servers...]"
  exit 1
}

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
    -f) FORCE=1; shift ;;
    -o) CERTS_DIR="$2"; shift 2 ;;
    --country) ARG_COUNTRY="$2"; shift 2 ;;
    --state) ARG_STATE="$2"; shift 2 ;;
    --locality) ARG_LOCALITY="$2"; shift 2 ;;
    --org) ARG_ORGANIZATION="$2"; shift 2 ;;
    --ou) ARG_ORG_UNIT="$2"; shift 2 ;;
    --cn) ARG_ROOT_CN="$2"; shift 2 ;;
    -h|--help) usage ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage ;;
    *) break ;;
  esac
done

# Final subject fields = CLI arg or ENV
COUNTRY="${ARG_COUNTRY:-$COUNTRY}"
STATE="${ARG_STATE:-$STATE}"
LOCALITY="${ARG_LOCALITY:-$LOCALITY}"
ORGANIZATION="${ARG_ORGANIZATION:-$ORGANIZATION}"
ORGANIZATIONAL_UNIT="${ARG_ORG_UNIT:-$ORGANIZATIONAL_UNIT}"
ROOT_CN="${ARG_ROOT_CN:-$ROOT_CN}"

prompt_var() {
    var_name=$1         # Name of the variable (e.g., COUNTRY)
    default_value=$2    # Default value (e.g., XX)
    description=$3      # Description text (e.g., "2-letter country code")

    current_value=$(eval "echo \$$var_name")
    # Only prompt if variable is empty/unset
    if [ -z "$current_value" ]; then
        printf "Enter %s (%s) [%s]: " "$var_name" "$description" "$default_value"
        read input
        # Use default if empty
        eval "$var_name=\"\${input:-$default_value}\""
    fi
}

# Prompt for certificate details only if not already set
prompt_var COUNTRY             "XX"                     "2-letter country code"
prompt_var STATE               "XX"                     "State or province"
prompt_var LOCALITY            "XX"                     "City/locality"
prompt_var ORGANIZATION        "XX"                     "Organization name"
prompt_var ORGANIZATIONAL_UNIT "XX"                     "Department/unit"
prompt_var ROOT_CN             "certificate-manager@XX" "Root CA Common Name"

echo "✨  Welcome to certificate-manager!"
echo "📋 Current configuration:"
echo "   FORCE               (-f)         = ${FORCE}"
echo "   CERTS_DIR           (-o)         = ${CERTS_DIR}"
echo "   COUNTRY             (--country)  = ${COUNTRY}"
echo "   STATE               (--state)    = ${STATE}"
echo "   LOCALITY            (--locality) = ${LOCALITY}"
echo "   ORGANIZATION        (--org)      = ${ORGANIZATION}"
echo "   ORGANIZATIONAL_UNIT (--ou)       = ${ORGANIZATIONAL_UNIT}"
echo "   ROOT_CN             (--cn)       = ${ROOT_CN}"
echo

# Detect OpenSSL flavor and set correct flag
OPENSSL_REQ_NOENC_FLAG="-noenc"
if openssl version 2>/dev/null | grep -qi "LibreSSL"; then
    # macOS (LibreSSL doesn't support -noenc)
    OPENSSL_REQ_NOENC_FLAG="-nodes"
fi

# Ensure root and servers directories
mkdir -p "$CERTS_DIR/root"

# Root CA key
if [ $FORCE -eq 1 ] || [ ! -f "$CERTS_DIR/root/rootCA.key" ]; then
    echo "⏳ Generating key for rootCA ..."
    openssl genrsa -out "$CERTS_DIR/root/rootCA.key" 4096 >/dev/null 2>&1
    echo "    ✅ $CERTS_DIR/root/rootCA.key"
else
    echo "🔎 Detected key for rootCA at $CERTS_DIR/root/rootCA.key. Use -f option to override. Skipping..."
fi

# Root CA cert
if [ $FORCE -eq 1 ] || [ ! -f "$CERTS_DIR/root/rootCA.crt" ]; then
    echo "⏳ Generating cert for rootCA ..."
    # Generate the Root Certificate.
    openssl req -x509 -sha256 -new $OPENSSL_REQ_NOENC_FLAG \
        -key "$CERTS_DIR/root/rootCA.key" \
        -out "$CERTS_DIR/root/rootCA.crt" \
        -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION CA/OU=$ORGANIZATIONAL_UNIT/CN=$ROOT_CN" \
        -days 800
    echo "    ✅ $CERTS_DIR/root/rootCA.crt"
else
    echo "🔎 Detected cert for rootCA at $CERTS_DIR/root/rootCA.crt. Use -f option to override. Skipping..."
fi

mkdir -p "$CERTS_DIR/servers"

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
    server="$1"
    echo "⏳ Generating $CERTS_DIR/servers/key for $server ..."
    mkdir -p "$CERTS_DIR/servers/$server"

    # Create the certificate's key if it doesn't exist
    if [ $FORCE -eq 1 ] || [ ! -f "$CERTS_DIR/servers/$server/key.pem" ]; then
        openssl genpkey -algorithm RSA \
            -out "$CERTS_DIR/servers/$server/key.pem" \
            -pkeyopt rsa_keygen_bits:4096 \
            >/dev/null 2>&1
        echo "    ✅ $CERTS_DIR/servers/$server/key.pem"
    else
        echo "    🔎 Detected key at $CERTS_DIR/servers/$server/key.pem. Use -f option to override. Skipping..."
    fi

    # Create the certificate if it doesn't exist
    if [ $FORCE -eq 1 ] || [ ! -f "$CERTS_DIR/servers/$server/cert.pem" ]; then
        # Generate the Certificate Signing Request (CSR)
        openssl req -new \
            -key "$CERTS_DIR/servers/$server/key.pem" \
            -out "$CERTS_DIR/servers/$server.csr" \
            -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION certificate/OU=$ORGANIZATIONAL_UNIT/CN=$server"

        # Configure extensions so browsers don't yell
        cat > "$CERTS_DIR/servers/$server.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $server
EOF

        # Finally create the certificate for the server and sign it using CA
        openssl x509 -req \
            -in "$CERTS_DIR/servers/$server.csr" \
            -CA "$CERTS_DIR/root/rootCA.crt" \
            -CAkey "$CERTS_DIR/root/rootCA.key" \
            -CAcreateserial \
            -out "$CERTS_DIR/servers/$server/cert.pem" \
            -days 825 -sha256 \
            -extfile "$CERTS_DIR/servers/$server.ext" \
            >/dev/null 2>&1

        # Remove unnecessary files: Certificate Signing Request (CSR).
        rm -f "$CERTS_DIR/servers/$server.csr" "$CERTS_DIR/servers/$server.ext" "$CERTS_DIR/root/rootCA.srl"

        echo "    ✅ $CERTS_DIR/servers/$server/cert.pem"
    else
        echo "    🔎 Detected cert at $CERTS_DIR/servers/$server/cert.pem. Use -f option to override. Skipping..."
    fi
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
        generate_server_cert_key "$server"
    fi
done
