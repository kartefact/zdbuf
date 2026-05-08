CLASS zcl_dbuf_live_committer DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_db_committer.
ENDCLASS.

CLASS zcl_dbuf_live_committer IMPLEMENTATION.
  METHOD zif_dbuf_db_committer~commit.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    ASSIGN table_ref->* TO <table>.
    IF <table> IS NOT ASSIGNED OR <table> IS INITIAL.
      result-message = 'No data to commit'.
      RETURN.
    ENDIF.
    TRY.
        MODIFY (table_name) CLIENT SPECIFIED FROM TABLE <table>. "#EC CI_DYNTAB
        IF sy-subrc = 0.
          COMMIT WORK.
          result-rows_committed = lines( <table> ).
          result-message = |{ result-rows_committed } row(s) committed to { table_name }|.
        ELSE.
          ROLLBACK WORK.
          result-rows_failed = lines( <table> ).
          result-message = |MODIFY { table_name } failed. SY-SUBRC = { sy-subrc }|.
          RAISE EXCEPTION TYPE zcx_dbuf_validation_error EXPORTING text = result-message.
        ENDIF.
      CATCH cx_sy_open_sql_db INTO DATA(exc).
        ROLLBACK WORK.
        result-rows_failed = lines( <table> ).
        result-message = exc->if_message~get_text( ).
        RAISE EXCEPTION TYPE zcx_dbuf_validation_error
          EXPORTING text = result-message previous = exc.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
