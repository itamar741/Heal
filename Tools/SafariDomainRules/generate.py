#!/usr/bin/env python3
"""Generate Safari Extension domain coverage from a local domains.json source."""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
DEFAULT_SOURCE = SCRIPT_DIR / "domains.json"
MANIFEST_PATH = REPO_ROOT / "HealSafariExtension" / "Resources" / "manifest.json"
RULES_PATH = REPO_ROOT / "HealSafariExtension" / "Resources" / "rules.json"

SUPPORTED_SCHEMA_VERSION = 1
PRODUCT_RULESET_ID = "heal_domain_blocklist"
HOST_PERMISSIONS = ["<all_urls>"]
HOSTNAME_RE = re.compile(
    r"^(?=.{1,253}$)(?!-)[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?"
    r"(?:\.(?!-)[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$"
)


class DomainRulesError(Exception):
    """Raised when the domain source is invalid."""


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def normalize_hostname(raw: str) -> str:
    if not isinstance(raw, str):
        raise DomainRulesError("domain must be a string")

    value = raw.strip()
    if not value:
        raise DomainRulesError("domain must not be empty")

    if any(ch.isspace() for ch in value):
        raise DomainRulesError(f"domain must not contain spaces: {raw!r}")

    lowered = value.lower()
    if lowered.endswith("."):
        lowered = lowered[:-1]

    if not lowered:
        raise DomainRulesError(f"domain is empty after normalization: {raw!r}")

    if "*" in lowered:
        raise DomainRulesError(f"wildcard domains are not supported: {raw!r}")

    if "://" in lowered or lowered.startswith("//"):
        raise DomainRulesError(f"schemes are not allowed: {raw!r}")

    if any(ch in lowered for ch in "/?#"):
        raise DomainRulesError(
            f"paths, query strings, and fragments are not allowed: {raw!r}"
        )

    if ":" in lowered:
        raise DomainRulesError(f"ports are not allowed: {raw!r}")

    if lowered.startswith(".") or lowered.endswith(".") or ".." in lowered:
        raise DomainRulesError(f"malformed hostname: {raw!r}")

    if not HOSTNAME_RE.fullmatch(lowered):
        raise DomainRulesError(f"malformed hostname: {raw!r}")

    return lowered


def load_source(path: Path) -> list[dict[str, Any]]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise DomainRulesError(f"source file not found: {path}") from None
    except json.JSONDecodeError as exc:
        raise DomainRulesError(f"invalid JSON in {path}: {exc}") from None

    if not isinstance(payload, dict):
        raise DomainRulesError("source root must be an object")

    schema_version = payload.get("schemaVersion")
    if schema_version != SUPPORTED_SCHEMA_VERSION:
        raise DomainRulesError(
            f"unsupported schemaVersion {schema_version!r}; "
            f"expected {SUPPORTED_SCHEMA_VERSION}"
        )

    domains = payload.get("domains")
    if not isinstance(domains, list):
        raise DomainRulesError("'domains' must be an array")
    if not domains:
        raise DomainRulesError("'domains' must not be empty")

    normalized: list[dict[str, Any]] = []
    seen: set[str] = set()

    for index, entry in enumerate(domains):
        if not isinstance(entry, dict):
            raise DomainRulesError(f"domains[{index}] must be an object")

        if "domain" not in entry:
            raise DomainRulesError(f"domains[{index}] missing required 'domain'")

        include_subdomains = entry.get("includeSubdomains", False)
        if not isinstance(include_subdomains, bool):
            raise DomainRulesError(
                f"domains[{index}].includeSubdomains must be a boolean"
            )

        purpose = entry.get("purpose")
        if purpose is not None and not isinstance(purpose, str):
            raise DomainRulesError(f"domains[{index}].purpose must be a string")

        domain = normalize_hostname(entry["domain"])
        if domain in seen:
            raise DomainRulesError(
                f"duplicate domain after normalization: {domain!r}"
            )
        seen.add(domain)

        normalized.append(
            {
                "domain": domain,
                "includeSubdomains": include_subdomains,
                "purpose": purpose,
            }
        )

    normalized.sort(key=lambda item: item["domain"])
    return normalized


