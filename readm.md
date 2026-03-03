### CNPJ Extractor Pipeline

[![Python](https://img.shields.io/badge/python-3.11+-blue)](https://www.python.org)
[![Ruff](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/astral-sh/ruff/main/assets/badge/v2.json)](https://github.com/astral-sh/ruff)

Downloads and processes Brazilian company data from Receita Federal into PostgreSQL.

#### Requirements

- [uv](https://docs.astral.sh/uv/) - `brew install uv`
- [just](https://github.com/casey/just) - `brew install just`
- Docker

#### Quick Start

```bash
cp .env.example .env
just up      # Start PostgreSQL
just run     # Run pipeline
```

#### Commands

```bash
just install # Install dependencies
just up      # Start PostgreSQL
just down    # Stop PostgreSQL
just db      # Open psql shell
just run     # Run pipeline
just reset   # Clear and reset database
just lint    # Check code
just format  # Format code
just test    # Run tests
just check   # Run all (lint, format, test)
```

#### Usage

```bash
just run                          # Process most recent month
just run --list                   # List available months
just run --month 2024-11          # Process specific month
just run --month 2024-11 --force  # Force reprocessing
```

#### Configuration

```bash
DATABASE_URL=postgres://hunt:hunt@localhost:5432/hunt
BATCH_SIZE=500000
TEMP_DIR=./temp
DOWNLOAD_WORKERS=4
RETRY_ATTEMPTS=3
RETRY_DELAY=5
CONNECT_TIMEOUT=30
READ_TIMEOUT=300
KEEP_DOWNLOADED_FILES=false
```

#### Schema

> Full documentation: [readme.data.md](readme.data.md)

All tables use the `pj_` prefix to distinguish them within the shared `hunt` database.

```
pj_companies (1) --- (N) pj_establishments
             |--- (N) pj_partners
             '--- (1) pj_simples_nacional
```

#### Data Source

- **URL**: https://arquivos.receitafederal.gov.br/index.php/s/YggdBLfdninEJX9
- **Update frequency**: Monthly
