# MySQL Collation and Charset Converter Script

## Overview

This Bash script automates the process of converting the collation and character set of a MySQL database, including its tables and columns, to a specified target collation. It ensures consistency across the database while handling foreign key constraints properly.

## Features

- Converts the database, tables, and columns to the target character set and collation.
- Handles foreign keys by automatically dropping and restoring them before and after modification.
- Processes all tables in the database or only a specific list provided by the user.
- Skips tables and columns that are already in the target collation to avoid unnecessary operations.
- Logs the current charset and collation of each database, table, and column before modifying them.
- Ensures safe execution by checking the MySQL connection before performing changes.
- Configuration

## Requirements

- MySQL 5.7+ or MariaDB
- Bash shell (Linux/macOS)
- User must have sufficient MySQL privileges (ALTER TABLE, ALTER DATABASE, SELECT, DROP FOREIGN KEY, etc.)

## Configuration

Before running the script, configure the following variables:

DB_USER="your_username"
DB_PASS="your_password"
DB_NAME="your_database"
TARGET_CHARSET="utf8mb4"
TARGET_COLLATION="utf8mb4_unicode_ci"

## Usage

Run the script with one of the following options:

Convert all tables in the database:
```sh
./mysql-collation-converter.sh --all
```
This will scan all tables and update only those that need conversion.

Convert specific tables (comma-separated list)
```sh
./mysql-collation-converter.sh --list table1,table2
```
This will process only the specified tables.

## Example Output

```sh
Database: Current charset: utf8, collation: utf8_general_ci
Database is already using target charset and collation.
Table 'b_iblock': Current collation: utf8_unicode_ci
Updating table 'b_iblock' to collation utf8mb4_unicode_ci...
Dropping foreign key 'b_iblock_ibfk_1' from table 'b_iblock'...
Dropping foreign key 'b_iblock_ibfk_2' from table 'b_iblock'...
Updating table 'b_iblock'...
Restoring foreign key 'b_iblock_ibfk_1'...
Restoring foreign key 'b_iblock_ibfk_2'...
Conversion complete!
```

## How It Works

- Checks the MySQL connection before executing any queries.
- Retrieves the current charset and collation of the database, tables, and columns.
- Drops foreign keys from tables before modifying their structure.
- Converts the database, tables, and columns only if their collation differs from the target.
- Restores foreign keys after successful modification.

## Important Notes

- Backup your database before running the script, especially when dealing with foreign keys.
- Ensure all applications using the database support the target charset before making changes.

## License
This script is released under the MIT License.
