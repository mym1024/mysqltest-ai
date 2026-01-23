# MySQL_Test

此仓库对应存放MySQLTest测试工具、测试案例、测试说明。

- tools：存放x86与arm平台对应的mysqltest测试工具。
- tools_help:存放mysqltest测试操作流程案例。
- case：存放对应主版本对应的基准文件（r）、基础案例（t）。

## 案例分类说明

> 备注：此案例分类说明以最新版本case为基准。

| ID编号 | 功能分类          | 功能描述                     | 总个数 |
| ------ | ----------------- | ---------------------------- | ------ |
|        |                   |                              | 985    |
| 0000   | DDL               | create/drop/alter            | 57     |
| 1000   | DML               | select/insert/update/replace | 186    |
| 2000   | sequence          | sequence                     | 11     |
| 3000   | secondary_index   | secondary_index              | 66     |
| 4000   | transaction       | 事务                         | 98     |
| 5000   | join              | 连接                         | 94     |
| 7000   | truncate          | 清空表数据                   | 67     |
| 8000   | partition         | 分区                         | 212    |
| 9000   | function          | count,group, order by, when  | 39     |
| A000   | bug               | 复杂bug                      | 19     |
| B000   | other             | 暂时无法归类                 | 96     |
| C000   | decimal           |                              | 5      |
| D000   | show/grant/user等 |                              | 19     |

## 架构说明

以下架构为mysql_test默认测试架构，如果有特殊架构，可以进行调整测试。

| 服务器IP       | 角色                    |
| -------------- | ----------------------- |
| 192.168.16.103 | AS0/TS1(paxos0)/DS0/SS0 |
| 192.168.16.105 | TS0(paxos1)             |

##  特殊架构

以下case有特定的集群架构要求:

| case_id                               | 要求                                         |
| ------------------------------------- | -------------------------------------------- |
| 0023_expire_info_cluster_up_down.test | 需要两台或两台以上DS、需要修改case中实际路径 |
| 1135_alias_use_block_cache   	        | 必须为单一DS                                 |
| 1136_dml_use_block_cache.test         | 必须为单一DS                                 |
| 1137_get_scan_use_block_cache.test    | 必须为单一DS                                 |
| 8078_ps_lose_insert_partition.test    | 必须单独执行                                 |

##  特殊用例

以下case的测试结果由于是动态的结果，与基准文件不一致，可忽略：

| case_id              | 与基准文件的不同点                       |
| -------------------- | ---------------------------------------- |
| 9034_func_mathe.test | UUID函数的查询结果每次执行都会不一致     |
| B082_json.test       | JSON功能中包含日期的值每次执行都会不一致 |
| B088_show_trace.test | SHOW_TRACE功能查询结果ip不一致           |

