# mdtk

**Mac Developer Toolkit (MDTK)** —— 一个面向 macOS 开发者的工具箱,用 zsh 编写。

为开发者、AI 工程师、从 Linux 转到 macOS 的用户、学生和重度终端用户,提供更好的终端体验。

> **状态:** v0.1.0 已发布。工具箱提供结构化日志、用户配置、缓存、Homebrew 后端、包搜索、安装建议、命令→formula 索引,以及接入 zsh 的"智能 command-not-found"。后续计划见 `.ai/ROADMAP.md`(Doctor、Plugin、更多后端)。

头条功能:输入一个没安装的命令,MDTK 会告诉你哪个 Homebrew formula 提供它、怎么装。

```
$ rg file
Found: the "rg" command is provided by the "ripgrep" formula.
Run: brew install ripgrep
```

---

## 环境要求

- **macOS**(Apple Silicon 或 Intel)
- **zsh** 5.x(macOS 默认 shell)
- **[Homebrew](https://brew.sh)**(搜索 / 安装建议 / command-not-found 功能依赖它)

> 日常使用**不需要 conda**。conda 只在**开发 MDTK 本身**时用于跑测试(见 [面向开发者](#面向开发者))。

---

## 安装(普通用户)

跑一键安装脚本:

```sh
git clone https://github.com/JoyJeeo/mdtk.git
cd mdtk
zsh scripts/install.sh
```

安装脚本会做这些事:

1. **检查环境** —— 非 macOS 或非 zsh 直接拒绝。
2. **检查 Homebrew** —— 没装的话,会打印 Homebrew 官方安装命令然后退出(**不自动跑网络脚本**,安全)。装好 Homebrew 后重跑本脚本即可。
3. **安装 `mdtk` 命令** —— 把 `bin/mdtk` 软链到第一个可写的 PATH 目录(`/usr/local/bin` 或 `~/.local/bin`)。
4. **配置 shell 钩子** —— 往 `~/.zshrc` 追加 `source <repo>/scripts/mdtk.zsh`(幂等,已存在则跳过;会先备份 `~/.zshrc`)。
5. **建命令索引** —— 跑 `mdtk index build`(brew 忙时会跳过并提示)。
6. 打印友好的完成提示。

然后**重启 shell**(或跑 `exec zsh`):

```sh
exec zsh
which mdtk        # -> /usr/local/bin/mdtk  或  ~/.local/bin/mdtk
mdtk version      # -> mdtk 0.1.0
```

> 如果重启后 `which mdtk` 仍为空,说明你的 `~/.zshrc`/`~/.zprofile` 没把 `~/.local/bin` 加进 PATH。在 `~/.zshrc` 加一行 `export PATH="$HOME/.local/bin:$PATH"`,再 `exec zsh`。

### 首次建索引

安装脚本会建一次,但**装了新的 brew formula 之后**应该重建,这样建议才准:

```sh
mdtk index build
```

---

## 使用

### 智能 command-not-found(头条功能)

装好 shell 钩子后(安装脚本已做),输入没安装的命令会自动给建议,而不是干巴巴报"command not found":

```sh
$ rg file
Found: the "rg" command is provided by the "ripgrep" formula.
Run: brew install ripgrep

$ nonexistent_cmd_xyz
No Homebrew formula found that provides "nonexistent_cmd_xyz".
Try: mdtk search nonexistent_cmd_xyz
```

也可以手动触发:

```sh
mdtk cnf rg
```

### 命令一览

| 命令 | 作用 |
| --- | --- |
| `mdtk version` | 显示已安装版本。 |
| `mdtk help` | 列出所有命令。 |
| `mdtk index build` | 从 Homebrew 建命令→formula 索引(装新 formula 后重建)。 |
| `mdtk index lookup <命令>` | 查某命令是哪个 formula 提供的(找不到 exit 1)。 |
| `mdtk index path` | 显示索引文件路径。 |
| `mdtk search <关键词>` | 搜索 Homebrew formula,一行一个。 |
| `mdtk install <命令>` | 找到提供该命令的 formula 并给安装建议(v0.1 **不自动装**)。 |
| `mdtk cnf <命令>` | command-not-found 处理(通常由 shell 钩子自动调)。 |
| `mdtk config get/set/list/path` | 读写用户配置。 |
| `mdtk cache get/set/clean/list/path` | 管理磁盘缓存。 |
| `mdtk logger --<level> "消息"` | 结构化日志(INFO/SUCCESS/WARNING/ERROR/DEBUG)。 |

### Logger 日志

```sh
mdtk logger --info "starting up"        # [INFO] starting up
mdtk logger --success "done"            # [SUCCESS] done
mdtk logger --warning "slow"            # [WARNING] slow
mdtk logger --error "failed"            # [ERROR] failed
mdtk logger --debug "x=42"             # (默认不输出,见下)
```

模式:默认带颜色 · `NO_COLOR=1` 或 `--no-color` 关色 · `--quiet`(只留 ERROR) · `--debug` 或 `MDTK_DEBUG=1` 才出 DEBUG:

```sh
NO_COLOR=1 mdtk logger --quiet --error "boom"    # 只看 error,无颜色
MDTK_DEBUG=1 mdtk logger --debug "x=42"          # 调试输出
```

### Config 配置

用户配置存在 `~/.config/mdtk/config`(遵 XDG),格式 `key=value`:

```sh
mdtk config set color on
mdtk config get color          # -> on(不存在 exit 1)
mdtk config list
mdtk config path
```

### Cache 缓存

缓存存在 `~/.cache/mdtk/`(遵 XDG)。命令索引就是其中一个缓存文件:

```sh
mdtk cache set snapshot "data"
mdtk cache get snapshot
mdtk cache list
mdtk cache clean               # 清空全部
mdtk cache clean snapshot      # 只清一个
mdtk cache path
```

### 文件都放哪了(遵 XDG)

| 类型 | 默认路径 | 用环境变量覆盖 |
| --- | --- | --- |
| 配置(用户偏好) | `~/.config/mdtk/config` | `XDG_CONFIG_HOME` |
| 缓存(含命令索引) | `~/.cache/mdtk/` | `XDG_CACHE_HOME` |
| shell 钩子 | 由安装器追加到 `~/.zshrc` | — |

---

## 卸载

```sh
# 1. 从 PATH 删 mdtk 命令
rm -f /usr/local/bin/mdtk ~/.local/bin/mdtk

# 2. 从 ~/.zshrc 删掉 shell 钩子那一行
#    (安装器会先备份 ~/.zshrc;可从 .mdtk-backup.* 副本恢复,
#     或手动删掉它加的两行:注释行 + source .../scripts/mdtk.zsh 行)

# 3. 删 MDTK 数据(可选)
rm -rf ~/.cache/mdtk ~/.config/mdtk

# 4. 删仓库克隆(可选)
rm -rf /path/to/mdtk
```

然后 `exec zsh`(或重开终端)。

---

## 面向开发者

开发者用一个**单独的**引导脚本(`scripts/dev-install.zsh`)装**测试工具链**(shellspec + shellcheck)到一个名为 `mdtk` 的 conda env,并把 `mdtk` 命令软链到该 env 的 bin(所以只有激活 env 时才有效):

```sh
git clone https://github.com/JoyJeeo/mdtk.git
cd mdtk
conda activate mdtk          # 这个 conda env 需预先存在
./scripts/dev-install.zsh    # 装 shellspec + shellcheck + 软链 mdtk

make test                    # 跑 shellspec 测试套件(98 个 example)
make lint                    # zsh -n(硬解析门)+ shellcheck(咨询)
make smoke                   # 烟测 CLI
```

> 这和普通用户的 `scripts/install.sh` 是两套:`install.sh` 装命令+钩子+索引(给用 MDTK 的人),`dev-install.zsh` 装测试工具链(给改 MDTK 的人)。

### 目录结构

```
bin/mdtk              入口(瘦脚本)
src/dispatcher.zsh    命令分发器(基础设施)
src/version.zsh       版本常量
src/<module>/         每个模块一个目录(logger/, config/, cache/, search/, install/, cnf/, ...)
src/core/             项目级只读常量
src/utils/            无状态共享工具(color, path, shell)
src/backends/         包管理器封装(homebrew, pip, ...)
tests/                shellspec 测试
scripts/              用户安装器(install.sh)+ shell 钩子(mdtk.zsh)+ 开发引导(dev-install.zsh)
docs/                 人读文档(vision, faq, architecture, development)
.ai/                  项目规范(先读这些)
AGENTS.md             AI 编程代理的指令
```

### 文档

- **`docs/vision.md`** —— MDTK 的为什么。
- **`docs/architecture.md`** —— 各部分如何拼合(叙事)。
- **`docs/development.md`** —— 如何构建、测试、贡献。
- **`docs/faq.md`** —— 常见问题。
- **`.ai/`** —— 权威规范(改代码前必读)。
- **`CHANGELOG.md`** —— 改了什么、为什么。

### 给 AI 编程代理

写代码前先读 `AGENTS.md` 和 `.ai/` 规范。**永远不要**实现 `.ai/TASK.md` 当前任务之外的功能。

---

## 许可证

MIT —— 见 [LICENSE](LICENSE)。
