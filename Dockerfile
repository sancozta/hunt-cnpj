FROM python:3.12-slim

WORKDIR /app

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copy project files
COPY pyproject.toml .
COPY main.py .
COPY scripts/ scripts/

# Install dependencies
RUN uv pip install --system -e .

# Create temp directory
RUN mkdir -p /app/temp

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD python -c "print('ok')" || exit 1

CMD ["tail", "-f", "/dev/null"]
