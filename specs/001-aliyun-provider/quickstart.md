# Quickstart — Aliyun Provider

1) **准备环境**
- 安装依赖：`./goad.sh`（引导虚拟环境与 Ansible/Terraform 依赖）。  
- 确认拥有阿里云账户/权限、region/zone、配额（ECS/磁盘/弹性公网如需）、可用实例规格。  
- 在环境变量中设置 `ALICLOUD_ACCESS_KEY`/`ALICLOUD_SECRET_KEY`（或 `ALICLOUD_ACCESS_KEY_ID`/`ALICLOUD_ACCESS_KEY_SECRET`）。  
- 在 `~/.goad/goad.ini` 中填写默认 region/zone、VPC/交换机 CIDR、标签前缀与镜像策略。

2) **预检**
- 运行：`./goad.sh -t check -l GOAD -p aliyun`。  
- 预期：配额、区域、CIDR、实例规格验证通过；若失败，按错误提示修正（权限、配额、CIDR 冲突、规格不可用）。

3) **部署**
- 运行：`python3 goad.py -t install -l GOAD -p aliyun`。  
- 执行期间自动创建专用 VPC/交换机、安全组、ECS 与标签并完成 Ansible 配置与域加入。  
- 完成后：保存私网清单与资源 ID，验证报告应显示所有节点可达并已加入域。

4) **验证**
- 如需重复验证：`python3 goad.py -t validate -l GOAD -p aliyun`（若存在对应任务），或 rerun install 的验证阶段。  
- 关注连通性、域加入与 Ansible facts。

5) **销毁**
- 运行：`python3 goad.py -t destroy -l GOAD -p aliyun`。  
- 预期：标签/清单中的资源全部删除；如有残留，输出手动清理步骤后可重跑销毁。

6) **安全与清理注意**
- 默认无公网入站；如临时开启管理入口，验证后立即关闭并销毁。  
- 不提交 `workspace/`、凭证或生成的密钥。  
- 遇限速/瞬时错误可重试；流程本身具备幂等与自动重试。

## 验证结果记录

- 预检命令：`./goad.sh -t check -l GOAD -p aliyun`
  - 结果：未执行
- 部署命令：`python3 goad.py -t install -l GOAD -p aliyun`
  - 结果：未执行
  - 部署耗时（目标 ≤90 分钟）：未记录
- 销毁命令：`python3 goad.py -t destroy -l GOAD -p aliyun`
  - 结果：未执行
  - 销毁耗时（目标 ≤30 分钟）：未记录
