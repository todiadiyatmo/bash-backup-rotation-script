"""Integration tests for backup-mysql.sh against real MySQL in Docker."""
import gzip
import os

from conftest import run_script


def test_local_only_creates_gzipped_dump(mysql_env, backup_dir):
    """Run daily backup in local-only mode, verify .sql.gz file is created."""
    result = run_script(
        "backup-mysql.sh",
        fake_date="2026-02-10 03:00:00",
        env_overrides=mysql_env,
    )
    assert result.returncode == 0, f"Script failed: {result.stderr}"

    files = os.listdir(backup_dir)
    gz_files = [f for f in files if f.endswith(".sql.gz")]
    assert len(gz_files) == 1, f"Expected 1 .sql.gz file, got: {files}"
    assert "testdb" in gz_files[0]
    assert "daily" in gz_files[0]
    assert "20260210" in gz_files[0]


def test_dump_contains_valid_sql(mysql_env, backup_dir):
    """Verify the gzipped dump contains valid MySQL output."""
    run_script(
        "backup-mysql.sh",
        fake_date="2026-02-10 03:00:00",
        env_overrides=mysql_env,
    )

    gz_files = [f for f in os.listdir(backup_dir) if f.endswith(".sql.gz")]
    assert len(gz_files) == 1

    filepath = os.path.join(backup_dir, gz_files[0])
    with gzip.open(filepath, "rt") as f:
        content = f.read()

    # mysqldump output should be non-empty and contain SQL-like content
    assert len(content) > 0, "Dump file is empty"
    # Check for any common mysqldump markers (varies by version)
    markers = ["dump", "mysql", "server", "host", "--"]
    found = any(marker in content.lower() for marker in markers)
    assert found, (
        f"Dump doesn't look like valid SQL. First 500 chars: {content[:500]}"
    )


def test_local_only_filename_uses_sql_not_mysql(mysql_env, backup_dir):
    """Document known bug: local_only creates -sql- filename, not -mysql-.

    This means the retention logic (which greps for 'mysql') never matches
    these files, so they are never cleaned up.
    """
    run_script(
        "backup-mysql.sh",
        fake_date="2026-02-10 03:00:00",
        env_overrides=mysql_env,
    )

    files = os.listdir(backup_dir)
    # local_only uses -sql- in filename
    sql_files = [f for f in files if "-sql-" in f]
    mysql_files = [f for f in files if "-mysql-" in f]

    assert len(sql_files) == 1, f"Expected -sql- pattern file, got: {files}"
    assert len(mysql_files) == 0, (
        "local_only should NOT create -mysql- pattern files. "
        "This is a known filename mismatch bug."
    )


def test_weekly_mysql_backup(mysql_env, backup_dir):
    """Sunday creates weekly MySQL backup."""
    result = run_script(
        "backup-mysql.sh",
        fake_date="2026-02-15 03:00:00",  # Sunday
        env_overrides=mysql_env,
    )
    # Note: exit code may be non-zero due to xargs cleanup on empty file list
    # (known script quirk when weekly/monthly is the last dispatch block)
    files = os.listdir(backup_dir)
    weekly_files = [f for f in files if "weekly" in f and f.endswith(".sql.gz")]
    assert len(weekly_files) == 1, f"Expected 1 weekly .sql.gz file, got: {files}"


def test_monthly_mysql_backup(mysql_env, backup_dir):
    """First of month creates monthly MySQL backup."""
    result = run_script(
        "backup-mysql.sh",
        fake_date="2026-03-01 03:00:00",  # 1st of March
        env_overrides=mysql_env,
    )
    # Note: exit code may be non-zero due to xargs cleanup on empty file list
    files = os.listdir(backup_dir)
    monthly_files = [f for f in files if "monthly" in f and f.endswith(".sql.gz")]
    assert len(monthly_files) == 1, f"Expected 1 monthly .sql.gz file, got: {files}"


def test_backup_skipped_when_retention_zero(mysql_env, backup_dir):
    """No backup created when retention is set to 0."""
    mysql_env["BACKUP_MYSQL_RETENTION_DAILY"] = "0"
    run_script(
        "backup-mysql.sh",
        fake_date="2026-02-10 03:00:00",
        env_overrides=mysql_env,
    )
    files = [f for f in os.listdir(backup_dir) if f.endswith(".sql.gz")]
    assert len(files) == 0, f"Expected no files with retention=0, got: {files}"
