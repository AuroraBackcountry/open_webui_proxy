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
HOSTNAME=$(echo $UPSTREAM_URL | sed 's|http://||' | sed 's|https://||' | sed 's|:.*||')
PORT=$(echo $UPSTREAM_URL | sed 's|.*:||')
echo "Testing resolution of: $HOSTNAME"
# Test DNS resolution but keep the original hostname
# On Render, using hostnames is more reliable than IPs due to dynamic IPs
getent hosts $HOSTNAME || echo "getent hosts failed (may be normal)"
# Note: ping may fail due to permissions, but DNS resolution via getent is what matters
ping -c 1 $HOSTNAME 2>/dev/null || true

# Keep the original UPSTREAM_URL with hostname - nginx will resolve it at runtime
# This is more reliable on Render where IPs can change
echo "Using UPSTREAM_URL as-is (with hostname): $UPSTREAM_URL"
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
    # Use quoted heredoc to preserve variables, then substitute with sed
    cat > /tmp/tts_config.conf << 'TTS_EOF'
    # ===============================
    #  Open WebUI -> Aurora TTS proxy
    #  (OpenAI-compatible endpoint)
    # ===============================
    location = /api/v1/audio/speech {
      # Upstream service (no trailing slash in env)
      # TTS_PROXY_ORIGIN: e.g. https://aurora-tts-service.onrender.com
      proxy_pass                  __TTS_PROXY_ORIGIN__/v1/audio/speech;

      # --- HTTPS upstream fixes (SNI/Host) ---
      proxy_ssl_server_name       on;         # enable SNI for TLS
      proxy_set_header            Host __TTS_HOST__;  # send upstream host, not client host

      # --- Auth to your TTS service ---
      proxy_set_header            X-TTS-Token "__TTS_SHARED_TOKEN__";

      # --- Streaming (CRITICAL) ---
      proxy_http_version          1.1;
      proxy_buffering             off;
      proxy_request_buffering     off;
      proxy_read_timeout          300s;
      add_header                  X-Accel-Buffering no;

      # --- Forwarded headers ---
      proxy_set_header            X-Real-IP        $remote_addr;
      proxy_set_header            X-Forwarded-For  $proxy_add_x_forwarded_for;
      proxy_set_header            X-Forwarded-Proto https;
      proxy_set_header            X-Forwarded-Port  443;
      proxy_set_header            X-Forwarded-Host  $host;

      proxy_redirect              off;
      absolute_redirect           off;
    }
TTS_EOF
    
    # Substitute TTS variables using sed (more reliable than envsubst for this)
    # BusyBox sed supports -i without extension for in-place editing
    sed -i "s|__TTS_HOST__|${TTS_HOST}|g" /tmp/tts_config.conf
    sed -i "s|__TTS_PROXY_ORIGIN__|${TTS_PROXY_ORIGIN}|g" /tmp/tts_config.conf
    sed -i "s|__TTS_SHARED_TOKEN__|${TTS_SHARED_TOKEN}|g" /tmp/tts_config.conf
    
    # Insert TTS config after the comment line
    sed '/# --- TTS proxy configuration will be conditionally inserted here ---/r /tmp/tts_config.conf' /tmp/nginx.conf.temp > /tmp/nginx.conf.with_tts
    mv /tmp/nginx.conf.with_tts /tmp/nginx.conf.temp
    rm -f /tmp/tts_config.conf
else
    echo "TTS proxy not configured (TTS_PROXY_ORIGIN not set)"
fi

# Substitute remaining env vars and create final config
# Note: TTS variables are already substituted in tts_config.conf, so only UPSTREAM_URL needs substitution
envsubst '${UPSTREAM_URL}' < /tmp/nginx.conf.temp > /etc/nginx/nginx.conf
rm -f /tmp/nginx.conf.temp

# Show generated config for debugging (sanitized - no tokens)
echo "=== Generated nginx.conf (sanitized) ==="
# Remove sensitive tokens before logging
sed 's/X-TTS-Token [^;]*/X-TTS-Token [REDACTED]/g' /etc/nginx/nginx.conf | head -50
echo "... (config truncated for security) ..."
echo "=== End nginx.conf ==="

# Start nginx in foreground
nginx -g 'daemon off;'
