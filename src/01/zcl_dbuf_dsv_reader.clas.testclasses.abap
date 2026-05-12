CLASS ltcl_test DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_dbuf_dsv_reader.
    METHODS setup.
    METHODS csv_single_row            FOR TESTING.
    METHODS tsv_separator             FOR TESTING.
    METHODS quoted_comma_not_split    FOR TESTING.
    METHODS empty_lines_skipped       FOR TESTING.
    METHODS bom_stripped              FOR TESTING.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_dbuf_dsv_reader( ).
  ENDMETHOD.

  METHOD csv_single_row.
    DATA(xdata) = cl_abap_codepage=>convert_to( 'A,B,C' ).
    DATA(sheets) = cut->zif_dbuf_file_reader~read( xdata ).
    cl_abap_unit_assert=>assert_equals( act = lines( sheets[ 1 ]-rows )
                                        exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = sheets[ 1 ]-rows[ 1 ]-cells[ 1 ]
                                        exp = 'A' ).
    cl_abap_unit_assert=>assert_equals( act = sheets[ 1 ]-rows[ 1 ]-cells[ 3 ]
                                        exp = 'C' ).
  ENDMETHOD.

  METHOD tsv_separator.
    cut->set_separator( cl_abap_char_utilities=>horizontal_tab ).
    DATA(line) = |A{ cl_abap_char_utilities=>horizontal_tab }B{ cl_abap_char_utilities=>horizontal_tab }C|.
    DATA(xdata) = cl_abap_codepage=>convert_to( line ).
    DATA(sheets) = cut->zif_dbuf_file_reader~read( xdata ).
    cl_abap_unit_assert=>assert_equals( act = lines( sheets[ 1 ]-rows[ 1 ]-cells )
                                        exp = 3 ).
  ENDMETHOD.

  METHOD quoted_comma_not_split.
    DATA(xdata) = cl_abap_codepage=>convert_to( '"Hello,World",B' ).
    DATA(sheets) = cut->zif_dbuf_file_reader~read( xdata ).
    cl_abap_unit_assert=>assert_equals( act = lines( sheets[ 1 ]-rows[ 1 ]-cells )
                                        exp = 2 ).
  ENDMETHOD.

  METHOD empty_lines_skipped.
    DATA(nl) = cl_abap_char_utilities=>newline.
    DATA(xdata) = cl_abap_codepage=>convert_to( |A,B{ nl }{ nl }C,D| ).
    DATA(sheets) = cut->zif_dbuf_file_reader~read( xdata ).
    cl_abap_unit_assert=>assert_equals( act = lines( sheets[ 1 ]-rows )
                                        exp = 2 ).
  ENDMETHOD.

  METHOD bom_stripped.
    DATA(bom)   = cl_abap_char_utilities=>byte_order_mark_utf8.
    DATA(xdata) = cl_abap_codepage=>convert_to( bom && 'A,B' ).
    DATA(sheets) = cut->zif_dbuf_file_reader~read( xdata ).
    cl_abap_unit_assert=>assert_equals(
      act = sheets[ 1 ]-rows[ 1 ]-cells[ 1 ]
      exp = 'A'
      msg = 'BOM must be stripped before parsing' ).
  ENDMETHOD.

ENDCLASS.
