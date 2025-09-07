# Certificate Manager

![](https://badgen.net/docker/pulls/godofkebab/certificate-manager)
![](https://badgen.net/docker/size/godofkebab/certificate-manager)


This repository provides a simple tool with Docker-support to generate TLS certificates for your system.  
It automatically creates a self-signed **Root CA** and issues **server certificates** for hostnames and IP addresses you specify (or all addresses/hostnames discovered on the machine).
It works on **macOS** and **Linux**, and can run locally or in Docker.

---

## Features

- Creates and stores a reusable Root CA in `certs/root/`.
- Issues server certificates into `certs/servers/<name>/`.
- Supports:
   - Individual hostnames, IPs, or FQDNs.
   - Bulk generation:
      - `all` – all hostnames + IPv4 + IPv6 addresses.
      - `all-hostname` – only system hostnames.
      - `all-ipv4` – only system IPv4 addresses.
      - `all-ipv6` – only system IPv6 addresses.
- Works on **Linux** and **macOS** (LibreSSL-compatible).
- Automatically uses host networking to detect system IPs when run via Docker on Linux.

---

## Environment Variables

| Variable              | Description                                                                                       |
|-----------------------|---------------------------------------------------------------------------------------------------|
| `COUNTRY`             | 2-letter country code (e.g., `TR`)                                                                |
| `STATE`               | State or province (e.g., `Istanbul`)                                                              |
| `LOCALITY`            | City/locality (e.g., `Fatih`)                                                                     |
| `ORGANIZATION`        | Organization name (e.g., `God Of Kebab Labs`)                                                     |
| `ORGANIZATIONAL_UNIT` | Department/unit (e.g., `God Of Kebab's Guide to the WWW`)                                         |
| `ROOT_CN`             | Common Name for the Root CA (e.g., `God Of Kebab Labs Root CA` or `certificate-manager@kebabnet`) |

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

curl -sSL https://raw.githubusercontent.com/GodOfKebab/certificate-manager/refs/heads/main/make-tls-certs.sh | sh -s all 1.2.3.4 example.com

# OR save the file before running
# curl https://raw.githubusercontent.com/GodOfKebab/certificate-manager/refs/heads/main/make-tls-certs.sh -o make-tls-certs.sh
# sh make-tls-certs.sh all 1.2.3.4 example.com
```

Certificates will be created in `./certs`.

---

### 2. Using the Prebuilt Docker Image (from Docker Hub)

You can pull and run the prebuilt image without cloning the repo:

```bash
docker run --rm \
  -v $(pwd)/certs:/app/certs \
  -e COUNTRY="TR" \
  -e STATE="Istanbul" \
  -e LOCALITY="Fatih" \
  -e ORGANIZATION="God Of Kebab Labs" \
  -e ORGANIZATIONAL_UNIT="God Of Kebab's Guide to the WWW" \
  -e ROOT_CN="certificate-manager@kebabnet" \
  godofkebab/certificate-manager:latest \
  all 1.2.3.4 example.com
```

Certificates will be written into `./certs`.

---

### 3. Building and Running the Docker Image Yourself

Clone the repo, build the Docker image, and run it:

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

