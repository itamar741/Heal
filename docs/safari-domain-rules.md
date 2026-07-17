# Safari Domain Rules

Local production pipeline that converts **verified-license upstream hosts snapshots** into Heal Safari Extension declarativeNetRequest (DNR) rules.

## Pipeline overview

1. **Import** four fixed external hosts snapshots into `domains.json` (with allowlist / local additions).
2. **Generate** Safari Extension `manifest.json` host permission / WAR matches and `rules.json` DNR redirects.

Python 3 standard library only. No Xcode build phase. Regeneration is an explicit developer command. Updating the domain list requires a new app build.

## Verified production sources

Production input is **not** the merged StevenBlack porn-only hosts file.

| Source | License | Snapshot filename | Official raw URL |
|--------|---------|-------------------|------------------|
| BigDargon adult | MIT | `bigdargon-adult-hosts-VN.txt` | `https://raw.githubusercontent.com/bigdargon/hostsVN/master/extensions/adult/hosts-VN` |
| Sinfonietta pornography | MIT | `sinfonietta-pornography-hosts.txt` | `https://raw.githubusercontent.com/Sinfonietta/hostfiles/master/pornography-hosts` |
| Sinfonietta snuff | MIT | `sinfonietta-snuff-hosts.txt` | `https://raw.githubusercontent.com/Sinfonietta/hostfiles/master/snuff-hosts` |
| Tiuxo pornography | CC BY 4.0 | `tiuxo-porn.txt` | `https://raw.githubusercontent.com/tiuxo/hosts/master/porn` |

Tracked metadata (URLs, SHA-256, expected entry counts, snapshot date, filenames):

```text
Tools/SafariDomainRules/source-metadata.json
```

Keep the four snapshot files **outside** the repository. Pass their directory with `--sources-dir`. The importer verifies every included source hash and expected entry count before writing `domains.json`.

Excluded from production data: Clefspeare13/pornhosts, brijrajparmar27/host-sources, and the StevenBlack merged porn-only alternate.

## Commands

From the repository root:

```bash
python3 Tools/SafariDomainRules/import_hosts.py --sources-dir /path/to/external-snapshots
python3 Tools/SafariDomainRules/generate.py
```

`--sources-dir` is required. It must contain the four snapshot filenames recorded in `source-metadata.json`.

Optional overrides:

```bash
python3 Tools/SafariDomainRules/import_hosts.py \
  --sources-dir /path/to/external-snapshots \
  --metadata Tools/SafariDomainRules/source-metadata.json
python3 Tools/SafariDomainRules/generate.py --source /path/to/domains.json
```

## Allowlist and local additions

| File | Role |
|------|------|
| `Tools/SafariDomainRules/allowlist.json` | Domains removed from the merged imported set |
| `Tools/SafariDomainRules/local-additions.json` | Domains added after allowlist exclusion |

Both use `schemaVersion: 1` and a `domains` array of hostname strings (or objects with a `domain` field).

Behavior:

- Hostnames are normalized (lowercase; one trailing dot removed).
- Malformed values are rejected.
- Domains present in both allowlist and local-additions are a hard conflict; the importer exits without writing output.
- Production v1 ships empty allowlist and empty local additions.
- No network checks and no inactive-domain cleanup are performed during import.

## `domains.json` schema

```json
{
  "schemaVersion": 1,
  "domains": [
    {
      "domain": "<plain-hostname>",
      "includeSubdomains": true,
      "purpose": "optional annotation"
    }
  ]
}
```

Fields:

- `schemaVersion` — currently `1` only
- `domains` — non-empty array of domain objects after a successful production import
- `domain` — plain hostname (no schemes, paths, ports, wildcards, or IP addresses)
- `includeSubdomains` — boolean annotation; production import writes `true`
- `purpose` — optional string for humans; ignored by generation logic

## Generator validation

The generator accepts plain hostnames only. It:

