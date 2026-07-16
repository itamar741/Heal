#!/usr/bin/env python3
"""Import verified-license external hosts snapshots into Heal's domains.json."""

from __future__ import annotations

import argparse
import hashlib
import ipaddress
import json
import re
import sys
import time
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_METADATA = SCRIPT_DIR / "source-metadata.json"
DEFAULT_ALLOWLIST = SCRIPT_DIR / "allowlist.json"
DEFAULT_LOCAL_ADDITIONS = SCRIPT_DIR / "local-additions.json"
DEFAULT_OUTPUT = SCRIPT_DIR / "domains.json"

SUPPORTED_SCHEMA_VERSION = 1
HOSTNAME_RE = re.compile(
    r"^(?=.{1,253}$)(?!-)[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?"
    r"(?:\.(?!-)[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$"
)


class HostsImportError(Exception):
    """Raised when the hosts import cannot proceed safely."""


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_json_object(path: Path) -> dict[str, Any]:
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise HostsImportError(f"file not found: {path}") from None
    except json.JSONDecodeError as exc:
        raise HostsImportError(f"invalid JSON in {path}: {exc}") from None
    if not isinstance(payload, dict):
        raise HostsImportError(f"root of {path} must be an object")
    return payload


def load_metadata(path: Path) -> dict[str, Any]:
    payload = load_json_object(path)
    schema_version = payload.get("schemaVersion")
    if schema_version != SUPPORTED_SCHEMA_VERSION:
        raise HostsImportError(
            f"unsupported metadata schemaVersion {schema_version!r}; "
            f"expected {SUPPORTED_SCHEMA_VERSION}"
        )

    snapshot_date = payload.get("snapshotDate")
    if not isinstance(snapshot_date, str) or not snapshot_date.strip():
        raise HostsImportError("metadata snapshotDate must be a non-empty string")

    sources = payload.get("sources")
    if not isinstance(sources, list) or not sources:
        raise HostsImportError("metadata 'sources' must be a non-empty array")

    seen_ids: set[str] = set()
    normalized_sources: list[dict[str, Any]] = []
    for index, source in enumerate(sources):
        if not isinstance(source, dict):
            raise HostsImportError(f"sources[{index}] must be an object")

        required = (
            "id",
            "name",
            "projectUrl",
            "sourceUrl",
            "license",
            "snapshotFilename",
            "sha256",
            "expectedEntryCount",
        )
        for key in required:
            if key not in source:
                raise HostsImportError(
                    f"sources[{index}] missing required field {key!r}"
                )

        source_id = source["id"]
        if not isinstance(source_id, str) or not source_id.strip():
            raise HostsImportError(f"sources[{index}].id must be a non-empty string")
        if source_id in seen_ids:
            raise HostsImportError(f"duplicate source id: {source_id!r}")
        seen_ids.add(source_id)

        sha = source["sha256"]
        if not isinstance(sha, str) or len(sha) != 64:
            raise HostsImportError(
                f"sources[{index}].sha256 must be a 64-character hex string"
            )

        expected = source["expectedEntryCount"]
        if not isinstance(expected, int) or expected < 0:
            raise HostsImportError(
                f"sources[{index}].expectedEntryCount must be a non-negative integer"
            )

        for key in (
            "name",
            "projectUrl",
            "sourceUrl",
            "license",
            "snapshotFilename",
        ):
            value = source[key]
            if not isinstance(value, str) or not value.strip():
                raise HostsImportError(
                    f"sources[{index}].{key} must be a non-empty string"
                )

        filename = source["snapshotFilename"]
        if Path(filename).name != filename or "/" in filename or "\\" in filename:
            raise HostsImportError(
                f"sources[{index}].snapshotFilename must be a bare filename"
            )

        normalized_sources.append(source)

    payload = dict(payload)
    payload["sources"] = normalized_sources
    return payload


def normalize_hostname(raw: str) -> str | None:
    """Return a normalized hostname, or None if the value is invalid."""
    if not isinstance(raw, str):
        return None

    value = raw.strip()
    if not value:
        return None

    if any(ch.isspace() for ch in value):
        return None

    lowered = value.lower()
    if lowered.endswith("."):
        lowered = lowered[:-1]

    if not lowered:
        return None

    if "*" in lowered:
        return None

    if "://" in lowered or lowered.startswith("//"):
        return None

    if any(ch in lowered for ch in "/?#"):
        return None

    if ":" in lowered:
        return None

    if lowered.startswith(".") or lowered.endswith(".") or ".." in lowered:
        return None

    try:
        ipaddress.ip_address(lowered)
        return None
    except ValueError:
        pass

    if not HOSTNAME_RE.fullmatch(lowered):
        return None

    return lowered


