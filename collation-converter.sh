#!/bin/bash

# configuration
DB_USER=''
DB_PASS=''
DB_NAME=''
TARGET_CHARSET="utf8"
TARGET_COLLATION="utf8_general_ci"

# usage info
show_usage() {
    echo "Usage: $0 --all | --list table1,table2,..."
    exit 1
}

# mysql connecton check
check_mysql_connection() {
    if ! mysql -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME" >/dev/null 2>&1; then
        echo "Error: Could not connect to MySQL database"
        exit 1
    fi
}

# get table list 
get_all_tables() {
    mysql -u"$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -N -e "
        SELECT table_name FROM information_schema.tables
        WHERE table_schema = '$DB_NAME';"
}

# get foreign keys list
get_foreign_keys() {
    local table=$1
    mysql -u"$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -N -e "
        SELECT constraint_name, table_name, column_name, referenced_table_name, referenced_column_name
        FROM information_schema.key_column_usage
        WHERE table_schema = '$DB_NAME' AND table_name = '$table' AND referenced_table_name IS NOT NULL;"
}

# delete foreign keys from table
drop_foreign_keys() {
    local table=$1
    while read -r FK_NAME TABLE_NAME COLUMN_NAME REF_TABLE REF_COLUMN; do
        echo "Dropping foreign key '$FK_NAME' from table '$TABLE_NAME'..."
        mysql -u"$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "
            ALTER TABLE $TABLE_NAME DROP FOREIGN KEY $FK_NAME;"
    done < <(get_foreign_keys "$table")
}

# restore foreign keys in table
restore_foreign_keys() {
    local table=$1
    while read -r FK_NAME TABLE_NAME COLUMN_NAME REF_TABLE REF_COLUMN; do
        echo "Restoring foreign key '$FK_NAME' on '$TABLE_NAME.$COLUMN_NAME' -> '$REF_TABLE.$REF_COLUMN'..."
        mysql -u"$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "
            ALTER TABLE $TABLE_NAME ADD CONSTRAINT $FK_NAME FOREIGN KEY ($COLUMN_NAME)
            REFERENCES $REF_TABLE($REF_COLUMN) ON DELETE CASCADE ON UPDATE CASCADE;"
    done < <(get_foreign_keys "$table")
}

# table encoding convert 
convert_table() {
    local table=$1
    drop_foreign_keys "$table"  # Удаляем внешние ключи
    echo "Updating table '$table' to collation $TARGET_COLLATION..."
    mysql -u"$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "
        ALTER TABLE $table CONVERT TO CHARACTER SET $TARGET_CHARSET COLLATE $TARGET_COLLATION;"
    restore_foreign_keys "$table"  # Восстанавливаем внешние ключи
}

# main table processing
process_tables() {
    for table in $1; do
        convert_table "$table"
    done
}

# Обработка параметров
if [[ $# -eq 0 ]]; then
    show_usage
fi

check_mysql_connection

case "$1" in
    --all)
        TABLES=$(get_all_tables)
        process_tables "$TABLES"
        ;;
    --list)
        if [[ -z "$2" ]]; then
            show_usage
        fi
        IFS=',' read -r -a TABLES <<< "$2"
        process_tables "${TABLES[@]}"
        ;;
    *)
        show_usage
        ;;
esac
