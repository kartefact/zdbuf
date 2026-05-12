CLASS zcl_dbuf_row_validator DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF validation_result,
        row_index TYPE i,
        is_valid  TYPE abap_bool,
        message   TYPE string,
      END OF validation_result.

    METHODS validate_row
      IMPORTING
        row_index     TYPE i
        cells         TYPE string_table
        mappings      TYPE zcl_dbuf_column_mapper=>column_mappings
        table_name    TYPE tabname
      RETURNING
        VALUE(result) TYPE validation_result.

  PRIVATE SECTION.
    METHODS get_field_metadata
      IMPORTING
        table_name    TYPE tabname
        field_name    TYPE fieldname
      RETURNING
        VALUE(result) TYPE dd03l.

    METHODS check_length
      IMPORTING
        value         TYPE string
        field_def     TYPE dd03l
      RETURNING
        VALUE(result) TYPE abap_bool.

ENDCLASS.

CLASS zcl_dbuf_row_validator IMPLEMENTATION.

  METHOD validate_row.
    result-row_index = row_index.
    result-is_valid  = abap_true.

    LOOP AT mappings INTO DATA(mapping).
      READ TABLE cells INTO DATA(cell_value) INDEX mapping-position.
      IF sy-subrc <> 0.
        result-is_valid = abap_false.
        result-message  = |Row { row_index }: Missing value for field { mapping-field_name }|.
        RETURN.
      ENDIF.

      DATA(field_def) = get_field_metadata( table_name = table_name
                                            field_name = mapping-field_name ).

      IF field_def-fieldname IS NOT INITIAL.
        IF check_length( value     = cell_value
                         field_def = field_def ) = abap_false.
          result-is_valid = abap_false.
          result-message  = |Row { row_index }: Value "{ cell_value }" exceeds max length |
                         && |{ field_def-leng } for field { mapping-field_name }|.
          RETURN.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_field_metadata.
    SELECT SINGLE * FROM dd03l
      WHERE tabname   = @table_name
        AND fieldname = @field_name
        AND as4local  = 'A' INTO @result.
  ENDMETHOD.

  METHOD check_length.
    IF field_def-leng = 0.
      result = abap_true.
      RETURN.
    ENDIF.
    result = xsdbool( strlen( value ) <= field_def-leng ).
  ENDMETHOD.

ENDCLASS.
