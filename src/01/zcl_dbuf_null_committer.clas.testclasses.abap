CLASS ltcl_test DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_dbuf_null_committer.
    METHODS setup.
    METHODS commit_never_writes_db   FOR TESTING.
    METHODS commit_returns_zero_rows FOR TESTING.
    METHODS message_contains_test    FOR TESTING.
    METHODS empty_table_still_works  FOR TESTING.

ENDCLASS.

CLASS ltcl_test IMPLEMENTATION.

  METHOD setup.
    cut = NEW zcl_dbuf_null_committer( ).
  ENDMETHOD.

  METHOD commit_never_writes_db.
    CREATE DATA DATA(tr) TYPE TABLE OF string.
    FIELD-SYMBOLS <t> TYPE STANDARD TABLE.
    ASSIGN tr->* TO <t>.
    APPEND 'dummy' TO <t>.
    DATA(result) = cut->zif_dbuf_db_committer~commit( table_name = 'ZTESTXXX' table_ref = tr ).
    cl_abap_unit_assert=>assert_equals( act = result-rows_committed exp = 0 ).
  ENDMETHOD.

  METHOD commit_returns_zero_rows.
    CREATE DATA DATA(tr) TYPE TABLE OF string.
    DATA(result) = cut->zif_dbuf_db_committer~commit( table_name = 'ZTESTXXX' table_ref = tr ).
    cl_abap_unit_assert=>assert_equals( act = result-rows_failed exp = 0 ).
  ENDMETHOD.

  METHOD message_contains_test.
    CREATE DATA DATA(tr) TYPE TABLE OF string.
    DATA(result) = cut->zif_dbuf_db_committer~commit( table_name = 'ZTESTXXX' table_ref = tr ).
    cl_abap_unit_assert=>assert_char_cp( act = result-message exp = '*TEST MODE*' ).
  ENDMETHOD.

  METHOD empty_table_still_works.
    CREATE DATA DATA(tr) TYPE TABLE OF string.
    TRY.
        cut->zif_dbuf_db_committer~commit( table_name = 'ZTESTXXX' table_ref = tr ).
      CATCH cx_root INTO DATA(exc).
        cl_abap_unit_assert=>fail( msg = |Must not raise: { exc->if_message~get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
