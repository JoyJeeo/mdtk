我建议**不要用一段 Prompt**，而是用一套 **AI 软件开发规范（AI Software Engineering Specification）**。

目前像 Claude Code、Codex、Gemini CLI、Cursor、OpenCode 这类 AI 编程工具，效果最好的方式都是：

> **一份 Master Prompt + 一份 PRD + 一份 Architecture + 分阶段开发。**

而不是一句："帮我写一个 MDTK。"

---

# 我建议的目录

```text
mdtk/
│
├── .ai/
│   ├── MASTER_PROMPT.md        ⭐ AI永远遵守的规范
│   ├── PRODUCT.md              产品需求(PRD)
│   ├── ARCHITECTURE.md         架构设计
│   ├── ROADMAP.md              开发计划
│   ├── STYLE_GUIDE.md          编码规范
│   ├── TESTING.md              测试规范
│   └── TASK.md                 当前开发任务（AI只看这一份）
│
├── src/
├── tests/
├── docs/
└── ...
```

以后 Codex 每次开发：

> **只需要读取 `.ai` 目录即可。**

---

# 第一份 Prompt（MASTER_PROMPT.md）

这是最重要的一份。

你可以直接复制。

---

```markdown
# Mac Developer Toolkit (MDTK)

You are the lead software engineer responsible for building MDTK.

This is NOT a demo project.

This is a production-quality open-source project.

Everything you implement must be maintainable, testable, modular and extensible.

Never generate quick hacks.

--------------------------------------------------

# Project Goal

MDTK is a developer toolkit for macOS.

It provides a better command line experience.

Target users:

- Developers
- AI Engineers
- Linux users switching to macOS
- Students
- Heavy terminal users

--------------------------------------------------

# Core Principles

1.

Code Quality First.

Never sacrifice architecture for speed.

2.

Readable.

Code should be understandable by a junior engineer.

3.

Extensible.

Every feature must be easy to extend.

4.

Single Responsibility.

One module only has one responsibility.

5.

Do not duplicate code.

6.

Never hardcode paths.

7.

Every public function must have documentation.

8.

Every feature must have tests.

9.

Never break existing APIs.

10.

Prefer composition over inheritance.

--------------------------------------------------

# Output Style

User-facing messages must be extremely simple.

Avoid technical jargon.

Example:

❌ Command not found: rg

Searching Homebrew...

Found 2 related packages.

Recommended:

brew install ripgrep

Reason:

Installing ripgrep provides the "rg" command.

--------------------------------------------------

# Logging

Only use:

INFO

SUCCESS

WARNING

ERROR

DEBUG

No other logging styles.

--------------------------------------------------

# Architecture

Every module must be independent.

No circular dependency.

--------------------------------------------------

# Performance

Shell startup must remain fast.

Heavy operations should use cache.

--------------------------------------------------

# Testing

Every module requires tests.

Every bug fix requires regression tests.

--------------------------------------------------

# Documentation

Every module requires:

Purpose

Input

Output

Examples

--------------------------------------------------

Never implement features outside the current task.

Always follow TASK.md.

```

---

# 第二份 Prompt（PRODUCT.md）

这一份告诉 AI：

**到底要做什么。**

复制即可。

```markdown
# Product Requirement

Project Name

Mac Developer Toolkit

Short Name

MDTK

------------------------------------------------

Mission

Provide the best terminal experience for macOS developers.

------------------------------------------------

Current Features

- Smart command not found
- Homebrew search
- Install recommendation
- Command cache
- Developer doctor
- Environment diagnostics
- Better logs
- Plugin system
- Configuration system

------------------------------------------------

Future Features

- pip support

- conda support

- cargo support

- npm support

- docker support

- sdkman support

------------------------------------------------

Design Goal

Simple

Fast

Friendly

Reliable

```

---

# 第三份 Prompt（ARCHITECTURE.md）

