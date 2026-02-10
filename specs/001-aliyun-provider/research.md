# research.md — Aliyun Provider Support

## Findings

### Provisioning 工具链
- **Decision**: 使用 Terraform（Aliyun provider）创建 VPC/交换机、安全组、ECS、磁盘与弹性公网（仅在显式开启时），Ansible 负责配置与域加入。  
- **Rationale**: 与现有云提供商一致的声明式 IaC，支持标签、依赖图与销毁回收；减少手写 API 交互。  
- **Alternatives considered**: 仅用 Ansible Aliyun 模块（覆盖面不足、销毁依赖弱）；直接调用阿里云 API/CLI（脚本维护成本高、幂等难）。

### 镜像与系统基线
- **Decision**: 通过 Packer 构建 Aliyun 专用基线镜像，保持与现有 GOAD Windows/Linux 基线一致；若短期缺镜像，临时使用官方公共镜像并在 Terraform 中注入初始化脚本。  
- **Rationale**: 基线一致性确保角色配置与域加入可重复，减少首次部署耗时。  
- **Alternatives considered**: 全部使用公共镜像（初始配置时间长、不一致）；手动上传本地镜像（流程复杂、验证难）。

### 网络与隔离
- **Decision**: 单地域、单可用区，专用 VPC + 交换机，私网默认关闭入站；仅在运维需求时临时打开管理入口并在验证后关闭。  
- **Rationale**: 满足宪章隔离要求与成本可控，简化路由与安全组规则。  
- **Alternatives considered**: 复用现有 VPC（隔离与清理风险高）；跨地域/多可用区（超出范围、成本高）。

### 标签与资源跟踪
- **Decision**: 统一标签集：`Project=GOAD`, `Lab=<lab>`, `Provider=aliyun`, `Instance=<instance_id>`, `Role=<hostname/role>`, `Purpose=lab`, `Owner=<operator>`, `TTL=<timestamp>`（如支持）。  
- **Rationale**: 便于成本核算、清单生成、清理残留。  
- **Alternatives considered**: 仅部分标签（难以追溯）；无 TTL（易留残留）。

### 重试与幂等
- **Decision**: 对限速、可恢复网络抖动等错误采用指数退避重试（有限重试次数）；所有任务保持幂等，清理时按标签枚举资源。  
- **Rationale**: 满足 FR-011，降低云端瞬时故障对流程的影响。  
- **Alternatives considered**: 失败即止（人工介入多）；无限重试（可能导致长时间阻塞）。

### 清单与数据源
- **Decision**: 清单依然由 `ad/<lab>/data/config.json` + `extensions/...` 驱动，Terraform/Ansible 仅作提供商映射；不在 playbook 中硬编码提供商数据。  
- **Rationale**: 遵循“数据与清单的唯一来源”，便于覆盖与调试。  
- **Alternatives considered**: 在 Terraform/Ansible 中重复定义拓扑（易漂移、难维护）。

## Resolved open questions
- 本轮未留下 NEEDS CLARIFICATION；上轮 Clarifications 已覆盖网络模式与可用性/重试策略。
