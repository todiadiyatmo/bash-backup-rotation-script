# Tests

Integration tests for the bash backup rotation scripts. Tests run inside Docker containers with `faketime` for date simulation and a real MySQL 8.0 instance.

## Requirements

- Docker
- Docker Compose

## Running Tests

```bash
# From project root
make test          # Build containers, run all tests, tear down
make test-down     # Force tear down containers and volumes
make lint          # Run shellcheck on all scripts
```

## How It Works

1. `docker-compose.test.yml` starts two containers:
   - **mysql** -- MySQL 8.0 with a `testdb` database and `backup` user
   - **test-runner** -- Debian with rsync, zip, gzip, faketime, mysql-client, and pytest
2. pytest discovers and runs all `test_*.py` files
3. Each test uses `faketime` to simulate a specific date, then runs the actual backup script with env var overrides pointing to temporary directories
4. Assertions check that the correct files were created, deleted, or retained

## Test Structure

```
tests/
  conftest.py              # Shared fixtures: run_script(), backup_dir, src_dir, mysql_env, zip_env
  test_schedule.py         # Schedule selection logic (daily/weekly/monthly)
  test_backup_mysql.py     # MySQL backup with real database
  test_backup_zip.py       # File zip backup
  test_backup_rsync.py     # Rsync bucket rotation
  test_retention.py        # File retention/rotation across multiple dates
  expected-results.csv     # Full test matrix in CSV format
```

## Test Files

### test_schedule.py (6 tests)

Tests which backup type is selected based on the simulated date.

| Test | Fake Date | Expected |
|------|-----------|----------|
| test_weekday_creates_daily_backup | 2026-02-10 (Tue) | File with "daily" in name |
| test_sunday_creates_weekly_backup | 2026-02-15 (Sun) | File with "weekly" in name |
| test_first_of_month_creates_monthly_backup | 2025-01-01 (1st) | File with "monthly" in name |
| test_monthly_takes_priority_over_weekly_on_first_sunday | 2026-03-01 (Sun+1st) | "monthly" exists, no "weekly" |
| test_sunday_with_weekly_disabled_creates_nothing | 2026-02-15 (Sun) | 0 files (known bug) |
| test_all_backup_types_disabled_creates_nothing | 2026-02-10 | 0 files |

### test_backup_mysql.py (6 tests)

Tests MySQL backup against a real MySQL 8.0 database running in Docker.

| Test | Fake Date | Expected |
|------|-----------|----------|
| test_local_only_creates_gzipped_dump | 2026-02-10 (Tue) | `testdb-sql-daily-20260210.sql.gz` exists |
| test_dump_contains_valid_sql | 2026-02-10 (Tue) | File contains mysqldump output |
| test_local_only_filename_uses_sql_not_mysql | 2026-02-10 (Tue) | File has `-sql-` not `-mysql-` (known bug) |
| test_weekly_mysql_backup | 2026-02-15 (Sun) | `*-weekly-*.sql.gz` created |
| test_monthly_mysql_backup | 2026-03-01 (1st) | `*-monthly-*.sql.gz` created |
| test_backup_skipped_when_retention_zero | 2026-02-10 (Tue) | 0 files created |

### test_backup_zip.py (5 tests)

Tests file zip backup using a temporary source directory with sample files.

| Test | Fake Date | Expected |
|------|-----------|----------|
| test_local_only_creates_zip | 2026-02-10 (Tue) | `testproject-htdocs-daily-20260210.zip` exists |
| test_zip_contains_source_files | 2026-02-10 (Tue) | Zip contains file1.txt, file2.txt |
| test_zip_weekly_backup | 2026-02-15 (Sun) | `*-weekly-*.zip` created |
| test_zip_monthly_backup | 2026-03-01 (1st) | `*-monthly-*.zip` created |
| test_zip_backup_skipped_when_retention_zero | 2026-02-10 | 0 files created |

### test_backup_rsync.py (5 tests)

Tests rsync bucket rotation logic by running backups on different simulated days.

| Test | Fake Date | Expected |
|------|-----------|----------|
| test_daily_backup_creates_bucket_directory | 2026-02-10 (day 41) | `daily/2/` (41 % 3 = 2) with source files |
| test_weekly_backup_creates_weekly_bucket | 2026-02-10 (week 7) | `weekly/1/` (7 % 2 = 1) with source files |
| test_different_days_use_different_buckets | Feb 10-12 | `daily/0`, `daily/1`, `daily/2` all exist |
| test_bucket_overwrites_old_content | Feb 10 + Feb 12 | Same bucket (% 2 = 1), content updated |
| test_rsync_preserves_subdirectories | 2026-02-10 | `subdir/nested.txt` inside bucket |

