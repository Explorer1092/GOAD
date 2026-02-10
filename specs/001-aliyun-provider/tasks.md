# 任务：阿里云提供商支持

**输入**：`/specs/001-aliyun-provider/` 下的设计文档  
**前置条件**：plan.md、spec.md、research.md、data-model.md、contracts/

## 格式说明：`[ID] [P?] [Story] 描述`

- **[P]**：可并行（不同文件、无依赖）
- **[Story]**：所属用户故事（如 US1、US2、US3）
- 描述中需包含精确文件路径

## 宪法门槛（GOAD）

- [ ] C001 隔离性：记录网络边界；避免除明确授权且限时的公网暴露。
- [ ] C002 可复现性：使用 `./goad.sh` 或 `python3 goad.py`；不要编辑或提交生成的 `workspace/` 产物。
- [ ] C003 提供商一致性：注明影响的提供商并说明差异原因；按需更新 `template/<provider>/` 与 `ad/<lab>/providers/<provider>/`。
- [ ] C004 数据/清单：修改依赖权威源（`ad/<lab>/data/config.json`、`extensions/<extension>/data/config.json`）并保持清单优先级。
- [ ] C005 校验与文档：规划 `./goad.sh -t check -l <LAB> -p <PROVIDER>`（含冒烟）并更新 `docs/mkdocs/docs/` 与 `README.md` 中的行为变更。

---

## 第 1 阶段：Setup（共享基础设施）

**目的**：启用阿里云提供商脚手架与配置默认值。

- [X] T001 创建阿里云提供商骨架目录 `template/provider/aliyun/` 与 `ad/GOAD/providers/aliyun/`，与现有 Terraform 提供商布局一致。
- [X] T002 在 `goad/utils.py` 中加入 `ALIYUN` 常量，并在 `goad/dependencies.py` 启用 `aliyun_enabled`（默认开）。
- [X] T003 在 `goad/config.py` 增加阿里云配置段（region/zone/VPC CIDR/NAT 开关/标签前缀占位），并将 `aliyun` 加入默认提供商选项。
- [X] T004 在 `goad/provider/provider_factory.py` 注册阿里云，并在 `goad/infos.py` 的提供商列表/帮助文本中暴露 CLI 选择。

---

## 第 2 阶段：基础（阻塞前提）

**目的**：用户故事开始前必须具备的核心资产。

- [X] T005 脚手架 Terraform 基础文件 `template/provider/aliyun/main.tf`、`variables.tf`、`outputs.tf`，包含阿里云 provider、共享 locals、NAT 开关变量，远程路径与 GOAD 布局对齐。
- [X] T006 创建实验覆盖 stub：`ad/GOAD/providers/aliyun/windows.tf`、`linux.tf` 与 `inventory`，用于接收 GOAD 角色映射与 ip_range 模板。
- [X] T007 在 `goad/provider/terraform/aliyun.py` 实现阿里云 Terraform 提供商类骨架，继承 `TerraformProvider`（路径、跳板脚本占位、NAT 默认开、标签 schema 预留、artifact 文件名）。
- [X] T008 确保共享 Terraform 驱动 `goad/provider/terraform/terraform.py` 处理阿里云特有变量/输出（region/zone/vpc_cidr/vswitch_cidrs/tags/nat 开关）且不破坏其他提供商。
- [X] T009 定义阿里云镜像来源与回退策略（优先使用 Packer 产物，公共镜像为后备），在 `template/provider/aliyun/variables.tf` 与 `goad/provider/terraform/aliyun.py` 中显式化变量/校验，并在文档/预检中验证可用性。

---

## 第 3 阶段：用户故事 1 - 在阿里云部署 GOAD 靶场（优先级：P1）🎯 MVP

**目标**：在阿里云以专用 VPC/vSwitch 部署完整 GOAD 拓扑，NAT 出站默认开启，无入站暴露，标签与清单对齐。

**独立验证**：`python3 goad.py -t install -l GOAD -p aliyun` 在目标时间内完成；清单显示全部节点拥有私网 IP；验证报告首轮 100% 节点连通且加入域。

### 用户故事 1 实施

- [X] T010 [US1] 构建阿里云网络 Terraform（`template/provider/aliyun/network.tf`）：专用 VPC/交换机、子网 CIDR、NAT 网关+SNAT 出网、安全组默认拒绝入站。
- [X] T011 [P] [US1] 在 `template/provider/aliyun/windows.tf` 与 `template/provider/aliyun/linux.tf` 为每个 GOAD 角色定义计算资源（私网 IP、标签、实例规格、磁盘、密钥/密码策略、私网网卡绑定）。
- [X] T012 [P] [US1] 在 `template/provider/aliyun/outputs.tf` 输出私网 IP、资源 ID、NAT/EIP 端点供清单与销毁使用。
- [X] T013 [US1] 在 `ad/GOAD/providers/aliyun/windows.tf` 与 `ad/GOAD/providers/aliyun/linux.tf` 映射 GOAD 实验数据到阿里云变量（角色 → 实例规格/磁盘/标签/NAT 标志）。
- [X] T014 [US1] 完成提供商清单模板 `ad/GOAD/providers/aliyun/inventory`，使用基于 `ip_range` 的私网地址并与 `ad/GOAD/data/config.json` 主机名一致。
- [X] T015 [US1] 在 `goad/provider/terraform/aliyun.py` 实现安装流程：串接 Terraform apply、标签传递（Project/Lab/Provider/Instance/Role/Owner/TTL）、NAT 默认开启、artifact 持久化。
- [X] T016 [US1] 确保私网连通性用于配置（Ansible SSH/WinRM）并写入 ValidationReport；在 `goad/provider/terraform/aliyun.py` 及必要时 `template/provider/aliyun/jumpbox.tf` 对齐跳板/NAT 输出。
- [X] T017 [US1] 增加资源级防护（默认无公网入站、安全组最小化、可选临时管理入口）于 `template/provider/aliyun/security.tf` 或等效 Terraform 文件。
- [X] T018 [US1] 强化安装与验证的幂等与重试：在 `goad/provider/terraform/aliyun.py` 与相关 Ansible/ Terraform 调用中处理限速/网络抖动的自动重试与幂等重入，记录重试日志与 rerun 行为。

