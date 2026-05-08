INTERFACE zif_dbuf_file_reader
  PUBLIC.

  TYPES:
    BEGIN OF row,
      cells TYPE string_table,
    END OF row,
    rows TYPE STANDARD TABLE OF row WITH DEFAULT KEY,
    BEGIN OF sheet,
      name TYPE string,
      rows TYPE rows,
    END OF sheet,
    sheets TYPE STANDARD TABLE OF sheet WITH DEFAULT KEY.

  "! Read file content and return parsed sheets.
  METHODS read
    IMPORTING
      file_content  TYPE xstring
      has_header    TYPE abap_bool DEFAULT abap_true
    RETURNING
      VALUE(result) TYPE sheets
    RAISING
      zcx_dbuf_file_error.

ENDINTERFACE.
