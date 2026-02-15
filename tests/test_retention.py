"""Test retention/rotation by running backups across multiple simulated dates.

Uses backup-file-zip.sh for retention tests because its filename pattern
(project-htdocs-TYPE-DATE.zip) is consistently matched by the retention
grep logic (greps for project name + htdocs + type).

Note: backup-mysql.sh local_only mode has a known bug where the filename
uses -sql- but retention greps for 'mysql', so retention never matches.
"""
import os

from conftest import run_script


class TestDailyRetention:
    """Test daily backup file rotation."""

    def test_keeps_n_newest_daily_files(self, backup_dir, src_dir):
        """Run daily backup on 5 weekdays with RETENTION=3.
        Only the 3 newest .zip files should remain.
        """
        env = {
            "BACKUP_ZIP_SRC": src_dir,
            "BACKUP_ZIP_DIR": backup_dir,
            "BACKUP_ZIP_PROJECT": "testproject",
            "BACKUP_ZIP_MODE": "local-only",
            "BACKUP_ZIP_RETENTION_DAILY": "3",
            "BACKUP_ZIP_RETENTION_WEEKLY": "3",
            "BACKUP_ZIP_RETENTION_MONTHLY": "3",
        }

        # Monday through Friday
        dates = [
            "2026-02-09 03:00:00",  # Monday
            "2026-02-10 03:00:00",  # Tuesday
            "2026-02-11 03:00:00",  # Wednesday
            "2026-02-12 03:00:00",  # Thursday
            "2026-02-13 03:00:00",  # Friday
        ]
        for d in dates:
            run_script("backup-file-zip.sh", fake_date=d, env_overrides=env)

        daily_files = sorted(f for f in os.listdir(backup_dir) if "daily" in f)
        assert len(daily_files) == 3, (
            f"Expected 3 daily files (retention=3), got {len(daily_files)}: {daily_files}"
        )

        # The 3 newest should survive
        assert any("20260211" in f for f in daily_files), f"Feb 11 file missing: {daily_files}"
        assert any("20260212" in f for f in daily_files), f"Feb 12 file missing: {daily_files}"
        assert any("20260213" in f for f in daily_files), f"Feb 13 file missing: {daily_files}"

        # The 2 oldest should be deleted
        assert not any("20260209" in f for f in daily_files), f"Feb 9 should be deleted: {daily_files}"
        assert not any("20260210" in f for f in daily_files), f"Feb 10 should be deleted: {daily_files}"

    def test_retention_1_keeps_only_newest(self, backup_dir, src_dir):
        """With RETENTION=1, only the most recent daily file survives."""
        env = {
            "BACKUP_ZIP_SRC": src_dir,
            "BACKUP_ZIP_DIR": backup_dir,
            "BACKUP_ZIP_PROJECT": "testproject",
            "BACKUP_ZIP_MODE": "local-only",
            "BACKUP_ZIP_RETENTION_DAILY": "1",
            "BACKUP_ZIP_RETENTION_WEEKLY": "3",
            "BACKUP_ZIP_RETENTION_MONTHLY": "3",
        }

        for d in ["2026-02-09 03:00:00", "2026-02-10 03:00:00", "2026-02-11 03:00:00"]:
            run_script("backup-file-zip.sh", fake_date=d, env_overrides=env)

        daily_files = [f for f in os.listdir(backup_dir) if "daily" in f]
        assert len(daily_files) == 1, f"Expected 1 daily file, got: {daily_files}"
        assert "20260211" in daily_files[0]


class TestWeeklyRetention:
    """Test weekly backup file rotation."""

    def test_weekly_files_not_affected_by_daily_retention(self, backup_dir, src_dir):
        """Daily retention should only delete daily files, not weekly ones."""
        env = {
            "BACKUP_ZIP_SRC": src_dir,
            "BACKUP_ZIP_DIR": backup_dir,
            "BACKUP_ZIP_PROJECT": "testproject",
            "BACKUP_ZIP_MODE": "local-only",
            "BACKUP_ZIP_RETENTION_DAILY": "2",
            "BACKUP_ZIP_RETENTION_WEEKLY": "3",
            "BACKUP_ZIP_RETENTION_MONTHLY": "3",
        }

        # Create a weekly backup on Sunday
        run_script("backup-file-zip.sh", fake_date="2026-02-08 03:00:00", env_overrides=env)

        # Run 4 daily backups (Mon-Thu)
        for d in [
            "2026-02-09 03:00:00",
            "2026-02-10 03:00:00",
            "2026-02-11 03:00:00",
            "2026-02-12 03:00:00",
        ]:
            run_script("backup-file-zip.sh", fake_date=d, env_overrides=env)

        weekly_files = [f for f in os.listdir(backup_dir) if "weekly" in f]
        daily_files = [f for f in os.listdir(backup_dir) if "daily" in f]

        assert len(weekly_files) == 1, f"Weekly file should survive: {weekly_files}"
        assert len(daily_files) == 2, f"Expected 2 daily files (retention=2): {daily_files}"

    def test_weekly_retention_keeps_n_newest(self, backup_dir, src_dir):
        """Run weekly backup across 4 Sundays with RETENTION=2."""
        env = {
            "BACKUP_ZIP_SRC": src_dir,
            "BACKUP_ZIP_DIR": backup_dir,
            "BACKUP_ZIP_PROJECT": "testproject",
            "BACKUP_ZIP_MODE": "local-only",
            "BACKUP_ZIP_RETENTION_DAILY": "3",
            "BACKUP_ZIP_RETENTION_WEEKLY": "2",
            "BACKUP_ZIP_RETENTION_MONTHLY": "3",
        }

        # 4 consecutive Sundays
        sundays = [
            "2026-02-01 03:00:00",
            "2026-02-08 03:00:00",
            "2026-02-15 03:00:00",
            "2026-02-22 03:00:00",
        ]
        for d in sundays:
            run_script("backup-file-zip.sh", fake_date=d, env_overrides=env)

        weekly_files = sorted(f for f in os.listdir(backup_dir) if "weekly" in f)
        assert len(weekly_files) == 2, (
            f"Expected 2 weekly files (retention=2), got: {weekly_files}"
        )
        # Newest 2 should survive
        assert any("20260215" in f for f in weekly_files)
        assert any("20260222" in f for f in weekly_files)


