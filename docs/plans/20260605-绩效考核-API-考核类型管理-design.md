# API 子设计文档：考核类型管理

- 日期：2026-06-05
- 版本：v1.0
- API 分级：A 类（标准 CRUD）
- 关联整体设计：[20260605-绩效考核-design.md](20260605-绩效考核-design.md)

## 1. 端点定义

| HTTP 方法 | 路径 | 说明 | 权限标识 |
|-----------|------|------|----------|
| GET | /performance/assessType/list | 分页查询考核类型列表 | performance:assessType:list |
| GET | /performance/assessType/{id} | 查询考核类型详情 | performance:assessType:query |
| POST | /performance/assessType | 新增考核类型 | performance:assessType:add |
| POST | /performance/assessType/edit | 修改考核类型 | performance:assessType:edit |
| POST | /performance/assessType/{ids} | 删除考核类型 | performance:assessType:remove |

## 2. 请求/响应结构

### 2.1 考核类型实体（PerfAssessType）

| 字段名 | 中文名 | 类型 | 长度 | 必填 | 默认值 | 取值范围 | 说明 |
|--------|--------|------|------|------|--------|----------|------|
| id | 主键ID | Long | — | 是（新增时否） | 无 | — | 自增主键 |
| typeName | 类型名称 | String | 32 | 是 | 无 | 周/月/季/年 | 考核周期类型名称 |
| typeCode | 类型编码 | String | 16 | 是 | 无 | WEEK/MONTH/QUARTER/YEAR | 唯一编码，用于关联 |
| status | 状态 | String | 1 | 是 | 0 | 0=正常, 1=停用 | 是否启用 |
| createBy | 创建者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| createTime | 创建时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| updateBy | 更新者 | String | 64 | 否 | 无 | — | BaseEntity 继承 |
| updateTime | 更新时间 | Date | — | 否 | 无 | — | BaseEntity 继承 |
| remark | 备注 | String | 500 | 否 | 无 | — | BaseEntity 继承 |

### 2.2 列表查询请求

| 字段名 | 中文名 | 类型 | 必填 | 说明 |
|--------|--------|------|------|------|
| typeName | 类型名称 | String | 否 | 模糊查询 |
| typeCode | 类型编码 | String | 否 | 精确查询 |
| status | 状态 | String | 否 | 精确查询 |
| pageNum | 页码 | Integer | 否 | 默认1 |
| pageSize | 每页数量 | Integer | 否 | 默认10 |

### 2.3 列表查询响应

| 字段名 | 中文名 | 类型 | 说明 |
|--------|--------|------|------|
| total | 总记录数 | long | — |
| rows | 数据列表 | List\<PerfAssessType\> | — |
| code | 状态码 | int | 200=成功 |
| msg | 消息 | String | — |

## 3. 业务规则约束表

| 规则编号 | 触发条件 | 执行逻辑 | 影响字段 | 说明 |
|----------|----------|----------|----------|------|
| R1 | typeCode 已存在 | 禁止新增，返回错误"类型编码已存在" | typeCode | 唯一性校验 |
| R2 | 考核类型下存在考核关系 | 禁止删除，返回错误"该类型下存在考核关系，无法删除" | id | 引用完整性 |
| R3 | 考核类型下存在绩效单 | 禁止停用，返回错误"该类型下存在绩效单，无法停用" | status | 引用完整性 |

## 4. 响应示例

**成功响应示例**（查询详情）：
```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {
    "id": 1,
    "typeName": "月度考核",
    "typeCode": "MONTH",
    "status": "0",
    "createBy": "admin",
    "createTime": "2026-06-05 10:00:00",
    "remark": "月度绩效考核"
  }
}
```

**失败响应示例**（编码重复）：
```json
{
  "code": 500,
  "msg": "类型编码已存在",
  "data": null
}
```

**失败响应示例**（删除被引用的类型）：
```json
{
  "code": 500,
  "msg": "该类型下存在考核关系，无法删除",
  "data": null
}
```
