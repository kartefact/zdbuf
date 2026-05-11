REPORT zdbuf_upload.

"----------------------------------------------------------------------
" Selection Screen
"----------------------------------------------------------------------
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS:
    p_file  TYPE string LOWER CASE OBLIGATORY,
    p_table TYPE tabname OBLIGATORY,
    p_sep   TYPE c DEFAULT ',',
    p_hdr   TYPE abap_bool AS CHECKBOX DEFAULT 'X',
    p_test  TYPE abap_bool AS CHECKBOX DEFAULT ' '.
PARAMETERS:
    p_fmt   TYPE c LENGTH 4 DEFAULT 'XLSX'.
SELECTION-SCREEN END OF BLOCK b1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  NEW zcl_dbuf_file_handler( )->get_file_path_via_f4( CHANGING file_path = p_file ).

"----------------------------------------------------------------------
" Start of Selection
"----------------------------------------------------------------------
START-OF-SELECTION.

  DATA(params) = VALUE zcl_dbuf_upload_processor=>upload_params(
    file_path  = p_file
    table_name = p_table
    separator  = p_sep
    has_header = p_hdr
    test_mode  = p_test
    out_format = p_fmt ).

  TRY.
      DATA(processor) = NEW zcl_dbuf_upload_processor( params ).
      DATA(result_xstring) = processor->execute( ).

      " Download result file
      DATA(out_path) = |C:\TEMP\{ p_table }_upload_result.{ to_lower( p_fmt ) }|.
      DATA binary_tab TYPE solix_tab.
      DATA file_length TYPE i.

      CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
        EXPORTING  buffer        = result_xstring
        IMPORTING output_length = file_length
        TABLES binary_tab    = binary_tab.

      cl_gui_frontend_services=>gui_download(
        EXPORTING
          filename     = out_path
          filetype     = 'BIN'
          bin_filesize = file_length
        CHANGING
          data_tab     = binary_tab
        EXCEPTIONS
          OTHERS       = 1 ).

      IF sy-subrc = 0.
        MESSAGE |Result file saved to { out_path }| TYPE 'S'.
      ELSE.
        MESSAGE |Result generated but download failed (SY-SUBRC={ sy-subrc })| TYPE 'W'.
      ENDIF.

    CATCH zcx_dbuf_auth_error INTO DATA(auth_exc).
      MESSAGE auth_exc->mv_text TYPE 'E'.

    CATCH zcx_dbuf_validation_error INTO DATA(val_exc).
      MESSAGE val_exc->mv_text TYPE 'E'.

    CATCH zcx_dbuf_mapping_error INTO DATA(map_exc).
      MESSAGE map_exc->mv_text TYPE 'E'.

    CATCH zcx_dbuf_file_error INTO DATA(file_exc).
      MESSAGE file_exc->mv_text TYPE 'E'.

    CATCH zcx_dbuf_error INTO DATA(base_exc).
      MESSAGE base_exc->mv_text TYPE 'E'.
  ENDTRY.
