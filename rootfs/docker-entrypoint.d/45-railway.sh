#!/bin/sh
# Railway wrapper for Swagger UI. Runs after upstream's 40-swagger-ui.sh.
#  - keeps OpenAPI files on the Railway volume (/data/specs), served at /specs/
#  - lets you upload them with HTTP PUT (basic auth, SPECS_PASSWORD)
#  - lists them in Swagger UI's "Select a definition" menu
#  - adds /healthz for Railway's health check
#  - optional: DOCS_PASSWORD puts the whole site behind HTTP basic auth
set -eu

DATA_DIR=${DATA_DIR:-/data}
SPECS_USER=${SPECS_USER:-admin}
SPECS_PASSWORD=${SPECS_PASSWORD:-}
DOCS_USER=${DOCS_USER:-viewer}
DOCS_PASSWORD=${DOCS_PASSWORD:-}
NGINX_ROOT=/usr/share/nginx/html
INIT=$NGINX_ROOT/swagger-initializer.js
CONF=/etc/nginx/conf.d/default.conf
HTPASSWD=/etc/nginx/railway/htpasswd

log() { echo "railway: $*"; }

# 1. Volume layout. Seed an example spec once; if you delete it, it stays deleted.
mkdir -p "$DATA_DIR/specs" "$DATA_DIR/.upload-tmp"
if [ ! -e "$DATA_DIR/.seeded" ]; then
  cp /etc/nginx/railway/example-openapi.yaml "$DATA_DIR/specs/example-openapi.yaml"
  date -u +%FT%TZ > "$DATA_DIR/.seeded"
  log "seeded $DATA_DIR/specs/example-openapi.yaml"
fi
chown -R nginx:nginx "$DATA_DIR/specs" "$DATA_DIR/.upload-tmp"

# 2. Passwords, in nginx {SSHA} format made with the image's Node.js.
ssha() { # ssha USER PASSWORD  (a shell function: nothing shows in ps)
  U="$1" P="$2" node -e '
    const c = require("crypto");
    const salt = c.randomBytes(8);
    const h = c.createHash("sha1").update(process.env.P).update(salt).digest();
    process.stdout.write(process.env.U + ":{SSHA}" + Buffer.concat([h, salt]).toString("base64") + "\n");
  '
}
if [ -n "$SPECS_PASSWORD" ]; then
  ssha "$SPECS_USER" "$SPECS_PASSWORD" > "$HTPASSWD"
  log "spec uploads enabled for user '$SPECS_USER'"
else
  : > "$HTPASSWD"
  log "SPECS_PASSWORD is empty: spec uploads are disabled (read-only /specs/)"
fi
if [ -n "$DOCS_PASSWORD" ]; then
  ssha "$DOCS_USER" "$DOCS_PASSWORD" > "$HTPASSWD-docs"
  # the upload user can read too
  if [ -s "$HTPASSWD" ]; then cat "$HTPASSWD" >> "$HTPASSWD-docs"; fi
  log "DOCS_PASSWORD is set: the site needs a login (user '$DOCS_USER')"
fi
for f in "$HTPASSWD" "$HTPASSWD-docs"; do
  if [ -e "$f" ]; then chown root:nginx "$f"; chmod 0640 "$f"; fi
done

# 3. nginx: add /healthz and /specs/ to Swagger UI's server block.
if ! grep -q 'railway/specs.conf' "$CONF"; then
  sed -i 's|^\( *\)server_name .*;|&\n\1include railway/specs.conf;|' "$CONF"
  if [ -n "$DOCS_PASSWORD" ]; then
    sed -i 's|^\( *\)server_name .*;|&\n\1auth_basic "Swagger UI";\n\1auth_basic_user_file railway/htpasswd-docs;|' "$CONF"
  fi
fi

# nginx's default starts one worker per host CPU, which wastes memory on large
# Railway hosts. Two workers are plenty for a docs site.
sed -i "s|^worker_processes .*;|worker_processes ${NGINX_WORKER_PROCESSES:-2};|" /etc/nginx/nginx.conf

# 4. Swagger UI: unless you point it at your own spec (URL, URLS, SWAGGER_JSON_URL,
#    CONFIG_URL, SPEC or a mounted SWAGGER_JSON file), list the files in /specs/.
own_spec=""
for v in URL URLS API_URL API_URLS SWAGGER_JSON_URL CONFIG_URL SPEC; do
  eval "val=\${$v:-}"
  if [ -n "$val" ]; then own_spec="$v"; fi
done
if [ -f "${SWAGGER_JSON:-/app/swagger.json}" ]; then own_spec="SWAGGER_JSON"; fi

if [ -n "$own_spec" ]; then
  log "using your own spec setting ($own_spec); the /specs/ picker is off"
elif ! grep -q '__railwaySpecUrls().then' "$INIT"; then
  tmp=$(mktemp)
  if grep -q 'window.__railwaySpecUrls = function' "$INIT"; then
    cat "$INIT" > "$tmp"
  else
    cat /etc/nginx/railway/spec-picker.js "$INIT" > "$tmp"
  fi
  sed -i \
    -e 's|window.ui = SwaggerUIBundle({|window.__railwaySpecUrls().then(function (urls) {\n      window.ui = SwaggerUIBundle({\n        urls: urls,|' \
    -e 's|^\( *\)//</editor-fold>|\1});\n&|' \
    "$tmp"
  cat "$tmp" > "$INIT"
  rm "$tmp"
  log "Swagger UI lists the OpenAPI files in /specs/"
fi
# upstream pre-compresses assets and nginx serves the .gz first, so refresh it
gzip < "$INIT" > "$INIT.gz"