class TestMonthlyRetention:
    """Test monthly backup file rotation."""

    def test_monthly_retention_keeps_n_newest(self, backup_dir, src_dir):
        """Run monthly backups on 1st of 4 months with RETENTION=2."""
        env = {
            "BACKUP_ZIP_SRC": src_dir,
            "BACKUP_ZIP_DIR": backup_dir,
            "BACKUP_ZIP_PROJECT": "testproject",
            "BACKUP_ZIP_MODE": "local-only",
            "BACKUP_ZIP_RETENTION_DAILY": "3",
            "BACKUP_ZIP_RETENTION_WEEKLY": "3",
            "BACKUP_ZIP_RETENTION_MONTHLY": "2",
        }

        # 1st of 4 consecutive months
        firsts = [
            "2026-01-01 03:00:00",
            "2026-02-01 03:00:00",
            "2026-03-01 03:00:00",
            "2026-04-01 03:00:00",
        ]
        for d in firsts:
            run_script("backup-file-zip.sh", fake_date=d, env_overrides=env)

        monthly_files = sorted(f for f in os.listdir(backup_dir) if "monthly" in f)
        assert len(monthly_files) == 2, (
            f"Expected 2 monthly files (retention=2), got: {monthly_files}"
        )
        assert any("20260301" in f for f in monthly_files)
        assert any("20260401" in f for f in monthly_files)

    def test_monthly_files_not_affected_by_daily_or_weekly(self, backup_dir, src_dir):
        """Monthly files should survive daily and weekly retention cleanup."""
        env = {
            "BACKUP_ZIP_SRC": src_dir,
            "BACKUP_ZIP_DIR": backup_dir,
            "BACKUP_ZIP_PROJECT": "testproject",
            "BACKUP_ZIP_MODE": "local-only",
            "BACKUP_ZIP_RETENTION_DAILY": "1",
            "BACKUP_ZIP_RETENTION_WEEKLY": "1",
            "BACKUP_ZIP_RETENTION_MONTHLY": "3",
        }

        # Monthly on 1st
        run_script("backup-file-zip.sh", fake_date="2026-03-01 03:00:00", env_overrides=env)
        # Weekly on Sunday
        run_script("backup-file-zip.sh", fake_date="2026-03-08 03:00:00", env_overrides=env)
        # Daily on weekdays
        run_script("backup-file-zip.sh", fake_date="2026-03-09 03:00:00", env_overrides=env)
        run_script("backup-file-zip.sh", fake_date="2026-03-10 03:00:00", env_overrides=env)

        monthly_files = [f for f in os.listdir(backup_dir) if "monthly" in f]
        assert len(monthly_files) == 1, f"Monthly file should survive: {monthly_files}"


class TestMysqlRetentionBug:
    """Document the known retention bug in backup-mysql.sh local_only mode."""

    def test_local_only_retention_does_not_clean_sql_files(self, mysql_env, backup_dir):
        """Known bug: local_only creates -sql- files but retention greps 'mysql'.

        Files created by local_only have the pattern: testdb-sql-daily-YYYYMMDD.sql.gz
        But retention does: ls -t | grep testdb | grep mysql | grep daily
        Since 'mysql' is not in '-sql-', retention never matches and files accumulate.
        """
        dates = [
            "2026-02-09 03:00:00",  # Monday
            "2026-02-10 03:00:00",  # Tuesday
            "2026-02-11 03:00:00",  # Wednesday
            "2026-02-12 03:00:00",  # Thursday
            "2026-02-13 03:00:00",  # Friday
        ]
        mysql_env["BACKUP_MYSQL_RETENTION_DAILY"] = "2"

        for d in dates:
            run_script("backup-mysql.sh", fake_date=d, env_overrides=mysql_env)

        daily_files = [f for f in os.listdir(backup_dir) if "daily" in f]
        # Bug: all 5 files remain because retention grep doesn't match -sql- pattern
        assert len(daily_files) == 5, (
            f"Known bug: all files should remain because retention doesn't match "
            f"-sql- pattern. Got {len(daily_files)}: {daily_files}"
        )
