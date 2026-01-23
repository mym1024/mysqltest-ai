#!/bin/bash
set -e   #exit  if error
#set -x
case_dir=mysql_test/t
count=0
split_num=8
arg=${@:1}

#Judge parameter validity

if [[ $arg -ge $split_num ]]; then
  echo "Invalid parameter"
  echo "useage:参数小于分割数量的整数，从0开始"
  echo "e.g: ./auto_mysqltest.sh 1"
  exit 
fi

if [[ ! $arg ]]; then
  echo "参数不能为空"
  exit
fi

#Get the case file name and delete the suffix
function get_filename(){
for i in `ls $case_dir`
  do
    glob=`basename -s .test $i`
    arry_glob[$count]=$glob
    count=`expr $count+1`
  done
#Get array length
array_length=${#arry_glob[@]}
}


#Get split file name
function get_splitfile(){
file_num=$[$array_length / $split_num]
remainder=$[$array_length % $split_num]
rm -rf *.txt
if [[ $arg -eq `expr $split_num-1` ]];then
for ((j=0;j<${#arry_glob[@]};j++))
    do
      if [[ $j -ge `expr $file_num*$arg` ]] && [[ $j -lt $((file_num*($arg+1)+$remainder)) ]];  then
        echo ${arry_glob[j]} >> tmp.txt
        pyargs=`eval cat tmp.txt | xargs | sed -e 's/ /,/g'`
      fi
    done
else 
for ((j=0;j<${#arry_glob[@]};j++))
    do
      if [[ $j -ge `expr $file_num*$arg` ]] && [[ $j -lt $((file_num*($arg+1))) ]];  then
        echo ${arry_glob[j]} >> tmp.txt
        pyargs=`eval cat tmp.txt | xargs | sed -e 's/ /,/g'`
      fi
    done
fi

}

#auto_test
function auto_test(){

#python multi_deploy.py ob1.mysqltest testset=$pyargs test
echo "python multi_deploy.py ob1.mysqltest testset=$pyargs test"
nohup python multi_deploy.py ob1.mysqltest testset=$pyargs test > $arg-case.log 2>&1 &

}

get_filename
get_splitfile
auto_test

