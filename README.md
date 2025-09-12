# Certificate Manager

![](https://badgen.net/docker/pulls/godofkebab/certificate-manager)
![](https://badgen.net/docker/size/godofkebab/certificate-manager)

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

## Environment Variables / CLI Arguments

| Environment Variable / Arg         | Description                                                                                                      |
|------------------------------------|------------------------------------------------------------------------------------------------------------------|
| `-f`                               | **Optional:** Force overwrite existing keys/certs (default `false`)                                              |
| `-o <dir>`                         | **Optional:** Output directory for certificates (default `./certs`)                                              |
| `COUNTRY` / `-country`             | **TLS Field:** 2-letter country code (e.g., `TR`)                                                                |
| `STATE` / `-state`                 | **TLS Field:** State or province (e.g., `Istanbul`)                                                              |
| `LOCALITY` / `-locality`           | **TLS Field:** City/locality (e.g., `Fatih`)                                                                     |
| `ORGANIZATION` / `-org`            | **TLS Field:** Organization name (e.g., `God Of Kebab Labs`)                                                     |
| `ORGANIZATIONAL_UNIT` / `-orgunit` | **TLS Field:** Department/unit (e.g., `God Of Kebab's Guide to the WWW`)                                         |
| `ROOT_CN` / `-rootcn`              | **TLS Field:** Common Name for the Root CA (e.g., `God Of Kebab Labs Root CA` or `certificate-manager@kebabnet`) |


> All TLS fields must be provided either as environment variables or as CLI arguments. The script will error out if any field is missing from both sources.

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

curl -sSL https://raw.githubusercontent.com/GodOfKebab/certificate-manager/refs/heads/main/make-tls-certs.sh | sh -s \
all 1.2.3.4 example.com

# OR use CLI arguments
curl -sSL https://raw.githubusercontent.com/GodOfKebab/certificate-manager/refs/heads/main/make-tls-certs.sh | sh -s \
-f -o another-certs-folder \
--country "TR" \
--state "Istanbul" \
--locality "Fatih" \
--org "God Of Kebab Labs" \
--ou "God Of Kebab's Guide to the WWW" \
--cn "certificate-manager@kebabnet" \
all 1.2.3.4 example.com

# OR save the file before running
# curl https://raw.githubusercontent.com/GodOfKebab/certificate-manager/refs/heads/main/make-tls-certs.sh -o make-tls-certs.sh
# sh make-tls-certs.sh all 1.2.3.4 example.com
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
  godofkebab/certificate-manager \
  all 1.2.3.4 example.com -f -o /app/certs
```

Certificates will be written into `./certs` (or whatever you set with `-o`).

---

### 3. Building and Running the Docker Image Yourself

Clone the repo, build the Docker image, and run it:

Known issues: Dockerized method is not good at detecting the interfaces of your system (only matters if you run the commands like all, etc.).

```bash
git clone https://github.com/GodOfKebab/certificate-manager.git
cd certificate-manager

docker build -t certificate-manager .
docker run --rm \
  -v $(pwd)/certs:/app/certs \
  -e COUNTRY="TR" \
  -e STATE="Istanbul" \
  -e LOCALITY="Fatih" \
  -e ORGANIZATION="God Of Kebab Labs" \
  -e ORGANIZATIONAL_UNIT="God Of Kebab's Guide to the WWW" \
  -e ROOT_CN="certificate-manager@kebabnet" \
  certificate-manager \
  all 1.2.3.4 example.com
```

