CLASS ltcl_test DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS live_mode_returns_live   FOR TESTING.
    METHODS test_mode_returns_null   FOR TESTING.
ENDCLASS.
CLASS ltcl_test IMPLEMENTATION.
  METHOD live_mode_returns_live.
    DATA(r) = zcl_dbuf_committer_factory=>create( abap_false ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_typedescr=>describe_by_object_ref( r )->get_relative_name( )
      exp = 'ZCL_DBUF_LIVE_COMMITTER' ).
  ENDMETHOD.
  METHOD test_mode_returns_null.
    DATA(r) = zcl_dbuf_committer_factory=>create( abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = cl_abap_typedescr=>describe_by_object_ref( r )->get_relative_name( )
      exp = 'ZCL_DBUF_NULL_COMMITTER' ).
  ENDMETHOD.
ENDCLASS.
