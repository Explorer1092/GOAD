# Implementation Plan: Aliyun Provider Support

**Branch**: `[001-aliyun-provider]` | **Date**: 2026-01-17 | **Spec**: /Users/user/Code/github.com/Orange-Cyberdefense/GOAD/specs/001-aliyun-provider/spec.md  
**Input**: Feature specification from `/specs/001-aliyun-provider/spec.md`

## Summary

Add Aliyun as a GOAD provider with parity to existing providers: single地域专用 VPC/交换机部署、预检（凭证/配额/区域）、全拓扑部署、验证与销毁。技术路径：GOAD CLI 驱动 Ansible + Terraform（Aliyun provider）完成网络/计算/存储创建，统一标签与清单生成，提供幂等与对临时云端错误的自动重试。

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Python 3 (per `./goad.sh` bootstrap) + Ansible 2.x  
**Primary Dependencies**: Ansible playbooks/roles, Terraform with Aliyun provider, GOAD CLI (`goad.py`), packer/windows assets where needed for images  
**Storage**: N/A（基础设施定义与清单为文件）  
**Testing**: `./goad.sh -t check -l GOAD -p aliyun`，Ansible 连通性与域加入验证，冒烟部署/销毁  
**Target Platform**: 阿里云 IaaS（单地域、单可用区、专用 VPC/交换机）  
**Project Type**: CLI 驱动的基础设施自动化  
**Performance Goals**: 部署 ≤90 分钟完成默认 GOAD 实例；首轮验证 100% 节点可达并域加入  
**Constraints**: 私网隔离、无默认公网入站；统一标签；幂等与对临时云端错误自动重试；单地域单可用区“最好努力”可用性  
**Scale/Scope**: 默认 GOAD 拓扑（约 8-10 台节点），单次部署/销毁一个实验室实例

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Isolation: PASS — 单地域专用 VPC/交换机，默认无公网入站；临时暴露需显式选择与拆除。  
- Reproducibility: PASS — 全部通过 `./goad.sh`/`python3 goad.py`，不手改 `workspace/`。  
- Provider parity: PASS — 目标与现有 providers 同步（install/check/destroy），差异仅限 Aliyun 必需配置并将记录。  
- Data and inventories: PASS — 仅调整 `template/aliyun/` 与 `ad/<lab>/providers/aliyun/` 覆盖，保持清单优先级（lab→provider workspace→extensions→globalsettings）。  
- Documentation and verification: PASS — 计划更新 `docs/mkdocs/docs` 使用说明；执行 `./goad.sh -t check -l GOAD -p aliyun` + 部署/销毁冒烟。
- Post-Phase1 Re-check: PASS — 设计产物（research/data-model/contracts/quickstart）遵循隔离、可重现与数据源原则。

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
goad.py
goad/                 # CLI 逻辑、命令、提供商框架
ansible/              # playbooks/roles
template/             # provider 模板（将新增 aliyun）
ad/                   # 实验室定义与 provider 覆盖
extensions/           # 可选扩展
docs/mkdocs/docs/     # 文档来源
packer/, vagrant/     # 镜像/提供商工具
.specify/             # 规范与计划资产
workspace/            # 生成物（不提交）
```

**Structure Decision**: 使用现有 GOAD 单仓库布局；在 `template/` 与 `ad/<lab>/providers/` 下新增/扩展 aliyun 资源，保持 CLI 与 Ansible 入口不变。

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | Not applicable | Existing provider pattern suffices |
