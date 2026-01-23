ALTER SYSTEM SET merge_delay_interval='6s' server_type=yaodatasvr;
ALTER SYSTEM SET major_freeze_wait_time='6s' server_type=yaoadminsvr;
ALTER SYSTEM SET  min_major_freeze_interval='5s' server_type=yaotxnsvr;
ALTER SYSTEM SET min_merge_interval='5s' server_type=yaodatasvr;
ALTER SYSTEM SET  max_merge_thread_num='20' server_type=yaodatasvr;
