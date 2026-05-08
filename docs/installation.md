# Installation

## Prerequisites
- SAP ECC 6.0 EhP7+ or S/4HANA
- abapGit (standalone or developer edition)
- [abap2xlsx](https://github.com/abap2xlsx/abap2xlsx) installed in package `$ABAP2XLSX` or similar

## Steps

1. Clone this repository via abapGit:
   - Transaction `ZABAPGIT`
   - New Online Repository
   - URL: `https://github.com/kartefact/zdbuf`
   - Package: `ZDBUF` (create as local or transportable)
2. Pull all objects
3. Activate all objects
4. Run report `ZDBUF_UPLOAD`

## Package dependency
Ensure `ZDBUF` has a dependency on the package containing abap2xlsx objects (`ZCL_EXCEL`, etc.).
