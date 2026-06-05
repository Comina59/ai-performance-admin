# API 子设计文档：面谈管理

- 日期：2026-06-05
- 版本：v1.0
- API 分级：B 类（含状态流转、改进计划生成等非标逻辑）
- 关联整体设计：[20260605-绩效考核-design.md](20260605-绩效考核-design.md)

## 1. 端点定义

| HTTP 方法 | 路径 | 说明 | 权限标识 |
|-----------|------|------|----------|
| GET | /performance/interview/detail/{assessId} | 查询面谈详情 | performance:interview:query |
| POST | /performance/interview/save | 保存面谈记录草稿 | performance:interview:edit |
| POST | /performance/interview/complete | 完成面谈（生成改进计划） | performance:interview:edit |
| GET | /performance/interview/view/{assessId} | 员工查看面谈安排 | performance:interview:query |

## 2. 请求/响应结构

### 2.1 面谈记录实体（PerfAssessInterview）

| 字段名 | 中文名 | 类型 | 长度 | 必填 | 默认值 | 取值范围 | 说明 |
|--------|--------|------|------|------|--------|----------|------|
| id | 主键ID | Long | — | 是 | 无 | — | 自增主键 |
| assessId | 绩效单ID | Long | — | 是 | 无 | — | 关联 perf_assess.id |
| interviewTime | 面谈时间 | Date | — | 否 | 无 | — | 面谈发生时间 |
| interviewLocation | 面谈地点 | String | 128 | 否 | 无 | — | 面谈地点 |
| interviewMinutes | 面谈纪要 | String | 4000 | 否 | 无 | — | 面谈过程记录 |
| interviewSummary | 面谈总结 | String | 2000 | 否 | 无 | — | 面谈结论总结 |
| status | 状态 | String | 1 | 是 | 0 | 0=草稿, 1=已完成 | 面谈状态 |
| createBy | 创建者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| createTime | 创建时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| updateBy | 更新者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| updateTime | 更新时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |

### 2.2 保存面谈记录请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessId | 绩效单ID | Long | 是 | — |
| interviewTime | 面谈时间 | Date | 否 | 保存草稿时允许为空 |
| interviewLocation | 面谈地点 | String | 否 | — |
| interviewMinutes | 面谈纪要 | String | 否 | — |
| interviewSummary | 面谈总结 | String | 否 | — |

### 2.3 完成面谈请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessId | 绩效单ID | Long | 是 | — |
| interviewTime | 面谈时间 | Date | 是 | — |
| interviewMinutes | 面谈纪要 | String | 是 | — |
| interviewSummary | 面谈总结 | String | 是 | — |
| improveItems | 改进计划项 | List\<ImproveItemInput\> | 是 | 详见改进计划管理 |

### 2.4 面谈详情响应

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| assessId | 绩效单ID | Long | — |
| employeeName | 员工姓名 | String | — |
| diffResult | 差异判定结果 | DiffResultVO | 详见差异判定API |
| interview | 面谈记录 | PerfAssessInterview | — |
| improveItems | 改进计划项 | List\<PerfAssessImprove\> | 详见改进计划管理 |

## 3. 业务规则约束表

| 规则编号 | 触发条件 | 执行逻辑 | 影响字段 | 说明 |
|----------|----------|----------|----------|------|
| R1 | 绩效单状态非06（待绩效面谈） | 禁止操作，返回错误"当前状态不允许面谈" | status | 状态校验 |
| R2 | 完成面谈时 | 状态 06→07，同时生成改进计划 | status | 状态流转 |
| R3 | 完成面谈时面谈纪要或总结为空 | 禁止完成，返回错误"面谈纪要和总结不能为空" | interviewMinutes, interviewSummary | 非空校验 |
| R4 | 完成面谈时改进计划为空 | 禁止完成，返回错误"请至少添加一个改进项" | improveItems | 改进计划校验 |
| R5 | 操作人非该员工的直属领导 | 禁止操作，返回错误"您不是该员工的直属领导" | — | 权限校验 |

## 4. 响应示例

**成功响应示例**（查询面谈详情）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "assessId": 1,
    "employeeName": "张三",
    "diffResult": {
      "scoreDiff": 20.50,
      "diffTriggered": true,
      "topDiffItems": [
        {
          "itemName": "项目交付",
          "diffRatio": 40.00
        }
      ]
    },
    "interview": {
      "id": 1,
      "interviewTime": "2026-06-10 14:00:00",
      "interviewLocation": "会议室A",
      "interviewMinutes": "就项目交付差异进行了深入沟通...",
      "interviewSummary": "双方就评分差异达成一致，制定改进计划",
      "status": "1"
    },
    "improveItems": []
  }
}
```

**失败响应示例**（状态不允许）：
```json
{
  "code": 500,
  "msg": "当前状态不允许面谈",
  "data": null
}
```

**失败响应示例**（缺少改进项）：
```json
{
  "code": 500,
  "msg": "请至少添加一个改进项",
  "data": null
}
```
