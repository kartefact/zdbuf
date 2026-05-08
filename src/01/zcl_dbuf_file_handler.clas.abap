CLASS zcl_dbuf_file_handler DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS upload_to_xstring
      IMPORTING
        file_path     TYPE string
      RETURNING
        VALUE(result) TYPE xstring
      RAISING
        zcx_dbuf_file_error.

    METHODS get_file_path_via_f4
      CHANGING
        file_path TYPE string.

ENDCLASS.

CLASS zcl_dbuf_file_handler IMPLEMENTATION.

  METHOD upload_to_xstring.
    DATA binary_tab  TYPE solix_tab.
    DATA file_length TYPE i.

    cl_gui_frontend_services=>gui_upload(
      EXPORTING filename = file_path filetype = 'BIN'
      IMPORTING filelength = file_length
      CHANGING  data_tab   = binary_tab
      EXCEPTIONS file_open_error = 1 file_read_error = 2
                 no_batch = 3 gui_refuse_filetransfer = 4 OTHERS = 5 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_dbuf_file_error
        EXPORTING text = |Cannot open file: { file_path } (SY-SUBRC={ sy-subrc })|.
    ENDIF.

    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING  input_length = file_length
      IMPORTING  buffer       = result
      TABLES     binary_tab   = binary_tab
      EXCEPTIONS OTHERS       = 1.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_dbuf_file_error
        EXPORTING text = |Binary conversion failed for: { file_path }|.
    ENDIF.
  ENDMETHOD.

  METHOD get_file_path_via_f4.
    DATA(filters) = VALUE cl_gui_frontend_services=>t_file_filter(
      ( mask = '*.csv;*.tsv;*.psv;*.txt;*.xlsx;*.xlsm' text = 'Upload files' )
      ( mask = '*.*' text = 'All files' ) ).

    cl_gui_frontend_services=>file_open_dialog(
      EXPORTING window_title = 'Select upload file'
                file_filter  = cl_gui_frontend_services=>build_filter_string( filters )
      CHANGING  file_table   = DATA(file_table)
                rc           = DATA(rc)
      EXCEPTIONS OTHERS      = 1 ).

    IF sy-subrc = 0 AND lines( file_table ) > 0.
      file_path = file_table[ 1 ]-filename.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
