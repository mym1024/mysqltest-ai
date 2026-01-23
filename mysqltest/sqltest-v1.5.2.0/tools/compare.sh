#!/bin/bash
#cat diff_two__file
#/bin/sbin
rm -rf diff.log
#rm -rf audit.log
rm -rf audit_tmp.log
#cp ../../../yaobase/log/audit.log ./
file1=audit_tmp.log
file2=audit_result.log
sed -e 's/\(start_time=\)\[\([^]]*\)\]/\1[replace_time]/g'  -e 's/session_id=[^[:space:]]*/session_id=replace_id/g'  -e 's/\(end_time=\)\[\([^]]*\)\]/\1[replace_time]/g'  audit.log > audit_tmp.log
diff $file2 $file1 -u > diff.log
