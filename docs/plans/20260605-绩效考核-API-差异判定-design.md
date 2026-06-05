# API 子设计文档：差异判定

- 日期：2026-06-05
- 版本：v1.0
- API 分级：B 类（含自动判定逻辑、阈值计算等非标逻辑）
- 关联整体设计：[20260605-绩效考核-design.md](20260605-绩效考核-design.md)

## 1. 端点定义

| HTTP 方法 | 路径 | 说明 | 权限标识 |
|-----------|------|------|----------|
| GET | /performance/diff/result/{assessId} | 查询差异判定结果 | performance:diff:query |
| POST | /performance/diff/execute/{assessId} | 手动触发差异判定（异常处理用） | performance:diff:execute |

## 2. 请求/响应结构

### 2.1 差异判定结果响应

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| assessId | 绩效单ID | Long | — |
| selfScoreTotal | 自评总分 | BigDecimal | — |
| leaderScoreTotal | 领导评分总分 | BigDecimal | — |
| scoreDiff | 总分差 | BigDecimal | |领导总分-自评总分| |
| diffTriggered | 是否触发差异 | Boolean | true=触发面谈 |
| triggerRules | 触发规则列表 | List\<DiffTriggerRule\> | 命中了哪些规则 |
| itemDiffs | 分项差异列表 | List\<ItemDiffVO\> | — |
| topDiffItems | 差异最大Top项 | List\<ItemDiffVO\> | 按差异比例降序，最多3项 |

DiffTriggerRule：

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| ruleCode | 规则编码 | String | ITEM_RATIO / TOTAL_SCORE |
| ruleName | 规则名称 | String | 单项差异比例 / 总分差 |
| threshold | 阈值 | BigDecimal | 配置的阈值 |
| actualValue | 实际值 | BigDecimal | 实际计算值 |
| triggered | 是否命中 | Boolean | — |

ItemDiffVO：

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| itemId | 评分项ID | Long | — |
| itemName | 评分项名称 | String | — |
| weight | 权重 | BigDecimal | — |
| selfScore | 员工自评分 | BigDecimal | — |
| leaderScore | 领导评分 | BigDecimal | — |
| scoreDiff | 分项差值 | BigDecimal | |领导分-员工分| |
| diffRatio | 差异比例 | BigDecimal | 差值/权重*100，百分比 |
| triggered | 是否触发 | Boolean | 差异比例≥阈值 |

## 3. 业务规则约束表

| 规则编号 | 触发条件 | 执行逻辑 | 影响字段 | 说明 |
|----------|----------|----------|----------|------|
| R1 | 领导提交评分后 | 系统自动执行差异判定，状态 05→06或07 | status | 自动触发 |
| R2 | 任一分项差异比例≥配置阈值（默认30%） | 触发面谈，状态→06 | status, diffTriggered | 规则1 |
| R3 | 总分差≥配置阈值（默认20分） | 触发面谈，状态→06 | status, diffTriggered | 规则2 |
| R4 | R2和R3均不满足 | 不触发面谈，状态→07 | status, diffTriggered | 未触发 |
| R5 | 差异比例计算 | diffRatio = |leaderScore - selfScore| / weight * 100 | diffRatio | 百分比 |
| R6 | 总分差计算 | scoreDiff = |leaderScoreTotal - selfScoreTotal| | scoreDiff | 绝对值 |
| R7 | 绩效单状态非05（差异判定中） | 手动触发时返回错误"当前状态不需要差异判定" | status | 状态校验 |

## 4. 响应示例

**成功响应示例**（差异判定结果-触发面谈）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "assessId": 1,
    "selfScoreTotal": 85.50,
    "leaderScoreTotal": 65.00,
    "scoreDiff": 20.50,
    "diffTriggered": true,
    "triggerRules": [
      {
        "ruleCode": "TOTAL_SCORE",
        "ruleName": "总分差",
        "threshold": 20,
        "actualValue": 20.50,
        "triggered": true
      },
      {
        "ruleCode": "ITEM_RATIO",
        "ruleName": "单项差异比例",
        "threshold": 30,
        "actualValue": 40,
        "triggered": true
      }
    ],
    "itemDiffs": [
      {
        "itemId": 1,
        "itemName": "项目交付",
        "weight": 40.00,
        "selfScore": 36.00,
        "leaderScore": 20.00,
        "scoreDiff": 16.00,
        "diffRatio": 40.00,
        "triggered": true
      }
    ],
    "topDiffItems": [
      {
        "itemId": 1,
        "itemName": "项目交付",
        "weight": 40.00,
        "selfScore": 36.00,
        "leaderScore": 20.00,
        "scoreDiff": 16.00,
        "diffRatio": 40.00,
        "triggered": true
      }
    ]
  }
}
```

**成功响应示例**（差异判定结果-未触发）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "assessId": 2,
    "selfScoreTotal": 85.50,
    "leaderScoreTotal": 80.00,
    "scoreDiff": 5.50,
    "diffTriggered": false,
    "triggerRules": [
      {
        "ruleCode": "TOTAL_SCORE",
        "ruleName": "总分差",
        "threshold": 20,
        "actualValue": 5.50,
        "triggered": false
      },
      {
        "ruleCode": "ITEM_RATIO",
        "ruleName": "单项差异比例",
        "threshold": 30,
        "actualValue": 12.50,
        "triggered": false
      }
    ],
    "itemDiffs": [],
    "topDiffItems": []
  }
}
```

**失败响应示例**（状态不允许）：
```json
{
  "code": 500,
  "msg": "当前状态不需要差异判定",
  "data": null
}
```
