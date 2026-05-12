CLASS ltcl_test DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_dbuf_auth_checker.

    METHODS setup.
    METHODS object_instantiates FOR TESTING.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_dbuf_auth_checker( ).
  ENDMETHOD.

  METHOD object_instantiates.
    cl_abap_unit_assert=>assert_not_initial( act = cut ).
  ENDMETHOD.

ENDCLASS.
