"""Test that the correct backup type (daily/weekly/monthly) is selected based on date.

Uses backup-file-zip.sh in local-only mode since it has consistent filename patterns
and doesn't require MySQL.
"""
import os

from conftest import run_script


def test_weekday_creates_daily_backup(zip_env, backup_dir):
    """Tuesday Feb 10 2026 -> daily backup."""
    run_script("backup-file-zip.sh", fake_date="2026-02-10 03:00:00", env_overrides=zip_env)
    files = os.listdir(backup_dir)
    daily_files = [f for f in files if "daily" in f]
    assert len(daily_files) == 1, f"Expected 1 daily file, got: {files}"
    assert daily_files[0].endswith(".zip")


def test_sunday_creates_weekly_backup(zip_env, backup_dir):
    """Sunday Feb 15 2026 -> weekly backup."""
    run_script("backup-file-zip.sh", fake_date="2026-02-15 03:00:00", env_overrides=zip_env)
    files = os.listdir(backup_dir)
    weekly_files = [f for f in files if "weekly" in f]
    assert len(weekly_files) == 1, f"Expected 1 weekly file, got: {files}"


def test_first_of_month_creates_monthly_backup(zip_env, backup_dir):
    """Wednesday Jan 1 2025 -> monthly backup (day-of-month == 1)."""
    run_script("backup-file-zip.sh", fake_date="2025-01-01 03:00:00", env_overrides=zip_env)
    files = os.listdir(backup_dir)
    monthly_files = [f for f in files if "monthly" in f]
    assert len(monthly_files) == 1, f"Expected 1 monthly file, got: {files}"


def test_monthly_takes_priority_over_weekly_on_first_sunday(zip_env, backup_dir):
    """Sunday March 1 2026 -> monthly (not weekly), because day-of-month==1 is checked first."""
    run_script("backup-file-zip.sh", fake_date="2026-03-01 03:00:00", env_overrides=zip_env)
    files = os.listdir(backup_dir)
    monthly_files = [f for f in files if "monthly" in f]
    weekly_files = [f for f in files if "weekly" in f]
    assert len(monthly_files) == 1, f"Expected monthly file, got: {files}"
    assert len(weekly_files) == 0, "Weekly file should not exist when monthly takes priority"


def test_sunday_with_weekly_disabled_creates_nothing(backup_dir, src_dir):
    """Known bug: Sunday + BACKUP_WEEKLY=false -> no backup at all.

    The daily check uses DAYWEEK -lt 7 which is false on Sunday (day 7),
    so neither weekly nor daily backup runs.
    """
    env = {
        "BACKUP_ZIP_SRC": src_dir,
        "BACKUP_ZIP_DIR": backup_dir,
        "BACKUP_ZIP_PROJECT": "testproject",
        "BACKUP_ZIP_MODE": "local-only",
        "BACKUP_ZIP_WEEKLY": "false",
        "BACKUP_ZIP_DAILY": "true",
        "BACKUP_ZIP_MONTHLY": "false",
        "BACKUP_ZIP_RETENTION_DAILY": "3",
        "BACKUP_ZIP_RETENTION_WEEKLY": "3",
        "BACKUP_ZIP_RETENTION_MONTHLY": "3",
    }
    run_script("backup-file-zip.sh", fake_date="2026-02-15 03:00:00", env_overrides=env)
    files = [f for f in os.listdir(backup_dir) if f.endswith(".zip")]
    # Bug: no backup file is created on Sunday when weekly is disabled
    assert len(files) == 0, (
        "Known bug: Sunday with weekly disabled produces no backup. "
        f"Got: {files}"
    )


def test_all_backup_types_disabled_creates_nothing(backup_dir, src_dir):
    """No backup when all type flags are false."""
    env = {
        "BACKUP_ZIP_SRC": src_dir,
        "BACKUP_ZIP_DIR": backup_dir,
        "BACKUP_ZIP_PROJECT": "testproject",
        "BACKUP_ZIP_MODE": "local-only",
        "BACKUP_ZIP_DAILY": "false",
        "BACKUP_ZIP_WEEKLY": "false",
        "BACKUP_ZIP_MONTHLY": "false",
        "BACKUP_ZIP_RETENTION_DAILY": "3",
        "BACKUP_ZIP_RETENTION_WEEKLY": "3",
        "BACKUP_ZIP_RETENTION_MONTHLY": "3",
    }
    run_script("backup-file-zip.sh", fake_date="2026-02-10 03:00:00", env_overrides=env)
    files = [f for f in os.listdir(backup_dir) if f.endswith(".zip")]
    assert len(files) == 0