---

## 第 4 阶段：用户故事 2 - 部署前就绪检查（优先级：P2）

**目标**：预检阻断配置错误的阿里云运行（凭证/配额/区域/规格/CIDR/NAT 依赖），并给出可操作的错误。

**独立验证**：`./goad.sh -t check -l GOAD -p aliyun` 在有效配置下成功；当凭证/配额/CIDR 冲突等异常时返回可操作错误且不创建资源。

### 用户故事 2 实施

- [X] T019 [US2] 在 `goad/provider/terraform/aliyun.py` 实现 `check()`：验证凭证、region/zone、实例规格、磁盘、EIP/NAT 配额，可用性可用 SDK 或 Terraform validate。
- [X] T020 [P] [US2] 在 `template/provider/aliyun/variables.tf` 增加 CIDR/重叠/参数校验与 NAT 开关校验，并在 `goad/provider/terraform/aliyun.py` 预检中强制。
- [X] T021 [US2] 规范错误提示与修复指引（缺权限、配额不足、区域不支持实例类型）于 `goad/provider/terraform/aliyun.py` 与 `goad/log.py`。
- [X] T022 [P] [US2] 为 `check()` 补充重试与幂等：对阿里云 API 限速/超时添加退避重试，确保可安全重复运行并记录失败点与恢复指引。

---

## 第 5 阶段：用户故事 3 - 安全销毁阿里云靶场（优先级：P3）

**目标**：销毁时干净删除所有带 GOAD 标签的阿里云资源（含 NAT/EIP/磁盘），且幂等。

**独立验证**：`python3 goad.py -t destroy -l GOAD -p aliyun` 删除 100% GOAD 标签资源并输出空残留清单；可重复执行无副作用。

### 用户故事 3 实施

- [X] T023 [US3] 在 `goad/provider/terraform/aliyun.py` 实现销毁流程，利用标签/工件删除 ECS/磁盘/安全组/VPC/NAT/EIP，包含临时错误的重试。
- [X] T024 [P] [US3] 确保 `template/provider/aliyun/*.tf` 中 Terraform destroy 的 targets 与依赖覆盖 NAT/EIP/路由表等，避免依赖阻塞。
- [X] T025 [US3] 在 `goad/provider/terraform/aliyun.py` 输出残留资源报告并提示手动清理步骤（含标签过滤命令）。

---

## 第 6 阶段：润色与跨领域

- [X] T026 [P] 添加提供商文档 `docs/mkdocs/docs/providers/aliyun.md` 及索引 `docs/mkdocs/docs/providers/index.md`，覆盖预检/部署/销毁/NAT 默认出网。
- [X] T027 在 `docs/mkdocs/docs/usage` 等处更新阿里云命令示例，并交叉引用 `specs/001-aliyun-provider/quickstart.md`。
- [ ] T028 运行验证：`./goad.sh -t check -l GOAD -p aliyun`、`python3 goad.py -t install -l GOAD -p aliyun`、`python3 goad.py -t destroy -l GOAD -p aliyun`；记录部署 ≤90 分钟与销毁 ≤30 分钟的达标/不达标结果与改进备注于 `specs/001-aliyun-provider/quickstart.md`。

---

## 依赖与执行顺序

- 阶段顺序：Setup → 基础 → US1（P1）→ US2（P2）→ US3（P3）→ 润色。
- US1 依赖基础完成；US2/US3 同样依赖基础并共享 Terraform/提供商骨架。
- 自然流程：运行时应先预检（US2）再安装，但实现可在 US1 完成共享资产后进行；镜像策略（T009）需在部署前确定。

## 并行机会

- Setup 中 T002–T004 可在目录（T001）建立后并行。
- 基础阶段 T005–T008 在路径就绪后大多可并行，T009 依赖镜像信息收集可与 T006 并行。
- US1 内：T011/T012 可在网络骨架后并行于 T010；T013–T014 可与 Terraform 输出并行；T016–T018 在安装串接（T015）后进行。
- US2 与 US3 在 US1 Terraform schema 稳定后可并行；T022 可与 T020 并行。

## 实施策略

- MVP = 完成阶段 1–3（US1），再用安装与验证报告校验。
- 随后加入 US2 预检以增强可靠性，再完成 US3 销毁以控制成本。
- 最后润色文档并进行端到端冒烟（T028）。
