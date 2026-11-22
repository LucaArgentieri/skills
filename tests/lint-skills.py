#!/usr/bin/env python3
"""Check every skill against the checklist in AGENTS.md.

Usage: python3 tests/lint-skills.py
Exit 0 when every check passes, 1 otherwise. Needs only python3.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
HARNESS_NAMES = re.compile(r"AskUserQuestion|WebFetch|TodoWrite|Task\(|CLAUDE_")
failures = []


def fail(where, msg):
    failures.append(f"{where}: {msg}")


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    fields = {}
    for line in m.group(1).splitlines():
        key, _, value = line.partition(":")
        fields[key.strip()] = value.strip()
    return fields


def links(path):
    text = path.read_text()
    for target in re.findall(r"\]\(([^)]+)\)", text):
        if re.match(r"[a-z]+:", target) or target.startswith("#"):
            continue
        if not (path.parent / target.split("#")[0]).exists():
            fail(path.relative_to(ROOT), f"broken link {target}")


plugin = json.loads((ROOT / ".claude-plugin/plugin.json").read_text())
plugin_skills = {p.lstrip("./") for p in plugin.get("skills", [])}
root_readme = (ROOT / "README.md").read_text()

skill_dirs = sorted(p.parent for p in ROOT.glob("skills/*/*/SKILL.md"))
if not skill_dirs:
    fail("skills/", "no skills found")

for d in skill_dirs:
    rel = d.relative_to(ROOT)
    skill_md = d / "SKILL.md"
    text = skill_md.read_text()
    fm = frontmatter(text)

    # 1. name matches folder, description within limits
    if fm is None:
        fail(rel, "SKILL.md has no frontmatter")
        continue
    if fm.get("name") != d.name:
        fail(rel, f"name '{fm.get('name')}' differs from folder '{d.name}'")
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", d.name) or len(d.name) > 64:
        fail(rel, "name is not lowercase-hyphen or exceeds 64 chars")
    desc = fm.get("description", "")
    if not desc:
        fail(rel, "missing description")
    elif len(desc) > 1024:
        fail(rel, f"description is {len(desc)} chars, max 1024")

    # 2. bucket README lists it
    bucket_readme = d.parent / "README.md"
    if not bucket_readme.exists() or f"./{d.name}/SKILL.md" not in bucket_readme.read_text():
        fail(rel, "missing from its bucket README.md")

    # 3. root README lists it
    if f"./{rel}/SKILL.md" not in root_readme:
        fail(rel, "missing from the root README.md")

    # 4. plugin.json lists it
    if str(rel) not in plugin_skills:
        fail(rel, "missing from .claude-plugin/plugin.json")

    # 5. agents/openai.yaml exists and matches invocation
    yaml = d / "agents/openai.yaml"
    if not yaml.exists():
        fail(rel, "missing agents/openai.yaml")
    else:
        user_invoked_fm = fm.get("disable-model-invocation") == "true"
        user_invoked_yaml = "allow_implicit_invocation: false" in yaml.read_text()
        if user_invoked_fm != user_invoked_yaml:
            fail(rel, "invocation policy differs between frontmatter and openai.yaml")

    # 6. relative links resolve
    for md in d.rglob("*.md"):
        links(md)

    # 7. no harness-specific tool names
    for f in d.rglob("*"):
        if f.is_file() and f.suffix in {".md", ".sh", ".js", ".py"}:
            for n, line in enumerate(f.read_text().splitlines(), 1):
                if HARNESS_NAMES.search(line):
                    fail(f.relative_to(ROOT), f"line {n}: harness-specific name")

    # size guideline
    lines = len(text.splitlines())
    if lines > 160:
        fail(rel, f"SKILL.md has {lines} lines, keep it under ~150")

for p in plugin_skills:
    if not (ROOT / p / "SKILL.md").exists():
        fail(".claude-plugin/plugin.json", f"lists missing skill {p}")

for md in [ROOT / "README.md", ROOT / "AGENTS.md", *ROOT.glob("skills/*/README.md")]:
    links(md)

if failures:
    print("\n".join(f"FAIL {f}" for f in failures))
    sys.exit(1)
print(f"ok: {len(skill_dirs)} skills pass the checklist")
