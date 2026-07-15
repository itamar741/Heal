# Safari Domain Rules

Local source of truth and generator for Heal Safari Extension domain coverage.

## Source of truth

Tracked source file:

```text
Tools/SafariDomainRules/domains.json
```

This file is the only intentional place to define which hostnames the Safari Extension covers. Generated extension files are derived from it and must be reviewed before commit.

## Generator command

From the repository root, using Python 3 standard library only:

```bash
python3 Tools/SafariDomainRules/generate.py
```

Optional source override for validation tests:

```bash
python3 Tools/SafariDomainRules/generate.py --source /path/to/domains.json
```

This milestone does not add an Xcode build phase. Regeneration remains an explicit developer command.

## Supported schema

```json
{
  "schemaVersion": 1,
  "domains": [
    {
      "domain": "example.com",
      "includeSubdomains": true,
      "purpose": "test-fixture"
    }
  ]
}
```

Fields:

- `schemaVersion` — currently `1` only
- `domains` — non-empty array of domain objects
- `domain` — plain hostname
- `includeSubdomains` — boolean; when `true`, also emits `*.domain` host permission / web-accessible match entries
- `purpose` — optional string annotation for humans; ignored by generation logic

## Validation rules

The generator accepts plain hostnames only. It:

- normalizes hostnames to lowercase
- removes a single trailing dot when present
- rejects schemes, paths, query strings, fragments, ports, spaces, and wildcards
- rejects empty or malformed hostnames
- rejects duplicate domains after normalization
- sorts domains deterministically before generation
- fails with a clear non-zero exit code on invalid input and does not update generated files

## Generated files

The generator updates only domain-derived portions of:

- `HealSafariExtension/Resources/manifest.json`
  - `host_permissions`
  - `web_accessible_resources` matches for `blocked.html`
- `HealSafariExtension/Resources/rules.json`
  - declarativeNetRequest redirect rules

It preserves the existing static `declarative_net_request` ruleset reference to `rules.json` and does not invent `<all_urls>` permissions.

Generated DNR rules use:

- stable sequential rule IDs starting at `1`
- `urlFilter: "||domain^"`
- `resourceTypes: ["main_frame"]`
- redirect to `/blocked.html`

## Review before commit

Always review the generated `manifest.json` and `rules.json` diff before committing. Do not treat generator output as automatically trusted.

## Current fixture status

`example.com` is only a test fixture. It exists so Safari Extension blocking, the Heal block page, and Safe Place handoff can be validated.

No production domain list exists yet.

Apple’s `.auto()` classifier data is not available to this generator and is out of scope for this local domain-rules foundation.
