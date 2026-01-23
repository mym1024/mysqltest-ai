#！/bin/bash
#以下文件和文件夹均已存在
rm -rf reject reject_t pass_t fail_t
mkdir reject reject_t pass_t fail_t
#日志文件路径
path=$(dirname "$PWD")
file=/home/mysqltest/test_log/svn1345_seq.log
#测试的test文件
file_test=t
#未跑通的test文件
fail_t=fail_t
#测试通过的test文件
pass_t=pass_t
#测试生成的reject文件
reject=reject
#测试reject的test的文件
reject_t=reject_t

resource_reject=var/log #arm
#resource_reject=r  #x86

#分类reject与fail
string=`tail -n1 $file | cut -b 23-`
array=(${string//,/ })
for i in ${array[@]}
do
a=${i}."reject"
b=${i}."test"
if [[ ! -f  "$resource_reject/$a" ]];then
cp $file_test/$b $fail_t
else
cp $resource_reject/$a $reject
cp $file_test/$b $reject_t
fi
done

#分类OK
b=`cat $file | grep OK | cut -b 23-26`
for line in ${b}
do
    e=`ls $file_test | grep "^${line}"`
    cp $file_test/$e $pass_t/
done

#for i in `ls $reject`
#do
#    f=${i%.*}
#    g=${f}".test"
#    cp $file_test/$g $reject_t
#done
zip -r /home/mysqltest/test_log/svn1345_seq.zip reject/ reject_t/ pass_t/ fail_t/ 
rm -rf reject/ reject_t/ pass_t/ fail_t/
