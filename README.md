# tls-cert-generator: Self-Signed TLS Certificate Generator

[![Release](https://img.shields.io/github/v/tag/godofkebab/tls-cert-generator?logo=github&label=latest%20tag&color=blue)](https://github.com/godofkebab/tls-cert-generator/releases/latest)
[![Docker](https://img.shields.io/docker/pulls/godofkebab/tls-cert-generator?logo=docker&color=%232496ED)](https://hub.docker.com/repository/docker/godofkebab/tls-cert-generator/tags)
[![Docker](https://img.shields.io/docker/image-size/godofkebab/tls-cert-generator?logo=docker&color=%232496ED)](https://hub.docker.com/repository/docker/godofkebab/tls-cert-generator)
![Static Badge](https://img.shields.io/badge/Linux%20%7C%20macOS%20%20-%20black?label=platform)


*No bloat. No complexity. Just one command.*

✅ **Root CA + Server Certificates** — automatically generated  
🎯 **Target specific hosts** or auto-discover all addresses  
⚡ **Pure shell script** — only requires `openssl`  
🐳 **macOS • Linux • Docker**

---

## Features

* Creates and stores a reusable Root CA in `certs/root/`.
* Issues server certificates into `certs/servers/<name>/`.
* Supports:

    * Individual hostnames, IPs, or FQDNs.
    * Bulk generation:

        * `all` – all hostnames + IPv4 + IPv6 addresses.
        * `all-hostname` – only system hostnames.
        * `all-ipv4` – only system IPv4 addresses.
        * `all-ipv6` – only system IPv6 addresses.
* Works on **Linux** and **macOS** (LibreSSL-compatible).
* Automatically uses host networking to detect system IPs when run via Docker on Linux.
* Optional flags:

    * `-f` – **force overwrite** existing keys/certs.
    * `-o <dir>` – specify the **output certs directory** (default `./certs`).
* Automatically maintains a `.env` file with the current configuration.

---

## Configuration

The script needs a set of certificate identity fields.
You can provide them in four ways (priority order):
1. CLI arguments (--country, --state, etc.)
2. Environment variables (COUNTRY, STATE, etc.) from the current shell
3. Environment variables (COUNTRY, STATE, etc.) from the $CERTS/.env file (automatically generated from a previous run)
4. Interactive prompt (script will ask if missing)

## Options

| CLI Flag     | Env Var               | Description                         | Example                                  |
|--------------|-----------------------|-------------------------------------|------------------------------------------|
| `-f`         | N/A                   | Flag for overwriting existing files | `-f`                                     |
| `-o`         | N/A                   | Output directory for certs          | `-o ./my-certs`                          |
| `--country`  | `COUNTRY`             | 2-letter country code               | `--country TR`                           |
| `--state`    | `STATE`               | State or province                   | `--state Istanbul`                       |
| `--locality` | `LOCALITY`            | City/locality                       | `--locality Fatih`                       |
| `--org`      | `ORGANIZATION`        | Organization name                   | `--org "God Of Kebab Labs"`              |
| `--ou`       | `ORGANIZATIONAL_UNIT` | Department/unit                     | `--ou "God Of Kebab's Guide to the WWW"` |
| `--cn`       | `ROOT_CN`             | Root CA Common Name                 | `--cn tls-cert-generator@kebabnet`      |

> Note: Interactive prompts doesn't work when the script is piped into sh 

---

## Ways to Run

### 1. Direct Execution (Recommended)

Make sure you have **OpenSSL** installed (default on Linux/macOS).

Clone the repo and run the script directly:

```bash
export COUNTRY="TR"
export STATE="Istanbul"
export LOCALITY="Fatih"
export ORGANIZATION="God Of Kebab Labs"
export ORGANIZATIONAL_UNIT="God Of Kebab's Guide to the WWW"
export ROOT_CN="tls-cert-generator@kebabnet"

# Note: Interactive prompts doesn't work when the script is piped into sh 
wget -qO- https://github.com/GodOfKebab/tls-cert-generator/releases/latest/download/tls-cert-generator.sh | sh -s -- \
all 1.2.3.4 example.com

# OR use CLI arguments
wget -qO- https://github.com/GodOfKebab/tls-cert-generator/releases/latest/download/tls-cert-generator.sh | sh -s -- \
-f -o another-certs-folder \
--country "TR" \
--state "Istanbul" \
--locality "Fatih" \
--org "God Of Kebab Labs" \
--ou "God Of Kebab's Guide to the WWW" \
--cn "tls-cert-generator@kebabnet" \
all 1.2.3.4 example.com

# OR save the file before running
# wget https://github.com/GodOfKebab/tls-cert-generator/releases/latest/download/tls-cert-generator.sh -O tls-cert-generator.sh
# mkdir certs && sh tls-cert-generator.sh all 1.2.3.4 example.com
```

<details>
<summary>Example Output</summary>

```text
Enter COUNTRY (2-letter country code) [XX]: 
Enter STATE (State or province) [XX]: 
Enter LOCALITY (City/locality) [XX]: 
Enter ORGANIZATION (Organization name) [XX]: 
Enter ORGANIZATIONAL_UNIT (Department/unit) [XX]: 
Enter ROOT_CN (Root CA Common Name) [tls-cert-generator@XX]: 
✨  Welcome to tls-cert-generator!
📋 Current configuration:
   FORCE               (-f)         = 1
   CERTS_DIR           (-o)         = /Users/username/make-tls-certs
   COUNTRY             (--country)  = XX
   STATE               (--state)    = XX
   LOCALITY            (--locality) = XX
   ORGANIZATION        (--org)      = XX
   ORGANIZATIONAL_UNIT (--ou)       = XX
   ROOT_CN             (--cn)       = tls-cert-generator@XX

⏳ Generating key for rootCA ...
    ✅ Success: /Users/username/make-tls-certs/root/rootCA.key
⏳ Generating cert for rootCA ...
    ✅ Success: /Users/username/make-tls-certs/root/rootCA.crt
⏳ Generating cert/key for HOSTNAME ...
    ✅ Success: /Users/username/make-tls-certs/servers/HOSTNAME/key.pem
    ✅ Success: /Users/username/make-tls-certs/servers/HOSTNAME.csr
    ✅ Success: /Users/username/make-tls-certs/servers/HOSTNAME/cert.pem
⏳ Generating cert/key for HOSTNAME.local ...
    ✅ Success: /Users/username/make-tls-certs/servers/HOSTNAME.local/key.pem
    ✅ Success: /Users/username/make-tls-certs/servers/HOSTNAME.local.csr
    ✅ Success: /Users/username/make-tls-certs/servers/HOSTNAME.local/cert.pem
⏳ Generating cert/key for HOSTNAME.local ...
    ✅ Success: /Users/username/make-tls-certs/servers/HOSTNAME.local/key.pem
    ✅ Success: /Users/username/make-tls-certs/servers/HOSTNAME.local.csr
    ✅ Success: /Users/username/make-tls-certs/servers/HOSTNAME.local/cert.pem
⏳ Generating cert/key for XX.XX.XX.XX ...
    ✅ Success: /Users/username/make-tls-certs/servers/XX.XX.XX.XX/key.pem
    ✅ Success: /Users/username/make-tls-certs/servers/XX.XX.XX.XX.csr
    ✅ Success: /Users/username/make-tls-certs/servers/XX.XX.XX.XX/cert.pem
⏳ Generating cert/key for 127.0.0.1 ...
    ✅ Success: /Users/username/make-tls-certs/servers/127.0.0.1/key.pem
    ✅ Success: /Users/username/make-tls-certs/servers/127.0.0.1.csr
    ✅ Success: /Users/username/make-tls-certs/servers/127.0.0.1/cert.pem
⏳ Generating cert/key for ::1 ...
    ✅ Success: /Users/username/make-tls-certs/servers/::1/key.pem
    ✅ Success: /Users/username/make-tls-certs/servers/::1.csr
    ✅ Success: /Users/username/make-tls-certs/servers/::1/cert.pem
```
</details>

Certificates will be created in `./certs`.
A `.env` file will be written in `./certs/.env` with the chosen values.

---

### 2. Using the Prebuilt Docker Image (from Docker Hub)

You can pull and run the prebuilt image without cloning the repo:

Known issues: Dockerized method is not good at detecting the interfaces of your host system (only matters if you run the commands like all, etc.).

```bash
docker run --rm \
  -v $(pwd)/certs:/app/certs \
  -e COUNTRY="TR" \
  -e STATE="Istanbul" \
  -e LOCALITY="Fatih" \
  -e ORGANIZATION="God Of Kebab Labs" \
  -e ORGANIZATIONAL_UNIT="God Of Kebab's Guide to the WWW" \
  -e ROOT_CN="tls-cert-generator@kebabnet" \
  godofkebab/tls-cert-generator \
  all 1.2.3.4 example.com
```

Certificates will be written into `./certs` (or wherever you set with `-o`).

---

### 3. Building and Running the Docker Image Yourself

Clone the repo, build the Docker image, and run it:

Known issues: Dockerized method is not good at detecting the interfaces of your host system (only matters if you run the commands like all, etc.).

```bash
git clone https://github.com/GodOfKebab/tls-cert-generator.git
cd tls-cert-generator

docker build -t tls-cert-generator .
docker run --rm \
  -v $(pwd)/certs:/app/certs \
  -e COUNTRY="TR" \
  -e STATE="Istanbul" \
  -e LOCALITY="Fatih" \
  -e ORGANIZATION="God Of Kebab Labs" \
  -e ORGANIZATIONAL_UNIT="God Of Kebab's Guide to the WWW" \
  -e ROOT_CN="tls-cert-generator@kebabnet" \
  tls-cert-generator \
  all 1.2.3.4 example.com
```

