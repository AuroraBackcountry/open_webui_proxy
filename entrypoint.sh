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
# Note: On Render, internal service discovery can be unreliable, so we resolve
# hostnames to IPs at startup to avoid nginx resolver issues
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
    # Use the resolved IP instead of hostname for more reliable proxying
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
    
    # Extract hostname from TTS_PROXY_ORIGIN for Host header
    TTS_HOST=$(echo "$TTS_PROXY_ORIGIN" | sed 's|https\?://||' | sed 's|/.*||')
    
    # Create TTS configuration block (OpenAI-compatible endpoint)
    cat > /tmp/tts_config.conf << EOF
    # ===============================
    #  Open WebUI -> Aurora TTS proxy
    #  (OpenAI-compatible endpoint)
    # ===============================
    location = /api/v1/audio/speech {
      # Upstream service (no trailing slash in env)
      # TTS_PROXY_ORIGIN: e.g. https://aurora-tts-service.onrender.com
      proxy_pass                  ${TTS_PROXY_ORIGIN}/v1/audio/speech;

      # --- HTTPS upstream fixes (SNI/Host) ---
      proxy_ssl_server_name       on;         # enable SNI for TLS
      proxy_set_header            Host ${TTS_HOST};  # send upstream host, not client host

      # --- Auth to your TTS service ---
      proxy_set_header            X-TTS-Token "${TTS_SHARED_TOKEN}";

      # --- Streaming (CRITICAL) ---
      proxy_http_version          1.1;
      proxy_buffering             off;
      proxy_request_buffering     off;
      proxy_read_timeout          300s;
      add_header                  X-Accel-Buffering no;

      # --- Forwarded headers ---
      proxy_set_header            X-Real-IP        \$remote_addr;
      proxy_set_header            X-Forwarded-For  \$proxy_add_x_forwarded_for;
      proxy_set_header            X-Forwarded-Proto https;
      proxy_set_header            X-Forwarded-Port  443;
      proxy_set_header            X-Forwarded-Host  \$host;

      proxy_redirect              off;
      absolute_redirect           off;
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
envsubst '${UPSTREAM_URL} ${TTS_PROXY_ORIGIN} ${TTS_SHARED_TOKEN}' < /tmp/nginx.conf.temp > /etc/nginx/nginx.conf
rm -f /tmp/nginx.conf.temp

# Show generated config for debugging (sanitized - no tokens)
echo "=== Generated nginx.conf (sanitized) ==="
# Remove sensitive tokens before logging
sed 's/X-TTS-Token [^;]*/X-TTS-Token [REDACTED]/g' /etc/nginx/nginx.conf | head -50
echo "... (config truncated for security) ..."
echo "=== End nginx.conf ==="

# Start nginx in foreground
nginx -g 'daemon off;'