### test_retention.py (7 tests)

Tests file rotation by running backup scripts across multiple simulated dates and verifying the correct number of files survive.

| Test | Dates | Retention | Expected |
|------|-------|-----------|----------|
| test_keeps_n_newest_daily_files | 5 weekdays (Mon-Fri) | daily=3 | 3 newest remain, 2 oldest deleted |
| test_retention_1_keeps_only_newest | 3 weekdays (Mon-Wed) | daily=1 | Only Wed file survives |
| test_weekly_files_not_affected_by_daily_retention | Sun + 4 weekdays | daily=2 | 1 weekly + 2 daily remain |
| test_weekly_retention_keeps_n_newest | 4 Sundays | weekly=2 | 2 newest weekly files remain |
| test_monthly_retention_keeps_n_newest | 4 months (1st of each) | monthly=2 | 2 newest monthly files remain |
| test_monthly_files_not_affected_by_daily_or_weekly | 1st + Sun + weekdays | daily=1, weekly=1 | Monthly file untouched |
| test_local_only_retention_does_not_clean_sql_files | 5 weekdays | daily=2 | All 5 remain (known MySQL bug) |

## Known Bugs Documented by Tests

### 1. Sunday Gap (test_schedule.py)

When `BACKUP_WEEKLY=false` on a Sunday, no backup runs at all. The daily condition checks `DAYWEEK -lt 7`, which is false on Sunday (day 7). Neither weekly nor daily backup triggers.

### 2. Filename Mismatch in backup-mysql.sh (test_backup_mysql.py, test_retention.py)

`local_only()` creates files with `-sql-` in the name (e.g. `testdb-sql-daily-20260210.sql.gz`), but the retention cleanup greps for `mysql`. Since `-sql-` does not contain `mysql`, files created by `local_only` are never cleaned up and accumulate forever.

Note: `local_remote()` creates files with `-mysql-` in the name, so retention works correctly in that mode.

## Adding New Tests

1. Add test functions to the appropriate `test_*.py` file, or create a new `test_*.py` file
2. Use the `run_script()` helper from `conftest.py` to execute scripts with faketime and env overrides
3. Use `backup_dir`, `src_dir`, `mysql_env`, `zip_env` fixtures for test setup
4. Update `expected-results.csv` with the new test entry
5. Run `make test` to verify


## Known Bug

  Tests by category:

  ┌────────────────┬───────┬────────────────────────────────────────────────────────────────────────┐
  │    Category    │ Count │                             What's covered                             │
  ├────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
  │ MySQL backup   │ 6     │ File creation, SQL validity, filename bug, weekly/monthly, retention=0 │
  ├────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
  │ Rsync rotation │ 5     │ Bucket math, --weekly flag, overwrite, subdirs                         │
  ├────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
  │ Zip backup     │ 5     │ File creation, archive content, weekly/monthly, retention=0            │
  ├────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
  │ Retention      │ 7     │ Daily/weekly/monthly rotation, cross-type isolation, MySQL bug         │
  ├────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
  │ Schedule       │ 6     │ Daily/weekly/monthly selection, priority, disabled flags, Sunday bug   │
  ├────────────────┼───────┼────────────────────────────────────────────────────────────────────────┤
  │ Total          │ 29    │ All pass                                                               │
  └────────────────┴───────┴────────────────────────────────────────────────────────────────────────┘

  3 known bugs documented by tests (#3, #23, #28):

  ┌──────────────────────────────────────┬─────────┬───────────────────────────────────────────────────────────────────────┐
  │                 Bug                  │ Test #  │                                Impact                                 │
  ├──────────────────────────────────────┼─────────┼───────────────────────────────────────────────────────────────────────┤
  │ Filename mismatch (-sql- vs -mysql-) │ #3, #23 │ local_only MySQL backups never get cleaned up by retention            │
  ├──────────────────────────────────────┼─────────┼───────────────────────────────────────────────────────────────────────┤
  │ Sunday gap                           │ #28     │ No backup on Sunday when BACKUP_WEEKLY=false even if daily is enabled │
  └──────────────────────────────────────┴─────────┴───────────────────────────────────────────────────────────────────────┘