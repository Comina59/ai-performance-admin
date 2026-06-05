# API 子设计文档：改进计划管理

- 日期：2026-06-05
- 版本：v1.0
- API 分级：B 类（含确认/调整状态流转等非标逻辑）
- 关联整体设计：[20260605-绩效考核-design.md](20260605-绩效考核-design.md)

## 1. 端点定义

| HTTP 方法 | 路径 | 说明 | 权限标识 |
|-----------|------|------|----------|
| GET | /performance/improve/list/{assessId} | 查询改进计划列表 | performance:improve:list |
| POST | /performance/improve | 新增改进项 | performance:improve:add |
| POST | /performance/improve | 修改改进项 | performance:improve:edit |
| POST | /performance/improve/{ids} | 删除改进项 | performance:improve:remove |
| POST | /performance/improve/confirm/{assessId} | 员工确认改进计划 | performance:improve:confirm |
| POST | /performance/improve/requestAdjust | 员工申请调整 | performance:improve:confirm |

## 2. 请求/响应结构

### 2.1 改进计划实体（PerfAssessImprove）

| 字段名 | 中文名 | 类型 | 长度 | 必填 | 默认值 | 取值范围 | 说明 |
|--------|--------|------|------|------|--------|----------|------|
| id | 主键ID | Long | — | 是 | 无 | — | 自增主键 |
| assessId | 绩效单ID | Long | — | 是 | 无 | — | 关联 perf_assess.id |
| improveItem | 改进项 | String | 500 | 是 | 无 | — | 改进内容描述 |
| responsiblePerson | 负责人 | String | 64 | 是 | 无 | — | 负责人姓名 |
| responsibleUserId | 负责人ID | Long | — | 否 | 无 | — | 关联 sys_user.user_id |
| deadline | 截止日期 | Date | — | 是 | 无 | — | 改进完成截止日期 |
| acceptStandard | 验收标准 | String | 500 | 是 | 无 | — | 验收标准描述 |
| confirmStatus | 确认状态 | String | 1 | 是 | 0 | 0=待确认, 1=已确认, 2=申请调整, 3=已调整 | 确认状态 |
| adjustReason | 调整原因 | String | 500 | 否 | 无 | — | 员工申请调整时填写 |
| sortOrder | 排序号 | Integer | — | 否 | 0 | — | 显示排序 |
| createBy | 创建者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| createTime | 创建时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| updateBy | 更新者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| updateTime | 更新时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |

### 2.2 新增改进项请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessId | 绩效单ID | Long | 是 | — |
| improveItem | 改进项 | String | 是 | 最长500字 |
| responsiblePerson | 负责人 | String | 是 | — |
| responsibleUserId | 负责人ID | Long | 否 | — |
| deadline | 截止日期 | Date | 是 | — |
| acceptStandard | 验收标准 | String | 是 | 最长500字 |

### 2.3 员工确认改进计划请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessId | 绩效单ID | Long | 是 | — |

### 2.4 员工申请调整请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessId | 绩效单ID | Long | 是 | — |
| adjustReason | 调整原因 | String | 是 | 最长500字 |

## 3. 业务规则约束表

| 规则编号 | 触发条件 | 执行逻辑 | 影响字段 | 说明 |
|----------|----------|----------|----------|------|
| R1 | 绩效单状态非07（待改进计划确认） | 禁止操作，返回错误"当前状态不允许确认改进计划" | status | 状态校验 |
| R2 | 员工确认改进计划 | 所有改进项 confirmStatus→1，绩效单状态 07→08 | confirmStatus, status | 状态流转 |
| R3 | 员工申请调整 | 所有改进项 confirmStatus→2，通知领导重新编辑 | confirmStatus | 状态变更 |
| R4 | 领导调整后重新提交 | 改进项 confirmStatus→3→0，员工需重新确认 | confirmStatus | 重新确认 |
| R5 | 确认时改进计划为空 | 禁止确认，返回错误"改进计划不能为空" | — | 非空校验 |
| R6 | 申请调整时原因为空 | 禁止提交，返回错误"调整原因不能为空" | adjustReason | 非空校验 |

## 4. 响应示例

**成功响应示例**（查询改进计划列表）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": [
    {
      "id": 1,
      "assessId": 1,
      "improveItem": "提升项目交付时效性",
      "responsiblePerson": "张三",
      "responsibleUserId": 100,
      "deadline": "2026-07-31",
      "acceptStandard": "下月项目交付延期不超过1天",
      "confirmStatus": "0",
      "sortOrder": 1
    },
    {
      "id": 2,
      "assessId": 1,
      "improveItem": "加强跨部门沟通",
      "responsiblePerson": "张三",
      "responsibleUserId": 100,
      "deadline": "2026-07-31",
      "acceptStandard": "每月至少主导1次跨部门协作会议",
      "confirmStatus": "0",
      "sortOrder": 2
    }
  ]
}
```

**成功响应示例**（确认改进计划）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": null
}
```

**失败响应示例**（状态不允许）：
```json
{
  "code": 500,
  "msg": "当前状态不允许确认改进计划",
  "data": null
}
```

**失败响应示例**（调整原因为空）：
```json
{
  "code": 500,
  "msg": "调整原因不能为空",
  "data": null
}
```
