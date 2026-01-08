#!/bin/bash
# ============================================================================
# Database Connection Wait Script
# Waits for database to be ready before proceeding
# ============================================================================

set -e

DB_HOST=${DB_HOST:-mysql}
DB_PORT=${DB_PORT:-3306}
DB_USERNAME=${DB_USERNAME:-root}
DB_PASSWORD=${DB_PASSWORD}
TIMEOUT=${DB_WAIT_TIMEOUT:-60}

echo "Waiting for database at ${DB_HOST}:${DB_PORT}..."

counter=0
until mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USERNAME}" -p"${DB_PASSWORD}" -e "SELECT 1" > /dev/null 2>&1; do
    counter=$((counter + 1))
    if [ $counter -gt $TIMEOUT ]; then
        echo "ERROR: Database connection timeout after ${TIMEOUT} seconds"
        exit 1
    fi
    echo "Database not ready yet... waiting (${counter}/${TIMEOUT})"
    sleep 1
done

echo "Database is ready!"
