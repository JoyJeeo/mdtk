

# 第一阶段：完善项目文档

今天的目标不是写代码，而是让 AI **100% 理解项目**。

项目结构应该像这样：

```text
mdtk/
├── .ai/
│   ├── MASTER_PROMPT.md
│   ├── PRODUCT.md
│   ├── ARCHITECTURE.md
│   ├── ROADMAP.md
│   ├── STYLE_GUIDE.md
│   ├── TESTING.md
│   └── TASK.md
│
├── docs/
│   ├── vision.md
│   ├── faq.md
│   ├── architecture.md
│   └── development.md
│
├── src/
├── tests/
├── scripts/
├── README.md
└── LICENSE
```

其中：

* `.ai/`：AI 的规范。
* `docs/`：给人看的文档。

---

# 第二阶段：让 AI 自己先完善文档

**不要让 AI 写代码。**

你的第一个 Prompt 应该是：

```text
Read every file under .ai/.

Your first task is NOT writing code.

Instead:

1. Review every design document.

2. Find missing requirements.

3. Find conflicting requirements.

4. Find anything that may become difficult to maintain.

5. Improve the documentation.

6. Do not write any source code.

7. Commit documentation improvements only.
```

这个 Prompt 会让 Codex 扮演 **Tech Lead**。

很多潜在问题都会在这一步暴露。

---

# 第三阶段：让 AI 设计整个目录

然后：

```
Current Task

Design the complete source tree.

Requirements:

1. Do not implement anything.

2. Only create empty files.

3. Every file must contain comments describing its responsibility.

4. Explain why this file exists.

5. No implementation.

```

最后生成类似：

```
src/

logger/

cache/

config/

doctor/

search/

brew/

plugin/

utils/

dispatcher/

core/
```

这样以后就不会越来越乱。

---

# 第四阶段：建立开发规范

这是我建议你增加的一个文件：

```
.ai/DEVELOPMENT_RULES.md
```

里面写：

```
Never modify multiple modules.

One commit = one feature.

Every feature must include:

tests

documentation

examples

CHANGELOG

Never skip tests.

Never leave TODO.

Never create dead code.

Never create duplicated functions.
```

以后 AI 会一直遵守。

---

# 第五阶段：建立 Issue 开发模式

不要：

```
TASK.md

↓

Build MDTK
```

而是：

```
TASK.md

↓

Issue #001

Logger
```

开发完：

```
Issue #002

Config
```

开发完：

```
Issue #003

Cache
```

……

AI 一次只开发一个 Issue。

---

# 第六阶段：建立 Definition of Done（DoD）

新增：

```
.ai/DOD.md
```

例如：

```
一个模块完成，必须满足：

✓ 编译通过

✓ ShellCheck 通过

✓ 测试通过

✓ README 更新

✓ Examples 更新

✓ CHANGELOG 更新

✓ 没有 TODO

✓ 没有重复代码

✓ API 有文档

否则禁止提交。
```

以后 AI 会自动检查。

---

# 第七阶段：建立 Review Prompt

每开发完一个模块。

不要直接 Merge。

而是：

```
You are NOT the developer.

You are now a senior reviewer.

Review the whole Pull Request.

Find:

architecture issues

performance problems

security issues

shell compatibility issues

maintainability problems

documentation issues

testing issues

Do not write code.

Only review.
```

这是很多人不会用 AI 的地方。

其实：

> AI Review 往往比 AI Coding 更重要。

---

# 第八阶段：开始真正开发

例如：

```
TASK.md

Current Task

Logger Module

Requirements

Implement logger.

Support

INFO

SUCCESS

WARNING

ERROR

DEBUG

Support colors.

Support no-color.

Support quiet.

Support debug.

Write tests.

Write README.

Do not modify other modules.
```

Codex 写完。

Review。

Merge。

然后：

```
TASK.md

↓

Cache
```

---

# 我建议增加一个 AGENTS.md

现在很多 AI 工具（包括 Codex、Claude Code 等）都会优先读取仓库根目录的 `AGENTS.md`。

建议内容非常简单：

```markdown
# MDTK AI Instructions

Before doing anything:

1. Read every file under .ai/

2. Follow MASTER_PROMPT.md

3. Only implement TASK.md

4. Never modify unrelated files.

5. Every implementation requires:

- tests
- documentation
- examples

6. Never skip code review.

7. Keep commits small.

```

这样你以后几乎不用重复输入提示词。
