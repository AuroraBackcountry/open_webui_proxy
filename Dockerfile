FROM nginx:alpine

# Copy PWA assets
COPY pwa /usr/share/nginx/html

# Nginx config templating
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