def parse_hosts_file(path: Path) -> tuple[set[str], int, int]:
    """Parse hosts-format lines into a unique domain set.

    Returns (domains, parsed_entry_count, invalid_entry_count).
    """
    parsed = 0
    invalid = 0
    unique: set[str] = set()

    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError as exc:
        raise HostsImportError(f"unable to read hosts snapshot: {exc}") from exc

    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        if "#" in stripped:
            stripped = stripped.split("#", 1)[0].strip()
            if not stripped:
                continue

        parts = stripped.split()
        if len(parts) < 2:
            invalid += 1
            continue

        address = parts[0]
        try:
            ipaddress.ip_address(address)
        except ValueError:
            invalid += 1
            continue

        for raw_name in parts[1:]:
            parsed += 1
            normalized = normalize_hostname(raw_name)
            if normalized is None:
                invalid += 1
                continue
            unique.add(normalized)

    return unique, parsed, invalid


def load_hostname_list(path: Path, label: str) -> list[str]:
    payload = load_json_object(path)
    schema_version = payload.get("schemaVersion")
    if schema_version != SUPPORTED_SCHEMA_VERSION:
        raise HostsImportError(
            f"unsupported {label} schemaVersion {schema_version!r}; "
            f"expected {SUPPORTED_SCHEMA_VERSION}"
        )

    domains = payload.get("domains")
    if not isinstance(domains, list):
        raise HostsImportError(f"{label} 'domains' must be an array")

    normalized: list[str] = []
    seen: set[str] = set()
    for index, entry in enumerate(domains):
        if isinstance(entry, str):
            raw = entry
        elif isinstance(entry, dict) and "domain" in entry:
            raw = entry["domain"]
        else:
            raise HostsImportError(
                f"{label} domains[{index}] must be a hostname string or object"
            )

        host = normalize_hostname(raw)
        if host is None:
            raise HostsImportError(
                f"{label} domains[{index}] is not a valid hostname"
            )
        if host in seen:
            raise HostsImportError(
                f"{label} contains duplicate hostname after normalization"
            )
        seen.add(host)
        normalized.append(host)

    normalized.sort()
    return normalized


def write_domains_json(path: Path, domains: list[str]) -> None:
    payload = {
        "schemaVersion": SUPPORTED_SCHEMA_VERSION,
        "domains": [
            {
                "domain": domain,
                "includeSubdomains": True,
            }
            for domain in domains
        ],
    }
    text = json.dumps(payload, indent=4, ensure_ascii=False) + "\n"
    path.write_text(text, encoding="utf-8")


def resolve_snapshot_path(sources_dir: Path, filename: str) -> Path:
    path = (sources_dir / filename).expanduser().resolve()
    try:
        path.relative_to(sources_dir.resolve())
    except ValueError as exc:
        raise HostsImportError(
            f"snapshot path escapes sources directory: {filename}"
        ) from exc
    return path


