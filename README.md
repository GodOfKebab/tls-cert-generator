# tls-cert-generator: TLS Certificate Generator

![](https://badgen.net/docker/pulls/godofkebab/tls-cert-generator)
![](https://badgen.net/docker/size/godofkebab/tls-cert-generator)

This repository provides a simple tool with Docker support to generate TLS certificates for your system.
It automatically creates a self-signed **Root CA** and issues **server certificates** for hostnames and IP addresses you specify (or all addresses/hostnames discovered on the machine).
It works on **macOS** and **Linux**, and can run locally or in Docker.

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

---

## Configuration

The script needs a set of certificate identity fields.
You can provide them in three ways (priority order):
1. CLI arguments (--country, --state, etc.)
2. Environment variables (COUNTRY, STATE, etc.)
3. Interactive prompt (script will ask if missing)

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
| `--cn`       | `ROOT_CN`             | Root CA Common Name                 | `--cn certificate-manager@kebabnet`      |

> Note: Interactive prompts doesn't work when the script is piped into sh 

---

## Ways to Run

### 1. Zero-Setup runner (Recommended)

Make sure you have **OpenSSL** installed (default on Linux/macOS).

Clone the repo and run the script directly:

```bash
export COUNTRY="TR"
export STATE="Istanbul"
export LOCALITY="Fatih"
export ORGANIZATION="God Of Kebab Labs"
export ORGANIZATIONAL_UNIT="God Of Kebab's Guide to the WWW"
export ROOT_CN="certificate-manager@kebabnet"

# Note: Interactive prompts doesn't work when the script is piped into sh 
wget -qO- https://raw.githubusercontent.com/GodOfKebab/tls-cert-generator/refs/heads/main/tls-cert-generator.sh | sh -s -- \
all 1.2.3.4 example.com

# OR use CLI arguments
wget -qO- https://raw.githubusercontent.com/GodOfKebab/tls-cert-generator/refs/heads/main/tls-cert-generator.sh | sh -s -- \
-f -o another-certs-folder \
--country "TR" \
--state "Istanbul" \
--locality "Fatih" \
--org "God Of Kebab Labs" \
--ou "God Of Kebab's Guide to the WWW" \
--cn "certificate-manager@kebabnet" \
all 1.2.3.4 example.com

# OR save the file before running
# wget https://raw.githubusercontent.com/GodOfKebab/tls-cert-generator/refs/heads/main/tls-cert-generator.sh -O tls-cert-generator.sh
# sh tls-cert-generator.sh all 1.2.3.4 example.com
```

Certificates will be created in `./certs`.

---

### 2. Using the Prebuilt Docker Image (from Docker Hub)

You can pull and run the prebuilt image without cloning the repo:

Known issues: Dockerized method is not good at detecting the interfaces of your system (only matters if you run the commands like all, etc.).

```bash
docker run --rm \
  -v $(pwd)/certs:/app/certs \
  -e COUNTRY="TR" \
  -e STATE="Istanbul" \
  -e LOCALITY="Fatih" \
  -e ORGANIZATION="God Of Kebab Labs" \
  -e ORGANIZATIONAL_UNIT="God Of Kebab's Guide to the WWW" \
  -e ROOT_CN="certificate-manager@kebabnet" \
  godofkebab/tls-cert-generator \
  all 1.2.3.4 example.com -f -o /app/certs
```

Certificates will be written into `./certs` (or whatever you set with `-o`).

---

### 3. Building and Running the Docker Image Yourself

Clone the repo, build the Docker image, and run it:

Known issues: Dockerized method is not good at detecting the interfaces of your system (only matters if you run the commands like all, etc.).

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
  -e ROOT_CN="certificate-manager@kebabnet" \
  tls-cert-generator \
  all 1.2.3.4 example.com
```

