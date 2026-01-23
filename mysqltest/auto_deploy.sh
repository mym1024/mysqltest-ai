#!/bin/bash
set -e
git_sqltest=/home/yaotest/base/sqltest/tools/mysqltest_yaobase_arm/mysqltest_yaobase
git_case="/home/yaotest/base/sqltest/case"
# 获取传入的参数
param="$1"  # 第一个参数
port_prefix="$2"  # 第二个参数
as_ip="$3"  # 第三个参数
ts_ip="$4"  # 第四个参数

mysqltest_dir=/home/yaotest/tool$param

# 判断第一个参数 (param) 是否是数字 1 到 9
validate_param() {
  if ! [[ "$param" =~ ^[0-9]$ ]]; then
    echo "第一个参数(param)必须是数字 0 到 9"
    return 1
  fi
  echo "参数1验证成功: $param"
}

# 判断第二个参数 (port_prefix) 是否是数字 20 到 50
validate_port_prefix() {
  if ! [[ "$port_prefix" =~ ^[1-4][0-9]$|^50$ ]]; then
    echo "第二个参数(port_prefix)必须是数字 10 到 50"
    return 1
  fi
  echo "参数2验证成功: $port_prefix"
}

# 判断第三个参数 (as_ip) 是否是有效的 IP 地址格式
validate_as_ip() {
  if ! [[ "$as_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "第三个参数(as_ip)必须是有效的IP地址"
    return 1
  fi
  echo "参数3验证成功: $as_ip"
}

# 判断第四个参数 (ts_ip) 是否是有效的 IP 地址格式
validate_ts_ip() {
  if ! [[ "$ts_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "第四个参数(ts_ip)必须是有效的IP地址"
    return 1
  fi
  echo "参数4验证成功: $ts_ip"
}

# 处理mysqltest环境配置文件
deal_config(){
  #处理config.py文件
  mkdir -p $mysqltest_dir
  if [ "$param" -eq 0 ]; then
    cp `pwd`/base/config.py `pwd`/base/$param.config.py
  else
    cp `pwd`/base/1dsconfig.py `pwd`/base/$param.config.py
  fi
  sed -i "s#31#$port_prefix#g" `pwd`/base/$param.config.py
  sed -i "s#192.168.16.106#$as_ip#g" `pwd`/base/$param.config.py
  sed -i "s#192.168.16.107#$ts_ip#g" `pwd`/base/$param.config.py
  sed -i "/data_dir/c data_dir = '$mysqltest_dir/yaobase/data'" `pwd`/base/$param.config.py
  cp -r $git_sqltest $mysqltest_dir/
  cp `pwd`/base/$param.config.py $mysqltest_dir/mysqltest_yaobase/config.py
  
  #处理multi_deploy.py文件
  sed -i "s#fan/tools#yaotest/tool$param#g" $mysqltest_dir/mysqltest_yaobase/multi_deploy.py
  sed -i "s#mysqltest/yaobase#tool$param/yaobase#g" $mysqltest_dir/mysqltest_yaobase/multi_deploy.py

  #处理mysqltest环境可执行文件
  cp `pwd`/base/auto_mysqltest.sh $mysqltest_dir/mysqltest_yaobase/
  chmod 777 $mysqltest_dir/mysqltest_yaobase/mysqltest
  chmod 777 $mysqltest_dir/mysqltest_yaobase/*.py
  chmod +x  $mysqltest_dir/mysqltest_yaobase/*.sh
  
}

#处理YaoBase环境

deal_yaobase(){
  #rm -rf `pwd`/base/resource_yaobase 
  #scp -r ybbuilder@192.168.16.107:/home/ybbuilder/yf_temp/yaobase `pwd`/base/resource_yaobase
  sshpass -p "cos!@#321" ssh yaotest@$ts_ip "mkdir -p ~/tool$param"
  mkdir -p $mysqltest_dir/mysqltest_yaobase/tools
  mkdir -p $mysqltest_dir/mysqltest_yaobase/mysql_test/audit
  rm -rf $mysqltest_dir/mysqltest_yaobase/bin/*
  rm -rf $mysqltest_dir/mysqltest_yaobase/tools/*
  rm -rf $mysqltest_dir/mysqltest_yaobase/lib/*
  rm -rf $mysqltest_dir/mysqltest_yaobase/collected_log
  # 基准文件
  rm -rf $mysqltest_dir/mysqltest_yaobase/mysql_test/r
  rm -rf $mysqltest_dir/mysqltest_yaobase/mysql_test/t
  rm -rf $mysqltest_dir/mysqltest_yaobase/mysql_test/var
  cp -r $git_case/* $mysqltest_dir/mysqltest_yaobase/mysql_test/
  cp -r `pwd`/base/resource_yaobase/bin/*svr $mysqltest_dir/mysqltest_yaobase/bin
  cp -r `pwd`/base/resource_yaobase/bin/*_admin $mysqltest_dir/mysqltest_yaobase/bin
  cp -r `pwd`/base/resource_yaobase/lib/ $mysqltest_dir/mysqltest_yaobase/
  cp -r `pwd`/base/resource_yaobase/bin/*_admin  $mysqltest_dir/mysqltest_yaobase/tools
  cd $mysqltest_dir/mysqltest_yaobase
  ./multi_deploy.py ob1.reboot
  cd ~/
  cp -r `pwd`/base/resource_yaobase/bin/default_srs_data_mysql.sql tool$param/yaobase/bin/
 # cp -r `pwd`/base/resource_yaobase/lib/* tool$param/yaobase/lib/
  sleep 30
  mysql -uadmin -padmin -h $as_ip -P ${port_prefix}880 -e "select * from __all_server;"
  cd $mysqltest_dir/mysqltest_yaobase/
  sh auto_mysqltest.sh $param
}


# 主函数，调用 a 和 b 函数
main() {
  # 检查是否有四个参数
  if [ $# -ne 4 ]; then
    echo "用法: $0 <param> <port_prefix> <as_ip> <ts_ip>"
    return 1
  fi

  # 调用各个验证函数
  validate_param	|| return 1
  validate_port_prefix	|| return 1
  validate_as_ip	|| return 1
  validate_ts_ip	|| return 1

  # 所有参数验证成功后执行其他操作
  deal_config
  deal_yaobase 
}

# 调用主函数并传入所有参数
main "$@"

