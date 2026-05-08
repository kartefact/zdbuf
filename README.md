# zdbuf — ABAP DB Upload Framework

Upload CSV / TSV / PSV / DSV / XLSX / XLSM files into any Z* or Y* transparent SAP table via a single report.

## Features
- Supports CSV, TSV, PSV, pipe-separated, XLSX, XLSM, huge-XLSX (SAX)
- Header-row auto-mapping to DDIC field names
- Row-level type/length validation against DD03L
- Test mode (null committer) — validates without writing
- XLSX or CSV result file download with row status colouring
- Full authorization check via S_TABU_DIS / S_TABU_NAM
- Clean ABAP OOP — Strategy, Factory, Null Object, Template Method
- ABAPUnit test classes on every object

## Installation
See [docs/installation.md](docs/installation.md)

## Usage
See [docs/usage.md](docs/usage.md)

## License
MIT — see [LICENSE](LICENSE)
