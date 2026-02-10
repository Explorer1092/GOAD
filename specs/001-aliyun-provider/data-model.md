# data-model.md — Aliyun Provider Support

## Entities

### AliyunProviderConfig
- **Fields**: `access_key_id`, `access_key_secret`（或 RAM 角色/STS 令牌）、`region`, `zone`, `vpc_cidr`, `vswitch_cidrs[]`, `security_group_rules`, `instance_types`（按角色映射）、`disk_profiles`（系统/数据盘规格与加密标志）、`keypair_name`/`ssh_keys`, `tags`（统一标签集）, `ttl`（可选销毁时间戳）。  
- **Relationships**: 作用于 LabDeploymentManifest 中的所有节点；向 ResourceTags 继承默认标签。  
- **Rules**: region/zone 必填且单值；cidr 必须非重叠；禁止默认入站规则；凭证来源于本地配置，不写入仓库。

### LabDeploymentManifest
- **Fields**: `lab_name`, `nodes[]`（包含 `hostname`, `role`, `os`, `instance_type`, `disk_profile`, `private_ip`, `network` 映射, `tags`），`networks`（引用 VPC/交换机），`artifacts`（云端生成的 ids，用于回收）。  
- **Relationships**: 节点引用 AliyunProviderConfig 的 region/zone、网络与标签；artifacts 由 provisioning 创建后回写供销毁使用。  
- **Rules**: 节点数量与角色来源于 `ad/<lab>/data/config.json` 与扩展；标签覆盖遵循清单优先级；节点私网 IP 与 CIDR 匹配。

### ResourceTags
- **Fields**: `Project`, `Lab`, `Provider`, `Instance`, `Role`, `Purpose`, `Owner`, `TTL`（可选）。  
- **Relationships**: 由 AliyunProviderConfig 默认提供，可被单节点追加但不可删除核心键。  
- **Rules**: `Project=GOAD`, `Provider=aliyun` 必须存在；`Role` 与节点一致；TTL 如支持则为 ISO8601 时间戳用于清理。

### ValidationReport
- **Fields**: `connectivity`（ping/SSH/WinRM 状态）、`domain_join`（结果与日志）、`ansible_fact_gather`（成功/失败节点）、`errors[]`（含可修复建议）。  
- **Relationships**: 针对 LabDeploymentManifest 的节点生成，用于决定是否允许后续步骤或需要重试/清理。  
- **Rules**: 记录首轮结果；若失败应可重跑；与幂等重试逻辑兼容。

## State Transitions (high level)
1. **Planned**: 清单与配置解析完成，待创建。  
2. **Provisioning**: Terraform 创建网络、实例、磁盘、标签。  
3. **Configured**: Ansible 配置完成并加入域。  
4. **Validated**: 验证通过，生成 ValidationReport。  
5. **Destroying**: 执行标签枚举与销毁；清理 artifacts。  
6. **Destroyed**: 资源删除完毕，清单标记回收。
