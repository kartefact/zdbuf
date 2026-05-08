CLASS zcl_dbuf_reader_factory DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS:
      ext_csv      TYPE string VALUE 'CSV',
      ext_tsv      TYPE string VALUE 'TSV',
      ext_psv      TYPE string VALUE 'PSV',
      ext_txt      TYPE string VALUE 'TXT',
      ext_xlsx     TYPE string VALUE 'XLSX',
      ext_xlsm     TYPE string VALUE 'XLSM',
      ext_xlshuge  TYPE string VALUE 'XLSHUGE'.

    CLASS-METHODS create_for_extension
      IMPORTING
        extension     TYPE string
        separator     TYPE c OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO zif_dbuf_file_reader.

    CLASS-METHODS separator_for_extension
      IMPORTING
        extension     TYPE string
      RETURNING
        VALUE(result) TYPE c.

ENDCLASS.

CLASS zcl_dbuf_reader_factory IMPLEMENTATION.

  METHOD create_for_extension.
    CASE to_upper( extension ).
      WHEN ext_xlsx.
        result = NEW zcl_dbuf_xlsx_reader( ).
      WHEN ext_xlsm.
        result = NEW zcl_dbuf_xlsm_reader( ).
      WHEN ext_xlshuge.
        result = NEW zcl_dbuf_huge_xlsx_reader( ).
      WHEN OTHERS.
        DATA(dsv) = NEW zcl_dbuf_dsv_reader( ).
        DATA(sep) = COND c(
          WHEN separator IS SUPPLIED AND separator <> space
            THEN separator
          ELSE separator_for_extension( extension ) ).
        dsv->set_separator( sep ).
        result = dsv.
    ENDCASE.
  ENDMETHOD.

  METHOD separator_for_extension.
    CASE to_upper( extension ).
      WHEN ext_tsv. result = cl_abap_char_utilities=>horizontal_tab.
      WHEN ext_psv. result = '|'.
      WHEN OTHERS.  result = ','.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.
