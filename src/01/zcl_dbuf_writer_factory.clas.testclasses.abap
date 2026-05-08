CLASS ltcl_test DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS xlsx_is_default      FOR TESTING.
    METHODS csv_returns_csv      FOR TESTING.
    METHODS unknown_returns_xlsx FOR TESTING.
ENDCLASS.
CLASS ltcl_test IMPLEMENTATION.
  METHOD xlsx_is_default.
    DATA(r) = zcl_dbuf_writer_factory=>create( ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_typedescr=>describe_by_object_ref( r )->get_relative_name( )
      exp = 'ZCL_DBUF_RESULT_XLSX_WRITER' ).
  ENDMETHOD.
  METHOD csv_returns_csv.
    DATA(r) = zcl_dbuf_writer_factory=>create( 'CSV' ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_typedescr=>describe_by_object_ref( r )->get_relative_name( )
      exp = 'ZCL_DBUF_RESULT_CSV_WRITER' ).
  ENDMETHOD.
  METHOD unknown_returns_xlsx.
    DATA(r) = zcl_dbuf_writer_factory=>create( 'PDF' ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_typedescr=>describe_by_object_ref( r )->get_relative_name( )
      exp = 'ZCL_DBUF_RESULT_XLSX_WRITER' ).
  ENDMETHOD.
ENDCLASS.
