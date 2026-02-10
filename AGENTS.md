# 仓库指南

## 项目结构与模块组织
- `goad.py` 是 CLI 入口；`goad/` 保存核心逻辑（命令、provider、provisioner、实例管理）。
- `ansible/` 包含 playbook 与角色；`playbooks.yml` 定义各 lab 的 playbook 顺序。
- `ad/` 存放 lab 定义、数据、脚本和 provider 覆盖；`extensions/` 提供可选扩展。
- `template/` 保存 provider 模板，实例创建时会复制到 `workspace/`；`packer/` 与 `vagrant/` 存放镜像与 provider 工具。
- `docs/`（主要是 `docs/mkdocs/docs`）为文档源；`workspace/` 为生成内容，不应提交。

## 构建、测试与开发命令
- `./goad.sh` 初始化 `~/.goad/.venv`，安装 Python 与 Ansible Galaxy 依赖，并启动交互式控制台。
- `./goad.sh -t check -l GOAD -p virtualbox` 校验 provider 依赖。
- `python3 goad.py -t install -l GOAD -p virtualbox` 在非交互模式下执行单次安装任务。
- `poetry run python3 goad.py` 是使用 Poetry 管理 Python 环境时的替代方式。

## 编码风格与命名规范
- Python 使用 4 空格缩进，函数/变量用 `snake_case`，类用 `CamelCase`，常量用 `UPPER_CASE`。
- YAML/Ansible 使用 2 空格缩进；playbook 命名保持 `ansible/` 中现有 `*-servers.yml`/`*-data.yml` 模式。
- 新 lab 资产放在 `ad/<LAB>/...`；扩展放在 `extensions/<extension>/...`，并包含各自的 `ansible/` 与 `inventory`。

## 测试指南
- 本仓库没有自动化单元测试套件。
- 修改后至少运行 `./goad.sh -t check`，并验证受影响的 lab/provider 路径（例如单独运行 playbook 或在可销毁环境中完整安装）。

## 提交与合并请求指南
- Git 历史倾向于简短、直接的摘要（例如 `update doc`）；提交保持精简且聚焦。
- PR 需说明影响的 lab/provider、基础设施前置条件以及验证方式；当安装步骤或行为变化时更新 `docs/mkdocs/docs`。

## 安全与配置说明
- 该 lab 故意设计为脆弱环境；切勿部署在公网。
- 本地配置位于 `~/.goad/goad.ini`；不要提交凭据或 `workspace/` 中生成的实例状态。

## Active Technologies
- Python 3 (per `./goad.sh` bootstrap) + Ansible 2.x + Ansible playbooks/roles, Terraform with Aliyun provider, GOAD CLI (`goad.py`), packer/windows assets where needed for images (001-aliyun-provider)
- N/A（基础设施定义与清单为文件） (001-aliyun-provider)

## Recent Changes
- 001-aliyun-provider: Added Python 3 (per `./goad.sh` bootstrap) + Ansible 2.x + Ansible playbooks/roles, Terraform with Aliyun provider, GOAD CLI (`goad.py`), packer/windows assets where needed for images

---

## 长时部署与故障恢复策略（强制要求）

由于基础设施部署耗时较长（通常30分钟到数小时），以下策略**必须严格遵守**，以减少无效劳动并保留进度。

### 1. 错误处理原则 - 先重试，再撤退

遇到命令执行错误时：

1. **原地重试优先**：在报告失败或建议回滚之前，先在当前环境重试2-3次（间隔30-60秒）。许多错误是暂时性的（网络超时、资源竞争、云API限流）。

2. **诊断根因**：重试失败后，深入调查：
   - 查看日志中的具体错误信息
   - 验证资源状态（VM运行中？网络可达？服务已启动？）
   - 判断错误是可恢复的还是致命的

3. **部分恢复**：单个组件失败时，尽可能继续执行剩余步骤。次要服务的失败不应阻塞主要基础设施的搭建。

4. **断点续传**：使用 Ansible 的 `--start-at-task` 或同等机制从断点继续，而非从头重来。

### 2. 经验沉淀 - 即时记录所学

**问题解决后，必须立即记录解决方案：**

```bash
# 位置：docs/mkdocs/docs/troobleshoot.md（唯一入口）
# 格式：
# 问题：[简要描述]
# 症状：[错误信息或异常行为]
# 根因：[为什么会发生]
# 解决：[修复命令或步骤]
# 预防：[如何避免再次发生]
```

**必须记录的内容：**
- 针对特定环境需要调整的命令
- 需要延迟或重试的时序问题
- 云服务商特有的怪癖（API限制、区域差异）
- 依赖顺序问题
- 已知bug的临时解决方案

### 3. 检查点与快照策略 - 支持增量回滚

**核心原则：绝不允许"只能全量回滚"的情况发生。**

#### 快照时机
在以下阶段创建快照/检查点：
1. **基础设施就绪后**：VM/网络创建完成，配置开始前
2. **域环境搭建后**：AD域功能正常后
3. **每个重要角色完成后**：每个关键 Ansible role 执行完成后
4. **漏洞注入前**：应用故意漏洞之前

#### 按Provider实现
```bash
# Terraform系（AWS/Azure/Aliyun）：状态文件快照
cp terraform.tfstate terraform.tfstate.checkpoint-<阶段>

# VMware/ESXi：使用VM快照
# Proxmox：使用容器/VM快照
# Vagrant：使用vagrant快照命令
vagrant snapshot save <vm_name> checkpoint-<阶段>
```

#### 命名规范
```
checkpoint-<阶段>-<YYYYMMDD-HHMM>
# 示例：
# checkpoint-infra-ready-20240115-1430
# checkpoint-domain-joined-20240115-1545
# checkpoint-pre-vulns-20240115-1630
```

#### 回滚决策树
```
发生错误
    │
    ├─► 是否暂时性错误？（网络、超时）──► 重试2-3次
    │
    ├─► 是否配置错误？──► 修复配置，从当前点继续
    │
    ├─► 是否状态损坏？──► 回滚到最近的检查点
    │
    └─► 是否基础设施问题？──► 回滚到基础设施就绪检查点
                            （保留VM创建，重做配置）
```

### 4. 部署工作流 - 增量验证

**禁止盲目执行完整部署。必须分阶段验证：**

```bash
# 阶段1：仅基础设施
python3 goad.py -t install -l GOAD -p <provider>  # 基础设施完成后暂停
# 验证：VM可访问？网络已配置？
# 检查点：在此打快照

# 阶段2：域环境搭建
# 执行域相关playbook
# 验证：域功能正常？DNS正常工作？
# 检查点：在此打快照

# 阶段3：完整配置
# 继续执行剩余playbook
# 检查点：漏洞注入前打快照

# 阶段4：最终验证
# 运行完整验证套件
# 只有所有阶段通过后，才算部署完成
```

### 5. 最终验证 - 必须从头重跑

成功调试并修复问题后：

1. **记录所有修复** 到相应位置
2. **干净测试** - 销毁环境，使用记录的流程从头重建
3. **验证修复永久有效** - 确保没有遗漏手动干预步骤
4. **更新脚本** - 将所有手动修复整合到自动化脚本中

这确保了可重现性，并能发现任何未记录的手动步骤。
