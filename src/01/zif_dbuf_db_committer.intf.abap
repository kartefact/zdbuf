INTERFACE zif_dbuf_db_committer
  PUBLIC.

  TYPES:
    BEGIN OF commit_result,
      rows_committed TYPE i,
      rows_failed    TYPE i,
      message        TYPE string,
    END OF commit_result.

  METHODS commit
    IMPORTING
      table_name    TYPE tabname
      table_ref     TYPE REF TO data
    RETURNING
      VALUE(result) TYPE char1ommit_result
    RAISING
      zcx_dbuf_validation_error.

ENDINTERFACE.
