CLASS zcl_dbuf_null_committer DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_db_committer.
ENDCLASS.

CLASS zcl_dbuf_null_committer IMPLEMENTATION.
  METHOD zif_dbuf_db_committer~commit.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    ASSIGN table_ref->* TO <table>.
    DATA(row_count) = COND i( WHEN <table> IS ASSIGNED THEN lines( <table> ) ELSE 0 ).
    result-rows_committed = 0.
    result-rows_failed    = 0.
    result-message = |TEST MODE: { row_count } row(s) validated; no DB write performed|.
  ENDMETHOD.
ENDCLASS.
