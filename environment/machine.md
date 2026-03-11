# Machine

Scan date: `2026-03-10T18:29:00-04:00`

## Host

| Field | Value |
|------|-------|
| Example hostname | `vcl-vm0-159` |
| Recommended repo root | `~/eda-pilot` |
| OS | Rocky Linux 8.10 (Green Obsidian) |
| Kernel | `4.18.0-553.27.1.el8_10.x86_64` |
| Headless | Yes |

## Compute

| Field | Value |
|------|-------|
| CPU model | Intel(R) Xeon(R) Gold 6248R CPU @ 3.00GHz |
| vCPUs | 4 |
| Threads per core | 1 |
| RAM | 15 GiB total |
| Swap | 15 GiB |

## Storage

| Mount | Size | Notes |
|------|------|-------|
| `/` | 30G | Local OS volume |
| `/CMC` | 12T | Shared tools and kits |
| `/scratch` | 2.9T | Best default for heavy generated data |
| `~/mydata` | 7.8T | Persistent user storage |

## Operational Notes

- This is a headless Linux environment. Plan for shell, TCL, Python, and batch flows only.
- EDA tools are installed under `/CMC/tools/`.
- Vendor launch scripts live under `/CMC/scripts/`.
- Large Innovus, Pegasus, and Sentaurus runs should write outputs to scratch or an explicit run directory, not the repo root.
