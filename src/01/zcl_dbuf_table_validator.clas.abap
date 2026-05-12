CLASS zcl_dbuf_table_validator DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Validates table name: Z*/Y* namespace + DDIC TRANSP check.
    METHODS validate
      IMPORTING
        table_name TYPE tabname
      RAISING
        zcx_dbuf_validation_error.

  PRIVATE SECTION.
    METHODS is_custom_namespace
      IMPORTING
        table_name    TYPE tabname
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS exists_in_ddic
      IMPORTING
        table_name    TYPE tabname
      RETURNING
        VALUE(result) TYPE abap_bool.

ENDCLASS.

CLASS zcl_dbuf_table_validator IMPLEMENTATION.

  METHOD validate.
    IF is_custom_namespace( table_name ) = abap_false.
      RAISE EXCEPTION NEW zcx_dbuf_validation_error( text = |Table { table_name } is not in Z* or Y* namespace| ).
    ENDIF.

    IF exists_in_ddic( table_name ) = abap_false.
      RAISE EXCEPTION NEW zcx_dbuf_validation_error( text = |Table { table_name } not found in DDIC as transparent table| ).
    ENDIF.
  ENDMETHOD.

  METHOD is_custom_namespace.
    DATA(first_char) = table_name(1).
    result = xsdbool( first_char = 'Z' OR first_char = 'Y' ).
  ENDMETHOD.

  METHOD exists_in_ddic.
    SELECT SINGLE tabname FROM dd02l
      WHERE tabname  = @table_name
        AND tabclass = 'TRANSP'
        AND as4local = 'A' INTO @DATA(found).
    result = xsdbool( sy-subrc = 0 AND found IS NOT INITIAL ).
  ENDMETHOD.

ENDCLASS.
