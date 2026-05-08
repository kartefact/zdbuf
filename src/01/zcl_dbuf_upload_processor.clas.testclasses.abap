CLASS ltcl_test DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS invalid_table_raises_error  FOR TESTING.
    METHODS missing_file_raises_error   FOR TESTING.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD invalid_table_raises_error.
    DATA(params) = VALUE zcl_dbuf_upload_processor=>upload_params(
      file_path  = 'C:\test.csv'
      table_name = 'MARA'
      separator  = ','
      has_header = abap_true
      test_mode  = abap_true
      out_format = 'XLSX' ).
    DATA(cut) = NEW zcl_dbuf_upload_processor( params ).
    TRY.
        cut->execute( ).
        cl_abap_unit_assert=>fail( 'SAP standard table MARA must raise validation error' ).
      CATCH zcx_dbuf_validation_error.
      CATCH zcx_dbuf_auth_error.
    ENDTRY.
  ENDMETHOD.

  METHOD missing_file_raises_error.
    DATA(params) = VALUE zcl_dbuf_upload_processor=>upload_params(
      file_path  = 'C:\nonexistent_zdbuf_test_file_xyz.csv'
      table_name = 'ZTESTXXX'
      separator  = ','
      has_header = abap_true
      test_mode  = abap_true
      out_format = 'XLSX' ).
    DATA(cut) = NEW zcl_dbuf_upload_processor( params ).
    TRY.
        cut->execute( ).
        cl_abap_unit_assert=>fail( 'Non-existent file must raise error' ).
      CATCH zcx_dbuf_validation_error.
      CATCH zcx_dbuf_file_error.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
