CLASS zcx_dbuf_validation_error DEFINITION
  PUBLIC
  INHERITING FROM zcx_dbuf_error
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        text     TYPE string OPTIONAL
        previous TYPE REF TO cx_root OPTIONAL.

ENDCLASS.

CLASS zcx_dbuf_validation_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( text     = text
                        previous = previous ).
  ENDMETHOD.
ENDCLASS.
