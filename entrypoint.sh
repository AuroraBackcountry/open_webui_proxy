#!/bin/sh
set -e
: "${UPSTREAM_URL:?Need to set UPSTREAM_URL, e.g. http://<internal-host>:8080}"

echo "=== Render Proxy Debug Info ==="
echo "UPSTREAM_URL: $UPSTREAM_URL"
echo "Hostname: $(hostname)"
echo "DNS resolvers:"
cat /etc/resolv.conf
echo "=== Testing DNS resolution ==="
# Extract hostname from UPSTREAM_URL for testing
HOSTNAME=$(echo $UPSTREAM_URL | sed 's|http://||' | sed 's|:.*||')
PORT=$(echo $UPSTREAM_URL | sed 's|.*:||')
echo "Attempting to resolve: $HOSTNAME"
# Try different DNS resolution methods
getent hosts $HOSTNAME || echo "getent hosts failed"
ping -c 1 $HOSTNAME || echo "ping failed"

# Get the resolved IP address
RESOLVED_IP=$(getent hosts $HOSTNAME | awk '{print $1}' | head -1)
if [ -n "$RESOLVED_IP" ]; then
    echo "Resolved $HOSTNAME to IP: $RESOLVED_IP"
    # Use the resolved IP instead of hostname
    export UPSTREAM_URL="http://$RESOLVED_IP:$PORT"
    echo "Updated UPSTREAM_URL to: $UPSTREAM_URL"
else
    echo "Failed to resolve $HOSTNAME, keeping original URL"
fi
echo "=== End Debug Info ==="

# TTS proxy configuration (optional)
if [ -n "$TTS_PROXY_ORIGIN" ]; then
    echo "TTS proxy enabled: $TTS_PROXY_ORIGIN"
    if [ -z "$TTS_SHARED_TOKEN" ]; then
        echo "WARNING: TTS_SHARED_TOKEN not set - TTS proxy will be unprotected"
    fi
else
    echo "TTS proxy not configured (TTS_PROXY_ORIGIN not set)"
fi

# Substitute env into nginx.conf from template
envsubst '${UPSTREAM_URL} ${TTS_PROXY_ORIGIN} ${TTS_SHARED_TOKEN}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Show generated config for debugging
echo "=== Generated nginx.conf ==="
cat /etc/nginx/nginx.conf
echo "=== End nginx.conf ==="

# Start nginx in foreground
nginx -g 'daemon off;'
