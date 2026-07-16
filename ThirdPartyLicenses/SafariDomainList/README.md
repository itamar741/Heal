# Safari Domain List — Third-Party License Texts

Exact upstream license texts for the **four verified-license sources** used by Heal’s production Safari domain-list pipeline.

| File | Upstream | SPDX / identifier | Role |
|------|----------|-------------------|------|
| `BigDargon-hostsVN-LICENSE` | https://github.com/bigdargon/hostsVN/blob/master/LICENSE | MIT | Included production source |
| `Sinfonietta-hostfiles-LICENSE` | https://github.com/Sinfonietta/hostfiles/blob/master/LICENSE | MIT | Included production sources (pornography + snuff) |
| `Tiuxo-hosts-LICENSE` | https://github.com/tiuxo/hosts/blob/master/LICENSE | CC-BY-4.0 | Included production source |
| `CC-BY-4.0-legalcode.txt` | https://creativecommons.org/licenses/by/4.0/legalcode.txt | CC-BY-4.0 | Official Creative Commons legal code (reference) |

## Not used for production data

| Source | Status |
|--------|--------|
| Clefspeare13/pornhosts | Excluded — LICENSE not verifiable |
| brijrajparmar27/host-sources | Excluded — no verifiable LICENSE / attribution |
| StevenBlack/hosts merged porn-only alternate | Excluded — not a production input |
| `StevenBlack-hosts-license.txt` | Removed from this directory; aggregator license not required for the verified-source production set |

See root `THIRD_PARTY_NOTICES.md` for URLs, SHA-256 values, snapshot filenames, CC BY attribution, and the modification statement. Local snapshot files are supplied to the importer with `--sources-dir` and are not stored in this repository.
