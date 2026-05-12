INTERFACE zif_dbuf_result_writer
  PUBLIC.

  TYPES:
    BEGIN OF result_row,
      row_number TYPE i,
      status     TYPE c LENGTH 1,
      message    TYPE string,
      raw_data   TYPE string,
    END OF result_row,
    result_rows TYPE STANDARD TABLE OF result_row WITH DEFAULT KEY.

  METHODS write
    IMPORTING
      table_name    TYPE tabname
      rows          TYPE result_rows
    RETURNING
      VALUE(result) TYPE xstring
    RAISING
      zcx_dbuf_file_error.

ENDINTERFACE.
