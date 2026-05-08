CLASS zcl_dbuf_writer_factory DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CONSTANTS:
      fmt_xlsx TYPE string VALUE 'XLSX',
      fmt_csv  TYPE string VALUE 'CSV'.

    CLASS-METHODS create
      IMPORTING
        format        TYPE string DEFAULT 'XLSX'
      RETURNING
        VALUE(result) TYPE REF TO zif_dbuf_result_writer.
ENDCLASS.

CLASS zcl_dbuf_writer_factory IMPLEMENTATION.
  METHOD create.
    CASE to_upper( format ).
      WHEN fmt_csv.
        result = NEW zcl_dbuf_result_csv_writer( ).
      WHEN OTHERS.
        result = NEW zcl_dbuf_result_xlsx_writer( ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
