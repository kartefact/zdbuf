CLASS zcl_dbuf_result_xlsx_writer DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_result_writer.
ENDCLASS.

CLASS zcl_dbuf_result_xlsx_writer IMPLEMENTATION.
  METHOD zif_dbuf_result_writer~write.
    DATA(excel) = NEW zcl_excel( ).
    DATA(ws)    = excel->get_active_worksheet( ).
    ws->set_title( |{ table_name }_Upload_Result| ).

    ws->set_cell( ip_column = 'A' ip_row = 1 ip_value = 'Row#' ).
    ws->set_cell( ip_column = 'B' ip_row = 1 ip_value = 'Status' ).
    ws->set_cell( ip_column = 'C' ip_row = 1 ip_value = 'Message' ).
    ws->set_cell( ip_column = 'D' ip_row = 1 ip_value = 'Raw Data' ).

    LOOP AT rows INTO DATA(row).
      DATA(r) = sy-tabix + 1.
      ws->set_cell( ip_column = 'A' ip_row = r ip_value = row-row_number ).
      ws->set_cell( ip_column = 'B' ip_row = r ip_value = row-status ).
      ws->set_cell( ip_column = 'C' ip_row = r ip_value = row-message ).
      ws->set_cell( ip_column = 'D' ip_row = r ip_value = row-raw_data ).
    ENDLOOP.

    TRY.
        DATA(writer) = CAST if_oi_spreadsheet(
          cl_oi_factory=>create_instance( )->get_spreadsheet_interface( 0 ) ).
        DATA(exporter) = NEW zcl_excel_writer_2007( ).
        result = exporter->write_file( excel ).
      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION TYPE zcx_dbuf_file_error
          EXPORTING text = |XLSX write failed: { exc->if_message~get_text( ) }| previous = exc.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
