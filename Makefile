# Docker Image Name
IMAGE_NAME=incodig/domain-local-ssl-cert-generator:latest
PWD := $(shell pwd)
CERTS_DIR=certs
CA_NAME=MyRootCA
DOMAIN=domain.local
CA_DAYS=3650

# Detect Operating System
OS := $(shell uname -s)

.PHONY: help all build run install-ca clean machine

# List available commands with descriptions
help: ## Lists all available commands in the Makefile
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help

generate-install: run install-ca ## Generates certificates and installs CA on the system

install: install-ca ## Install CA on the system

machine: ## Detects the operating system
	@echo $(OS)

# Run Docker container to generate SSL certificates
run: ## Generates SSL certificates and places them in the 'certs/' folder
	@echo "Generating SSL certificates..."
	docker run --rm -v $(PWD):/app \
      -e DAYS=$(CA_DAYS) \
      -e DOMAIN=$(DOMAIN) \
      -e CA_NAME=$(CA_NAME) \
      $(IMAGE_NAME)
	@echo "Certificates generated in $(CERTS_DIR)/"

# Install CA on the operating system
install-ca: ## Installs CA on the operating system (Linux/macOS/Windows)
	@echo "Installing '$(CA_NAME)' CA on the system..."

ifeq ($(OS),Linux)
	sudo cp $(CERTS_DIR)/$(CA_NAME)-ca.crt /usr/local/share/ca-certificates/$(CA_NAME)-ca.pem
	sudo update-ca-certificates
	@echo "CA installed on Linux!"
endif

ifeq ($(OS),Darwin)
	sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $(CERTS_DIR)/$(CA_NAME)-ca.pem
	@echo "CA installed on macOS!"
endif

ifeq ($(OS),Windows_NT)
	powershell -Command "Import-Certificate -FilePath $(CERTS_DIR)/$(CA_NAME)-ca.pem -CertStoreLocation Cert:\LocalMachine\Root"
	@echo "CA installed on Windows!"
endif

# Remove generated certificates
clean-root-ca: ## Removes generated certificates from the 'certs/' folder
	@echo "Removing certificates (except wildcard.ext)..."
	@find $(CERTS_DIR) -type f ! -name 'wildcard.ext' -delete
	@echo "Cleanup completed!"

ifeq ($(OS),Linux)
	@if [ -f /usr/local/share/ca-certificates/$(CA_NAME)-ca.pem ]; then \
		sudo rm -f /usr/local/share/ca-certificates/$(CA_NAME)-ca.pem; \
		sudo update-ca-certificates --fresh; \
		echo "CA removed from Linux!"; \
	else \
		echo "No CA certificate found on Linux. Skipping removal."; \
	fi
endif

ifeq ($(OS),Darwin)
	@if security find-certificate -a -c "$(CA_NAME) Root CA" -Z | grep -q "SHA-1 hash"; then \
		security find-certificate -a -c "$(CA_NAME) Root CA" -Z | awk '/SHA-1 hash:/ {print $$3}' | while read hash; do \
			sudo security delete-certificate -Z $$hash; \
		done; \
		echo "CA removed from macOS!"; \
	else \
		echo "No CA certificate found on macOS. Skipping removal."; \
	fi
endif

ifeq ($(OS),Windows_NT)
	@powershell -Command "$$certs = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $$_.Subject -match '$(CA_NAME)' }; if ($$certs) { $$certs | Remove-Item; echo 'CA removed from Windows!'; } else { echo 'No CA certificate found on Windows. Skipping removal.'; }"
endif

	@echo "Removal completed!"

# Generate certificates and install CA automatically
all: run install-ca ## Generates image, certificates and installs CA on the system

