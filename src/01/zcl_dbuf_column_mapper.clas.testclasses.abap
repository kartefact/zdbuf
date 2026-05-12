CLASS ltcl_test DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_dbuf_column_mapper.
    METHODS setup.
    METHODS empty_header_raises_error FOR TESTING.
    METHODS no_match_raises_error     FOR TESTING.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_dbuf_column_mapper( ).
  ENDMETHOD.

  METHOD empty_header_raises_error.
    TRY.
        cut->map_headers( table_name = 'ZTESTXXX'
                          header_row = VALUE #( ) ).
        cl_abap_unit_assert=>fail( 'Empty header must raise mapping error' ).
      CATCH zcx_dbuf_mapping_error INTO DATA(exc).
        cl_abap_unit_assert=>assert_char_cp( act = exc->mv_text
                                             exp = '*empty*' ).
    ENDTRY.
  ENDMETHOD.

  METHOD no_match_raises_error.
    TRY.
        cut->map_headers(
          table_name = 'ZTESTXXX_NONEXISTENT'
          header_row = VALUE #( ( 'COL1' ) ( 'COL2' ) ) ).
        cl_abap_unit_assert=>fail( 'No DDIC match must raise mapping error' ).
      CATCH zcx_dbuf_mapping_error.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
