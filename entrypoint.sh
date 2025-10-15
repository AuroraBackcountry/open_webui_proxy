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

# Generate nginx.conf with conditional TTS configuration
cp /etc/nginx/nginx.conf.template /tmp/nginx.conf.temp

# TTS proxy configuration (optional)
if [ -n "$TTS_PROXY_ORIGIN" ]; then
    echo "TTS proxy enabled: $TTS_PROXY_ORIGIN"
    if [ -z "$TTS_SHARED_TOKEN" ]; then
        echo "WARNING: TTS_SHARED_TOKEN not set - TTS proxy will be unprotected"
    fi
    
    # Create TTS configuration block
    cat > /tmp/tts_config.conf << EOF
    # --- Stream ElevenLabs audio with no buffering ---
    location /tts/ {
        proxy_pass              ${TTS_PROXY_ORIGIN}/;
        proxy_http_version      1.1;

        # auth header to your TTS service (matches TTS_SHARED_TOKEN)
        proxy_set_header        X-TTS-Token ${TTS_SHARED_TOKEN};

        # CRITICAL for streaming
        proxy_buffering         off;
        proxy_request_buffering off;
        proxy_read_timeout      300s;
        add_header              X-Accel-Buffering no;

        gzip                    off;   # don't gzip audio
    }
EOF
    
    # Insert TTS config after the comment line
    sed '/# --- TTS proxy configuration will be conditionally inserted here ---/r /tmp/tts_config.conf' /tmp/nginx.conf.temp > /tmp/nginx.conf.with_tts
    mv /tmp/nginx.conf.with_tts /tmp/nginx.conf.temp
    rm -f /tmp/tts_config.conf
else
    echo "TTS proxy not configured (TTS_PROXY_ORIGIN not set)"
fi

# Substitute remaining env vars and create final config
envsubst '${UPSTREAM_URL}' < /tmp/nginx.conf.temp > /etc/nginx/nginx.conf
rm -f /tmp/nginx.conf.temp

# Show generated config for debugging
echo "=== Generated nginx.conf ==="
cat /etc/nginx/nginx.conf
echo "=== End nginx.conf ==="

# Start nginx in foreground
nginx -g 'daemon off;'
