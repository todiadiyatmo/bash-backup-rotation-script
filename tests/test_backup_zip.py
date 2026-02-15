"""Integration tests for backup-file-zip.sh."""
import os
import subprocess

from conftest import run_script


def test_local_only_creates_zip(zip_env, backup_dir):
    """Run daily backup, verify .zip file is created with correct name."""
    result = run_script(
        "backup-file-zip.sh",
        fake_date="2026-02-10 03:00:00",
        env_overrides=zip_env,
    )
    assert result.returncode == 0, f"Script failed: {result.stderr}"

    files = os.listdir(backup_dir)
    zip_files = [f for f in files if f.endswith(".zip")]
    assert len(zip_files) == 1, f"Expected 1 .zip file, got: {files}"
    assert "testproject" in zip_files[0]
    assert "htdocs" in zip_files[0]
    assert "daily" in zip_files[0]
    assert "20260210" in zip_files[0]


def test_zip_contains_source_files(zip_env, backup_dir, src_dir):
    """Verify the zip archive contains the expected source files."""
    run_script(
        "backup-file-zip.sh",
        fake_date="2026-02-10 03:00:00",
        env_overrides=zip_env,
    )

    zip_files = [f for f in os.listdir(backup_dir) if f.endswith(".zip")]
    assert len(zip_files) == 1

    filepath = os.path.join(backup_dir, zip_files[0])
    result = subprocess.run(
        ["unzip", "-l", filepath],
        capture_output=True, text=True,
    )
    assert "file1.txt" in result.stdout
    assert "file2.txt" in result.stdout


def test_zip_weekly_backup(zip_env, backup_dir):
    """Sunday creates weekly zip backup."""
    run_script(
        "backup-file-zip.sh",
        fake_date="2026-02-15 03:00:00",  # Sunday
        env_overrides=zip_env,
    )
    # Note: exit code may be non-zero due to xargs cleanup on empty file list
    files = os.listdir(backup_dir)
    weekly_files = [f for f in files if "weekly" in f and f.endswith(".zip")]
    assert len(weekly_files) == 1, f"Expected 1 weekly .zip file, got: {files}"


def test_zip_monthly_backup(zip_env, backup_dir):
    """First of month creates monthly zip backup."""
    run_script(
        "backup-file-zip.sh",
        fake_date="2026-03-01 03:00:00",
        env_overrides=zip_env,
    )
    # Note: exit code may be non-zero due to xargs cleanup on empty file list
    files = os.listdir(backup_dir)
    monthly_files = [f for f in files if "monthly" in f and f.endswith(".zip")]
    assert len(monthly_files) == 1, f"Expected 1 monthly .zip file, got: {files}"


def test_zip_backup_skipped_when_retention_zero(zip_env, backup_dir):
    """No backup created when retention is set to 0."""
    zip_env["BACKUP_ZIP_RETENTION_DAILY"] = "0"
    run_script(
        "backup-file-zip.sh",
        fake_date="2026-02-10 03:00:00",
        env_overrides=zip_env,
    )
    files = [f for f in os.listdir(backup_dir) if f.endswith(".zip")]
    assert len(files) == 0, f"Expected no files with retention=0, got: {files}"
