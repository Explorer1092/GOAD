<!--
同步影响报告
版本变更：template → 1.0.0
修改的原则：初始化（隔离与风险控制；通过 GOAD CLI 实现确定性部署；提供商一致性与模板完整性；数据与清单的唯一来源；文档、代码规范与验证）
新增章节：运行约束与技术栈；开发流程与质量闸门；治理（已填充）
移除章节：无
需要更新的模板：.specify/templates/plan-template.md ✅；.specify/templates/spec-template.md ✅；.specify/templates/tasks-template.md ✅；命令模板 ⚠（不存在命令模板）
后续 TODO：无
-->

# GOAD 宪章

## 核心原则

### I. 隔离与风险控制（不可协商）
实验室资产是有意设计为脆弱的；默认使用提供商私有网络，除非有明确文档、限定时间且获得批准，否则避免入站暴露。凭据、密钥和配置机密仅保存在本地设置（如 `~/.goad/goad.ini` 和每个实例的 `workspace/<id>/ssh_keys`）中，绝不提交。使用云时必须限定 IP 范围并规划拆除步骤。理由：防止有意脆弱的实验室意外泄漏并限制影响范围。

### II. 通过 GOAD CLI 实现确定性部署
所有实验室生命周期操作（安装、提供、部署）均通过 `./goad.sh` 或 `python3 goad.py` 运行；除临时调试外，不要手动编辑生成的 `workspace/` 产物，且永不提交。提供商产物来源于 `template/<provider>/`，与 `ad/<lab>/providers/<provider>/` 及可选的 `extensions/<extension>/providers/<provider>/` 合并；修改这些源而非生成物。合并任何影响部署或依赖的更改前，运行 `./goad.sh -t check -l <LAB> -p <PROVIDER>`。理由：确保跨用户与提供商的可重现性。

### III. 提供商一致性与模板完整性
调整部署逻辑时，评估并记录所有受支持提供商（virtualbox、vmware、proxmox、azure、aws、ludus）的行为一致性；任何有意差异都必须在文档中说明。模板、packer、vagrant 与 terraform 资产保持精简且易于覆盖；除非有保护措施，避免在共享 playbook 中嵌入特定提供商逻辑。破坏提供商兼容性时必须提供迁移说明和理由。理由：无论提供商如何都保持实验室行为一致，减少漂移。

### IV. 数据与清单的唯一来源
实验室数据存放于 `ad/<lab>/data/config.json`，扩展数据存放于 `extensions/<extension>/data/config.json`；不要在 playbook 中复制或硬编码这些值。保持清单优先级：实验室清单 → 提供商工作区清单 → 扩展清单 → `globalsettings.ini`；避免修改基础实验室清单结构。将 `workspace/<instance>/...` 视为临时状态，既不提交也不作为权威数据。理由：可预测的覆盖顺序确保确定性部署与可靠调试。

### V. 文档、代码规范与验证
任何行为或接口变化都必须更新 `docs/mkdocs/docs/` 与 `README.md`，说明提供商影响和使用说明。遵循仓库风格（Python 四空格缩进、snake_case；Ansible/YAML 两空格缩进），并避免将机密或生成资产提交到版本控制（`workspace/` 保持忽略）。至少需要验证：对受影响实验室/提供商运行对应的 `./goad.sh -t check`，并在可行时执行针对性的 playbook 或提供商冒烟测试并记录结果。理由：文档与基本验证确保高危实验室仍可使用且可信。

## 运行约束与技术栈

GOAD 是通过特定提供商虚拟基础设施交付的脆弱 Active Directory 实验室。受管入口是 `./goad.sh`（引导并提供交互式控制台）或 `python3 goad.py`（针对性任务）；隔离 Ansible 依赖时可使用 `goad_docker.sh`。支持的提供商包括 virtualbox、vmware、proxmox、azure、aws 与 ludus；proxmox 与 ludus 在部署前需要准备模板。实例位于 `workspace/<instance_id>/`，其中包含合并后的提供商文件与清单；这些生成产物必须保持未提交。全局覆盖放在 `globalsettings.ini`，用户默认配置在 `~/.goad/goad.ini`。

## 开发流程与质量闸门

设计阶段需要声明受影响的实验室、提供商和扩展，以及任何必要的隔离或暴露窗口。实现时在源位置（`ad/<lab>/...`、`extensions/<extension>/...`、`template/<provider>/`、`ansible/`、`playbooks.yml`）修改，而非生成的工作区文件，并保持 playbook 顺序。评审前，对每个受影响提供商运行 `./goad.sh -t check -l <LAB> -p <PROVIDER>`，并记录任何针对性 playbook 或冒烟验证。任何改变行为的修改都需要文档更新及简要验证说明。

## 治理

本宪章优先于其他 GOAD 交付实践指南。修订需提供理由、更新本文件并提升版本，同时记录必要的迁移或测试说明；采用语义化版本（重大变更用于不兼容的治理调整，次要版本用于新增或实质扩展原则，修订版本用于澄清）。`RATIFICATION_DATE` 记录初始采纳日期，`LAST_AMENDED_DATE` 随每次变更更新。评审必须执行宪章检查，确认隔离控制、通过 GOAD CLI 的可重现部署、提供商一致性、数据与清单源的遵循、文档更新以及验证记录。`.specify/templates/` 下的模板文件需与治理变更同步更新，保持工具一致性。

**Version**: 1.0.0 | **Ratified**: 2026-01-17 | **Last Amended**: 2026-01-17
