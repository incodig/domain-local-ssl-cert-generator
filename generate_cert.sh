#!/bin/sh

# Set exit on error to prevent script from continuing upon failure of any command
set -e

# Default environment variable values for APP_DIR, DAYS, CA_NAME, and DOMAIN
# These can be overridden by user if needed
if [ -z "$APP_DIR" ]; then
  APP_DIR="/app"
fi

# Check if CERTS_DIR exists under APP_DIR, create it if not
if [ -d "$APP_DIR/certs" ]; then
  CERTS_DIR="$APP_DIR/certs"
fi

if [ -z "$DAYS" ]; then
  DAYS=365
fi

# Set default CA_NAME and DOMAIN if they are not already set
if [ -z "$CA_NAME" ]; then
  CA_NAME="MyRootCA"
fi

if [ -z "$DOMAIN" ]; then
  DOMAIN="domain.local"
fi

# Create the directory to store certificates if it doesn't already exist.
if [ ! -d "$CERTS_DIR/$DOMAIN" ]; then
  mkdir -p "$CERTS_DIR/$DOMAIN"
fi

# Define CA key and certificate paths
CA_KEY="${CERTS_DIR}/${CA_NAME}-ca.key"
CA_CERT="${CERTS_DIR}/${CA_NAME}-ca.pem"
WILDCARD="*.${DOMAIN}"

# Check if Makefile exists before copying it to the certificates directory.
if [ -f "/Makefile" ]; then
    cp "/Makefile" "$APP_DIR/Makefile"
    echo "Makefile copied successfully."
else
    echo "Warning: Makefile not found. It was not copied."
fi

# Generate the Certificate Authority (CA) certificate and private key.
echo "Generating SSL certificates for localhost with Certificate Authority '$CA_NAME'..."
if [[ ! -f "$CA_KEY" || ! -f "$CA_CERT" ]]; then
  # Generate new CA key and certificate if they don't exist
  openssl genrsa -out "$CA_KEY" 4096
  openssl req -x509 -new -nodes -key "$CA_KEY" \
    -sha256 -days ${DAYS} -out "$CA_CERT" \
    -subj "/C=XX/ST=Dev/L=Dev/O=Dev/CN=$CA_NAME"
  echo "CA created at:"
  echo " - $CA_CERT"
else
  # Reuse existing CA if it already exists
  echo "CA already exists, will be reused."
fi

#
## Generate a new private key domain
echo "Creating SAN configuration for $DOMAIN and $WILDCARD..."
# Set wildcard for the given DOMAIN
WILDCARD="*.${DOMAIN}"

echo "Generating wildcard certificate for ${WILDCARD}..."
if [ ! -f "$CERTS_DIR/$DOMAIN/wildcard.ext" ]; then
# Create a configuration file for extensions to be used in certificate signing request.
cat > "${CERTS_DIR}/${DOMAIN}/wildcard.ext" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
EOF
fi

echo "Generating private key and CSR..."
# Generate new private key and certificate signing request (CSR)
openssl genrsa -out "${CERTS_DIR}/${DOMAIN}/${DOMAIN}.key" 2048

# Create a CSR with the private key and SAN configuration
openssl req -new -key "${CERTS_DIR}/${DOMAIN}/${DOMAIN}.key" \
  -out "${CERTS_DIR}/${DOMAIN}/${DOMAIN}.csr" \
  -subj "/C=XX/ST=Dev/L=Local/O=Dev/CN=${DOMAIN}"

echo "Signing certificate with CA..."
# Sign the CSR using the CA key and certificate
openssl x509 -req \
  -in "${CERTS_DIR}/${DOMAIN}/${DOMAIN}.csr" \
  -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
  -out "${CERTS_DIR}/${DOMAIN}/${DOMAIN}.crt" \
  -days ${DAYS} -sha256 \
  -extfile "${CERTS_DIR}/${DOMAIN}/wildcard.ext"

echo "Preparing files for services..."
# Generate fullchain.pem by concatenating the certificate and CA
cat "${CERTS_DIR}/${DOMAIN}/${DOMAIN}.crt" "$CA_CERT" > "${CERTS_DIR}/${DOMAIN}/fullchain.pem"
# Copy cert.pem and key.pem as standard names for services to use
cp "${CERTS_DIR}/${DOMAIN}/fullchain.pem" "${CERTS_DIR}/${DOMAIN}/cert.pem"
cp "${CERTS_DIR}/${DOMAIN}/${DOMAIN}.key" "${CERTS_DIR}/${DOMAIN}/key.pem"

echo ""
echo "Wildcard certificate for localhost created successfully!"
echo " - ${CERTS_DIR}/${DOMAIN}/cert.pem (fullchain)"
echo " - ${CERTS_DIR}/${DOMAIN}/key.pem"
echo " - ${CERTS_DIR}/${CA_NAME}-ca.pem (install in the system to avoid warnings)"
echo ""

echo "To install CA (Linux):"
echo "   sudo cp ${CA_CERT} /usr/local/share/ca-certificates/${CA_NAME}-ca.crt && sudo update-ca-certificates"

# Notify the user that certificates have been generated successfully.
echo "SSL certificates generated successfully and saved in '$CERTS_DIR'!"
