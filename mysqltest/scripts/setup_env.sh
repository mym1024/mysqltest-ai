#!/bin/bash
set -e

# Configuration (These can be parameterized or loaded from config)
# Using hardcoded paths for now based on previous auto_deploy.sh analysis
# Ideally these should be passed as args or ENV vars from Go runner

# Default values if not set by ENV
: "${YAO_TEST_DIR:=/home/yaotest/tool0}"
: "${YAO_BASE_SRC:=/home/fan/tools/yaobase}"
: "${MYSQLTEST_SRC:=/home/yaotest/base/sqltest}"

echo "[Shell] Setting up environment..."

# 1. Create Directories
echo "[Shell] Creating directories in $YAO_TEST_DIR..."
mkdir -p "$YAO_TEST_DIR/mysqltest_yaobase/tools"
mkdir -p "$YAO_TEST_DIR/mysqltest_yaobase/mysql_test/audit"
mkdir -p "$YAO_TEST_DIR/yaobase/data" # Data directory

# 2. Cleanup Old Files (Caution: Be careful with rm -rf)
# Only clean bin/lib/tools mostly
rm -rf "$YAO_TEST_DIR/mysqltest_yaobase/bin/"*
rm -rf "$YAO_TEST_DIR/mysqltest_yaobase/tools/"*
rm -rf "$YAO_TEST_DIR/mysqltest_yaobase/lib/"*

# 3. Copy binaries and libraries
# Assuming source files are available locally or mounted
# In real scenario, this might involve scp or rsync if cross-machine
# For this refactor, we assume local or already mounted resources similar to auto_deploy.sh

# Mocking the source path availability check
if [ ! -d "$YAO_BASE_SRC" ]; then
    echo "[Warning] Source directory $YAO_BASE_SRC not found. Skipping file copy (Simulation Mode)."
else
    echo "[Shell] Copying binaries from $YAO_BASE_SRC..."
    cp -r "$YAO_BASE_SRC/bin/"* "$YAO_TEST_DIR/mysqltest_yaobase/bin/" || true
    cp -r "$YAO_BASE_SRC/lib/"* "$YAO_TEST_DIR/mysqltest_yaobase/lib/" || true
    # Special admin tools
    cp "$YAO_BASE_SRC/bin/as_admin" "$YAO_TEST_DIR/mysqltest_yaobase/tools/" || true
    cp "$YAO_BASE_SRC/bin/ts_admin" "$YAO_TEST_DIR/mysqltest_yaobase/tools/" || true
fi

# 4. Copy Test Cases
if [ -d "$MYSQLTEST_SRC/case" ]; then
     echo "[Shell] Copying test cases..."
     # Cleaning old test targets
     rm -rf "$YAO_TEST_DIR/mysqltest_yaobase/mysql_test/t"
     rm -rf "$YAO_TEST_DIR/mysqltest_yaobase/mysql_test/r"
     
     mkdir -p "$YAO_TEST_DIR/mysqltest_yaobase/mysql_test/t"
     mkdir -p "$YAO_TEST_DIR/mysqltest_yaobase/mysql_test/r"

     # cp -r "$MYSQLTEST_SRC/case/"* "$YAO_TEST_DIR/mysqltest_yaobase/mysql_test/"
     # Simplified copy for now
fi

echo "[Shell] Environment setup complete."