```markdown
# Architecture

Entry

↓

Command Dispatcher

↓

Modules

Logger

Config

Cache

Search

Install

Doctor

Plugin

↓

Backends

Homebrew

pip

conda

cargo

npm

------------------------------------------------

Rules

Modules cannot call each other directly.

Everything goes through the dispatcher.

```

---

# 第四份 Prompt（STYLE_GUIDE.md）

这是我觉得最重要的一份。

```markdown
# Coding Style

Language

Shell (zsh)

------------------------------------------------

Function Naming

snake_case

------------------------------------------------

Variables

lowercase

------------------------------------------------

Constants

UPPER_CASE

------------------------------------------------

Indentation

4 spaces

------------------------------------------------

Quotes

Prefer double quotes.

------------------------------------------------

Always use:

local

inside functions.

------------------------------------------------

Never use global variables.

------------------------------------------------

Every file begins with:

Purpose

Author

Date

------------------------------------------------

Every function requires:

Description

Parameters

Return

Example

------------------------------------------------

No duplicated logic.

```

---

# 第五份 Prompt（TESTING.md）

```markdown
# Testing Rules

Every module requires tests.

Coverage target:

>90%

------------------------------------------------

Tests must include:

Success

Failure

Edge cases

Empty input

Large input

------------------------------------------------

Regression tests required.

```

---

# 第六份 Prompt（ROADMAP.md）

```markdown
v0.1

Logger

Config

Cache

Search

------------------------------------------------

v0.2

Homebrew backend

Command index

Install recommendation

------------------------------------------------

v0.3

Doctor

Plugin

------------------------------------------------

v0.4

pip backend

cargo backend

conda backend

------------------------------------------------

v1.0

Production release

```

---

# 最关键的一份（TASK.md）

以后 Codex 永远只看这一份。

例如：

```markdown
Current Task

Build Logger Module.

Requirements

Support:

INFO

SUCCESS

WARNING

ERROR

DEBUG

Support colors.

Support no-color mode.

Support quiet mode.

Support debug mode.

Write tests.

Do not modify any other module.

```

开发完 Logger 后，把 TASK.md 改成：

```markdown
Current Task

Build Cache Module.

Requirements

Implement:

cache_init

cache_get

cache_set

cache_clean

Write tests.

Do not modify Logger.

```

这样 AI 永远不会一次改整个项目。

---

# 最后，再给 Codex 一个"永久系统提示词"

每次打开 Codex 时，把下面这段作为 System Prompt（或仓库级 Instructions）：

```text
You are the lead architect of MDTK.

Read the following documents before doing anything:

.ai/MASTER_PROMPT.md
.ai/PRODUCT.md
.ai/ARCHITECTURE.md
.ai/STYLE_GUIDE.md
.ai/TESTING.md
.ai/ROADMAP.md
.ai/TASK.md

Never implement features outside TASK.md.

Never modify unrelated modules.

Never reduce code quality for speed.

Prefer maintainability over short code.

Always explain why you made architectural decisions.

Always update documentation and tests together with implementation.
```

---

## 我建议再进一步

如果你真的打算把 **MDTK** 做成一个长期项目，我建议直接采用**成熟开源项目**的工作流，而不是只依赖 Prompt：

* 在仓库根目录增加 `AGENTS.md`（Claude Code、Codex、Gemini CLI 等都越来越支持或遵循这类仓库级 AI 指令文件）。
* 将上面的 `.ai` 文档作为项目规范，`AGENTS.md` 负责告诉 AI 必须先阅读这些规范。
* 使用 GitHub Issues 管理需求，每个 Issue 对应一个 `TASK.md`，AI 一次只实现一个 Issue。
* 要求 AI **每次只提交一个功能 + 对应测试 + 对应文档**，而不是一次生成几千行代码。

这种方式比单纯的一长串提示词稳定得多，也更适合让不同 AI 编程工具长期协作开发同一个项目。
> Historical design notes. These files preserve the project's original planning conversation; `.ai/`, `README.md`, and the current source code are authoritative.
