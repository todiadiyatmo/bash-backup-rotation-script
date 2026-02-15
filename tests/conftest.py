import subprocess
import os

import pytest


SCRIPTS_DIR = os.path.join(os.path.dirname(__file__), "..")


def run_script(script_name, env_overrides=None, fake_date=None, args=None):
    """Run a backup script with optional faketime and env overrides.

    Args:
        script_name: Name of the script (e.g. "backup-mysql.sh")
        env_overrides: Dict of environment variables to set
        fake_date: Datetime string for faketime (e.g. "2026-02-10 03:00:00")
        args: List of extra arguments to pass to the script

    Returns:
        subprocess.CompletedProcess
    """
    env = os.environ.copy()
    if env_overrides:
        env.update(env_overrides)

    script_path = os.path.join(SCRIPTS_DIR, script_name)
    cmd = []
    if fake_date:
        cmd = ["faketime", fake_date]
    cmd += ["bash", script_path]
    if args:
        cmd += args

    result = subprocess.run(
        cmd, env=env, capture_output=True, text=True, timeout=60
    )
    return result


@pytest.fixture
def backup_dir(tmp_path):
    """Fresh temp directory for each test's backup output."""
    d = tmp_path / "backup"
    d.mkdir()
    return str(d)


@pytest.fixture
def src_dir(tmp_path):
    """Source directory with sample files for zip/rsync tests."""
    d = tmp_path / "source"
    d.mkdir()
    (d / "file1.txt").write_text("hello")
    (d / "file2.txt").write_text("world")
    sub = d / "subdir"
    sub.mkdir()
    (sub / "nested.txt").write_text("nested content")
    return str(d)


@pytest.fixture
def mysql_env(backup_dir):
    """Common env overrides for MySQL backup tests."""
    return {
        "BACKUP_MYSQL_HOST": os.environ.get("MYSQL_HOST", "mysql"),
        "BACKUP_MYSQL_USER": "backup",
        "BACKUP_MYSQL_PASS": "backup",
        "BACKUP_MYSQL_DBNAME": "testdb",
        "BACKUP_MYSQL_DIR": backup_dir,
        "BACKUP_MYSQL_MODE": "local-only",
        "BACKUP_MYSQL_RETENTION_DAILY": "3",
        "BACKUP_MYSQL_RETENTION_WEEKLY": "3",
        "BACKUP_MYSQL_RETENTION_MONTHLY": "3",
    }


@pytest.fixture
def zip_env(backup_dir, src_dir):
    """Common env overrides for zip backup tests."""
    return {
        "BACKUP_ZIP_SRC": src_dir,
        "BACKUP_ZIP_DIR": backup_dir,
        "BACKUP_ZIP_PROJECT": "testproject",
        "BACKUP_ZIP_MODE": "local-only",
        "BACKUP_ZIP_RETENTION_DAILY": "3",
        "BACKUP_ZIP_RETENTION_WEEKLY": "3",
        "BACKUP_ZIP_RETENTION_MONTHLY": "3",
    }
