#！/bin/bash
#set -e
#以下文件和文件夹均已存在
# 检查参数数量
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <0-10>"
  exit 1
fi

# 获取与定义参数
number="$1"

# 检查第一个参数是否是 0-10 的数字
if ! [[ "$number" =~ ^[0-9]$|^10$ ]]; then
  echo "Error: The first argument must be a number between 0 and 10."
  exit 1
fi

mysqltest_dir=/home/yaotest/tool$number/mysqltest_yaobase
base_dir=/home/yaotest/tool$number/mysqltest_yaobase/mysql_test
file=/home/yaotest/tool$number/mysqltest_yaobase/$number-case.log
resource_reject=$base_dir/var/log #arm
#resource_reject=r  #x86

deal_reject(){
  rm -rf $base_dir/{reject,reject_t,fail_t,base_r,reject_r}
  mkdir -p $base_dir/{reject,reject_t,fail_t,base_r,reject_r}
  sleep 3
  string=`tail -n1 $file | cut -b 23-`
  array=(${string//,/ })
  for i in ${array[@]}
  do
    a=${i}."reject"
    b=${i}."test"
    c=${i}."result"
    if [[ ! -f  "$resource_reject/$a" ]];then
       cp $base_dir/t/$b $base_dir/fail_t
    else
       cp $resource_reject/$a $base_dir/reject
       cp $base_dir/t/$b $base_dir/reject_t
       cp $base_dir/r/$c $base_dir/base_r
       fi
  done
  cp -r $base_dir/reject/* $base_dir/reject_r
  cd $base_dir/reject_r
  rename .reject .result *.reject
  cd $base_dir
  zip -r $number-case.zip ../$number-case.log reject/ reject_t/ fail_t/ base_r/ reject_r/
  mv $number-case.zip /home/yaotest/
  rm -rf $base_dir/{reject,reject_t,fail_t,base_r}
}

deal_reject
