# Swagger UI for Railway, built from the official image.
# Upstream: https://github.com/swagger-api/swagger-ui (Apache-2.0)
# Bump the version and digest together; see CHANGELOG.md.
FROM swaggerapi/swagger-ui:v5.35.1@sha256:cd314c0a167841dc1c9869ff2df6f949e2e7fa63f8b77f610b7e75878ac2da4e

# Railway wrapper: /specs/ on the /data volume (public read, password-protected
# upload), a /healthz path, and a spec picker that lists the uploaded files.
COPY rootfs/etc/nginx/railway/ /etc/nginx/railway/
COPY rootfs/docker-entrypoint.d/45-railway.sh /docker-entrypoint.d/45-railway.sh
RUN chmod 0755 /etc/nginx/railway /docker-entrypoint.d/45-railway.sh && \
    chmod 0644 /etc/nginx/railway/*

ENV PORT=8080
EXPOSE 8080

# The nginx entrypoint runs /docker-entrypoint.d/*.sh (upstream's 40-swagger-ui.sh,
# then ours) before starting nginx.
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
