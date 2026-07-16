# Third-Party Notices — Safari Domain List

Heal’s production Safari domain list is built only from **verified-license upstream hosts files**. The raw source files are stored **outside** this repository as fixed local snapshots and are supplied to the importer with `--sources-dir`.

Heal **modifies** this data: it normalizes hostnames, merges sources, deduplicates entries, filters invalid records, optionally applies allowlist exclusions and local additions, and converts the resulting domain set into Safari Web Extension declarativeNetRequest (DNR) rules packaged with the app.

Exact upstream license texts are preserved under:

```text
ThirdPartyLicenses/SafariDomainList/
```

## Production snapshot set

| Fact | Value |
|------|-------|
| Snapshot date | 16 July 2026 11:40:03 (UTC) |
| Snapshot files | Bare filenames listed per source below; resolved via `import_hosts.py --sources-dir <dir>` |
| Tracked metadata | `Tools/SafariDomainRules/source-metadata.json` |
| Included sources | 4 verified-license upstream files |
| Production count | 63,311 domains / DNR rules (device-validated) |
| Production input | **Not** the merged StevenBlack porn-only hosts file |

StevenBlack/hosts’ [porn-only source mapping](https://github.com/StevenBlack/hosts/blob/master/alternates/porn-only/readme.md) was used only to **identify** candidate upstream projects and URLs during research. StevenBlack’s **merged** porn-only alternate is **not** a production data source for Heal.

---

## Included sources

### 1. BigDargon adult list — MIT

| Field | Value |
|-------|-------|
| Project | https://github.com/bigdargon/hostsVN |
| Source URL | https://raw.githubusercontent.com/bigdargon/hostsVN/master/extensions/adult/hosts-VN |
| Snapshot filename | `bigdargon-adult-hosts-VN.txt` |
| SHA-256 | `0dbc6e1f390963efc90f764b68c0da79c32cee21caeaeb89b4d4c24bf3a3ccdb` |
| Expected entry count | 1,895 |
| License identifier | MIT |
| License file | https://github.com/bigdargon/hostsVN/blob/master/LICENSE |
| Copyright | Copyright (c) 2026 BigDargon |
| Preserved text | `ThirdPartyLicenses/SafariDomainList/BigDargon-hostsVN-LICENSE` |

### 2. Sinfonietta pornography — MIT

| Field | Value |
|-------|-------|
| Project | https://github.com/Sinfonietta/hostfiles |
| Source URL | https://raw.githubusercontent.com/Sinfonietta/hostfiles/master/pornography-hosts |
| Snapshot filename | `sinfonietta-pornography-hosts.txt` |
| SHA-256 | `9a26dfd1ad977e06365938196b43a4c087583140b8e409735df557b07b2eaf50` |
| Expected entry count | 61,187 |
| License identifier | MIT |
| License file | https://github.com/Sinfonietta/hostfiles/blob/master/LICENSE |
| Copyright | Copyright (c) 2016 Sinfonietta |
| Preserved text | `ThirdPartyLicenses/SafariDomainList/Sinfonietta-hostfiles-LICENSE` |

### 3. Sinfonietta snuff — MIT

| Field | Value |
|-------|-------|
| Project | https://github.com/Sinfonietta/hostfiles |
| Source URL | https://raw.githubusercontent.com/Sinfonietta/hostfiles/master/snuff-hosts |
| Snapshot filename | `sinfonietta-snuff-hosts.txt` |
| SHA-256 | `b3a520a880082714add887c81b57810e8668238c4fec689c1a79b7f2cf511de8` |
| Expected entry count | 23 |
| License identifier | MIT |
| License file | https://github.com/Sinfonietta/hostfiles/blob/master/LICENSE |
| Copyright | Copyright (c) 2016 Sinfonietta |
| Preserved text | `ThirdPartyLicenses/SafariDomainList/Sinfonietta-hostfiles-LICENSE` |

(Same repository LICENSE covers both Sinfonietta lists.)

### 4. Tiuxo pornography — CC BY 4.0

| Field | Value |
|-------|-------|
| Project | https://github.com/tiuxo/hosts |
| Source URL | https://raw.githubusercontent.com/tiuxo/hosts/master/porn |
| Snapshot filename | `tiuxo-porn.txt` |
| SHA-256 | `2e30d7012de8560ced54c92963a1fc9e8b755c437d691d20fa268e810897399c` |
| Expected entry count | 369 |
| License identifier | CC-BY-4.0 |
| License file (upstream) | https://github.com/tiuxo/hosts/blob/master/LICENSE |
| Official license reference | https://creativecommons.org/licenses/by/4.0/ |
| Official legal code | https://creativecommons.org/licenses/by/4.0/legalcode.txt |
| Preserved upstream LICENSE | `ThirdPartyLicenses/SafariDomainList/Tiuxo-hosts-LICENSE` |
| Preserved official legal code | `ThirdPartyLicenses/SafariDomainList/CC-BY-4.0-legalcode.txt` |

#### Required CC BY 4.0 attribution (Tiuxo)

- **Work:** Tiuxo categorized hosts — pornography list  
- **Author / Licensor:** tiuxo ([GitHub project](https://github.com/tiuxo/hosts))  
- **Source:** https://github.com/tiuxo/hosts (file path `porn`)  
- **License:** [Creative Commons Attribution 4.0 International (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)  
- **Modifications:** Yes — Heal normalizes, merges with other verified sources, deduplicates, filters invalid hostnames, may apply allowlist/local additions, and converts domains into Safari DNR redirect rules. This is an adapted / modified form of the original hosts list, not a verbatim redistribution of the upstream file.

---

## Explicitly excluded from production data

These sources do **not** contribute domains to Heal’s distributable production list:

| Source | Reason |
|--------|--------|
| Clefspeare13/pornhosts | Upstream LICENSE not verifiable (GitHub repository access blocked) |
| brijrajparmar27/host-sources | No verifiable upstream LICENSE file or attribution statement |
| StevenBlack/hosts porn-only **merged** alternate | Aggregator merge is not used as production input |

No production attribution or runtime dependency is claimed for the excluded sources.

---

## Modification statement

Heal does **not** redistribute the raw upstream hosts files inside this repository.

Heal **does** create a modified derivative used at runtime as Safari Web Extension DNR rules:

1. Verify SHA-256 of each of the four fixed external snapshots  
2. Parse hosts-format entries  
3. Normalize hostnames (lowercase; strip one trailing dot)  
4. Reject malformed entries, schemes, paths, ports, wildcards, spaces, and IP addresses  
5. Merge sources, deduplicate, and sort  
6. Apply `allowlist.json` exclusions and `local-additions.json` additions when present  
7. Emit `domains.json` and generate domain-specific `main_frame` DNR redirects to `/blocked.html`, with `<all_urls>` host permission / WAR matches for packaging  

Snapshot identity for this verified-source pipeline:

- Date: **16 July 2026 11:40:03 (UTC)**  
- Sources, filenames, hashes, and expected counts: see tables above and `Tools/SafariDomainRules/source-metadata.json`
