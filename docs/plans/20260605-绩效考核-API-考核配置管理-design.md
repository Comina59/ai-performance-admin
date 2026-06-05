# API 子设计文档：考核配置管理

- 日期：2026-06-05
- 版本：v1.0
- API 分级：A 类（标准 CRUD）
- 关联整体设计：[20260605-绩效考核-design.md](20260605-绩效考核-design.md)

## 1. 端点定义

| HTTP 方法 | 路径 | 说明 | 权限标识 |
|-----------|------|------|----------|
| GET | /performance/assessConfig/list | 分页查询配置列表 | performance:assessConfig:list |
| GET | /performance/assessConfig/{id} | 查询配置详情 | performance:assessConfig:query |
| POST | /performance/assessConfig | 新增配置项 | performance:assessConfig:add |
| POST | /performance/assessConfig | 修改配置项 | performance:assessConfig:edit |
| POST | /performance/assessConfig/{ids} | 删除配置项 | performance:assessConfig:remove |

## 2. 请求/响应结构

### 2.1 考核配置实体（PerfAssessConfig）

| 字段名 | 中文名 | 类型 | 长度 | 必填 | 默认值 | 取值范围 | 说明 |
|--------|--------|------|------|------|--------|----------|------|
| id | 主键ID | Long | — | 是（新增时否） | 无 | — | 自增主键 |
| configKey | 配置项KEY | String | 64 | 是 | 无 | — | 唯一标识，如 assess.diff.item_ratio |
| configValue | 配置值 | String | 256 | 是 | 无 | — | 配置项的值 |
| configName | 配置名称 | String | 128 | 是 | 无 | — | 中文描述，如"单项差异比例阈值" |
| configType | 配置类型 | String | 16 | 是 | 无 | NUMBER/STRING/BOOLEAN | 值类型，用于前端校验 |
| status | 状态 | String | 1 | 是 | 0 | 0=正常, 1=停用 | 是否启用 |
| createBy | 创建者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| createTime | 创建时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| updateBy | 更新者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| updateTime | 更新时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| remark | 备注 | String | 500 | 否 | 无 | — | BaseEntity 继承 |

### 2.2 预置配置项

| configKey | configName | configValue | configType | 说明 |
|-----------|-----------|-------------|------------|------|
| assess.diff.item_ratio | 单项差异比例阈值 | 30 | NUMBER | 百分比，如30表示30% |
| assess.diff.total_score | 总分差阈值 | 20 | NUMBER | 分值，如20表示20分 |
| assess.improve.required | 是否强制改进计划 | true | BOOLEAN | true=强制，false=不强制 |

### 2.3 列表查询请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| configKey | 配置项KEY | String | 否 | 模糊查询 |
| configName | 配置名称 | String | 否 | 模糊查询 |
| configType | 配置类型 | String | 否 | 精确查询 |
| status | 状态 | String | 否 | 精确查询 |
| pageNum | 页码 | Integer | 否 | 默认1 |
| pageSize | 每页数量 | Integer | 否 | 默认10 |

## 3. 业务规则约束表

| 规则编号 | 触发条件 | 执行逻辑 | 影响字段 | 说明 |
|----------|----------|----------|----------|------|
| R1 | configKey 已存在 | 禁止新增，返回错误"配置项KEY已存在" | configKey | 唯一性校验 |
| R2 | configType=NUMBER 且 configValue 非数字 | 禁止保存，返回错误"数值类型配置项的值必须为数字" | configValue | 类型校验 |
| R3 | configType=BOOLEAN 且 configValue 非 true/false | 禁止保存，返回错误"布尔类型配置项的值必须为true或false" | configValue | 类型校验 |

## 4. 响应示例

**成功响应示例**（查询详情）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "id": 1,
    "configKey": "assess.diff.item_ratio",
    "configValue": "30",
    "configName": "单项差异比例阈值",
    "configType": "NUMBER",
    "status": "0",
    "createBy": "admin",
    "createTime": "2026-06-05 10:00:00",
    "remark": "差异判定：单项差异比例阈值（百分比）"
  }
}
```

**失败响应示例**（KEY重复）：
```json
{
  "code": 500,
  "msg": "配置项KEY已存在",
  "data": null
}
```

**失败响应示例**（数值类型校验失败）：
```json
{
  "code": 500,
  "msg": "数值类型配置项的值必须为数字",
  "data": null
}
```
