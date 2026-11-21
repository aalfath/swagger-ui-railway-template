# Changelog

Breaking changes are listed first in each entry. Read the entry before you apply an update on Railway.

## v5.35.1-railway.1 (2026-11-21)

First release of the template.

- Swagger UI v5.35.1, official image `swaggerapi/swagger-ui:v5.35.1` pinned by digest (`sha256:cd314c0a…2da4e`).
- OpenAPI files live on the Railway volume (`/data/specs`), are served at `/specs/` and appear in the "Select a definition" menu. Uploads with HTTP PUT need the generated `SPECS_PASSWORD`.
- `/healthz` health check, nginx on Railway's `PORT`.
- Optional `DOCS_PASSWORD` puts the whole site behind a login.
