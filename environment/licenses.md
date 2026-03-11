# Licenses

## Default License Servers

| Vendor | Env var | Default value |
|------|---------|---------------|
| Cadence | `CDS_LIC_FILE` | `6055@licaccess.cmc.ca` |
| Synopsys | `SNPSLMD_LICENSE_FILE` | `6053@licaccess.cmc.ca` |
| Siemens / Mentor | `MGLS_LICENSE_FILE` | `6056@licaccess.cmc.ca` |

## Activation Patterns

| Vendor | Recommended entrypoint | Notes |
|------|--------------------------|-------|
| Cadence | `source setup/cadence.sh` | Bash-friendly wrapper for IC23 and Spectre |
| Synopsys | `source setup/synopsys.sh` | Bash-friendly wrapper for DC, PT, LC, and Sentaurus |
| Vendor tcsh scripts | `source /CMC/scripts/...` | Useful for debugging or matching a vendor-native shell |

## Notes

- Preserve an existing license env var when the shell is already configured.
- Do not commit license files. Only server addresses belong in repo docs.
- If a tool fails immediately, verify both the binary path and the matching vendor license variable.
