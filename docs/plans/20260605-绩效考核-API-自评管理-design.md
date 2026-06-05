# API 子设计文档：自评管理

- 日期：2026-06-05
- 版本：v1.0
- API 分级：B 类（含状态校验、分数校验等非标逻辑）
- 关联整体设计：[20260605-绩效考核-design.md](20260605-绩效考核-design.md)

## 1. 端点定义

| HTTP 方法 | 路径 | 说明 | 权限标识 |
|-----------|------|------|----------|
| GET | /performance/selfAssess/list/{assessId} | 查询自评内容（评分项+自评分+描述） | performance:selfAssess:list |
| POST | /performance/selfAssess/save | 保存自评草稿 | performance:selfAssess:edit |
| POST | /performance/selfAssess/submit | 提交自评 | performance:selfAssess:edit |

## 2. 请求/响应结构

### 2.1 保存自评草稿请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessId | 绩效单ID | Long | 是 | — |
| items | 评分项列表 | List\<SelfAssessItem\> | 是 | 详见下表 |

SelfAssessItem：

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| itemId | 评分项ID | Long | 是 | — |
| selfScore | 员工自评分 | BigDecimal | 否 | 保存草稿时允许为空 |
| selfDesc | 员工成果描述 | String | 否 | 保存草稿时允许为空 |

### 2.2 提交自评请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessId | 绩效单ID | Long | 是 | — |
| items | 评分项列表 | List\<SelfAssessItem\> | 是 | 所有字段必填 |

### 2.3 自评内容响应

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| assessId | 绩效单ID | Long | — |
| selfScoreTotal | 自评总分 | BigDecimal | 自动汇总 |
| items | 评分项列表 | List\<SelfAssessItemVO\> | — |

SelfAssessItemVO：

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| itemId | 评分项ID | Long | — |
| itemName | 评分项名称 | String | — |
| weight | 权重 | BigDecimal | — |
| selfScore | 员工自评分 | BigDecimal | — |
| selfDesc | 员工成果描述 | String | — |

## 3. 业务规则约束表

| 规则编号 | 触发条件 | 执行逻辑 | 影响字段 | 说明 |
|----------|----------|----------|----------|------|
| R1 | 绩效单状态非03（待员工自评） | 禁止操作，返回错误"当前状态不允许自评" | status | 状态校验 |
| R2 | 提交时任一项自评分>权重 | 禁止提交，返回错误"自评分不得超过该项权重{weight}，当前为{selfScore}" | selfScore | 分数上限 |
| R3 | 提交时任一项自评分<0 | 禁止提交，返回错误"自评分不得小于0" | selfScore | 分数下限 |
| R4 | 提交时成果描述为空 | 禁止提交，返回错误"成果描述不能为空" | selfDesc | 非空校验 |
| R5 | 提交自评成功 | 状态 03→04，自动汇总自评总分到主表 | status, selfScoreTotal | 状态流转+汇总 |
| R6 | 保存草稿 | 不校验分数和描述完整性，仅保存 | — | 草稿宽松 |

## 4. 响应示例

**成功响应示例**（查询自评内容）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "assessId": 1,
    "selfScoreTotal": 85.50,
    "items": [
      {
        "itemId": 1,
        "itemName": "项目交付",
        "weight": 40.00,
        "selfScore": 36.00,
        "selfDesc": "按时完成3个项目交付，客户满意度95%"
      },
      {
        "itemId": 2,
        "itemName": "团队协作",
        "weight": 30.00,
        "selfScore": 27.50,
        "selfDesc": "主导2次跨部门协作，解决3个技术难题"
      }
    ]
  }
}
```

**失败响应示例**（自评分超权重）：
```json
{
  "code": 500,
  "msg": "自评分不得超过该项权重40，当前为45",
  "data": null
}
```

**失败响应示例**（状态不允许）：
```json
{
  "code": 500,
  "msg": "当前状态不允许自评",
  "data": null
}
```
