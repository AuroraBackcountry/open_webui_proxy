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
echo "Attempting to resolve: $HOSTNAME"
# Try different DNS resolution methods
getent hosts $HOSTNAME || echo "getent hosts failed"
ping -c 1 $HOSTNAME || echo "ping failed"
echo "=== End Debug Info ==="

# Substitute env into nginx.conf from template
envsubst '${UPSTREAM_URL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Show generated config for debugging
echo "=== Generated nginx.conf ==="
cat /etc/nginx/nginx.conf
echo "=== End nginx.conf ==="

# Start nginx in foreground
nginx -g 'daemon off;'
