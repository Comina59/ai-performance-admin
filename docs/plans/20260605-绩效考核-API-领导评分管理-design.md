# API 子设计文档：领导评分管理

- 日期：2026-06-05
- 版本：v1.0
- API 分级：B 类（含独立评分、分数校验等非标逻辑）
- 关联整体设计：[20260605-绩效考核-design.md](20260605-绩效考核-design.md)

## 1. 端点定义

| HTTP 方法 | 路径 | 说明 | 权限标识 |
|-----------|------|------|----------|
| GET | /performance/leaderScore/detail/{assessId} | 查询评分详情（左侧员工自评+右侧领导评分区） | performance:leaderScore:list |
| POST | /performance/leaderScore/save | 保存评分草稿 | performance:leaderScore:edit |
| POST | /performance/leaderScore/submit | 提交领导评分 | performance:leaderScore:edit |

## 2. 请求/响应结构

### 2.1 保存评分草稿请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessId | 绩效单ID | Long | 是 | — |
| items | 评分项列表 | List\<LeaderScoreItem\> | 是 | 详见下表 |

LeaderScoreItem：

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| itemId | 评分项ID | Long | 是 | — |
| leaderScore | 领导评分 | BigDecimal | 否 | 保存草稿时允许为空 |
| leaderComment | 领导评语 | String | 否 | 保存草稿时允许为空 |

### 2.2 提交评分请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| assessId | 绩效单ID | Long | 是 | — |
| items | 评分项列表 | List\<LeaderScoreItem\> | 是 | 所有字段必填 |

### 2.3 评分详情响应

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| assessId | 绩效单ID | Long | — |
| employeeName | 员工姓名 | String | — |
| selfScoreTotal | 自评总分 | BigDecimal | — |
| leaderScoreTotal | 领导评分总分 | BigDecimal | 自动汇总 |
| items | 评分项列表 | List\<LeaderScoreItemVO\> | — |

LeaderScoreItemVO：

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| itemId | 评分项ID | Long | — |
| itemName | 评分项名称 | String | — |
| weight | 权重 | BigDecimal | — |
| selfScore | 员工自评分 | BigDecimal | 左侧展示 |
| selfDesc | 员工成果描述 | String | 左侧展示 |
| leaderScore | 领导评分 | BigDecimal | 右侧输入/展示 |
| leaderComment | 领导评语 | String | 右侧输入/展示 |

## 3. 业务规则约束表

| 规则编号 | 触发条件 | 执行逻辑 | 影响字段 | 说明 |
|----------|----------|----------|----------|------|
| R1 | 绩效单状态非04（待领导评分） | 禁止操作，返回错误"当前状态不允许评分" | status | 状态校验 |
| R2 | 提交时任一项领导评分>权重 | 禁止提交，返回错误"领导评分不得超过该项权重{weight}，当前为{leaderScore}" | leaderScore | 分数上限 |
| R3 | 提交时任一项领导评分<0 | 禁止提交，返回错误"领导评分不得小于0" | leaderScore | 分数下限 |
| R4 | 提交评分成功 | 状态 04→05，自动汇总领导评分总分到主表，触发差异判定 | status, leaderScoreTotal | 状态流转+汇总+联动 |
| R5 | 领导评分输入区 | 默认不带入员工分数，仅展示员工内容供参考 | — | 独立评分原则 |
| R6 | 操作人非该员工的直属领导 | 禁止操作，返回错误"您不是该员工的直属领导" | — | 权限校验 |

## 4. 响应示例

**成功响应示例**（查询评分详情）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "assessId": 1,
    "employeeName": "张三",
    "selfScoreTotal": 85.50,
    "leaderScoreTotal": 78.00,
    "items": [
      {
        "itemId": 1,
        "itemName": "项目交付",
        "weight": 40.00,
        "selfScore": 36.00,
        "selfDesc": "按时完成3个项目交付，客户满意度95%",
        "leaderScore": 32.00,
        "leaderComment": "项目交付质量良好，但有一个项目延期2天"
      }
    ]
  }
}
```

**失败响应示例**（评分超权重）：
```json
{
  "code": 500,
  "msg": "领导评分不得超过该项权重40，当前为45",
  "data": null
}
```

**失败响应示例**（非直属领导）：
```json
{
  "code": 500,
  "msg": "您不是该员工的直属领导",
  "data": null
}
```
