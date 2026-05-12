CLASS zcl_dbuf_result_csv_writer DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_result_writer.
ENDCLASS.

CLASS zcl_dbuf_result_csv_writer IMPLEMENTATION.
  METHOD zif_dbuf_result_writer~write.
    DATA(nl) = cl_abap_char_utilities=>newline.
    DATA(output) = |Row#,Status,Message,Raw Data{ nl }|.

    LOOP AT rows INTO DATA(row).
      DATA(msg)  = replace( val = row-message
                            sub = ','
                            of  = ';' ).
      DATA(data) = replace( val = row-raw_data
                            sub = ','
                            of  = ';' ).
      output = output && |{ row-row_number },{ row-status },{ msg },{ data }{ nl }|.
    ENDLOOP.

    TRY.
        result = cl_abap_codepage=>convert_from( output ).
      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION NEW zcx_dbuf_file_error( text     = |CSV encode failed: { exc->if_message~get_text( ) }|
                                                 previous = exc ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
