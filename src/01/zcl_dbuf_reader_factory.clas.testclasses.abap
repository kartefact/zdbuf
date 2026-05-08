CLASS ltcl_test DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS xlsx_returns_xlsx_reader  FOR TESTING.
    METHODS xlsm_returns_xlsm_reader  FOR TESTING.
    METHODS csv_returns_dsv_reader    FOR TESTING.
    METHODS tsv_returns_dsv_reader    FOR TESTING.
    METHODS unknown_returns_dsv       FOR TESTING.
    METHODS explicit_sep_overrides    FOR TESTING.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD xlsx_returns_xlsx_reader.
    DATA(r) = zcl_dbuf_reader_factory=>create_for_extension( 'xlsx' ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_typedescr=>describe_by_object_ref( r )->get_relative_name( )
      exp = 'ZCL_DBUF_XLSX_READER' ).
  ENDMETHOD.

  METHOD xlsm_returns_xlsm_reader.
    DATA(r) = zcl_dbuf_reader_factory=>create_for_extension( 'xlsm' ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_typedescr=>describe_by_object_ref( r )->get_relative_name( )
      exp = 'ZCL_DBUF_XLSM_READER' ).
  ENDMETHOD.

  METHOD csv_returns_dsv_reader.
    DATA(r) = zcl_dbuf_reader_factory=>create_for_extension( 'csv' ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_typedescr=>describe_by_object_ref( r )->get_relative_name( )
      exp = 'ZCL_DBUF_DSV_READER' ).
  ENDMETHOD.

  METHOD tsv_returns_dsv_reader.
    DATA(r) = zcl_dbuf_reader_factory=>create_for_extension( 'tsv' ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_typedescr=>describe_by_object_ref( r )->get_relative_name( )
      exp = 'ZCL_DBUF_DSV_READER' ).
  ENDMETHOD.

  METHOD unknown_returns_dsv.
    DATA(r) = zcl_dbuf_reader_factory=>create_for_extension( 'dat' ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_typedescr=>describe_by_object_ref( r )->get_relative_name( )
      exp = 'ZCL_DBUF_DSV_READER' ).
  ENDMETHOD.

  METHOD explicit_sep_overrides.
    DATA(r) = zcl_dbuf_reader_factory=>create_for_extension(
      extension = 'csv' separator = ';' ).
    cl_abap_unit_assert=>assert_not_initial( act = r ).
  ENDMETHOD.

ENDCLASS.
