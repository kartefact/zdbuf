CLASS zcl_dbuf_column_mapper DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF column_mapping,
        header_token TYPE string,
        field_name   TYPE fieldname,
        position     TYPE i,
      END OF column_mapping,
      column_mappings TYPE STANDARD TABLE OF column_mapping WITH DEFAULT KEY.

    METHODS map_headers
      IMPORTING
        table_name    TYPE tabname
        header_row    TYPE string_table
      RETURNING
        VALUE(result) TYPE column_mappings
      RAISING
        zcx_dbuf_mapping_error.

  PRIVATE SECTION.
    METHODS get_ddic_fields
      IMPORTING
        table_name    TYPE tabname
      RETURNING
        VALUE(result) TYPE STANDARD TABLE.

ENDCLASS.

CLASS zcl_dbuf_column_mapper IMPLEMENTATION.

  METHOD map_headers.
    IF header_row IS INITIAL.
      RAISE EXCEPTION TYPE zcx_dbuf_mapping_error
        EXPORTING text = |Header row is empty for table { table_name }|.
    ENDIF.

    DATA(ddic_fields) = get_ddic_fields( table_name ).

    LOOP AT header_row INTO DATA(token).
      DATA(position)    = sy-tabix.
      DATA(upper_token) = to_upper( condense( token ) ).
      READ TABLE ddic_fields INTO DATA(field_row) WITH KEY ('FIELDNAME') = upper_token.
      IF sy-subrc = 0.
        APPEND VALUE column_mapping(
          header_token = token
          field_name   = upper_token
          position     = position ) TO result.
      ENDIF.
    ENDLOOP.

    IF result IS INITIAL.
      RAISE EXCEPTION TYPE zcx_dbuf_mapping_error
        EXPORTING text =
          |No header tokens matched DDIC fields of { table_name }. Check column names.|.
    ENDIF.
  ENDMETHOD.

  METHOD get_ddic_fields.
    SELECT fieldname FROM dd03l INTO TABLE @result
      WHERE tabname  = @table_name
        AND as4local = 'A'
        AND fieldname NOT LIKE '.%'.
  ENDMETHOD.

ENDCLASS.
