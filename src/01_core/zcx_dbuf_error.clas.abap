CLASS zcx_dbuf_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_text TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        text     TYPE string OPTIONAL
        previous TYPE REF TO cx_root OPTIONAL.

    METHODS if_message~get_text
      REDEFINITION.

ENDCLASS.

CLASS zcx_dbuf_error IMPLEMENTATION.

  METHOD constructor.
    super->constructor( previous = previous ).
    mv_text = text.
  ENDMETHOD.

  METHOD if_message~get_text.
    result = mv_text.
  ENDMETHOD.

ENDCLASS.
