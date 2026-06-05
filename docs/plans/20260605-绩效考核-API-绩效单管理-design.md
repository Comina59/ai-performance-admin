# API 子设计文档：绩效单管理

- 日期：2026-06-05
- 版本：v1.0
- API 分级：B 类（含状态流转、唯一性校验等非标逻辑）
- 关联整体设计：[20260605-绩效考核-design.md](20260605-绩效考核-design.md)

## 1. 端点定义

| HTTP 方法 | 路径 | 说明 | 权限标识 |
|-----------|------|------|----------|
| GET | /performance/assess/list | 分页查询绩效单列表 | performance:assess:list |
| GET | /performance/assess/{id} | 查询绩效单详情（含评分项） | performance:assess:query |
| POST | /performance/assess | 新建绩效单 | performance:assess:add |
| POST | /performance/assess/submitApproval | 提交领导审批 | performance:assess:edit |
| POST | /performance/assess/approve | 审批通过 | performance:assess:approve |
| POST | /performance/assess/reject | 驳回 | performance:assess:approve |
| GET | /performance/assess/myList | 查询我的绩效列表（员工视角） | performance:assess:list |
| GET | /performance/assess/teamList | 查询团队绩效列表（领导视角） | performance:assess:list |
| GET | /performance/assess/dashboard | 绩效管理员工作台统计 | performance:assess:list |

## 2. 请求/响应结构

### 2.1 绩效单实体（PerfAssess）

| 字段名 | 中文名 | 类型 | 长度 | 必填 | 默认值 | 取值范围 | 说明 |
|--------|--------|------|------|------|--------|----------|------|
| id | 主键ID | Long | — | 是（新增时否） | 无 | — | 自增主键 |
| assessTypeId | 考核类型ID | Long | — | 是 | 无 | — | 关联 perf_assess_type.id |
| period | 考核周期 | String | 16 | 是 | 无 | 如 2026-06 / 2026-Q1 | 标识考核周期 |
| employeeId | 员工ID | Long | — | 是 | 无 | — | 关联 sys_user.user_id |
| status | 状态 | String | 2 | 是 | 01 | 01=草稿中, 02=待领导审批, 03=待员工自评, 04=待领导评分, 05=差异判定中, 06=待绩效面谈, 07=待改进计划确认, 08=已完成 | 全局状态 |
| deadline | 截止日期 | Date | — | 否 | 无 | — | 绩效提交截止时间 |
| selfScoreTotal | 自评总分 | BigDecimal | 5,2 | 否 | 无 | — | 员工自评总分（自动汇总） |
| leaderScoreTotal | 领导评分总分 | BigDecimal | 5,2 | 否 | 无 | — | 领导评分总分（自动汇总） |
| scoreDiff | 总分差 | BigDecimal | 5,2 | 否 | 无 | — | |领导总分-自评总分| |
| diffTriggered | 是否触发差异 | String | 1 | 否 | 0 | 0=否, 1=是 | 差异判定结果 |
| createBy | 创建者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| createTime | 创建时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| updateBy | 更新者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| updateTime | 更新时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| remark | 备注 | String | 500 | 否 | 无 | — | BaseEntity 继承 |

### 2.2 新建绩效单请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessTypeId | 考核类型ID | Long | 是 | — |
| period | 考核周期 | String | 是 | 如 2026-06 |

### 2.3 提交审批请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| id | 绩效单ID | Long | 是 | — |

### 2.4 审批通过请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| id | 绩效单ID | Long | 是 | — |

### 2.5 驳回请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| id | 绩效单ID | Long | 是 | — |
| rejectReason | 驳回原因 | String | 是 | 最长500字 |

### 2.6 驳回记录实体（PerfAssessReject）

| 字段名 | 中文名 | 类型 | 长度 | 必填 | 默认值 | 取值范围 | 说明 |
|--------|--------|------|------|------|--------|----------|------|
| id | 主键ID | Long | — | 是 | 无 | — | 自增主键 |
| assessId | 绩效单ID | Long | — | 是 | 无 | — | 关联 perf_assess.id |
| rejectReason | 驳回原因 | String | 500 | 是 | 无 | — | 领导填写的驳回原因 |
| rejectBy | 驳回人 | String | 64 | 是 | 无 | — | 驳回操作人 |
| rejectTime | 驳回时间 | Date | — | 是 | 无 | — | 驳回操作时间 |
| createBy | 创建者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| createTime | 创建时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |

### 2.7 我的绩效列表响应

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| total | 总记录数 | long | — |
| rows | 数据列表 | List\<PerfAssessVO\> | — |

PerfAssessVO 在 PerfAssess 基础上增加：

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| assessTypeName | 考核类型名称 | String | — |
| statusName | 状态名称 | String | 中文状态名 |
| pendingAction | 待办动作 | String | 如"继续填写"/"查看结果"等 |

### 2.8 团队绩效列表响应

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| pendingApproval | 待我审批 | List\<PerfAssessVO\> | 状态=02 |
| pendingScore | 待我评分 | List\<PerfAssessVO\> | 状态=04 |
| pendingInterview | 待我面谈 | List\<PerfAssessVO\> | 状态=06 |

### 2.9 管理员工作台统计响应

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| totalCount | 总绩效单数 | Integer | — |
| statusDistribution | 状态分布 | Map\<String, Integer\> | 各状态数量 |
| diffTriggeredCount | 触发差异数 | Integer | — |
| completedCount | 已完成数 | Integer | — |

## 3. 业务规则约束表

| 规则编号 | 触发条件 | 执行逻辑 | 影响字段 | 说明 |
|----------|----------|----------|----------|------|
| R1 | 同一员工+同一考核类型+同一周期已存在绩效单 | 禁止新建，返回错误"该周期已存在绩效单" | employeeId, assessTypeId, period | 唯一性约束 |
| R2 | 同一员工+同一考核类型+同一周期存在草稿 | 点击"新建本月绩效"时提示"本月已存在草稿，是否继续编辑" | status | 草稿提示 |
| R3 | 提交审批时权重合计≠100 | 禁止提交，返回错误"权重合计需为100分，当前为xx分" | status | 权重校验 |
| R4 | 提交审批时评分项为空 | 禁止提交，返回错误"请至少添加一个评分项" | status | 评分项校验 |
| R5 | 提交审批 | 状态 01→02，同时快照考核关系到历史表 | status | 状态流转 |
| R6 | 审批通过 | 状态 02→03 | status | 状态流转 |
| R7 | 驳回 | 状态 02→01，记录驳回原因 | status | 状态流转 |
| R8 | 非当前状态允许的操作 | 禁止操作，返回错误"当前状态不允许此操作" | status | 状态校验 |
| R9 | 新建绩效单时 | 自动根据考核关系查找直属领导，若无则返回错误"未配置考核关系，请联系绩效管理员" | employeeId | 考核关系校验 |

## 4. 响应示例

**成功响应示例**（新建绩效单）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "id": 1,
    "assessTypeId": 2,
    "period": "2026-06",
    "employeeId": 100,
    "status": "01",
    "selfScoreTotal": null,
    "leaderScoreTotal": null,
    "scoreDiff": null,
    "diffTriggered": "0"
  }
}
```

**失败响应示例**（重复绩效单）：
```json
{
  "code": 500,
  "msg": "该周期已存在绩效单",
  "data": null
}
```

**失败响应示例**（权重校验失败）：
```json
{
  "code": 500,
  "msg": "权重合计需为100分，当前为80分",
  "data": null
}
```

**失败响应示例**（状态不允许操作）：
```json
{
  "code": 500,
  "msg": "当前状态不允许此操作",
  "data": null
}
```
