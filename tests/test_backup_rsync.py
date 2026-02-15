"""Integration tests for backup-rsync.sh bucket rotation."""
import os

from conftest import run_script


def test_daily_backup_creates_bucket_directory(backup_dir, src_dir):
    """Daily rsync creates the correct bucket directory structure."""
    env = {
        "BACKUP_RSYNC_SOURCE": src_dir + "/",
        "BACKUP_RSYNC_DEST": backup_dir,
        "BACKUP_RSYNC_DAILY_COUNT": "3",
    }
    # Feb 10 2026: day-of-year = 41, 41 % 3 = 2
    result = run_script(
        "backup-rsync.sh",
        fake_date="2026-02-10 03:00:00",
        env_overrides=env,
    )
    assert result.returncode == 0, f"Script failed: {result.stderr}"
    assert os.path.isdir(os.path.join(backup_dir, "daily", "2"))
    assert os.path.exists(os.path.join(backup_dir, "daily", "2", "file1.txt"))
    assert os.path.exists(os.path.join(backup_dir, "daily", "2", "file2.txt"))


def test_weekly_backup_creates_weekly_bucket(backup_dir, src_dir):
    """--weekly flag creates weekly bucket structure."""
    env = {
        "BACKUP_RSYNC_SOURCE": src_dir + "/",
        "BACKUP_RSYNC_DEST": backup_dir,
        "BACKUP_RSYNC_WEEKLY_COUNT": "2",
    }
    # Feb 10 2026: week 7, 7 % 2 = 1
    result = run_script(
        "backup-rsync.sh",
        fake_date="2026-02-10 03:00:00",
        env_overrides=env,
        args=["--weekly"],
    )
    assert result.returncode == 0, f"Script failed: {result.stderr}"
    assert os.path.isdir(os.path.join(backup_dir, "weekly", "1"))
    assert os.path.exists(os.path.join(backup_dir, "weekly", "1", "file1.txt"))


def test_different_days_use_different_buckets(backup_dir, src_dir):
    """Consecutive days should rotate across buckets."""
    env = {
        "BACKUP_RSYNC_SOURCE": src_dir + "/",
        "BACKUP_RSYNC_DEST": backup_dir,
        "BACKUP_RSYNC_DAILY_COUNT": "3",
    }

    # Run backups on 3 consecutive days to fill all buckets
    # Day 41 (Feb 10) % 3 = 2
    # Day 42 (Feb 11) % 3 = 0
    # Day 43 (Feb 12) % 3 = 1
    for date in ["2026-02-10 03:00:00", "2026-02-11 03:00:00", "2026-02-12 03:00:00"]:
        run_script("backup-rsync.sh", fake_date=date, env_overrides=env)

    # All 3 buckets should exist
    for bucket in ["0", "1", "2"]:
        bucket_path = os.path.join(backup_dir, "daily", bucket)
        assert os.path.isdir(bucket_path), f"Bucket {bucket} should exist"
        assert os.path.exists(os.path.join(bucket_path, "file1.txt"))


def test_bucket_overwrites_old_content(backup_dir, src_dir):
    """Same bucket on different days overwrites previous content."""
    env = {
        "BACKUP_RSYNC_SOURCE": src_dir + "/",
        "BACKUP_RSYNC_DEST": backup_dir,
        "BACKUP_RSYNC_DAILY_COUNT": "2",
    }

    # Day 41 (Feb 10) % 2 = 1
    run_script("backup-rsync.sh", fake_date="2026-02-10 03:00:00", env_overrides=env)
    assert os.path.exists(os.path.join(backup_dir, "daily", "1", "file1.txt"))

    # Day 43 (Feb 12) % 2 = 1 (same bucket)
    # Modify source content
    with open(os.path.join(src_dir, "file1.txt"), "w") as f:
        f.write("updated content")

    run_script("backup-rsync.sh", fake_date="2026-02-12 03:00:00", env_overrides=env)

    # Bucket should contain updated content
    with open(os.path.join(backup_dir, "daily", "1", "file1.txt")) as f:
        content = f.read()
    assert content == "updated content"


def test_rsync_preserves_subdirectories(backup_dir, src_dir):
    """Rsync should preserve the directory structure including subdirs."""
    env = {
        "BACKUP_RSYNC_SOURCE": src_dir + "/",
        "BACKUP_RSYNC_DEST": backup_dir,
        "BACKUP_RSYNC_DAILY_COUNT": "2",
    }
    run_script("backup-rsync.sh", fake_date="2026-02-10 03:00:00", env_overrides=env)

    bucket = os.path.join(backup_dir, "daily", "1")
    assert os.path.exists(os.path.join(bucket, "subdir", "nested.txt"))
