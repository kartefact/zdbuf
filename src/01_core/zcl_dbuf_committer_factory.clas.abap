CLASS zcl_dbuf_committer_factory DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS create
      IMPORTING
        test_mode     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE REF TO zif_dbuf_db_committer.
ENDCLASS.

CLASS zcl_dbuf_committer_factory IMPLEMENTATION.
  METHOD create.
    IF test_mode = abap_true.
      result = NEW zcl_dbuf_null_committer( ).
    ELSE.
      result = NEW zcl_dbuf_live_committer( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
