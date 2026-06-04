# SKILL.md 输出结构模板

第五步生成SKILL.md时，按以下结构组织内容。

## 1. 元数据区

标准YAML front matter，包含name和description。

## 2. Maven坐标区

用户提供的GA坐标，XML格式。

## 3. 模块级类索引区

按模块分组，每组一个表格。删除时搜索类名定位到该行整行删除即可。

示例：

```markdown
### ruoyi-common

| 类名 | 作用 | extends/implements |
|------|------|-------------------|
| BaseEntity | 抽象实体基类，含createBy/updateBy等公共字段 | implements Serializable |
| AjaxResult | 统一响应结果封装，含code/msg/data | implements Serializable |
| TableDataInfo | 分页查询响应封装，含total/rows/code/msg | implements Serializable |
```

## 4. MCP工具使用说明区

```markdown
## 代码读取工具

使用 **zbiti-code-reader** skill 按三步分层调用：

1. **tree模式**：获取目录文件树结构，定位目标文件
2. **signature_only模式**：获取类的方法签名和字段声明，了解API
3. **full模式**：获取完整源码，了解实现细节

**调用原则**：优先 tree（定位）→ signature_only（轻量）→ full（全文），按需递进。每次调用仅传1个文件路径，禁止批量传入。
```