def import_hosts(
    metadata_path: Path,
    sources_dir: Path,
    allowlist_path: Path,
    local_additions_path: Path,
    output_path: Path,
) -> None:
    started = time.perf_counter()
    metadata = load_metadata(metadata_path)

    if not sources_dir.is_dir():
        raise HostsImportError(f"sources directory not found: {sources_dir}")

    merged: set[str] = set()
    total_parsed = 0
    total_invalid = 0
    total_unique_before_merge = 0
    per_source_stats: list[tuple[str, int, int, int]] = []

    for source in metadata["sources"]:
        source_id = source["id"]
        hosts_path = resolve_snapshot_path(sources_dir, source["snapshotFilename"])
        if not hosts_path.is_file():
            raise HostsImportError(
                f"hosts snapshot not found for {source_id}: {hosts_path}"
            )

        actual_sha = sha256_file(hosts_path)
        expected_sha = source["sha256"].lower()
        if actual_sha != expected_sha:
            raise HostsImportError(
                f"hosts snapshot SHA-256 mismatch for {source_id}: "
                f"expected {expected_sha}, got {actual_sha}"
            )

        domains, parsed_count, invalid_count = parse_hosts_file(hosts_path)
        if parsed_count != source["expectedEntryCount"]:
            raise HostsImportError(
                f"parsed entry count mismatch for {source_id}: "
                f"expected {source['expectedEntryCount']}, got {parsed_count}"
            )

        unique_count = len(domains)
        total_parsed += parsed_count
        total_invalid += invalid_count
        total_unique_before_merge += unique_count
        merged |= domains
        per_source_stats.append(
            (source_id, parsed_count, invalid_count, unique_count)
        )

    unique_after_merge = len(merged)
    overlap_removed = total_unique_before_merge - unique_after_merge

    allowlist = load_hostname_list(allowlist_path, "allowlist")
    local_additions = load_hostname_list(local_additions_path, "local-additions")

    allowlist_set = set(allowlist)
    local_set = set(local_additions)
    conflicts = sorted(allowlist_set & local_set)
    if conflicts:
        raise HostsImportError(
            "allowlist and local-additions conflict on "
            f"{len(conflicts)} domain(s); resolve before import"
        )

    excluded = 0
    retained: list[str] = []
    for domain in sorted(merged):
        if domain in allowlist_set:
            excluded += 1
            continue
        retained.append(domain)

    retained_set = set(retained)
    added = 0
    for domain in local_additions:
        if domain not in retained_set:
            retained.append(domain)
            retained_set.add(domain)
            added += 1

    retained.sort()
    write_domains_json(output_path, retained)

    elapsed_ms = (time.perf_counter() - started) * 1000.0
    output_size = output_path.stat().st_size

    print("Safari domain import complete (verified-license sources only).")
    print(f"Snapshot date: {metadata['snapshotDate']}")
    print(f"Sources directory: {sources_dir}")
    print(f"Included sources: {len(metadata['sources'])}")
    for source_id, parsed_count, invalid_count, unique_count in per_source_stats:
        print(
            f"Source {source_id}: parsed={parsed_count}, "
            f"invalid={invalid_count}, unique={unique_count}"
        )
    print(f"Total parsed entries: {total_parsed}")
    print(f"Total invalid entries: {total_invalid}")
    print(f"Unique entries before merge dedup: {total_unique_before_merge}")
    print(f"Overlap removed during merge: {overlap_removed}")
    print(f"Unique domains after merge: {unique_after_merge}")
    print(f"Allowlist exclusions: {excluded}")
    print(f"Local additions applied: {added}")
    print(f"Final production domain count: {len(retained)}")
    print(f"Wrote: {output_path}")
    print(f"Output size bytes: {output_size}")
    print(f"Duration ms: {elapsed_ms:.1f}")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Import verified-license external hosts snapshots into "
            "Tools/SafariDomainRules/domains.json."
        )
    )
    parser.add_argument(
        "--sources-dir",
        type=Path,
        required=True,
        help=(
            "Directory containing the four fixed external snapshot files named "
            "in source-metadata.json (required; snapshots stay outside the repo)."
        ),
    )
    parser.add_argument(
        "--metadata",
        type=Path,
        default=DEFAULT_METADATA,
        help=f"Path to source-metadata.json (default: {DEFAULT_METADATA})",
    )
    parser.add_argument(
        "--allowlist",
        type=Path,
        default=DEFAULT_ALLOWLIST,
        help=f"Path to allowlist.json (default: {DEFAULT_ALLOWLIST})",
    )
    parser.add_argument(
        "--local-additions",
        type=Path,
        default=DEFAULT_LOCAL_ADDITIONS,
        help=f"Path to local-additions.json (default: {DEFAULT_LOCAL_ADDITIONS})",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Path to domains.json output (default: {DEFAULT_OUTPUT})",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])

    try:
        import_hosts(
            metadata_path=args.metadata.resolve(),
            sources_dir=args.sources_dir.expanduser().resolve(),
            allowlist_path=args.allowlist.resolve(),
            local_additions_path=args.local_additions.resolve(),
            output_path=args.output.resolve(),
        )
    except HostsImportError as exc:
        fail(str(exc))
    except SystemExit:
        raise
    except Exception as exc:  # pragma: no cover - unexpected failure path
        fail(f"unexpected failure: {exc}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
