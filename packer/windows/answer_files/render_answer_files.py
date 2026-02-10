#!/usr/bin/env python3
import json
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
VARIANTS_FILE = BASE_DIR / "variants.json"

SECTION_RE = re.compile(r"\{\{#([A-Z0-9_]+)\}\}(.*?)\{\{/\1\}\}", re.S)
VAR_RE = re.compile(r"\{\{([A-Z0-9_]+)\}\}")
INCLUDE_RE = re.compile(r"\{\{>\s*([A-Za-z0-9_./-]+)\s*\}\}")
DEFAULT_VARS = {
    "VIRTIO_DRIVE": "F",
}


def load_template(path, stack):
    path = path.resolve()
    if path in stack:
        chain = " -> ".join(str(p) for p in stack + [path])
        raise ValueError(f"include cycle detected: {chain}")

    stack.append(path)
    with open(path, "r", newline="") as f:
        text = f.read()

    def replace_include(match):
        include_ref = match.group(1)
        include_path = (path.parent / include_ref).resolve()
        try:
            include_path.relative_to(BASE_DIR)
        except ValueError as exc:
            raise ValueError(f"include path escapes base dir: {include_ref}") from exc
        if not include_path.exists():
            raise FileNotFoundError(f"include not found: {include_ref}")
        return load_template(include_path, stack)

    text = INCLUDE_RE.sub(replace_include, text)
    stack.pop()
    return text


def render_template(text, variables):
    def render_section(match):
        name = match.group(1)
        body = match.group(2)
        return body if variables.get(name) else ""

    while True:
        new_text = SECTION_RE.sub(render_section, text)
        if new_text == text:
            break
        text = new_text

    def replace_var(match):
        name = match.group(1)
        if name not in variables:
            raise KeyError(f"missing template variable: {name}")
        value = variables[name]
        if isinstance(value, bool):
            return ""
        return str(value)

    text = VAR_RE.sub(replace_var, text)

    if "{{" in text or "}}" in text:
        raise ValueError("unresolved template markers found")

    return text


def main():
    with open(VARIANTS_FILE, "r", encoding="utf-8") as f:
        variants = json.load(f)

    profiles = variants.get("profiles", {})

    for item in variants.get("variants", []):
        template_path = BASE_DIR / item["template"]
        output_path = BASE_DIR / item["output"]
        variables = DEFAULT_VARS.copy()
        for profile_type, profile_name in item.get("profiles", {}).items():
            profile_group = profiles.get(profile_type, {})
            if profile_name not in profile_group:
                raise KeyError(f"missing profile {profile_type}:{profile_name}")
            variables.update(profile_group[profile_name])
        variables.update(item.get("vars", {}))

        template = load_template(template_path, [])

        rendered = render_template(template, variables)

        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "w", newline="") as f:
            f.write(rendered)

        print(f"rendered {output_path.relative_to(BASE_DIR)}")


if __name__ == "__main__":
    main()
