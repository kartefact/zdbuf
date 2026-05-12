CLASS ltcl_test DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_dbuf_row_validator.
    METHODS setup.
    METHODS valid_row_returns_valid       FOR TESTING.
    METHODS missing_cell_returns_invalid  FOR TESTING.
    METHODS never_raises_exception        FOR TESTING.
    METHODS empty_mappings_returns_valid  FOR TESTING.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_dbuf_row_validator( ).
  ENDMETHOD.

  METHOD valid_row_returns_valid.
    DATA(mappings) = VALUE zcl_dbuf_column_mapper=>column_mappings(
      ( header_token = 'NAME' field_name = 'NAME' position = 1 ) ).
    DATA(result) = cut->validate_row(
      row_index  = 1
      cells      = VALUE string_table( ( 'ABAP' ) )
      mappings   = mappings
      table_name = 'ZTESTXXX' ).
    cl_abap_unit_assert=>assert_equals( act = result-is_valid
                                        exp = abap_true ).
  ENDMETHOD.

  METHOD missing_cell_returns_invalid.
    DATA(mappings) = VALUE zcl_dbuf_column_mapper=>column_mappings(
      ( header_token = 'COL1' field_name = 'COL1' position = 1 )
      ( header_token = 'COL2' field_name = 'COL2' position = 2 ) ).
    DATA(result) = cut->validate_row(
      row_index  = 5
      cells      = VALUE string_table( ( 'ONLY_ONE' ) )
      mappings   = mappings
      table_name = 'ZTESTXXX' ).
    cl_abap_unit_assert=>assert_equals( act = result-is_valid
                                        exp = abap_false ).
    cl_abap_unit_assert=>assert_char_cp( act = result-message
                                         exp = '*Row 5*' ).
  ENDMETHOD.

  METHOD never_raises_exception.
    TRY.
        cut->validate_row(
          row_index  = 99
          cells      = VALUE string_table( )
          mappings   = VALUE zcl_dbuf_column_mapper=>column_mappings(
            ( header_token = 'X' field_name = 'X' position = 1 ) )
          table_name = 'ZTESTXXX' ).
      CATCH cx_root INTO DATA(unexpected).
        cl_abap_unit_assert=>fail( msg = |Must not raise: { unexpected->if_message~get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD empty_mappings_returns_valid.
    DATA(result) = cut->validate_row(
      row_index  = 1
      cells      = VALUE string_table( ( 'A' ) )
      mappings   = VALUE zcl_dbuf_column_mapper=>column_mappings( )
      table_name = 'ZTESTXXX' ).
    cl_abap_unit_assert=>assert_equals( act = result-is_valid
                                        exp = abap_true ).
  ENDMETHOD.

ENDCLASS.
