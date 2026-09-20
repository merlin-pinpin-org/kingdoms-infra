# Python 3.12 image with uv for dependency management.
# Builds the kingdoms bot from the kingdoms-services sources.
# The build context must provide the kingdoms-services checkout
# (see deploy/*/docker-compose.yml build args in kingdoms-services#20).

FROM python:3.12-slim

WORKDIR /app

COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

COPY pyproject.toml uv.lock ./
RUN uv sync --no-dev --no-install-project

COPY src/ ./src/
COPY config/ ./config/
COPY docker/entrypoint.sh ./
RUN chmod +x entrypoint.sh && uv sync --no-dev

ENTRYPOINT ["./entrypoint.sh"]