- normalizes hostnames to lowercase
- removes a single trailing dot when present
- rejects schemes, paths, query strings, fragments, ports, spaces, and wildcards
- rejects empty or malformed hostnames
- rejects duplicate domains after normalization
- sorts domains deterministically before generation
- fails with a clear non-zero exit code on invalid input and does not update generated files

## Manifest and DNR design

Production generation updates only domain-derived portions of:

- `HealSafariExtension/Resources/manifest.json`
  - `host_permissions` → `["<all_urls>"]`
  - `web_accessible_resources` preserves both:
    - `blocked.html`
    - `blocked-test.html`
  - production static ruleset:
    - `id` → `heal_domain_blocklist`
    - `path` → `rules.json`
- `HealSafariExtension/Resources/rules.json`
  - one domain-specific DNR redirect rule per production domain
  - no catch-all DNR rule

The manifest also contains a separate, non-generated functional-test ruleset:

- `id`: `heal_safari_protection_test`
- `path`: `safari-protection-test-rules.json`
- exact test URL:
  `https://example.com/heal-safari-protection-test`
- redirect:
  `/blocked-test.html`

The generator must preserve the dedicated test ruleset and both web-accessible
block pages. It must not merge the test rule into the production domain list.

### All Websites permission versus domain-specific blocking

Safari’s **All Websites** / `<all_urls>` host permission grants the extension broad website access so a large domain list does not require impractical per-domain permission prompts. Actual blocking remains scoped by domain-specific DNR rules:

- stable sequential rule IDs starting at `1`
- `urlFilter: "||domain^"`
- `resourceTypes: ["main_frame"]` only
- redirect to `/blocked.html`

Sites not present in `rules.json` are not redirected by this ruleset.

## Physical-device validation (Production Safari Domain List v1)

Classification: **SAFARI-DOMAIN-LIST-PROD-1** (16 July 2026)

Verified-license production build on a physical iPhone:

| Result | Detail |
|--------|--------|
| Production count | **63,311** domain-specific DNR rules loaded successfully |
| Ruleset sampling | Responsive domains near the **start**, **middle**, and **end** of the ruleset redirected to Heal |
| Safari | Normal and Private Browsing both showed Heal’s intervention page |
| Safe Place | Open Safe Place handoff worked |
| Unrelated Safari sites | Remained accessible |
| Chrome (System Website Filtering disabled) | Unaffected by the Safari extension ruleset |
| Chrome (System Website Filtering enabled) | Retained Apple’s generic fallback behavior |
| Runtime | No noticeable delay, crash, freeze, or rule-loading failure |

Tested hostnames are not recorded in this document.

## App build requirement

Because `domains.json`, `manifest.json`, and `rules.json` are packaged into the Safari Web Extension, any domain-list update must be followed by a new Heal app / extension build before devices receive the change. There is no remote rules update path in this milestone.

## Future cleanup and maintenance

Production list maintenance should include periodic cleanup and revalidation:

- remove inactive or non-resolving domains after a defined grace period
- do not remove a domain solely because of temporary downtime
- review ownership changes and content-category drift that can create false positives
- review parked domains, redirects, duplicates, malformed entries, and stale subdomains
- maintain snapshot / version / hash tracking for each verified upstream source
- maintain the allowlist for confirmed false positives
- add carefully reviewed local additions when needed

## Review before commit

Always review the generated `manifest.json` and `rules.json` diffs (and aggregate importer/generator counts) before committing. Do not treat generator output as automatically trusted. Do not paste adult hostnames into docs, commit messages, or issue text.

When changing the generator, verify that regeneration preserves:

- `heal_safari_protection_test`
- `safari-protection-test-rules.json`
- `blocked-test.html`
- the existing production ruleset and production rule count

## Third-party notices

See `THIRD_PARTY_NOTICES.md` and `ThirdPartyLicenses/SafariDomainList/` for verified licenses, CC BY attribution, excluded sources, and the modification statement.
