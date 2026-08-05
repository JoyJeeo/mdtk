# mdtk

**Mac Developer Toolkit (MDTK)** —— 一个面向 macOS 开发者的工具箱,用 zsh 编写。

为开发者、AI 工程师、从 Linux 转到 macOS 的用户、学生和重度终端用户,提供更好的终端体验。

> **状态:** v1.0.0 生产版已发布；v1.1 的多后端离线索引正在开发。完整能力包括五个包管理器后端、显式后端选择、按需插件、环境诊断、原生 Zsh 补全、智能 command-not-found、安全安装/更新/卸载流程和可重复的离线发布门禁。

头条功能:输入一个没安装的命令,MDTK 会告诉你哪个 Homebrew formula 提供它、怎么装。

```
$ rg file
[SUCCESS] Found: the "rg" command is provided by the "ripgrep" formula.
[INFO]    Run: brew install ripgrep
```

---

## 环境要求

- **macOS**(Apple Silicon 或 Intel)
- **zsh** 5.x(macOS 默认 shell)
- **[Homebrew](https://brew.sh)**（安装器、默认搜索/建议及完整 Homebrew 离线索引依赖它）
- 可选后端命令：`pip3`/`pip`、`cargo`、`conda`、`npm`（仅在显式选择对应后端时需要）

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
  MDTK_INSTALL_CHANNEL=coder zsh
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
6. **建命令索引** —— 跑 `mdtk index build` 构建 Homebrew、pip、npm、Cargo、conda
   五个索引；单个后端失败会保留旧索引并提示，但不会中断安装。
7. 打印友好的完成提示。

安装后的 Zsh shell hook 同时启用原生 Tab 补全。它支持一级命令、模块子命令和选项；
Index 的后端、统计周期、tracking action 和报告 limit 也有静态候选。补全过程
不运行 MDTK、包管理器、Git、文件系统查询或网络请求。MDTK 不主动运行
`compinit`，由用户现有的 Zsh 配置或 shell framework 管理补全初始化。

然后**重启 shell**(或跑 `exec zsh`):

```sh
exec zsh
which mdtk        # -> /usr/local/bin/mdtk  或  ~/.local/bin/mdtk
mdtk version      # -> mdtk 1.0.0
mdtk upd<Tab>     # -> mdtk update
```

> 如果重启后 `which mdtk` 仍为空,说明你的 `~/.zshrc`/`~/.zprofile` 没把 `~/.local/bin` 加进 PATH。在 `~/.zshrc` 加一行 `export PATH="$HOME/.local/bin:$PATH"`,再 `exec zsh`。

### 首次建索引

安装脚本会建立五个离线索引：Homebrew 来自完整命令元数据，未安装 formula
所提供的命令也会包含；其他后端来自当前版本随附的热门 CLI 目录。之后需要人工
刷新时运行：

```sh
mdtk index refresh
```

---

## 使用

### 智能 command-not-found(头条功能)

装好 shell 钩子后(安装脚本已做),输入没安装的命令会自动给建议,而不是干巴巴报"command not found":

```sh
$ rg file
Found: the "rg" command is provided by the "ripgrep" formula.
Run: brew install ripgrep
Found: the "rg" command matches the "ripgrep" package in cargo.
Run: cargo install ripgrep

$ nonexistent_cmd_xyz
No cached package recommendation found for "nonexistent_cmd_xyz".
Try manually: mdtk search nonexistent_cmd_xyz
```

钩子会先分析完整输入，再依次对 Homebrew、pip、npm、Cargo、conda 本地索引做
精确二分查询，并展示全部命中及对应安装命令。它不会在终端前台运行包管理器或
访问网络，因此乱码、短词和未命中查询都能快速返回。未命中只表示
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
| `mdtk index build [--backend <名称>]` | 重建全部离线索引，或只重建指定后端。 |
| `mdtk index refresh [--backend <名称>]` | 人工刷新入口；行为与 `build` 相同。 |
| `mdtk index lookup <命令>` | 二分查询命令由哪个 formula 提供(找不到 exit 1)。 |
| `mdtk index lookup --backend <名称> <命令>` | 查询指定后端的隔离离线索引。 |
| `mdtk index lookup --all <命令>` | 按 Homebrew、pip、npm、Cargo、conda 顺序显示全部本地命中。 |
| `mdtk index path` | 显示索引文件路径。 |
| `mdtk index path --backend <名称>` | 显示指定后端的隔离索引路径。 |
| `mdtk index stats [--period 7d\|30d\|all]` | 显示本地聚合查询命中率（默认 30 天）。 |
| `mdtk index miss-tracking <enable\|disable\|status>` | 显式控制命令级 miss 记录（默认关闭）。 |
| `mdtk index miss-report [--limit 1..100]` | 显示本地高频未命中命令（默认 20 项）。 |
| `mdtk index miss-reset` | 清除详细 miss 历史，但不改变启用状态。 |
| `mdtk search [--backend <名称>] <关键词>` | 搜索 Homebrew（默认）、pip、cargo、conda 或 npm 包。 |
| `mdtk install [--backend <名称>] <命令>` | 从指定后端给出安装建议（**不自动安装**）。 |
| `mdtk uninstall [选项]` | 安全卸载 MDTK；支持预览和保留配置。 |
| `mdtk update [--ref <tag>]` | 将普通用户安装更新到最新稳定 tag 或指定 ref。 |
| `mdtk update --coder` | 将开发者安装更新到最新 `main`。 |
| `mdtk cnf <命令> [参数...]` | 分析完整输入并处理 command-not-found(通常由 shell 钩子自动调)。 |
| `mdtk doctor` | 只读检查 MDTK、macOS、Zsh、Homebrew、Shell Hook、离线索引和用户目录。 |
| `mdtk plugin list/path/run` | 查看插件目录、列出插件或显式运行一个用户插件。 |
| `mdtk config get/set/list/path` | 读写用户配置。 |
| `mdtk cache get/set/clean/list/path` | 管理磁盘缓存。 |
| `mdtk logger --<level> "消息"` | 结构化日志(INFO/SUCCESS/WARNING/ERROR/DEBUG)。 |

Homebrew 仍是默认后端。其他后端必须显式选择，Search 会访问相应 registry，Install
只打印建议而不会安装软件：

```sh
mdtk search --backend pip httpie
mdtk search --backend cargo ripgrep
mdtk install --backend conda httpie
mdtk install --backend npm typescript
```

### 环境诊断

遇到 MDTK、Homebrew、补全或命令推荐异常时，运行：

```sh
mdtk doctor
```

Doctor 仅进行本地只读检查，不会安装软件、修改配置、重建索引或访问网络。每项检查都会显示结果和可执行的修复建议；必要条件异常时返回 1，Shell Hook 或索引缺失只会警告并返回 0。

### 状态日志

MDTK 的安装、更新、推荐、卸载和错误提示统一使用以下级别样式：只给固定宽度的级别标签着色，不使用图标，正文保持终端默认颜色。版本号、路径、配置值、缓存内容和搜索结果仍输出纯文本，便于管道处理。

```sh
mdtk logger --info "starting up"        # [INFO]    starting up
mdtk logger --success "done"            # [SUCCESS] done
mdtk logger --warning "slow"            # [WARNING] slow
mdtk logger --error "failed"            # [ERROR]   failed
mdtk logger --debug "x=42"             # (默认不输出,见下)
```

模式:默认带颜色 · `NO_COLOR=1` 关闭所有状态颜色 · Logger 还支持 `--no-color` · `--quiet`(只留 ERROR) · `--debug` 或 `MDTK_DEBUG=1` 才出 DEBUG:

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

缓存存在 `~/.cache/mdtk/`(遵 XDG)。旧版 Homebrew 离线命令索引
`command_index` 继续保留，隔离的后端索引使用 `index/homebrew.idx`、
`pip.idx`、`npm.idx`、`cargo.idx` 和 `conda.idx`。查询只读取本地文件，不访问
软件仓库或网络；五个索引的容量上限合计为 80 MiB：

`mdtk index refresh` 默认依次处理 Homebrew、pip、npm、Cargo、conda。
Homebrew 使用完整 executable metadata；其他四项只编译当前 MDTK 版本随附的
热门 CLI 目录，不访问 registry。某个后端失败时会保留它原来的有效索引、继续
刷新其他后端，并最终返回非零。最近一次结果记录在 `index/manifest`。

贡献者修改 `catalogs/` 后应运行 `make catalog-check`。它只在临时目录中离线编译
四份热门 CLI 目录，显示各后端的命令数、字节数和容量上限，不改用户 XDG 索引，
也不调用包管理器、registry、Git 或 curl；人工审核步骤见 `catalogs/README.md`。

CNF 会在 `index/stats` 保存最多 1 MiB 的本地聚合事件，用于判断热门目录是否
需要扩容。事件只包含时间、命中/未命中和命中的后端集合，不包含命令名或参数，
不会上传。可用 `mdtk index stats` 查看默认 30 天命中率，或选择 `7d` / `all`。

命令级 miss 记录默认关闭。只有运行 `mdtk index miss-tracking enable` 后，MDTK
才会在权限为 `600`、最大 256 KiB 的 `index/misses` 中保存时间和缺失命令名；
参数始终不会保存。`disable` 停止新增但保留历史，`miss-reset` 才会清除历史：

```sh
mdtk index miss-tracking status
mdtk index miss-tracking enable
mdtk index miss-report --limit 20
mdtk index miss-tracking disable
mdtk index miss-reset
```

```sh
mdtk index refresh
mdtk index refresh --backend npm
mdtk cache set snapshot "data"
mdtk cache get snapshot
mdtk cache list
mdtk cache clean               # 清空全部
mdtk cache clean snapshot      # 只清一个
mdtk cache path
```

### Plugin 插件

插件是放在 `$XDG_DATA_HOME/mdtk/plugins`（默认
`~/.local/share/mdtk/plugins`）中的 `.zsh` 文件。文件名就是插件名，并须定义
唯一入口 `mdtk_plugin_main`：

```zsh
mdtk_plugin_main() {
    print -r -- "hello, ${1:-world}"
}
```

将它保存为 `hello.zsh` 后，可以显式查看和运行：

```sh
mdtk plugin path
mdtk plugin list
mdtk plugin run hello MDTK
```

MDTK 不会在 shell 启动或普通命令中自动扫描、加载插件。插件以当前用户权限执行且
不受沙箱保护，请只运行你已经审查并信任的脚本；软链接插件会被拒绝。

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

通过远程 installer 安装的 MDTK 可以直接更新到最新稳定 tag：

```sh
mdtk update
```

开发者需要跟随最新 `main` 时使用：

```sh
mdtk update --coder
```

也可以切换到指定 branch 或 tag：

```sh
mdtk update --ref v0.1.1
```

更新会复用 installer 的 ref/origin 安全校验，并重新执行安装设置和五个命令索引
构建。可选后端无法刷新时会保留已有有效索引并显示具体错误，更新本身仍可完成；
之后可手动运行 `mdtk index refresh` 重试全部后端。普通的源码 clone 不会被自动修改。

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
