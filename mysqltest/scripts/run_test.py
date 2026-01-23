#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import sys
import os
import argparse
import json

# Mocking common library import if not present
try:
    from common import *
except ImportError:
    def info(msg): print("[INFO] " + msg)
    def force_info(msg): print("[INFO] " + msg)
    def sh(cmd): 
        print("[EXEC] " + cmd)
        return 0

def load_config_if_needed():
    # Helper to load config.json if env vars are missing
    # Assuming config.json is in parent directory of this script's directory
    # i.e. ../../config.json relative to script execution?
    # Or just ../config.json if script is in scripts/ folder
    
    # Check if critical env vars are missing
    if not os.environ.get('OBMYSQL_PORT') or not os.environ.get('OBMYSQL_MS0'):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        config_path = os.path.join(script_dir, '../config.json')
        
        if os.path.exists(config_path):
            try:
                with open(config_path, 'r') as f:
                    config = json.load(f)
                    
                # Set env vars from config if not already set
                if 'database' in config:
                    if 'host' in config['database'] and 'OBMYSQL_MS0' not in os.environ:
                        os.environ['OBMYSQL_MS0'] = config['database']['host']
                    if 'port' in config['database'] and 'OBMYSQL_PORT' not in os.environ:
                        os.environ['OBMYSQL_PORT'] = str(config['database']['port'])
                        
                if 'paths' in config:
                     # Add other paths if needed
                     pass
            except Exception as e:
                print("[WARN] Failed to load config.json: " + str(e))

def run_test(args):
    info("Starting Test Execution...")
    info("Config: " + str(args))
    
    # 1. Load config if not set (fallback for standalone execution)
    load_config_if_needed()
    
    # 2. Set Environment Variables
    # Use environment variables if set, otherwise default to hardcoded fallbacks or error
    db_port = os.environ.get('OBMYSQL_PORT', '2881')
    db_host = os.environ.get('OBMYSQL_MS0', '127.0.0.1')
    
    info("Database: " + db_host + ":" + db_port)

    # 3. Build mysqltest command
    cmd = ["./mysqltest"] # path to mysqltest binary
    # Should mysqltest binary path be configurable? 
    # Yes, normally. But for now keeping as ./mysqltest or from env.
    
    if args.mode == "record":
        cmd.append("--record")
    
    if args.testset:
        cmd.append("--test-set=" + args.testset)
        
    if args.testpat:
        cmd.append("--test-pattern=" + args.testpat)
        
    cmd_str = " ".join(cmd)
    
    # 4. Execute
    info("Running: " + cmd_str)
    # ret = sh(cmd_str)
    # exit(ret)
    
    info("Test execution simulated.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run MySQL tests.')
    parser.add_argument('--quiet', action='store_true', help='Quiet mode')
    parser.add_argument('--testset', type=str, help='Test set')
    parser.add_argument('--testpat', type=str, help='Test pattern')
    parser.add_argument('--mode', type=str, default='test', choices=['record', 'test'], help='Test mode')
    
    args = parser.parse_args()
    run_test(args)
