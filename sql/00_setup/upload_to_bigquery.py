import os
import time
from pathlib import Path

import pandas as pd
from google.cloud import bigquery


# ============================================================
# KONFIGURASI — SESUAIKAN DENGAN PROJECT ANDA
# ============================================================
PROJECT_ID = "olist-ecommerce-analytics-1"
DATASET_ID = "olist_raw"
DATA_DIR = Path("data/raw")

# Mapping: nama file CSV → nama tabel BigQuery
FILE_TABLE_MAPPING = {
    "olist_order_reviews_dataset.csv": "raw_order_reviews",
}


def get_bigquery_client(project_id: str) -> bigquery.Client:
    return bigquery.Client(project=project_id)

def upload_csv_to_bigquery(
    client: bigquery.Client,
    csv_path: Path,
    table_id: str,
    project_id: str,
    dataset_id: str,
) -> dict:
    """
    Mengupload satu file CSV ke BigQuery sebagai tabel baru.

    Strategy:
    - Schema: Auto-detect dari CSV
    - Write disposition: WRITE_TRUNCATE (overwrite jika tabel sudah ada)
    - Source format: CSV dengan header baris pertama

    Args:
        client: BigQuery client yang sudah authenticated
        csv_path: Path ke file CSV
        table_id: Nama tabel di BigQuery
        project_id: Google Cloud Project ID
        dataset_id: BigQuery Dataset ID

    Returns:
        dict: Hasil upload (status, row_count, error)
    """
    full_table_id = f"{project_id}.{dataset_id}.{table_id}"

    # Baca CSV untuk mendapatkan row count (validasi)
    print(f"\n{'='*60}")
    print(f"Processing: {csv_path.name}")
    print(f"Target: {full_table_id}")

    df_preview = pd.read_csv(
        csv_path,
        nrows=5,
        encoding="utf-8"
    )

    total_rows = sum(
        1 for _ in open(csv_path, encoding="utf-8")
    ) - 1
    
    print(f"File size: {csv_path.stat().st_size / 1024 / 1024:.2f} MB")
    print(f"Estimated rows: {total_rows:,}")
    print(f"Columns ({len(df_preview.columns)}): {list(df_preview.columns)}")

    # Konfigurasi job upload
    job_config = bigquery.LoadJobConfig(
        # Auto-detect schema dari CSV
        autodetect=True,
        # Skip baris pertama (header)
        skip_leading_rows=1,
        # Format file
        source_format=bigquery.SourceFormat.CSV,
        # Overwrite tabel jika sudah ada
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        # Handle quoted fields dengan newline di dalamnya
        allow_quoted_newlines=True,
        # Encoding CSV (UTF-8 adalah default, tapi Latin-1 untuk data Brazil)
        encoding="UTF-8",
    )

    # Jalankan upload job
    start_time = time.time()
    with open(csv_path, "rb") as f:
        load_job = client.load_table_from_file(
            f,
            destination=full_table_id,
            job_config=job_config,
        )

    # Tunggu job selesai
    load_job.result()
    elapsed = time.time() - start_time

    # Verifikasi: ambil info tabel setelah upload
    table = client.get_table(full_table_id)
    actual_rows = table.num_rows

    print(f" Upload berhasil!")
    print(f"   Rows uploaded: {actual_rows:,}")
    print(f"   Time elapsed: {elapsed:.1f}s")

    return {
        "table": table_id,
        "status": "success",
        "rows_uploaded": actual_rows,
        "columns": len(table.schema),
        "size_mb": table.num_bytes / 1024 / 1024,
        "elapsed_seconds": round(elapsed, 1),
    }


def verify_upload_summary(results: list) -> None:
    """
    Menampilkan ringkasan hasil upload semua tabel.

    Args:
        results: List of dict hasil upload per tabel
    """
    print(f"\n{'='*60}")
    print("UPLOAD SUMMARY")
    print(f"{'='*60}")
    print(f"{'Table':<40} {'Rows':>12} {'Cols':>6} {'MB':>8} {'Status'}")
    print(f"{'-'*40} {'-'*12} {'-'*6} {'-'*8} {'-'*10}")

    total_rows = 0
    total_mb = 0
    success_count = 0

    for r in results:
        status_icon = "" if r["status"] == "success" else ""
        print(
            f"{r['table']:<40} "
            f"{r['rows_uploaded']:>12,} "
            f"{r['columns']:>6} "
            f"{r['size_mb']:>8.2f} "
            f"{status_icon} {r['status']}"
        )
        if r["status"] == "success":
            total_rows += r["rows_uploaded"]
            total_mb += r["size_mb"]
            success_count += 1

    print(f"{'-'*40} {'-'*12} {'-'*6} {'-'*8} {'-'*10}")
    print(
        f"{'TOTAL':<40} "
        f"{total_rows:>12,} "
        f"{'':>6} "
        f"{total_mb:>8.2f}"
    )
    print(f"\n {success_count}/{len(results)} tables uploaded successfully")
    print(f"Total rows: {total_rows:,}")
    print(f"Total size: {total_mb:.2f} MB")


def main():
    """Main function untuk orchestrate upload semua CSV files."""

    print("=" * 60)
    print("OLIST BIGQUERY UPLOAD SCRIPT")
    print("Raw Layer: olist_raw")
    print("=" * 60)

    # Validasi data directory
    if not DATA_DIR.exists():
        raise FileNotFoundError(
            f"Data directory tidak ditemukan: {DATA_DIR}\n"
            "Pastikan sudah download CSV files ke folder data/raw/"
        )

    # Inisialisasi BigQuery client
    print(f"\nConnecting to BigQuery...")
    print(f"Project: {PROJECT_ID}")
    print(f"Dataset: {DATASET_ID}")
    client = get_bigquery_client(PROJECT_ID)
    print(" Connected!")

    # Upload setiap file
    results = []
    errors = []

    for filename, table_name in FILE_TABLE_MAPPING.items():
        csv_path = DATA_DIR / filename

        # Cek file ada
        if not csv_path.exists():
            print(f" File not found: {csv_path}")
            errors.append({"table": table_name, "error": "File not found"})
            results.append({
                "table": table_name,
                "status": "error",
                "rows_uploaded": 0,
                "columns": 0,
                "size_mb": 0,
                "elapsed_seconds": 0,
            })
            continue

        try:
            result = upload_csv_to_bigquery(
                client=client,
                csv_path=csv_path,
                table_id=table_name,
                project_id=PROJECT_ID,
                dataset_id=DATASET_ID,
            )
            results.append(result)
        except Exception as e:
            print(f" Error uploading {filename}: {str(e)}")
            errors.append({"table": table_name, "error": str(e)})
            results.append({
                "table": table_name,
                "status": "error",
                "rows_uploaded": 0,
                "columns": 0,
                "size_mb": 0,
                "elapsed_seconds": 0,
            })

    # Tampilkan summary
    verify_upload_summary(results)

    if errors:
        print(f"\n  {len(errors)} errors occurred:")
        for err in errors:
            print(f"   - {err['table']}: {err['error']}")


if __name__ == "__main__":
    main()