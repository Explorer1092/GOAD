# Answer files

Answer files are generated from templates under `templates/` using
`render_answer_files.py`. Templates can include partials from
`templates/partials/` using `{{> partials/name.xml.tmpl}}`. Do not edit
generated `Autounattend.xml` files by hand.

## Layout

```
answer_files/<provider>/<os>/<variant>/<locale>/Autounattend.xml
```

- `provider`: `vsphere`, `proxmox`
- `os`: `windows_server_2016`, `windows_server_2019`, `windows_10`
- `variant`: `default`, `cloudinit`, `cloudinit_uptodate`
- `locale`: locale profile name from `variants.json`

## Regenerate

```bash
python3 packer/windows/answer_files/render_answer_files.py
```

Update or add profiles in `variants.json` under `profiles.*` (for example
`locale`, `os`, `drives`, `update_strategy`), then reference the profile
from each variant.

`VIRTIO_DRIVE` defaults to `F` in `render_answer_files.py` unless
overridden.
