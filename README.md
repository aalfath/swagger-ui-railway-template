[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/swagger-ui-1?utm_medium=integration&utm_source=button&utm_campaign=swagger-ui)

# Swagger UI on Railway

Railway template for [Swagger UI](https://github.com/swagger-api/swagger-ui) **v5.35.1**, the interactive documentation page for OpenAPI (Swagger) specifications. It runs the official image, pinned by version and digest, with a small wrapper that keeps your spec files on a Railway volume.

| Service | Base image (pinned) | Volume |
|---|---|---|
| Swagger UI (public) | `swaggerapi/swagger-ui:v5.35.1@sha256:cd314c0a167841dc1c9869ff2df6f949e2e7fa63f8b77f610b7e75878ac2da4e` | `/data` |

## What the wrapper adds

`rootfs/docker-entrypoint.d/45-railway.sh` runs after upstream's own start script and:

- keeps OpenAPI files in `/data/specs` on the volume and serves them at `https://YOUR-DOMAIN/specs/` (public read, CORS open);
- accepts uploads and deletes with HTTP `PUT`/`DELETE` and basic auth (user `admin`, password `SPECS_PASSWORD`);
- lists every `.json`, `.yaml` and `.yml` file in `/specs/` in Swagger UI's "Select a definition" menu;
- seeds one example spec on the first start (it documents the upload API; delete it when you like, it isn't recreated);
- adds `/healthz` for Railway's health check;
- puts the whole site behind a login when `DOCS_PASSWORD` is set.

Upload a spec:

```sh
curl -u admin:SPECS_PASSWORD -T openapi.yaml https://YOUR-DOMAIN/specs/openapi.yaml
# delete it again
curl -u admin:SPECS_PASSWORD -X DELETE https://YOUR-DOMAIN/specs/openapi.yaml
```

## Variables

| Variable | Default | What it does |
|---|---|---|
| `SPECS_PASSWORD` | generated (`${{secret(32)}}`) | Password for uploading and deleting spec files (user `admin`). Read it in the service's Variables tab. Empty disables uploads |
| `PORT` | `8080` | Port nginx listens on; the Railway domain points here |

Nothing is prompted at deploy. Optional variables you can add to the service:

- `DOCS_PASSWORD` (and `DOCS_USER`, default `viewer`): require a login for the whole site. `/healthz` stays open.
- `URL`, `URLS` or `SWAGGER_JSON_URL`: show specs hosted elsewhere instead of the `/specs/` list.
- Any of upstream's [configuration variables](https://github.com/swagger-api/swagger-ui/blob/v5.35.1/docs/usage/configuration.md), such as `DOC_EXPANSION`, `DEEP_LINKING`, `PERSIST_AUTHORIZATION`, `OAUTH_CLIENT_ID`, `BASE_URL`, `CORS` or `EMBEDDING`.

"Try it out" sends requests from the visitor's browser, so the API you document must allow CORS from your Swagger UI domain.

## Updates

Railway shows deployers an "update available" notice when `main` changes. Each version bump changes the pinned image tag and digest in the `Dockerfile` and adds an entry to [CHANGELOG.md](CHANGELOG.md), breaking changes first. Your spec files stay on the volume across updates.

## Licence

Swagger UI is Apache-2.0 licensed by SmartBear Software. This wrapper is offered under the same licence.
