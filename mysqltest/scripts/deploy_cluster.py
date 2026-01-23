#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

import sys
import os
import time
import subprocess
import json
import socket

# Mocking common library import if not present
try:
    from common import *
except ImportError:
    # Minimal mock for standalone testing if common.py not found
    def info(msg): print("[INFO] " + msg)
    def force_info(msg): print("[INFO] " + msg)
    def sh(cmd): 
        print("[EXEC] " + cmd)
        return 0

def load_config():
    # Attempt to find config.json
    # 1. Check parent directory of script
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(script_dir, '../config.json')
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            return json.load(f)
    return {}

def get_local_ip():
    try:
        # Connect to a public DNS to determine the best local IP (doesn't actually send data)
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        # Fallback
        return "127.0.0.1"

def get_iface(ip):
    try:
        # Use ip addr show and grep to find the interface for the specific IP
        # Command: ip addr show | grep -B2 "192.168.1.5" | head -n 1 | awk '{print $2}' | sed 's/://'
        cmd = "ip addr show | grep -B2 '%s' | head -n 1 | awk '{print $2}' | sed 's/://'" % ip
        output = subprocess.check_output(cmd, shell=True).strip()
        return output
    except Exception as e:
        print("[WARN] Failed to get interface: " + str(e))
        return "eth0-mock" # Default fallback

def stop_processes(yao_test_dir):
    info("Stopping existing YaoBase processes...")
    # Based on deploy.sh: looks for pid files in run/ directory
    # Assuming config.json paths.yao_test_dir points to base, and DB is in .../yaobase/run/
    
    # Simulating kill commands based on process names commonly used
    pids = ["yaoadminsvr", "yaotxnsvr", "yaodatasvr", "yaosqlsvr"]
    for p in pids:
        sh("pkill -9 %s || true" % p)

def deploy_cluster():
    info("Starting Cluster Deployment...")
    
    # 0. Load Config
    config = load_config()
    
    # Get Paths
    yao_test_dir = os.environ.get('YAO_TEST_DIR', config.get('paths', {}).get('yao_test_dir', '/home/yaotest/tool0'))
    db_home = os.path.join(yao_test_dir, 'mysqltest_yaobase') # Adjusted to match setup_env.sh structure probably
    # setup_env.sh creates: $YAO_TEST_DIR/mysqltest_yaobase
    
    info("DB Home: " + db_home)

    # 1. Environment Detection
    local_ip = get_local_ip()
    iface = get_iface(local_ip)
    info("Detected IP: %s, Interface: %s" % (local_ip, iface))
    
    # 2. Stop Processes
    stop_processes(yao_test_dir)
    
    # 3. Start Processes
    cluster_conf = config.get('cluster', {})
    services = cluster_conf.get('services', {})
    app_name = cluster_conf.get('app_name', 'yaotest')
    
    if not services:
        info("[WARN] No services configured in config.json. Exiting.")
        return

    # Helper to get port
    def get_port(svc, key='port'):
        return str(services.get(svc, {}).get(key, 0))

    # Construct paths
    bin_dir = os.path.join(db_home, "bin") # Assuming binaries are copied here by setup_env.sh

    # Start Admin Server
    # bin/yaoadminsvr -r "$local_ip:49500" -R "$local_ip:49500" -i "$iface" -C 0 -G 1 -K 1 -F true -U 1 -u 1
    admin_port = get_port('admin')
    cmd_admin = "{bin}/yaoadminsvr -r {ip}:{port} -R {ip}:{port} -i {iface} -C 0 -G 1 -K 1 -F true -U 1 -u 1".format(
        bin=bin_dir, ip=local_ip, port=admin_port, iface=iface
    )
    sh(cmd_admin + " &")
    time.sleep(3) # Wait for admin to start

    # Start Txn Server
    # bin/yaotxnsvr -r "$local_ip:49500" -p 49700 -m 49701 -i "$iface" -C 0 -g 0
    cmd_txn = "{bin}/yaotxnsvr -r {ip}:{aport} -p {port} -m {mport} -i {iface} -C 0 -g 0".format(
        bin=bin_dir, ip=local_ip, aport=admin_port, 
        port=get_port('txn', 'port'), mport=get_port('txn', 'manage_port'), iface=iface
    )
    sh(cmd_txn + " &")

    # Start Data Server
    # bin/yaodatasvr -r "$local_ip:49500" -p 49600  -n "$appName" -i "$iface" -C 0
    cmd_data = "{bin}/yaodatasvr -r {ip}:{aport} -p {port} -n {app} -i {iface} -C 0".format(
        bin=bin_dir, ip=local_ip, aport=admin_port, 
        port=get_port('data'), app=app_name, iface=iface
    )
    sh(cmd_data + " &")

    # Start SQL Server
    # bin/yaosqlsvr -r "$local_ip:49500" -p 49800 -z 49880 -i "$iface" -C 0
    cmd_sql = "{bin}/yaosqlsvr -r {ip}:{aport} -p {port} -z {mysql} -i {iface} -C 0".format(
        bin=bin_dir, ip=local_ip, aport=admin_port, 
        port=get_port('sql'), mysql=get_port('sql', 'mysql_port'), iface=iface
    )
    sh(cmd_sql + " &")

    # 4. Bootstrap (Optional - usually done on install/rebuild, not every test run? 
    # check deploy.sh: install DOES bootstrap. start DOES NOT.
    # Logic in runner seems to be "Deploy Cluster" which sounds like start/restart.
    # User said "拉起服务" (Pull up service / Start service).
    # If bootstrap is needed, we need another flag or check.)
    
    info("Cluster services started.")

if __name__ == "__main__":
    deploy_cluster()
