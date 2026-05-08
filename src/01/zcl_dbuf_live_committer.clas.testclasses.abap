CLASS ltcl_test DEFINITION FINAL FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS object_instantiates FOR TESTING.
ENDCLASS.
CLASS ltcl_test IMPLEMENTATION.
  METHOD object_instantiates.
    cl_abap_unit_assert=>assert_not_initial( act = NEW zcl_dbuf_live_committer( ) ).
  ENDMETHOD.
ENDCLASS.
