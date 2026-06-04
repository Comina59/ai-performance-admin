# 子agent Prompt模板

第四步派发子agent时，使用以下prompt模板。`{占位符}` 由主agent替换为实际值。

```text
## 你的任务
读取以下Java文件，为每个类提取：类名、作用（一句话，需理解类的职责而非简单复述类名）、extends/implements关系。

## 文件读取方式（重要）

你必须使用Bash工具批量读取文件，禁止逐个使用Read工具。

### 读取规则
1. 每次Bash调用，拼接读取的文件总行数不超过 3000 行（参考下方文件行数表）
2. 每个文件前插入分隔符 `=== FILE: {文件路径} ===`
3. 按批次依次读取所有文件后，统一输出结果表格

### Bash命令模板（PowerShell）
$files = @("文件1路径", "文件2路径", "文件3路径")
foreach ($f in $files) {
    Write-Output "=== FILE: $f ==="
    Get-Content -LiteralPath $f -Encoding UTF8
    Write-Output ""
}

## 必须处理的文件列表（只处理这些文件，禁止处理列表外的文件）
{当前批次的文件完整路径列表}

## 文件行数表（供批量读取分批参考）
| 文件路径 | 行数 |
|---------|------|
| {文件1} | {行数1} |
| {文件2} | {行数2} |

## 作用描述要求
1. 必须基于你实际读取到的代码来总结，禁止猜测。
2. 优先使用Javadoc注释的第一句话作为作用描述。
3. 如果没有Javadoc，需要理解类的职责来描述，而非简单复述类名。
   - 好的描述："REST交互核心领域对象，封装响应码、数据和消息"
   - 差的描述："RestDomain类"
   - 好的描述："AES对称加密工具，支持RuoYi平台属性加解密"
   - 差的描述："AES工具类"
4. 对于注解类，描述其标注目标和核心属性。
5. 对于枚举类，描述其代表的业务含义。
6. 对于异常类，描述其触发的业务场景。
7. 对于@Deprecated类，在作用描述末尾标注 [已废弃]，并简述替代方案（如有）。

## extends/implements列填写规则
1. 只记录本项目内的类和JDK/第三方核心接口（如Serializable、ApplicationRunner）。
2. 省略显而易见的父类（如enum类不写extends Enum，注解类不写extends Annotation）。
3. 格式示例：`extends BaseEntity`、`implements IBaseController`、`extends BaseException`

## 严格规则
1. 你只能处理上面列出的文件。如果文件读取失败，在结果中标注"[读取失败]"，禁止猜测其内容。
2. 如果一个文件中定义了多个类/接口/枚举，每个都要单独列出。
3. 禁止虚构任何不在文件列表中的类。
4. 禁止处理test目录下的文件，即使文件列表中误包含了test路径，也必须跳过。
5. 输出格式为Markdown表格，列：| 类名 | 作用 | extends/implements |
6. 类名列不需要import路径，只需要类名本身（含泛型参数，如 AjaxResult<T>）。
7. 批量读取时，根据分隔符 `=== FILE: {路径} ===` 区分不同文件的内容，禁止混淆。
```
