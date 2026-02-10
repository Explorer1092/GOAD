# contracts — Aliyun Provider

## CLI Contracts

### Provider Check (`./goad.sh -t check -l <LAB> -p aliyun`)
- **Inputs**: `LAB` (e.g., GOAD)，`region`, `zone`, `credentials`（本地配置），`vpc_cidr`, `vswitch_cidrs`, `instance_type_map`, `disk_profiles`, `tags`.  
- **Behavior**: 验证凭证有效性、区域/可用区可用度、配额（ECS/磁盘/弹性公网，如开启）、网络 CIDR 合法性、实例规格可用性。  
- **Outputs**: 通过/失败；失败返回可操作错误（缺权限、配额不足、CIDR 冲突、规格不可用）。  
- **Idempotency**: 幂等，不创建资源。  
- **Errors**: 限速/瞬时错误应自动重试有限次数。

### Install (`python3 goad.py -t install -l <LAB> -p aliyun`)
- **Inputs**: `LAB`，`region`, `zone`, `vpc_cidr`, `vswitch_cidrs`, `security_group_rules`, `instance_type_map`, `disk_profiles`, `keypair`/`ssh_keys`, `tags`, 可选 `temp_public_access`。  
- **Behavior**: Terraform 创建网络/实例/磁盘/标签（遵守单地域单可用区）；Ansible 配置并域加入；生成/更新清单与 artifacts 供后续操作。  
- **Outputs**: 清单与 artifacts（资源 ID、私网 IP、标签）；ValidationReport（连通性/域加入/Ansible facts）。  
- **Idempotency**: 幂等；对临时错误自动重试；残留资源按标签对齐。  
- **Errors**: 若失败，返回剩余资源列表与清理指导。

### Destroy (`python3 goad.py -t destroy -l <LAB> -p aliyun`)
- **Inputs**: `LAB`，`tags`/`artifacts`（源于 install），同一 region/zone。  
- **Behavior**: 按标签与 artifacts 枚举并删除实例、磁盘、网络等；更新清单为已移除。  
- **Outputs**: 清理报告（删除成功/失败项）；未删资源的手动步骤。  
- **Idempotency**: 幂等；可多次运行以清理残留。  
- **Errors**: 对临时错误自动重试，保留未删除列表。

## Data Contracts (derived from data-model)
- `AliyunProviderConfig`: 详见 data-model.md；凭证与区域必填。  
- `ResourceTags`: `Project=GOAD`, `Provider=aliyun`, `Lab`, `Instance`, `Role`, `Purpose=lab`, `Owner`, 可选 `TTL`。  
- `ValidationReport`: 包含 connectivity/domain_join/facts 状态与错误摘要。
