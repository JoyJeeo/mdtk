# mdtk

**Mac Developer Toolkit (MDTK)** —— 一个面向 macOS 开发者的工具箱,用 zsh 编写。

为开发者、AI 工程师、从 Linux 转到 macOS 的用户、学生和重度终端用户,提供更好的终端体验。

> **状态:** v0.1.2 已发布。工具箱提供结构化日志、用户配置、缓存、Homebrew 后端、包搜索、安装建议、全量离线命令索引、智能 command-not-found、指定 ref 安装和自动更新。后续计划见 `.ai/ROADMAP.md`(Doctor、Plugin、更多后端)。

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

无需手动 clone，运行一键安装命令：

```sh
curl -fsSL https://raw.githubusercontent.com/JoyJeeo/mdtk/main/install.sh | zsh
```

默认安装最新的已发布 `vX.Y.Z` tag。开发者如需安装最新开发代码 `main`：

```sh
curl -fsSL https://raw.githubusercontent.com/JoyJeeo/mdtk/main/install.sh | \
  MDTK_INSTALL_CHANNEL=development zsh
```

要固定安装某个已发布 tag：

```sh
curl -fsSL https://raw.githubusercontent.com/JoyJeeo/mdtk/main/install.sh | \
  MDTK_INSTALL_REF=v0.1.1 zsh
```

重复运行同一 ref 且提交没有变化时会直接跳过安装。切换 ref 时安装器会先验证
受管 checkout 的远程来源，再获取并切换到指定 ref；选择结果记录在
`~/.local/share/mdtk/.mdtk-managed-ref`。

脚本会把受管理的代码安装到 `$XDG_DATA_HOME/mdtk`（默认 `~/.local/share/mdtk`）。如果希望先检查脚本再运行：

```sh
curl -fsSL https://raw.githubusercontent.com/JoyJeeo/mdtk/main/install.sh -o /tmp/mdtk-install.sh
less /tmp/mdtk-install.sh
zsh /tmp/mdtk-install.sh
```

已经 clone 仓库时仍可运行 `zsh install.sh`，这种本地 checkout 不会被卸载命令删除。

安装脚本会做这些事:

1. **检查环境** —— 非 macOS、非 zsh 或缺少 Git 时直接拒绝。
2. **准备受管理的 checkout** —— 远程安装放在 XDG 数据目录；重复运行会验证来源后安装指定 branch/tag ref。已有未标记目录不会被覆盖。
3. **检查 Homebrew** —— 没装的话,会打印 Homebrew 官方安装命令然后退出(**不自动跑网络脚本**,安全)。装好 Homebrew 后重跑本脚本即可。
4. **安装 `mdtk` 命令** —— 优先软链到当前 Homebrew 的可写 bin 目录（Apple Silicon 通常为 `/opt/homebrew/bin`），再尝试 `/usr/local/bin` 或已在 PATH 的 `~/.local/bin`。
5. **配置 shell 钩子** —— 往 `~/.zshrc` 添加或迁移 `source <repo>/scripts/mdtk.zsh`；修改前必须成功备份。
6. **建命令索引** —— 跑 `mdtk index build`(brew 忙时会跳过并提示)。
7. 打印友好的完成提示。

然后**重启 shell**(或跑 `exec zsh`):

```sh
exec zsh
which mdtk        # -> /usr/local/bin/mdtk  或  ~/.local/bin/mdtk
mdtk version      # -> mdtk 0.1.2
```

> 如果重启后 `which mdtk` 仍为空,说明你的 `~/.zshrc`/`~/.zprofile` 没把 `~/.local/bin` 加进 PATH。在 `~/.zshrc` 加一行 `export PATH="$HOME/.local/bin:$PATH"`,再 `exec zsh`。

### 首次建索引

安装脚本会根据 Homebrew 的完整命令元数据建立一次离线索引，未安装的 formula
所提供的命令也会包含在内。需要刷新 Homebrew 最新数据时可以重建：

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
No cached Homebrew recommendation found for "nonexistent_cmd_xyz".
Try manually: mdtk search nonexistent_cmd_xyz
```

钩子会先分析完整输入，再对排序后的本地离线索引做精确二分查询。它不会在终端前台运行
Homebrew 或访问网络，因此乱码、短词和未命中查询都能快速返回。未命中只表示
当前缓存没有建议，不代表该命令一定无法安装；需要最新结果时可按提示运行
`mdtk search <命令>`。

也可以手动触发:

```sh
mdtk cnf rg
```

### 命令一览

| 命令 | 作用 |
| --- | --- |
| `mdtk version` | 显示已安装版本。 |
| `mdtk help` | 列出所有命令。 |
| `mdtk index build` | 从 Homebrew 完整元数据建立离线命令→formula 索引。 |
| `mdtk index lookup <命令>` | 二分查询命令由哪个 formula 提供(找不到 exit 1)。 |
| `mdtk index path` | 显示索引文件路径。 |
| `mdtk search <关键词>` | 搜索 Homebrew formula,一行一个。 |
| `mdtk install <命令>` | 找到提供该命令的 formula 并给安装建议(v0.1 **不自动装**)。 |
| `mdtk uninstall [选项]` | 安全卸载 MDTK；支持预览和保留配置。 |
| `mdtk update [--ref <tag>]` | 将普通用户安装更新到最新稳定 tag 或指定 ref。 |
| `mdtk update --coder` | 将开发者安装更新到最新 `main`。 |
| `mdtk cnf <命令> [参数...]` | 分析完整输入并处理 command-not-found(通常由 shell 钩子自动调)。 |
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

缓存存在 `~/.cache/mdtk/`(遵 XDG)。完整离线命令索引
`command_index` 也保存在这里，当前 Homebrew 数据规模下通常不到 1 MB：

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
mdtk uninstall
```

命令会先显示确认提示，只删除 MDTK 管理的命令软链、shell hook、缓存和配置；普通仓库 clone 不会被删除。卸载前想查看操作，或需要无交互执行：

```sh
mdtk uninstall --dry-run
mdtk uninstall --yes
mdtk uninstall --yes --keep-config
```

修改 `~/.zshrc` 前会创建 `.mdtk-uninstall-backup.*` 备份。完成后运行 `exec zsh` 或重开终端。

---

## 更新

通过远程 installer 安装的 MDTK 可以直接更新到最新 `main`：

```sh
mdtk update
```

也可以切换到指定 branch 或 tag：

```sh
mdtk update --ref v0.1.1
```

更新会复用 installer 的 ref/origin 安全校验，并重新执行安装设置和命令索引
构建。普通的源码 clone 不会被自动修改。

---

## 面向开发者

开发者用一个**单独的**引导脚本(`scripts/dev-install.zsh`)装**测试工具链**(shellspec + shellcheck)到一个名为 `mdtk` 的 conda env,并把 `mdtk` 命令软链到该 env 的 bin(所以只有激活 env 时才有效):

```sh
git clone https://github.com/JoyJeeo/mdtk.git
cd mdtk
conda activate mdtk          # 这个 conda env 需预先存在
./scripts/dev-install.zsh    # 装 shellspec + shellcheck + 软链 mdtk

make test                    # 跑完整 shellspec 测试套件
make lint                    # zsh -n(硬解析门)+ shellcheck(咨询)
make smoke                   # 烟测 CLI
```

> 这和普通用户的顶层 `install.sh` 是两套流程：`install.sh` 准备受管理 checkout 并安装命令、hook 和索引；`scripts/dev-install.zsh` 只为贡献者安装测试工具链。

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
install.sh             普通用户的本地/远程安装入口
scripts/              checkout 安装器 + shell 钩子 + 开发引导
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