def build_rules(domains: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rules: list[dict[str, Any]] = []
    for index, entry in enumerate(domains, start=1):
        rules.append(
            {
                "id": index,
                "priority": 1,
                "action": {
                    "type": "redirect",
                    "redirect": {
                        "extensionPath": "/blocked.html",
                    },
                },
                "condition": {
                    "urlFilter": f"||{entry['domain']}^",
                    "resourceTypes": ["main_frame"],
                },
            }
        )
    return rules


def update_manifest(manifest: dict[str, Any]) -> None:
    if "declarative_net_request" not in manifest:
        raise DomainRulesError(
            "manifest.json is missing declarative_net_request; "
            "refusing to invent a ruleset reference"
        )

    rule_resources = manifest["declarative_net_request"].get("rule_resources")
    if not isinstance(rule_resources, list) or not rule_resources:
        raise DomainRulesError(
            "manifest.json is missing a static ruleset reference"
        )

    rules_json_resources = [
        item
        for item in rule_resources
        if isinstance(item, dict) and item.get("path") == "rules.json"
    ]
    if not rules_json_resources:
        raise DomainRulesError(
            "manifest.json static ruleset reference must point to rules.json"
        )

    for item in rules_json_resources:
        item["id"] = PRODUCT_RULESET_ID
        item["enabled"] = True
        item["path"] = "rules.json"

    # Production permission model: one All Websites grant; DNR rules scope blocking.
    manifest["host_permissions"] = list(HOST_PERMISSIONS)
    manifest["web_accessible_resources"] = [
        {
            "resources": ["blocked.html"],
            "matches": list(HOST_PERMISSIONS),
        }
    ]


def write_json(path: Path, value: Any) -> None:
    text = json.dumps(value, indent=4, ensure_ascii=False) + "\n"
    path.write_text(text, encoding="utf-8")


def generate(source_path: Path) -> None:
    started = time.perf_counter()
    domains = load_source(source_path)
    rules = build_rules(domains)

    try:
        manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    except FileNotFoundError:
        fail(f"manifest not found: {MANIFEST_PATH}")
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in manifest: {exc}")

    if not isinstance(manifest, dict):
        fail("manifest.json root must be an object")

    try:
        update_manifest(manifest)
    except DomainRulesError as exc:
        fail(str(exc))

    write_json(MANIFEST_PATH, manifest)
    write_json(RULES_PATH, rules)

    elapsed_ms = (time.perf_counter() - started) * 1000.0
    subdomain_count = sum(1 for item in domains if item["includeSubdomains"])
    print(
        "Safari domain rules generated: "
        f"{len(domains)} domain(s), "
        f"{subdomain_count} with subdomains, "
        f"{len(rules)} DNR rule(s), "
        f"{len(HOST_PERMISSIONS)} host permission(s)."
    )
    print(f"Source: {source_path}")
    print(f"Updated: {MANIFEST_PATH.relative_to(REPO_ROOT)}")
    print(f"Updated: {RULES_PATH.relative_to(REPO_ROOT)}")
    print(f"Manifest size bytes: {MANIFEST_PATH.stat().st_size}")
    print(f"Rules size bytes: {RULES_PATH.stat().st_size}")
    print(f"Duration ms: {elapsed_ms:.1f}")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Generate HealSafariExtension domain coverage from a local "
            "domains.json source of truth."
        )
    )
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help=f"Path to domains.json (default: {DEFAULT_SOURCE})",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    source_path = args.source.resolve()

    try:
        generate(source_path)
    except DomainRulesError as exc:
        fail(str(exc))
    except SystemExit:
        raise
    except Exception as exc:  # pragma: no cover - unexpected failure path
        fail(f"unexpected failure: {exc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
