"""CSV processing and transformation for CNPJ data files using Polars."""

import logging
import tempfile
from pathlib import Path
from typing import Generator, List, Optional, Tuple

import polars as pl

logger = logging.getLogger(__name__)

# File pattern → table name mapping
FILE_MAPPINGS = {
    "CNAECSV": "pj_activity_codes",
    "MOTICSV": "pj_status_reasons",
    "MUNICCSV": "pj_cities",
    "NATJUCSV": "pj_legal_natures",
    "PAISCSV": "pj_countries",
    "QUALSCSV": "pj_partner_qualifications",
    "EMPRECSV": "pj_companies",
    "ESTABELE": "pj_establishments",
    "SOCIOCSV": "pj_partners",
    "SIMPLESCSV": "pj_simples_nacional",
}

# Column names by file type
COLUMNS = {
    "CNAECSV": ["code", "description"],
    "MOTICSV": ["code", "description"],
    "MUNICCSV": ["code", "description"],
    "NATJUCSV": ["code", "description"],
    "PAISCSV": ["code", "description"],
    "QUALSCSV": ["code", "description"],
    "EMPRECSV": [
        "cnpj",
        "social_reason_name",
        "legal_nature_name",
        "responsible_qualification",
        "social_capital",
        "company_size",
        "responsible_federative_entity",
    ],
    "ESTABELE": [
        "cnpj",
        "cnpj_establishment",
        "cnpj_check_digit",
        "filial_identifier",
        "fantasy_name",
        "status",
        "status_date",
        "status_reason",
        "exterior_city_name",
        "country",
        "activity_start_date",
        "cnae_primary",
        "cnae_secondary",
        "street_type",
        "street",
        "number",
        "complement",
        "district",
        "zip_code",
        "state",
        "city",
        "area_code_primary",
        "phone_primary",
        "area_code_secondary",
        "phone_secondary",
        "fax_area_code",
        "fax",
        "email",
        "special_status",
        "special_status_date",
    ],
    "SOCIOCSV": [
        "cnpj",
        "partner_type",
        "partner_name",
        "partner_document",
        "partner_qualification",
        "entry_date",
        "country",
        "legal_representative",
        "representative_name",
        "representative_qualification",
        "age_range",
    ],
    "SIMPLESCSV": [
        "cnpj",
        "simples_option",
        "simples_option_date",
        "simples_exclusion_date",
        "mei_option",
        "mei_option_date",
        "mei_exclusion_date",
    ],
}


def get_file_type(filename: str) -> Optional[str]:
    """Determine file type from filename."""
    filename_upper = filename.upper()

    # Special case for Simples files that have different naming pattern
    if "SIMPLES" in filename_upper:
        return "SIMPLESCSV"

    for pattern in FILE_MAPPINGS:
        if pattern in filename_upper:
            return pattern
    return None


def _convert_encoding(file_path: Path) -> Path:
    """Convert ISO-8859-1 to UTF-8. Returns path to converted file."""
    utf8_file = Path(tempfile.mktemp(suffix=".utf8.csv"))
    with open(file_path, "r", encoding="ISO-8859-1") as infile:
        with open(utf8_file, "w", encoding="UTF-8") as outfile:
            for chunk in iter(lambda: infile.read(50 * 1024 * 1024), ""):  # 50MB chunks
                outfile.write(chunk)
    return utf8_file


def process_file(
    file_path: Path, batch_size: int = 50000
) -> Generator[Tuple[pl.DataFrame, str, List[str]], None, None]:
    """Process a CSV file and yield batches as Polars DataFrames."""
    file_type = get_file_type(file_path.name)
    if not file_type:
        logger.warning(f"Unknown file type: {file_path.name}")
        return

    table_name = FILE_MAPPINGS[file_type]
    columns = COLUMNS[file_type]

    # Convert encoding first (faster for Polars to read UTF-8)
    utf8_file = _convert_encoding(file_path)

    try:
        offset = 0
        while True:
            try:
                df = pl.read_csv(
                    utf8_file,
                    separator=";",
                    has_header=False,
                    new_columns=columns,
                    encoding="utf8",
                    infer_schema_length=0,
                    null_values=[""],
                    ignore_errors=True,
                    low_memory=False,
                    skip_rows=offset,
                    n_rows=batch_size,
                )
            except pl.exceptions.NoDataError:
                break

            if df.is_empty():
                break

            df = _transform(df, file_type)
            yield df, table_name, columns

            # End of file if we got fewer rows than requested
            if len(df) < batch_size:
                break
            offset += len(df)
    finally:
        utf8_file.unlink(missing_ok=True)


def _transform(df: pl.DataFrame, file_type: str) -> pl.DataFrame:
    """Apply transformations based on file type."""

    # Social capital: "1.234,56" → "1234.56"
    if file_type == "EMPRECSV" and "social_capital" in df.columns:
        df = df.with_columns(pl.col("social_capital").str.replace_all(r"\.", "").str.replace(",", "."))

    # Date columns: "0" or "00000000" → null
    date_cols = {
        "ESTABELE": ["status_date", "activity_start_date", "special_status_date"],
        "SIMPLESCSV": [
            "simples_option_date",
            "simples_exclusion_date",
            "mei_option_date",
            "mei_exclusion_date",
        ],
        "SOCIOCSV": ["entry_date"],
    }
    if file_type in date_cols:
        for col in date_cols[file_type]:
            if col in df.columns:
                df = df.with_columns(
                    pl.when((pl.col(col) == "0") | (pl.col(col) == "00000000") | (pl.col(col).is_null()))
                    .then(None)
                    .otherwise(pl.col(col))
                    .alias(col)
                )

    # Establishments: pad country code
    if file_type == "ESTABELE" and "country" in df.columns:
        df = df.with_columns(pl.col("country").str.zfill(3))

    # Partners: ensure partner_document is not null (PK)
    if file_type == "SOCIOCSV" and "partner_document" in df.columns:
        df = df.with_columns(pl.col("partner_document").fill_null("00000000000000"))

    return df
