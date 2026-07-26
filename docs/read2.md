很好，这说明**项目准备工作已经完成了**。

接下来，你的角色要从**产品经理**切换到**Tech Lead**。你的工作不再是写代码，而是**管理 AI 开发**。

我建议采用真正的软件团队开发模式：**Issue 驱动 + AI 实现 + AI Review + 人工验收**。

---

# 开发流程（以后一直重复）

以后每开发一个功能，都按照下面的流程：

```text
            GitHub Issue
                  │
                  ▼
          更新 .ai/TASK.md
                  │
                  ▼
          AI 实现当前 Issue
                  │
                  ▼
          AI 自测（Unit Test）
                  │
                  ▼
          AI Code Review
                  │
                  ▼
          修复 Review 问题
                  │
                  ▼
          人工验收
                  │
                  ▼
          Git Commit
                  │
                  ▼
          下一个 Issue
```

**千万不要让 AI 一次写完整个项目。**

---

# 我建议的 v0.1 开发顺序

这是我认为最合理的依赖关系。

| Issue | 模块                        | 为什么先做                |
| ----- | ------------------------- | -------------------- |
| #001  | Logger                    | 所有模块都会用到             |
| #002  | Config                    | 后面所有配置依赖它            |
| #003  | Utils                     | 公共函数                 |
| #004  | Cache                     | Search 依赖缓存          |
| #005  | Command Dispatcher        | CLI 入口               |
| #006  | Homebrew Backend          | 搜索基础                 |
| #007  | Search Engine             | command-not-found 核心 |
| #008  | Install Recommendation    | 安装建议                 |
| #009  | Command Index             | 建立命令索引               |
| #010  | command_not_found_handler | 第一个可用版本              |
| #011  | Install Script            | 一键安装                 |
| #012  | Doctor                    | 环境检查                 |

做到 #010，其实 MDTK 已经可以发布 **v0.1.0**。

---

# 每个 Issue 都用同一个 Prompt

例如，Issue #001（Logger）：

```text
You are implementing GitHub Issue #001.

Read all documents under .ai/.

Implement ONLY Issue #001.

Requirements:

1. Do not modify unrelated modules.

2. Follow all architecture rules.

3. Write production-quality code.

4. Write unit tests.

5. Update documentation.

6. Update examples if needed.

7. Update CHANGELOG.

8. Explain design decisions.

Before finishing:

- Run all tests.
- Review your own code.
- Make sure no duplicated logic exists.

Do not implement future Issues.
```

以后 Issue #002、#003，只需要替换 Issue 编号。

---

# 写完后，不要马上接受

让 AI 自己 Review。

Prompt：

```text
You are now a senior software reviewer.

You did NOT write this code.

Review the implementation of Issue #001.

Focus on:

- architecture
- maintainability
- readability
- performance
- shell compatibility
- edge cases
- duplicated logic
- hidden bugs
- unnecessary complexity

Do not write code.

Only review.

Classify every finding as:

Critical
Major
Minor
Suggestion

At the end, decide:

APPROVED

or

REQUEST CHANGES
```

这是提高代码质量最有效的一步。

---

# Review 完再修

再让 AI：

```text
Fix every review comment.

Do not introduce new features.

Do not change APIs.

Keep backward compatibility.

Update tests if needed.
```

---

# 最后才提交

Commit Message：

```text
feat(logger): implement structured logging system
```

然后：

```text
Issue #002
```

继续。

---

# 每个模块都要求 AI 生成测试

例如：

```
tests/logger/

logger_info_test.sh

logger_error_test.sh

logger_color_test.sh

logger_quiet_test.sh

logger_debug_test.sh
```

以后任何改动：

```text
全部测试自动跑。
```

---

# 我建议增加一个 "验收 Prompt"

每个模块完成以后，不要问：

> "有没有 Bug？"

而是：

```text
Assume this module will be used by 100,000 developers.

Be extremely critical.

Find everything that could become a maintenance problem within the next three years.

Do not praise the implementation.

Only identify weaknesses.

Suggest concrete improvements.
```

这个 Prompt 能让 AI 从长期维护的角度审视代码，而不是只看功能是否能跑。

---

# 什么时候可以发布 v0.1？

我建议设置一个明确标准：

必须完成：

* ✅ Logger
* ✅ Config
* ✅ Cache
* ✅ Dispatcher
* ✅ Homebrew Backend
* ✅ Search Engine
* ✅ Install Recommendation
* ✅ Command Index
* ✅ command_not_found_handler
* ✅ install.sh
* ✅ README
* ✅ 全部测试通过

就发布：

```text
v0.1.0
```

不要等 Doctor、Plugin、Conda 支持都做完。

---

## 我建议你现在立刻做的事

不要开始写第一个模块，而是**一次性创建整个项目的 GitHub Issues**。

建议先创建 **30 个左右的 Issue**，每个 Issue 都是一个可以独立完成、独立测试、独立 Review 的功能点。例如：

* Milestone v0.1：Logger、Config、Cache、Search、Homebrew Backend、Command Index……
* Milestone v0.2：Doctor、Plugin System……
* Milestone v0.3：pip Backend、Conda Backend、Cargo Backend……

以后你的工作就变成：

1. 选择一个 Issue。
2. 把它写进 `.ai/TASK.md`。
3. 让 AI 完成。
4. AI Review。
5. 人工验收。
6. Merge。

整个项目会像真正的软件团队一样有节奏地推进，而不是一次生成几千行代码后再返工。
