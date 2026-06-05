# API 子设计文档：考核关系管理

- 日期：2026-06-05
- 版本：v1.0
- API 分级：B 类（含层级链管理、历史快照等非标逻辑）
- 关联整体设计：[20260605-绩效考核-design.md](20260605-绩效考核-design.md)

## 1. 端点定义

| HTTP 方法 | 路径 | 说明 | 权限标识 |
|-----------|------|------|----------|
| GET | /performance/assessRelation/list | 分页查询考核关系列表 | performance:assessRelation:list |
| GET | /performance/assessRelation/{id} | 查询考核关系详情 | performance:assessRelation:query |
| POST | /performance/assessRelation | 新增考核关系 | performance:assessRelation:add |
| POST | /performance/assessRelation | 修改考核关系 | performance:assessRelation:edit |
| POST | /performance/assessRelation/{ids} | 删除考核关系 | performance:assessRelation:remove |
| GET | /performance/assessRelation/leaderChain/{assessId} | 查询某考核的完整领导链 | performance:assessRelation:query |
| GET | /performance/assessRelation/subordinates | 查询当前用户的直属下属列表 | performance:assessRelation:list |
| POST | /performance/assessRelation/batchSave | 批量保存考核关系（含层级链） | performance:assessRelation:add |

## 2. 请求/响应结构

### 2.1 考核关系实体（PerfAssessRelation）

| 字段名 | 中文名 | 类型 | 长度 | 必填 | 默认值 | 取值范围 | 说明 |
|--------|--------|------|------|------|--------|----------|------|
| id | 主键ID | Long | — | 是（新增时否） | 无 | — | 自增主键 |
| assessTypeId | 考核类型ID | Long | — | 是 | 无 | — | 关联 perf_assess_type.id |
| employeeId | 员工ID | Long | — | 是 | 无 | — | 关联 sys_user.user_id |
| leaderId | 领导ID | Long | — | 是 | 无 | — | 关联 sys_user.user_id |
| levelOrder | 层级序号 | Integer | — | 是 | 无 | 1-10 | 1=直属领导，2=二级领导，依次递增 |
| effectivePeriod | 生效周期 | String | 16 | 是 | 无 | 格式：2026-Q1 / 2026-06 | 该关系生效的考核周期 |
| status | 状态 | String | 1 | 是 | 0 | 0=正常, 1=停用 | 是否启用 |
| createBy | 创建者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| createTime | 创建时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| updateBy | 更新者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| updateTime | 更新时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| remark | 备注 | String | 500 | 否 | 无 | — | BaseEntity 继承 |

### 2.2 考核关系历史实体（PerfAssessRelationHistory）

| 字段名 | 中文名 | 类型 | 长度 | 必填 | 默认值 | 取值范围 | 说明 |
|--------|--------|------|------|------|--------|----------|------|
| id | 主键ID | Long | — | 是 | 无 | — | 自增主键 |
| assessId | 绩效单ID | Long | — | 是 | 无 | — | 关联 perf_assess.id，标识哪次考核 |
| relationId | 原关系ID | Long | — | 是 | 无 | — | 关联 perf_assess_relation.id |
| employeeId | 员工ID | Long | — | 是 | 无 | — | 快照：员工ID |
| leaderId | 领导ID | Long | — | 是 | 无 | — | 快照：领导ID |
| levelOrder | 层级序号 | Integer | — | 是 | 无 | 1-10 | 快照：层级序号 |
| snapshotTime | 快照时间 | Date | — | 是 | 无 | — | 记录快照时间 |
| createBy | 创建者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| createTime | 创建时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |

### 2.3 批量保存请求（batchSave）

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessTypeId | 考核类型ID | Long | 是 | — |
| effectivePeriod | 生效周期 | String | 是 | 格式：2026-Q1 / 2026-06 |
| relations | 关系列表 | List\<RelationItem\> | 是 | 详见下表 |

RelationItem：

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| employeeId | 员工ID | Long | 是 | — |
| leaderId | 领导ID | Long | 是 | — |
| levelOrder | 层级序号 | Integer | 是 | 1=直属领导 |

### 2.4 领导链查询响应

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| employeeId | 员工ID | Long | — |
| employeeName | 员工姓名 | String | — |
| leaders | 领导列表 | List\<LeaderInfo\> | 按层级排序 |

LeaderInfo：

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| leaderId | 领导ID | Long | — |
| leaderName | 领导姓名 | String | — |
| levelOrder | 层级序号 | Integer | 1=直属领导 |

## 3. 业务规则约束表

| 规则编号 | 触发条件 | 执行逻辑 | 影响字段 | 说明 |
|----------|----------|----------|----------|------|
| R1 | 同一考核类型+同一员工+同一周期+同一层级序号已存在 | 禁止新增，返回错误"该员工在此考核类型和周期下已存在同级领导" | employeeId, assessTypeId, effectivePeriod, levelOrder | 唯一性约束 |
| R2 | 批量保存时同一员工的层级序号不连续 | 禁止保存，返回错误"层级序号必须从1开始连续" | levelOrder | 层级连续性 |
| R3 | 删除考核关系时该关系已被绩效单引用 | 禁止删除，返回错误"该考核关系已被绩效单引用，无法删除" | id | 引用完整性 |
| R4 | 员工发起绩效时 | 系统自动将当前考核关系快照到历史表 | perf_assess_relation_history | 保证历史可追溯 |
| R5 | 修改考核关系时 | 先将旧关系快照到历史表，再更新 | perf_assess_relation_history | 变更留痕 |

## 4. 响应示例

**成功响应示例**（查询领导链）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "employeeId": 100,
    "employeeName": "张三",
    "leaders": [
      {
        "leaderId": 200,
        "leaderName": "李四",
        "levelOrder": 1
      },
      {
        "leaderId": 300,
        "leaderName": "王五",
        "levelOrder": 2
      }
    ]
  }
}
```

**失败响应示例**（层级序号重复）：
```json
{
  "code": 500,
  "msg": "该员工在此考核类型和周期下已存在同级领导",
  "data": null
}
```

**失败响应示例**（层级不连续）：
```json
{
  "code": 500,
  "msg": "层级序号必须从1开始连续",
  "data": null
}
```
