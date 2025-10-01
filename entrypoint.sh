#!/bin/sh
set -e
: "${UPSTREAM_URL:?Need to set UPSTREAM_URL, e.g. http://<internal-host>:8080}"

# Substitute env into nginx.conf from template
envsubst '${UPSTREAM_URL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Start nginx in foreground
nginx -g 'daemon off;'
