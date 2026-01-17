#!/bin/bash
# ============================================================================
# SSL Certificate Generation Script
# Generates a self-signed certificate valid for 10 years
# ============================================================================

set -e

SSL_DIR="/etc/nginx/ssl"
CERT_FILE="${SSL_DIR}/nginx.crt"
KEY_FILE="${SSL_DIR}/nginx.key"
DAYS_VALID=3650  # 10 years

echo "========================================="
echo "Generating Self-Signed SSL Certificate"
echo "========================================="

# Create SSL directory if it doesn't exist
mkdir -p "${SSL_DIR}"

# Check if certificate already exists
if [ -f "${CERT_FILE}" ] && [ -f "${KEY_FILE}" ]; then
    echo "SSL certificate already exists. Skipping generation."
    exit 0
fi

# Detect LAN IP address
LAN_IP=$(hostname -i 2>/dev/null | awk '{print $1}' || echo "")
echo "Detected LAN IP: ${LAN_IP:-none}"

# Build Subject Alternative Names
SAN="DNS:localhost,DNS:*.localhost,IP:127.0.0.1"
if [ -n "$LAN_IP" ] && [ "$LAN_IP" != "127.0.0.1" ]; then
    SAN="${SAN},IP:${LAN_IP}"
    echo "Adding LAN IP to certificate: ${LAN_IP}"
fi

# Note: Cannot add IP ranges (CIDR notation) to SSL certificates
# Each IP must be added individually if needed

# Generate self-signed certificate
echo "Generating certificate valid for ${DAYS_VALID} days (10 years)..."
echo "Subject Alternative Names: ${SAN}"
openssl req -x509 -nodes -days ${DAYS_VALID} \
    -newkey rsa:2048 \
    -keyout "${KEY_FILE}" \
    -out "${CERT_FILE}" \
    -subj "/C=NO/ST=NoState/L=NoWhere/O=NoDev/OU=Development/CN=localhost" \
    -addext "subjectAltName=${SAN}"

# Set proper permissions
chmod 600 "${KEY_FILE}"
chmod 644 "${CERT_FILE}"
chown -R www-data:www-data "${SSL_DIR}"

echo "========================================="
echo "SSL Certificate generated successfully!"
echo "Certificate: ${CERT_FILE}"
echo "Private Key: ${KEY_FILE}"
echo "Valid for: ${DAYS_VALID} days (10 years)"
echo "========================================="
