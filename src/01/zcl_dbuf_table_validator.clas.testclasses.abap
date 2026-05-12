CLASS ltcl_test DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_dbuf_table_validator.

    METHODS setup.
    METHODS sap_table_raises_error          FOR TESTING.
    METHODS numeric_start_raises_error      FOR TESTING.
    METHODS empty_name_raises_error         FOR TESTING.
    METHODS lowercase_z_raises_error        FOR TESTING.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_dbuf_table_validator( ).
  ENDMETHOD.

  METHOD sap_table_raises_error.
    TRY.
        cut->validate( 'MARA' ).
        cl_abap_unit_assert=>fail( 'SAP table MARA should raise validation error' ).
      CATCH zcx_dbuf_validation_error INTO DATA(exc).
        cl_abap_unit_assert=>assert_char_cp(
          act = exc->mv_text
          exp = '*not in Z* or Y* namespace*' ).
    ENDTRY.
  ENDMETHOD.

  METHOD numeric_start_raises_error.
    "Regression: table starting with digit bypassed namespace check
    TRY.
        cut->validate( '1ZTABLE' ).
        cl_abap_unit_assert=>fail( 'Numeric-start table must raise error' ).
      CATCH zcx_dbuf_validation_error.
        "Expected
    ENDTRY.
  ENDMETHOD.

  METHOD empty_name_raises_error.
    TRY.
        cut->validate( '' ).
        cl_abap_unit_assert=>fail( 'Empty table name must raise error' ).
      CATCH zcx_dbuf_validation_error.
        "Expected
    ENDTRY.
  ENDMETHOD.

  METHOD lowercase_z_raises_error.
    "Regression: lowercase 'z' was incorrectly allowed
    TRY.
        cut->validate( 'ztable' ).
        cl_abap_unit_assert=>fail( 'Lowercase z prefix must raise namespace error' ).
      CATCH zcx_dbuf_validation_error.
        "Expected
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
