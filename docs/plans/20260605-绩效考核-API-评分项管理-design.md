# API 子设计文档：评分项管理

- 日期：2026-06-05
- 版本：v1.0
- API 分级：B 类（含权重校验、实时汇总等非标逻辑）
- 关联整体设计：[20260605-绩效考核-design.md](20260605-绩效考核-design.md)

## 1. 端点定义

| HTTP 方法 | 路径 | 说明 | 权限标识 |
|-----------|------|------|----------|
| GET | /performance/assessItem/list/{assessId} | 查询某绩效单的评分项列表 | performance:assessItem:list |
| POST | /performance/assessItem | 新增评分项 | performance:assessItem:add |
| POST | /performance/assessItem | 修改评分项 | performance:assessItem:edit |
| POST | /performance/assessItem/{ids} | 删除评分项 | performance:assessItem:remove |
| GET | /performance/assessItem/weightSummary/{assessId} | 查询权重合计 | performance:assessItem:list |

## 2. 请求/响应结构

### 2.1 评分项实体（PerfAssessItem）

| 字段名 | 中文名 | 类型 | 长度 | 必填 | 默认值 | 取值范围 | 说明 |
|--------|--------|------|------|------|--------|----------|------|
| id | 主键ID | Long | — | 是（新增时否） | 无 | — | 自增主键 |
| assessId | 绩效单ID | Long | — | 是 | 无 | — | 关联 perf_assess.id |
| itemName | 评分项名称 | String | 128 | 是 | 无 | — | 评分项名称 |
| weight | 权重 | BigDecimal | 5,2 | 是 | 无 | 0.01-100.00 | 权重值，所有项合计须=100 |
| sortOrder | 排序号 | Integer | — | 否 | 0 | — | 显示排序 |
| selfScore | 员工自评分 | BigDecimal | 5,2 | 否 | 无 | 0-权重值 | 员工自评打分 |
| selfDesc | 员工成果描述 | String | 2000 | 否 | 无 | — | 员工自评描述 |
| leaderScore | 领导评分 | BigDecimal | 5,2 | 否 | 无 | 0-权重值 | 领导独立打分 |
| leaderComment | 领导评语 | String | 2000 | 否 | 无 | — | 领导评语 |
| createBy | 创建者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| createTime | 创建时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| updateBy | 更新者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| updateTime | 更新时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |

### 2.2 新增评分项请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessId | 绩效单ID | Long | 是 | — |
| itemName | 评分项名称 | String | 是 | 最长128字 |
| weight | 权重 | BigDecimal | 是 | 0.01-100.00 |
| sortOrder | 排序号 | Integer | 否 | 默认0 |

### 2.3 权重合计响应

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| totalWeight | 权重合计 | BigDecimal | 所有评分项权重之和 |
| isValid | 是否有效 | Boolean | 合计=100时为true |

## 3. 业务规则约束表

| 规则编号 | 触发条件 | 执行逻辑 | 影响字段 | 说明 |
|----------|----------|----------|----------|------|
| R1 | 评分项名称为空 | 禁止保存，返回错误"评分项名称不能为空" | itemName | 非空校验 |
| R2 | 权重≤0 | 禁止保存，返回错误"权重必须大于0" | weight | 正数校验 |
| R3 | 权重>100 | 禁止保存，返回错误"单项权重不能超过100" | weight | 上限校验 |
| R4 | 绩效单状态非草稿中 | 禁止增删改评分项，返回错误"当前状态不允许编辑评分项" | — | 状态校验 |
| R5 | 删除评分项后 | 自动重算权重合计，无需额外操作 | — | 联动计算 |

## 4. 响应示例

**成功响应示例**（查询权重合计）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "totalWeight": 80.00,
    "isValid": false
  }
}
```

**失败响应示例**（权重无效）：
```json
{
  "code": 500,
  "msg": "权重必须大于0",
  "data": null
}
```

**失败响应示例**（状态不允许编辑）：
```json
{
  "code": 500,
  "msg": "当前状态不允许编辑评分项",
  "data": null
}
```
