# Usage

## Running the Upload Report

1. Execute report `ZDBUF_UPLOAD` (SE38 or via menu)
2. Fill in the selection screen:
   - **File Path**: Local file to upload (F4 help available)
   - **Table Name**: Target Z* or Y* transparent table
   - **Separator**: Column separator for DSV files (default: comma)
   - **Has Header Row**: Check if first row contains field names
   - **Test Mode**: Check to validate without writing to DB
   - **Result Format**: XLSX or CSV for the result download
3. Execute (F8)
4. Review the ALV result list
5. Result file is auto-downloaded to `C:\TEMP\<TABLE>_upload_result.xlsx`

## Supported File Formats
| Extension | Reader Used |
|-----------|-------------|
| .csv | DSV Reader (comma) |
| .tsv | DSV Reader (tab) |
| .psv | DSV Reader (pipe) |
| .txt | DSV Reader (auto/manual sep) |
| .xlsx | XLSX Reader (abap2xlsx) |
| .xlsm | XLSM Reader (abap2xlsx) |
| .xlshuge | Huge XLSX Reader (SAX) |

## Test Mode
With **Test Mode** checked, the null committer is used — all rows are validated and the result file is generated, but **no data is written to the database**.
