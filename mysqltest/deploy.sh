#!/bin/bash

# 设置默认路径为当前目录
CURDIR=$(pwd)
DBHome="${DBHome:-$CURDIR/yaobase}"
Linked="${Linked:-$CURDIR/data}"
appName="${appName:-yaotest}"
udisk_num="${udisk_num:-4}"
cdisk_num="${cdisk_num:-4}"

# 日志打印
printlog() {
    echo "[$(date +'%F %T')] : $*"
}

# 安全创建目录
safe_mkdir() {
    [ -d "$1" ] || { mkdir -p "$1" && printlog "创建目录: $1"; }
}

# 安全清理目录
safe_clean() {
    local path="$1"
    if [ -e "$path" ]; then
        if [ -d "$path" ]; then
            rm -rf "$path"/* && printlog "清理目录内容: $path"
        else
            rm -f "$path" && printlog "删除文件: $path"
        fi
    else
        printlog "路径不存在，无需清理: $path"
    fi
}

# 创建 AS 测试目录结构
run_as_test() {
    printlog "开始创建 AS 测试目录结构"

    safe_mkdir "$Linked"
    safe_mkdir "$DBHome"
    safe_clean "$DBHome/data"
    safe_mkdir "$DBHome/data"

    safe_mkdir "$Linked/commitlog"
    safe_clean "$Linked/commitlog/as_commitlog"
    safe_mkdir "$Linked/commitlog/as_commitlog"
    safe_clean "$Linked/commitlog/ts_commitlog"
    safe_mkdir "$Linked/commitlog/ts_commitlog"
    safe_clean "$DBHome/data/as"
    safe_mkdir "$DBHome/data/as"

    ln -sfn "$Linked/commitlog/as_commitlog" "$DBHome/data/as_commitlog"
    ln -sfn "$Linked/commitlog/ts_commitlog" "$DBHome/data/ts_commitlog"

    for ((i=0; i<udisk_num; i++)); do
        safe_clean "$DBHome/data/ts_data/raid${i}"
        safe_mkdir "$DBHome/data/ts_data/raid${i}"
    done

    safe_clean "$Linked/ts_data"
    safe_mkdir "$Linked/ts_data"
    for ((i=1; i<udisk_num * 2 + 1; i++)); do
        safe_clean "$Linked/ts_data/$i"
        safe_mkdir "$Linked/ts_data/$i"
    done

    for ((i=1; i<udisk_num * 2 + 1; i++)); do
        raid=$(( (i - 1) / 2 ))
        store=$(( (i - 1) % 2 ))
        ln -sfn "$Linked/ts_data/$i" "$DBHome/data/ts_data/raid${raid}/store${store}"
        printlog "链接创建: raid${raid}/store${store} -> ts_data/$i"
    done
}

# 创建 DS 测试目录结构
run_ds_test() {
    printlog "开始创建 DS 测试目录结构"

    safe_clean "$Linked/ds_data"
    safe_mkdir "$Linked/ds_data"

    for ((i=1; i<=cdisk_num; i++)); do
        base="$Linked/ds_data/$i"
        safe_mkdir "$base"
        safe_clean "$base/$appName/sstable"
        safe_mkdir "$base/$appName/sstable"
        safe_clean "$base/Recycle"
        safe_mkdir "$base/Recycle"

        ln -sfn "$base" "$DBHome/data/$i"
        printlog "链接创建: $DBHome/data/$i -> $base"
    done
}

# 停止进程功能
stop_processes() {
    printlog "开始停止后台进程..."

    for pidfile in "${DBHome}/run"/yaoadminsvr.pid "${DBHome}/run"/yaosqlsvr.pid "${DBHome}/run"/yaodatasvr.pid "${DBHome}/run"/yaotxnsvr.pid; do
        if [ -f "$pidfile" ]; then
            pid=$(cat "$pidfile")
            if [ -n "$pid" ]; then
                kill -9 "$pid" && printlog "已终止进程: $pidfile (PID: $pid)"
            fi
        else
            printlog "未找到PID文件: $pidfile，跳过"
        fi
    done

    printlog "后台进程已处理完毕"
}

# 启动进程功能
start_processes() {
    # 进入 DBHome 目录
    if [ -d "$DBHome" ]; then
        cd "$DBHome" || exit 1
        printlog "进入 DBHome 目录: $DBHome"
    else
        printlog "错误：DBHome 目录不存在！"
        exit 1
    fi

    get_local_ip_and_iface

    # 启动相关进程
    printlog "启动进程..."
    bin/yaoadminsvr -r "$local_ip:49500" -R "$local_ip:49500" -i "$iface" -C 0 -G 1 -K 1 -F true -U 1 -u 1
    sleep 3
    bin/yaotxnsvr -r "$local_ip:49500" -p 49700 -m 49701 -i "$iface" -C 0 -g 0
    bin/yaodatasvr -r "$local_ip:49500" -p 49600  -n "$appName" -i "$iface" -C 0
    bin/yaosqlsvr -r "$local_ip:49500" -p 49800 -z 49880 -i "$iface" -C 0
    printlog "进程启动完成"
}

# 获取本地IP和网卡信息
get_local_ip_and_iface() {
    local_ip=$(hostname -I | awk '{print $1}')
    iface=$(ip addr show | grep -B2 "$local_ip" | head -n 1 | awk '{print $2}' | sed 's/://')
    printlog "自动获取到 IP: $local_ip，网卡: $iface"
}

# 主逻辑判断
case "$1" in
    rebuild)
        if [ "$(id -u)" = "0" ]; then
            printlog "请不要使用 root 用户运行脚本！"
            exit 9
        fi

        printlog "========== 初始化测试目录 =========="
        printlog "DBHome: $DBHome"
        printlog "Linked: $Linked"
        printlog "AppName: $appName"
        printlog "Txn磁盘数: $udisk_num"
        printlog "Data磁盘数: $cdisk_num"

        run_as_test
        run_ds_test

        printlog "========== 目录结构创建完成 =========="
        ;;
    stop)
        stop_processes
        ;;
    start)
        start_processes
        ;;
     install)
        stop_processes
        run_as_test
        run_ds_test
        start_processes
        printlog "bin/as_admin -r $local_ip -p 49500 -t 120000000 boot_strap"
        bin/as_admin -r $local_ip -p 49500 -t 120000000 boot_strap
        printlog "mysql -uadmin -padmin -h $local_ip -P 49880"
        ;;
    *)
        echo "用法: $0 {rebuild|stop|start}"
        echo "  rebuild  创建目录结构"
        echo "  stop     停止相关进程"
        echo "  start    启动进程（脚本自动进入 DBHome 目录）"
        exit 1
        ;;
esac

