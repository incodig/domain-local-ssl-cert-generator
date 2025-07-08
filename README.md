# Domain Local SSL Certificate Generator

This repository provides a lightweight and automated way to generate **self-signed SSL/TLS certificates** for `domain.local` and custom wildcard subdomains, making it easy to enable HTTPS in local development environments.

---

## Features

-  **Self-signed SSL certificates** for `domain.local` and `*.domain.local`
-  **Multi-format support** (`.pem`, `.crt`, `.key`) for use with web servers and applications
-  **Automated certificate generation** using a simple `Makefile`
-  **Multi-platform support** with Docker
-  **Signed and verified using Cosign** for security and integrity

---

## Prerequisites

Make sure you have the following installed:

- [Docker](https://www.docker.com/) — for containerized execution (optional)
- [Make](https://www.gnu.org/software/make/) — for automated certificate generation (optional)

---

## Installation & Usage

### 1. Generate certificates using Docker

To generate a local domain SSL certificate using Docker, run:

```sh
  docker run --rm -v $(pwd)/localhost-ssl:/app incodig/localhost-cert-generator:latest
```
This will generate SSL certificates in the `certs/` directory under `localhost-ssl`.


### **2. Customize your local domain**
Open the `Makefile` and change the domain value:

```
DOMAIN=CHANGE_YOUR_LOCAL_DOMAIN.local
```

By default, certificates will be generated for:

- domain.local
- *.domain.local

### **3. Generate and install certificates manually**
If you're running locally with make, follow these steps:

```sh
    make generate-install
```
This will create the certificates and install them in your system's trust store (Linux/macOS).

## Contributing
Pull requests and contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch (git checkout -b feature-branch).
3. Commit your changes (git commit -m 'Add new feature').
4. Push to your branch (git push origin feature-branch).
5. Open a Pull Request.