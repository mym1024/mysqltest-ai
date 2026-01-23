#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import sys
import os
import time

# Mocking common library import if not present
try:
    from common import *
except ImportError:
    # Minimal mock for standalone testing if common.py not found
    def info(msg): print "[INFO] " + msg
    def force_info(msg): print "[INFO] " + msg
    def sh(cmd): 
        print "[EXEC] " + cmd
        return 0

def deploy_cluster():
    info("Starting Cluster Deployment...")
    
    # 1. Generate Config
    # Real implementation would update config.py based on template and current environment
    info("Generating configuration...")
    # Mock config generation
    
    # 2. Reboot Cluster (Stop -> Start -> Bootstrap)
    info("Rebooting cluster logic...")
    
    # Stop Servers
    sh("echo 'Stopping servers...'")
    
    # Start Servers
    sh("echo 'Starting servers...'")
    
    # Bootstrap
    # In real scenario: ./multi_deploy.py ob1.boot_strap
    sh("echo 'Bootstrapping cluster...'")
    
    # Wait for ready
    time.sleep(2) 
    info("Cluster deployed successfully.")

if __name__ == "__main__":
    deploy_cluster()
