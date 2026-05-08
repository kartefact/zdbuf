CLASS zcl_dbuf_dsv_reader DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_dbuf_file_reader.

    CONSTANTS:
      sep_comma     TYPE c VALUE ',',
      sep_semicolon TYPE c VALUE ';',
      sep_tab       TYPE c VALUE cl_abap_char_utilities=>horizontal_tab,
      sep_pipe      TYPE c VALUE '|',
      sep_tilde     TYPE c VALUE '~',
      sep_caret     TYPE c VALUE '^',
      sep_hash      TYPE c VALUE '#',
      sep_at        TYPE c VALUE '@'.

    METHODS set_separator
      IMPORTING separator TYPE c.

  PRIVATE SECTION.
    DATA separator TYPE c VALUE ','.

    METHODS xstring_to_string
      IMPORTING
        xdata         TYPE xstring
      RETURNING
        VALUE(result) TYPE string.

    METHODS strip_bom
      IMPORTING
        raw           TYPE string
      RETURNING
        VALUE(result) TYPE string.

    METHODS tokenize_line
      IMPORTING
        line          TYPE string
      RETURNING
        VALUE(result) TYPE string_table.

ENDCLASS.

CLASS zcl_dbuf_dsv_reader IMPLEMENTATION.

  METHOD set_separator.
    me->separator = separator.
  ENDMETHOD.

  METHOD zif_dbuf_file_reader~read.
    DATA(raw_string) = xstring_to_string( file_content ).
    DATA(clean)      = strip_bom( raw_string ).

    DATA(lines) = VALUE string_table( ).
    SPLIT clean AT cl_abap_char_utilities=>newline INTO TABLE lines.

    DATA(sheet) = VALUE zif_dbuf_file_reader=>sheet( name = 'Sheet1' ).

    LOOP AT lines INTO DATA(line).
      line = replace( val = line sub = cl_abap_char_utilities=>cr_lf of = '' ).
      line = replace( val = line sub = cl_abap_char_utilities=>newline of = '' ).
      IF line IS INITIAL. CONTINUE. ENDIF.

      DATA(row) = VALUE zif_dbuf_file_reader=>row( cells = tokenize_line( line ) ).
      APPEND row TO sheet-rows.
    ENDLOOP.

    APPEND sheet TO result.
  ENDMETHOD.

  METHOD xstring_to_string.
    DATA(conv) = cl_abap_conv_in_ce=>create(
      input    = xdata
      encoding = 'UTF-8'
      ignore_cerr = abap_true ).
    conv->read( IMPORTING data = result ).
  ENDMETHOD.

  METHOD strip_bom.
    DATA(bom) = cl_abap_char_utilities=>byte_order_mark_utf8.
    IF result CS bom.
      result = replace( val = raw sub = bom of = '' ).
    ELSE.
      result = raw.
    ENDIF.
  ENDMETHOD.

  METHOD tokenize_line.
    DATA in_quotes TYPE abap_bool VALUE abap_false.
    DATA current   TYPE string.

    DATA(chars) = cl_abap_string_utilities=>get_char_table( line ).

    LOOP AT chars INTO DATA(ch).
      IF ch = '"'.
        IF in_quotes = abap_false.
          in_quotes = abap_true.
        ELSEIF in_quotes = abap_true.
          in_quotes = abap_false.
        ENDIF.
      ELSEIF ch = separator AND in_quotes = abap_false.
        APPEND current TO result.
        CLEAR current.
      ELSE.
        current = current && ch.
      ENDIF.
    ENDLOOP.

    APPEND current TO result.
  ENDMETHOD.

ENDCLASS.
