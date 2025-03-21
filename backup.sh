#!/bin/bash

export PGUSER="postgres"
export PGHOST="127.0.0.1"
export PGPORT="5432"
export BACKUP_DIR="/tmp/backup"
export MAX_RETRIES=3  # Maximum number of retries
export RETRY_DELAY=5  # Delay between retries (seconds)
export PGPASSWORD="Abc1234%"

backup_db() {
    local DB=$1
    local TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    local BACKUP_FILE="${BACKUP_DIR}/${DB}_backup_${TIMESTAMP}.backup"

    echo "Starting database backup: $DB --> $BACKUP_FILE"

    local attempt=1  # Ensure `attempt` variable is properly initialized
    while [[ "$attempt" -le "$MAX_RETRIES" ]]; do
        echo "Attempt $attempt to back up..."

        pg_dump -U "$PGUSER" -h "$PGHOST" -p "$PGPORT" -F c -b -v -f "$BACKUP_FILE" "$DB"
        if [[ $? -eq 0 ]]; then
            echo "Backup of $DB completed successfully!"
            return 0  # Exit function if the backup is successful
        else
            echo "Backup of $DB failed, retrying in $RETRY_DELAY seconds..." >&2
            sleep "$RETRY_DELAY"
        fi

        attempt=$((attempt + 1))  # Ensure the attempt count increments
    done

    echo "Backup of $DB failed after $MAX_RETRIES attempts, aborting." >&2
    return 1  # Final failure
}

# Export `backup_db` so it can be recognized by `xargs`
export -f backup_db

# Run backups in parallel
echo "db1 db2 db3" | xargs -n 1 -P 3 bash -c 'backup_db "$1"' _ 

