# Changelog

## [1.0.0] - 2026-05-08
### Added
- Initial release
- CSV/TSV/PSV/DSV reader (RFC 4180, UTF-8 BOM, CRLF/LF)
- XLSX / XLSM / Huge-XLSX readers via abap2xlsx
- Reader factory (extension-based)
- Column mapper (header token -> DDIC field)
- Row validator (DD03L type/length)
- Live committer (MODIFY CLIENT SPECIFIED)
- Null Object committer (test mode)
- XLSX + CSV result writers
- Writer factory
- Upload processor (Template Method, 6 steps)
- Report ZDBUF_UPLOAD with ALV + file download
- Full ABAPUnit test coverage
