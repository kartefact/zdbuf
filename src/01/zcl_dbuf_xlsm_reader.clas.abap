CLASS zcl_dbuf_xlsm_reader DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_file_reader.
ENDCLASS.

CLASS zcl_dbuf_xlsm_reader IMPLEMENTATION.
  METHOD zif_dbuf_file_reader~read.
    DATA(excel)  = NEW zcl_excel( ).
    DATA(reader) = NEW zcl_excel_reader_xlsm( ).
    TRY.
        reader->load_data( EXPORTING iv_data = file_content CHANGING io_excel = excel ).
      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION TYPE zcx_dbuf_file_error
          EXPORTING text = |XLSM read failed: { exc->if_message~get_text( ) }| previous = exc.
    ENDTRY.
    DATA(iterator) = excel->get_worksheets_iterator( ).
    WHILE iterator->has_next( ) = abap_true.
      DATA(ws) = CAST zcl_excel_worksheet( iterator->get_next( ) ).
      DATA(sheet) = VALUE zif_dbuf_file_reader=>sheet( name = ws->get_title( ) ).
      DATA(max_row) = ws->get_highest_row( ).
      DATA(max_col) = ws->get_highest_column( ).
      DO max_row TIMES.
        DATA(r) = sy-index.
        DATA(row_entry) = VALUE zif_dbuf_file_reader=>row( ).
        DO max_col TIMES.
          DATA(col) = zcl_excel_common=>convert_column2alpha( sy-index ).
          ws->get_cell( EXPORTING ip_column = col ip_row = r IMPORTING ep_value = DATA(cv) ).
          APPEND CONV string( cv ) TO row_entry-cells.
        ENDDO.
        APPEND row_entry TO sheet-rows.
      ENDDO.
      APPEND sheet TO result.
    ENDWHILE.
  ENDMETHOD.
ENDCLASS.
