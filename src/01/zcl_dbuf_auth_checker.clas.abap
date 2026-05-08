CLASS zcl_dbuf_auth_checker DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Checks S_TABU_DIS (via TDDAT) then falls back to S_TABU_NAM.
    METHODS check
      IMPORTING
        table_name TYPE tabname
      RAISING
        zcx_dbuf_auth_error.

  PRIVATE SECTION.
    METHODS get_auth_group
      IMPORTING
        table_name    TYPE tabname
      RETURNING
        VALUE(result) TYPE tddat-cclass.

    METHODS check_by_group
      IMPORTING
        auth_group    TYPE tddat-cclass
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS check_by_table_name
      IMPORTING
        table_name    TYPE tabname
      RETURNING
        VALUE(result) TYPE abap_bool.

ENDCLASS.

CLASS zcl_dbuf_auth_checker IMPLEMENTATION.

  METHOD check.
    DATA(auth_group) = get_auth_group( table_name ).

    IF auth_group IS NOT INITIAL.
      IF check_by_group( auth_group ) = abap_true.
        RETURN.
      ENDIF.
    ENDIF.

    IF check_by_table_name( table_name ) = abap_true.
      RETURN.
    ENDIF.

    RAISE EXCEPTION TYPE zcx_dbuf_auth_error
      EXPORTING text = |Not authorized to change table { table_name }|.
  ENDMETHOD.

  METHOD get_auth_group.
    SELECT SINGLE cclass FROM tddat INTO @result
      WHERE tabname = @table_name.
  ENDMETHOD.

  METHOD check_by_group.
    AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
      ID 'DICBERCLS' FIELD auth_group
      ID 'ACTVT'     FIELD '02'.
    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD check_by_table_name.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
      ID 'TABLE' FIELD table_name
      ID 'ACTVT' FIELD '02'.
    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

ENDCLASS.
