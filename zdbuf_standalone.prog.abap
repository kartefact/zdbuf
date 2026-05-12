*&---------------------------------------------------------------------*
*& Report zdbuf_standalone
*&---------------------------------------------------------------------*
*&*& Uploads DSV (CSV/TSV/PSV/TXT) or Excel files into a Z/Y DDIC table.
*&
*& Optional dependency: abap2xlsx (https://github.com/abap2xlsx/abap2xlsx)
*& XLSX/XLSM support is activated automatically when abap2xlsx classes
*& (ZCL_EXCEL, ZCL_EXCEL_READER_2007, etc.) are present in the system.
*& Without abap2xlsx only DSV formats (CSV, TSV, PSV, TXT) are supported.
*&---------------------------------------------------------------------*
REPORT zdbuf_standalone.

INTERFACE lif_dbuf_result_writer DEFERRED.
INTERFACE lif_dbuf_file_reader DEFERRED.
INTERFACE lif_dbuf_db_committer DEFERRED.
CLASS lcl_dbuf_xlsx_reader DEFINITION DEFERRED.
CLASS lcl_dbuf_xlsm_reader DEFINITION DEFERRED.
CLASS lcl_dbuf_writer_factory DEFINITION DEFERRED.
CLASS lcl_dbuf_upload_processor DEFINITION DEFERRED.
CLASS lcl_dbuf_table_validator DEFINITION DEFERRED.
CLASS lcl_dbuf_row_validator DEFINITION DEFERRED.
CLASS lcl_dbuf_result_xlsx_writer DEFINITION DEFERRED.
CLASS lcl_dbuf_result_csv_writer DEFINITION DEFERRED.
CLASS lcl_dbuf_reader_factory DEFINITION DEFERRED.
CLASS lcl_dbuf_null_committer DEFINITION DEFERRED.
CLASS lcl_dbuf_live_committer DEFINITION DEFERRED.
CLASS lcl_dbuf_huge_xlsx_reader DEFINITION DEFERRED.
CLASS lcl_dbuf_file_handler DEFINITION DEFERRED.
CLASS lcl_dbuf_dsv_reader DEFINITION DEFERRED.
CLASS lcl_dbuf_committer_factory DEFINITION DEFERRED.
CLASS lcl_dbuf_column_mapper DEFINITION DEFERRED.
CLASS lcl_dbuf_auth_checker DEFINITION DEFERRED.
CLASS lcl_dbuf_template_builder DEFINITION DEFERRED.
CLASS lcl_dbuf_env DEFINITION DEFERRED.
CLASS lcx_dbuf_error DEFINITION
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    DATA mv_text TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING !text     TYPE string         OPTIONAL
                !previous TYPE REF TO cx_root OPTIONAL.

    METHODS if_message~get_text REDEFINITION.

ENDCLASS.


CLASS lcx_dbuf_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( previous = previous ).
    mv_text = text.
  ENDMETHOD.

  METHOD if_message~get_text.
    result = mv_text.
  ENDMETHOD.
ENDCLASS.


CLASS lcx_dbuf_auth_error DEFINITION
  INHERITING FROM lcx_dbuf_error FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING !text     TYPE string         OPTIONAL
                !previous TYPE REF TO cx_root OPTIONAL.

ENDCLASS.


CLASS lcx_dbuf_auth_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( text     = text
                        previous = previous ).
  ENDMETHOD.
ENDCLASS.


CLASS lcx_dbuf_file_error DEFINITION
  INHERITING FROM lcx_dbuf_error FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING !text     TYPE string         OPTIONAL
                !previous TYPE REF TO cx_root OPTIONAL.

ENDCLASS.


CLASS lcx_dbuf_file_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( text     = text
                        previous = previous ).
  ENDMETHOD.
ENDCLASS.


CLASS lcx_dbuf_mapping_error DEFINITION
  INHERITING FROM lcx_dbuf_error FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING !text     TYPE string         OPTIONAL
                !previous TYPE REF TO cx_root OPTIONAL.

ENDCLASS.


CLASS lcx_dbuf_mapping_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( text     = text
                        previous = previous ).
  ENDMETHOD.
ENDCLASS.


CLASS lcx_dbuf_validation_error DEFINITION
  INHERITING FROM lcx_dbuf_error FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING !text     TYPE string         OPTIONAL
                !previous TYPE REF TO cx_root OPTIONAL.

ENDCLASS.


CLASS lcx_dbuf_validation_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( text     = text
                        previous = previous ).
  ENDMETHOD.
ENDCLASS.


INTERFACE lif_dbuf_db_committer.

  TYPES:
    BEGIN OF commit_result,
      rows_committed TYPE i,
      rows_failed    TYPE i,
      message        TYPE string,
    END OF commit_result.

  METHODS commit
    IMPORTING table_name    TYPE tabname
              table_ref     TYPE REF TO data
    RETURNING VALUE(result) TYPE commit_result
    RAISING   lcx_dbuf_validation_error.

ENDINTERFACE.


INTERFACE lif_dbuf_file_reader.

  TYPES: BEGIN OF row,
           cells TYPE string_table,
         END OF row,
         rows TYPE STANDARD TABLE OF row WITH DEFAULT KEY.
  TYPES: BEGIN OF sheet,
           name TYPE string,
           rows TYPE rows,
         END OF sheet,
         sheets TYPE STANDARD TABLE OF sheet WITH DEFAULT KEY.

  "! Read file content and return parsed sheets.
  "!
  "! @parameter file_content        | File Content as XSTRING.
  "! @parameter has_header          | Indicates if the first row contains headers (default: true).
  "! @parameter result              | Parsed sheets with rows and cells.
  "! @raising   lcx_dbuf_file_error | In case of file read or parsing errors.
  METHODS read
    IMPORTING file_content  TYPE xstring
              has_header    TYPE abap_bool DEFAULT abap_true
    RETURNING VALUE(result) TYPE sheets
    RAISING   lcx_dbuf_file_error.

ENDINTERFACE.


INTERFACE lif_dbuf_result_writer.

  TYPES:
    BEGIN OF result_row,
      row_number TYPE i,
      status     TYPE c LENGTH 1,
      message    TYPE string,
      raw_data   TYPE string,
    END OF result_row,
    result_rows TYPE STANDARD TABLE OF result_row WITH DEFAULT KEY.

  METHODS write
    IMPORTING table_name    TYPE tabname
              !rows         TYPE result_rows
    RETURNING VALUE(result) TYPE xstring
    RAISING   lcx_dbuf_file_error.

ENDINTERFACE.


CLASS lcl_dbuf_auth_checker DEFINITION FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Checks S_TABU_DIS (via TDDAT) then falls back to S_TABU_NAM.
    "!
    "! @parameter table_name          | Name of the table to check authorization for.
    "! @raising   lcx_dbuf_auth_error | In case of missing authorization.
    METHODS check
      IMPORTING table_name TYPE tabname
      RAISING   lcx_dbuf_auth_error.

    CLASS-METHODS f4_table
      IMPORTING search_pattern TYPE tabname DEFAULT 'Z*'
      CHANGING  table_name     TYPE tabname.

  PRIVATE SECTION.
    METHODS get_auth_group
      IMPORTING table_name    TYPE tabname
      RETURNING VALUE(result) TYPE tddat-cclass.

    METHODS check_by_group
      IMPORTING auth_group    TYPE tddat-cclass
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS check_by_table_name
      IMPORTING table_name    TYPE tabname
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS lcl_dbuf_column_mapper DEFINITION FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF column_mapping,
        header_token TYPE string,
        field_name   TYPE fieldname,
        position     TYPE i,
      END OF column_mapping,
      column_mappings TYPE STANDARD TABLE OF column_mapping WITH DEFAULT KEY.

    METHODS map_headers
      IMPORTING table_name    TYPE tabname
                header_row    TYPE string_table
      RETURNING VALUE(result) TYPE column_mappings
      RAISING   lcx_dbuf_mapping_error.

  PRIVATE SECTION.
    TYPES tt_dd03l TYPE STANDARD TABLE OF dd03l WITH DEFAULT KEY.

    METHODS get_ddic_fields
      IMPORTING table_name    TYPE tabname
      RETURNING VALUE(result) TYPE tt_dd03l.

ENDCLASS.


CLASS lcl_dbuf_committer_factory DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS create
      IMPORTING test_mode     TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(result) TYPE REF TO lif_dbuf_db_committer.
ENDCLASS.


CLASS lcl_dbuf_dsv_reader DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES lif_dbuf_file_reader.

    CONSTANTS sep_comma     TYPE c LENGTH 1 VALUE ','.
    CONSTANTS sep_semicolon TYPE c LENGTH 1 VALUE ';'.
    CONSTANTS sep_tab       TYPE c LENGTH 1 VALUE cl_abap_char_utilities=>horizontal_tab.
    CONSTANTS sep_pipe      TYPE c LENGTH 1 VALUE '|'.
    CONSTANTS sep_tilde     TYPE c LENGTH 1 VALUE '~'.
    CONSTANTS sep_caret     TYPE c LENGTH 1 VALUE '^'.
    CONSTANTS sep_hash      TYPE c LENGTH 1 VALUE '#'.
    CONSTANTS sep_at        TYPE c LENGTH 1 VALUE '@'.

    METHODS set_separator
      IMPORTING separator TYPE char1.

  PRIVATE SECTION.
    DATA separator TYPE char1 VALUE ','.

    METHODS xstring_to_string
      IMPORTING xdata         TYPE xstring
      RETURNING VALUE(result) TYPE string.

    METHODS strip_bom
      IMPORTING !raw          TYPE string
      RETURNING VALUE(result) TYPE string.

    METHODS tokenize_line
      IMPORTING !line         TYPE string
      RETURNING VALUE(result) TYPE string_table.

ENDCLASS.


CLASS lcl_dbuf_file_handler DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS upload_to_xstring
      IMPORTING file_path     TYPE string
      RETURNING VALUE(result) TYPE xstring
      RAISING   lcx_dbuf_file_error.

    METHODS get_file_path_via_f4
      CHANGING file_path TYPE string.

    CLASS-METHODS f4_server_file
      IMPORTING operation TYPE c                 DEFAULT 'R'    " 'R' = open, 'W' = save
                start_dir TYPE dxfields-longpath DEFAULT '/tmp'
      CHANGING  file_path TYPE string.

ENDCLASS.


CLASS lcl_dbuf_huge_xlsx_reader DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_dbuf_file_reader.
ENDCLASS.


CLASS lcl_dbuf_live_committer DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_dbuf_db_committer.
ENDCLASS.


CLASS lcl_dbuf_null_committer DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_dbuf_db_committer.
ENDCLASS.


CLASS lcl_dbuf_reader_factory DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS ext_csv     TYPE string VALUE 'CSV'.
    CONSTANTS ext_tsv     TYPE string VALUE 'TSV'.
    CONSTANTS ext_psv     TYPE string VALUE 'PSV'.
    CONSTANTS ext_txt     TYPE string VALUE 'TXT'.
    CONSTANTS ext_xlsx    TYPE string VALUE 'XLSX'.
    CONSTANTS ext_xlsm    TYPE string VALUE 'XLSM'.
    CONSTANTS ext_xlshuge TYPE string VALUE 'XLSHUGE'.

    CLASS-METHODS create_for_extension
      IMPORTING !extension    TYPE string
                separator     TYPE char1 OPTIONAL
      RETURNING VALUE(result) TYPE REF TO lif_dbuf_file_reader
      RAISING   lcx_dbuf_file_error.

    CLASS-METHODS separator_for_extension
      IMPORTING !extension    TYPE string
      RETURNING VALUE(result) TYPE char1.

    CLASS-METHODS abap2xlsx_available
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS lcl_dbuf_result_csv_writer DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_dbuf_result_writer.
ENDCLASS.


CLASS lcl_dbuf_result_xlsx_writer DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_dbuf_result_writer.
ENDCLASS.


CLASS lcl_dbuf_row_validator DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF validation_result,
        row_index TYPE i,
        is_valid  TYPE abap_bool,
        message   TYPE string,
      END OF validation_result.

    METHODS validate_row
      IMPORTING row_index     TYPE i
                cells         TYPE string_table
                mappings      TYPE lcl_dbuf_column_mapper=>column_mappings
                table_name    TYPE tabname
      RETURNING VALUE(result) TYPE validation_result.

  PRIVATE SECTION.
    METHODS get_field_metadata
      IMPORTING table_name    TYPE tabname
                field_name    TYPE fieldname
      RETURNING VALUE(result) TYPE dd03l.

    METHODS check_length
      IMPORTING !value        TYPE string
                field_def     TYPE dd03l
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS lcl_dbuf_table_validator DEFINITION FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Validates table name: Z*/Y* namespace + DDIC TRANSP check.
    "!
    "! @parameter table_name                | Name of the table to validate.
    "! @raising   lcx_dbuf_validation_error | In case of validation failure.
    METHODS validate
      IMPORTING table_name TYPE tabname
      RAISING   lcx_dbuf_validation_error.

  PRIVATE SECTION.
    METHODS is_custom_namespace
      IMPORTING table_name    TYPE tabname
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS exists_in_ddic
      IMPORTING table_name    TYPE tabname
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS lcl_dbuf_upload_processor DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF upload_params,
        file_path  TYPE string,
        table_name TYPE tabname,
        separator  TYPE char1,
        has_header TYPE abap_bool,
        test_mode  TYPE abap_bool,
        out_format TYPE string,
      END OF upload_params.

    METHODS constructor
      IMPORTING params TYPE upload_params.

    METHODS execute
      RETURNING VALUE(result_xstring) TYPE xstring
      RAISING   lcx_dbuf_error.

    METHODS get_out_format
      RETURNING VALUE(result) TYPE string
      RAISING   lcx_dbuf_file_error.

    " NEW: returns parsed rows — populated after execute()
    METHODS get_result_rows
      RETURNING VALUE(result) TYPE lif_dbuf_result_writer=>result_rows.

  PRIVATE SECTION.
    DATA ms_params    TYPE upload_params.
    DATA mo_mapper    TYPE REF TO lcl_dbuf_column_mapper.
    DATA mo_validator TYPE REF TO lcl_dbuf_row_validator.
    DATA mt_rows      TYPE lif_dbuf_result_writer=>result_rows. " NEW

    METHODS read_file
      RETURNING VALUE(result) TYPE xstring
      RAISING   lcx_dbuf_file_error.

    METHODS get_extension
      RETURNING VALUE(result) TYPE string
      RAISING   lcx_dbuf_file_error.

    METHODS parse_and_process
      IMPORTING file_content  TYPE xstring
      RETURNING VALUE(result) TYPE lif_dbuf_result_writer=>result_rows
      RAISING   lcx_dbuf_error.

    METHODS build_dynamic_table
      IMPORTING mappings      TYPE lcl_dbuf_column_mapper=>column_mappings
      RETURNING VALUE(result) TYPE REF TO data
      RAISING   lcx_dbuf_validation_error.

    METHODS fill_dynamic_row
      IMPORTING row_ref  TYPE REF TO data
                cells    TYPE string_table
                mappings TYPE lcl_dbuf_column_mapper=>column_mappings.

ENDCLASS.


CLASS lcl_dbuf_writer_factory DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CONSTANTS fmt_xlsx TYPE string VALUE 'XLSX'.
    CONSTANTS fmt_csv  TYPE string VALUE 'CSV'.

    CLASS-METHODS create
      IMPORTING !format       TYPE string DEFAULT 'XLSX'
      RETURNING VALUE(result) TYPE REF TO lif_dbuf_result_writer.
ENDCLASS.


CLASS lcl_dbuf_xlsm_reader DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_dbuf_file_reader.
ENDCLASS.


CLASS lcl_dbuf_xlsx_reader DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_dbuf_file_reader.
ENDCLASS.


CLASS lcl_dbuf_template_builder DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    "! Builds a CSV header-only template from DDIC field names.
    "!
    "! @parameter table_name                | Name of the table to build template for.
    "! @parameter result                    | CSV content as string with header row only.
    "! @raising   lcx_dbuf_validation_error | In case of table validation failure.
    CLASS-METHODS build_csv
      IMPORTING table_name    TYPE tabname
      RETURNING VALUE(result) TYPE string
      RAISING   lcx_dbuf_validation_error.

    "! Downloads the template CSV to the user's PC via file save dialog.
    "!
    "! @parameter table_name          | Name of the table to build template for (used for filename and header).
    "! @parameter content             | CSV content as string with header row only.
    "! @raising   lcx_dbuf_file_error | In case of file download errors.
    CLASS-METHODS download
      IMPORTING table_name TYPE tabname
                content    TYPE string
      RAISING   lcx_dbuf_file_error.

ENDCLASS.


CLASS lcl_dbuf_env DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Checks if the current environment supports GUI operations (file dialogs, downloads, etc.).
    "! In a non-GUI environment (e.g., background job), file operations should be handled differently or avoided.
    "! This method can be used to conditionally enable/disable features that require GUI access.
    "!
    "! @parameter result | abap_bool indicating if GUI operations are available (true) or not (false).
    CLASS-METHODS gui_available
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS lcl_dbuf_xlsx_reader IMPLEMENTATION.
  METHOD lif_dbuf_file_reader~read.
    DATA lo_reader   TYPE REF TO object.
    DATA lo_excel    TYPE REF TO object.
    DATA lo_iterator TYPE REF TO object.
    DATA lv_has_next TYPE abap_bool.
    DATA lo_ws       TYPE REF TO object.
    DATA lv_title    TYPE string.
    DATA lv_max_row  TYPE i.
    DATA lv_max_col  TYPE i.
    DATA lv_col      TYPE string.
    DATA lv_cv       TYPE string.

    TRY.
        CREATE OBJECT lo_reader TYPE ('ZCL_EXCEL_READER_2007').

        CALL METHOD lo_reader->('ZIF_EXCEL_READER~LOAD')
          EXPORTING i_excel2007 = file_content
          RECEIVING r_excel     = lo_excel.

        " GET_WORKSHEETS_ITERATOR is directly on ZCL_EXCEL — RETURNING eo_iterator
        CALL METHOD lo_excel->('GET_WORKSHEETS_ITERATOR')
          RECEIVING eo_iterator = lo_iterator.

        WHILE abap_true = abap_true.
          CALL METHOD lo_iterator->('HAS_NEXT')
            RECEIVING has_next = lv_has_next.
          IF lv_has_next = abap_false. EXIT. ENDIF.

          CALL METHOD lo_iterator->('GET_NEXT')
            RECEIVING object = lo_ws.

          CALL METHOD lo_ws->('GET_TITLE')
            RECEIVING ep_title = lv_title.

          DATA(sheet) = VALUE lif_dbuf_file_reader=>sheet( name = lv_title ).

          CALL METHOD lo_ws->('GET_HIGHEST_ROW')
            RECEIVING r_highest_row = lv_max_row.

          CALL METHOD lo_ws->('GET_HIGHEST_COLUMN')
            RECEIVING r_highest_column = lv_max_col.

          DO lv_max_row TIMES.
            DATA(r)         = sy-index.
            DATA(row_entry) = VALUE lif_dbuf_file_reader=>row( ).
            DO lv_max_col TIMES.
              DATA(lv_col_idx) = sy-index.          " named variable — not sy-index inline
              CALL METHOD ('ZCL_EXCEL_COMMON')=>('CONVERT_COLUMN2ALPHA')
                EXPORTING ip_column = lv_col_idx
                RECEIVING ep_column = lv_col.
              CALL METHOD lo_ws->('GET_CELL')
                EXPORTING ip_column = lv_col
                          ip_row    = r
                IMPORTING ep_value  = lv_cv.
              APPEND lv_cv TO row_entry-cells.
            ENDDO.
            APPEND row_entry TO sheet-rows.
          ENDDO.
          APPEND sheet TO result.
        ENDWHILE.

      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION TYPE lcx_dbuf_file_error
          EXPORTING text     = |XLSX read failed: { exc->if_message~get_text( ) }| ##NO_TEXT
                    previous = exc.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_xlsm_reader IMPLEMENTATION.
  METHOD lif_dbuf_file_reader~read.
    DATA lo_reader   TYPE REF TO object.
    DATA lo_excel    TYPE REF TO object.
    DATA lo_iterator TYPE REF TO object.
    DATA lv_has_next TYPE abap_bool.
    DATA lo_ws       TYPE REF TO object.
    DATA lv_title    TYPE string.
    DATA lv_max_row  TYPE i.
    DATA lv_max_col  TYPE i.
    DATA lv_col      TYPE string.
    DATA lv_cv       TYPE string.

    TRY.
        CREATE OBJECT lo_reader TYPE ('ZCL_EXCEL_READER_XLSM').

        CALL METHOD lo_reader->('ZIF_EXCEL_READER~LOAD')
          EXPORTING i_excel2007 = file_content
          RECEIVING r_excel     = lo_excel.

        CALL METHOD lo_excel->('GET_WORKSHEETS_ITERATOR')
          RECEIVING eo_iterator = lo_iterator.

        WHILE abap_true = abap_true.
          CALL METHOD lo_iterator->('HAS_NEXT')
            RECEIVING has_next = lv_has_next.
          IF lv_has_next = abap_false. EXIT. ENDIF.

          CALL METHOD lo_iterator->('GET_NEXT')
            RECEIVING object = lo_ws.

          CALL METHOD lo_ws->('GET_TITLE')
            RECEIVING ep_title = lv_title.

          DATA(sheet) = VALUE lif_dbuf_file_reader=>sheet( name = lv_title ).

          CALL METHOD lo_ws->('GET_HIGHEST_ROW')
            RECEIVING r_highest_row = lv_max_row.

          CALL METHOD lo_ws->('GET_HIGHEST_COLUMN')
            RECEIVING r_highest_column = lv_max_col.

          DO lv_max_row TIMES.
            DATA(r)         = sy-index.
            DATA(row_entry) = VALUE lif_dbuf_file_reader=>row( ).
            DO lv_max_col TIMES.
              DATA(lv_col_idx) = sy-index.          " named variable — not sy-index inline
              CALL METHOD ('ZCL_EXCEL_COMMON')=>('CONVERT_COLUMN2ALPHA')
                EXPORTING ip_column = lv_col_idx
                RECEIVING ep_column = lv_col.
              CALL METHOD lo_ws->('GET_CELL')
                EXPORTING ip_column = lv_col
                          ip_row    = r
                IMPORTING ep_value  = lv_cv.
              APPEND lv_cv TO row_entry-cells.
            ENDDO.
            APPEND row_entry TO sheet-rows.
          ENDDO.
          APPEND sheet TO result.
        ENDWHILE.

      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION TYPE lcx_dbuf_file_error
          EXPORTING text     = |XLSM read failed: { exc->if_message~get_text( ) }| ##NO_TEXT
                    previous = exc.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_huge_xlsx_reader IMPLEMENTATION.
  METHOD lif_dbuf_file_reader~read.
    DATA lo_reader   TYPE REF TO object.
    DATA lo_excel    TYPE REF TO object.
    DATA lo_iterator TYPE REF TO object.
    DATA lv_has_next TYPE abap_bool.
    DATA lo_ws       TYPE REF TO object.
    DATA lv_title    TYPE string.
    DATA lv_max_row  TYPE i.
    DATA lv_max_col  TYPE i.
    DATA lv_col      TYPE string.
    DATA lv_cv       TYPE string.

    TRY.
        CREATE OBJECT lo_reader TYPE ('ZCL_EXCEL_READER_HUGE_FILE').

        CALL METHOD lo_reader->('ZIF_EXCEL_READER~LOAD')
          EXPORTING i_excel2007 = file_content
          RECEIVING r_excel     = lo_excel.

        CALL METHOD lo_excel->('GET_WORKSHEETS_ITERATOR')
          RECEIVING eo_iterator = lo_iterator.

        WHILE abap_true = abap_true.
          CALL METHOD lo_iterator->('HAS_NEXT')
            RECEIVING has_next = lv_has_next.
          IF lv_has_next = abap_false. EXIT. ENDIF.

          CALL METHOD lo_iterator->('GET_NEXT')
            RECEIVING object = lo_ws.

          CALL METHOD lo_ws->('GET_TITLE')
            RECEIVING ep_title = lv_title.

          DATA(sheet) = VALUE lif_dbuf_file_reader=>sheet( name = lv_title ).

          CALL METHOD lo_ws->('GET_HIGHEST_ROW')
            RECEIVING r_highest_row = lv_max_row.

          CALL METHOD lo_ws->('GET_HIGHEST_COLUMN')
            RECEIVING r_highest_column = lv_max_col.

          DO lv_max_row TIMES.
            DATA(r)         = sy-index.
            DATA(row_entry) = VALUE lif_dbuf_file_reader=>row( ).
            DO lv_max_col TIMES.
              DATA(lv_col_idx) = sy-index.          " named variable — not sy-index inline
              CALL METHOD ('ZCL_EXCEL_COMMON')=>('CONVERT_COLUMN2ALPHA')
                EXPORTING ip_column = lv_col_idx
                RECEIVING ep_column = lv_col.
              CALL METHOD lo_ws->('GET_CELL')
                EXPORTING ip_column = lv_col
                          ip_row    = r
                IMPORTING ep_value  = lv_cv.
              APPEND lv_cv TO row_entry-cells.
            ENDDO.
            APPEND row_entry TO sheet-rows.
          ENDDO.
          APPEND sheet TO result.
        ENDWHILE.

      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION TYPE lcx_dbuf_file_error
          EXPORTING text     = |Huge XLSX read failed: { exc->if_message~get_text( ) }| ##NO_TEXT
                    previous = exc.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_writer_factory IMPLEMENTATION.
  METHOD create.
    CASE to_upper( format ).
      WHEN fmt_csv.
        result = NEW lcl_dbuf_result_csv_writer( ).
      WHEN OTHERS.
        IF lcl_dbuf_reader_factory=>abap2xlsx_available( ) = abap_true.
          result = NEW lcl_dbuf_result_xlsx_writer( ).
        ELSE.
          result = NEW lcl_dbuf_result_csv_writer( ).
        ENDIF.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_upload_processor IMPLEMENTATION.
  METHOD constructor.
    ms_params = params.
    mo_mapper = NEW lcl_dbuf_column_mapper( ).
    mo_validator = NEW lcl_dbuf_row_validator( ).
  ENDMETHOD.

  METHOD execute.
    NEW lcl_dbuf_table_validator( )->validate( ms_params-table_name ).
    NEW lcl_dbuf_auth_checker( )->check( ms_params-table_name ).

    DATA(file_content) = read_file( ).
    mt_rows = parse_and_process( file_content ).         " store for get_result_rows()

    DATA(writer) = lcl_dbuf_writer_factory=>create( get_out_format( ) ).
    result_xstring = writer->write( table_name = ms_params-table_name
                                    rows       = mt_rows ).
  ENDMETHOD.

  METHOD get_result_rows.
    result = mt_rows.
  ENDMETHOD.

  METHOD get_out_format.
    DATA(ext) = get_extension( ).
    CASE ext.
      WHEN lcl_dbuf_reader_factory=>ext_xlsx
        OR lcl_dbuf_reader_factory=>ext_xlsm
        OR lcl_dbuf_reader_factory=>ext_xlshuge.
        IF lcl_dbuf_reader_factory=>abap2xlsx_available( ) = abap_true.
          result = lcl_dbuf_writer_factory=>fmt_xlsx.
        ELSE.
          result = lcl_dbuf_writer_factory=>fmt_csv.
        ENDIF.
      WHEN OTHERS.
        result = lcl_dbuf_writer_factory=>fmt_csv.
    ENDCASE.
  ENDMETHOD.

  METHOD read_file.
    result = NEW lcl_dbuf_file_handler( )->upload_to_xstring( ms_params-file_path ).
  ENDMETHOD.

  METHOD get_extension.
    DATA parts TYPE string_table.

    " Fast-fail: no dot at all — no extension possible
    IF NOT ms_params-file_path CA '.'.
      RAISE EXCEPTION TYPE lcx_dbuf_file_error
        EXPORTING
          text = |Cannot determine file type from path: { ms_params-file_path }. Please include extension (e.g. .xlsx, .csv)| ##NO_TEXT.
    ENDIF.

    SPLIT ms_params-file_path AT '.' INTO TABLE parts.
    DATA(count) = lines( parts ).

    " count > 1 ensures there is actually a segment after the dot
    IF count > 1.
      result = to_upper( condense( val  = parts[ count ]
                                   from = ` `
                                   to   = `` ) ).
    ENDIF.

    IF result IS INITIAL.
      RAISE EXCEPTION TYPE lcx_dbuf_file_error
        EXPORTING
          text = |Cannot determine file type from path: { ms_params-file_path }. Please include extension (e.g. .xlsx, .csv)| ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD parse_and_process.
    DATA header_tokens TYPE string_table.
    DATA lo_row_ref    TYPE REF TO data.

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    DATA(extension) = get_extension( ).
    DATA(reader) = lcl_dbuf_reader_factory=>create_for_extension( extension = extension
                                                                  separator = ms_params-separator ).

    DATA(sheets) = reader->read( file_content = file_content
                                 has_header   = ms_params-has_header ).

    IF sheets IS INITIAL.
      RAISE EXCEPTION TYPE lcx_dbuf_file_error
        EXPORTING text = 'File contains no parseable sheets' ##NO_TEXT.
    ENDIF.

    DATA(rows) = sheets[ 1 ]-rows.
    IF rows IS INITIAL.
      RAISE EXCEPTION TYPE lcx_dbuf_file_error
        EXPORTING text = 'File sheet is empty' ##NO_TEXT.
    ENDIF.

    DATA(start_row) = 2.

    IF ms_params-has_header = abap_true.
      header_tokens = rows[ 1 ]-cells.
    ELSE.
      start_row = 1.
      SELECT fieldname FROM dd03l
        INTO TABLE @header_tokens
        WHERE tabname          = @ms_params-table_name AND as4local = 'A'
          AND fieldname NOT LIKE '.%'
        ORDER BY position.
    ENDIF.

    DATA(mappings) = mo_mapper->map_headers( table_name = ms_params-table_name
                                             header_row = header_tokens ).
    DATA(table_ref) = build_dynamic_table( mappings ).
    DATA(committer) = lcl_dbuf_committer_factory=>create( ms_params-test_mode ).

    ASSIGN table_ref->* TO <table>.

    DATA(row_idx) = start_row.
    LOOP AT rows INTO DATA(data_row) FROM start_row.
      DATA(vr) = mo_validator->validate_row( row_index  = row_idx
                                             cells      = data_row-cells
                                             mappings   = mappings
                                             table_name = ms_params-table_name ).

      IF vr-is_valid = abap_false.
        APPEND VALUE lif_dbuf_result_writer=>result_row( row_number = row_idx
                                                         status     = 'E'
                                                         message    = vr-message
                                                         raw_data   = concat_lines_of( table = data_row-cells
                                                                                       sep   = ',' ) )
               TO result.
        row_idx = row_idx + 1.
        CONTINUE.
      ENDIF.

      CREATE DATA lo_row_ref LIKE LINE OF <table>.
      fill_dynamic_row( row_ref  = lo_row_ref
                        cells    = data_row-cells
                        mappings = mappings ).
      INSERT lo_row_ref->* INTO TABLE <table>.

      APPEND VALUE lif_dbuf_result_writer=>result_row( row_number = row_idx
                                                       status     = 'S'
                                                       message    = 'OK'
                                                       raw_data   = concat_lines_of( table = data_row-cells
                                                                                     sep   = ',' ) )
             TO result.
      row_idx = row_idx + 1.
    ENDLOOP.

    committer->commit( table_name = ms_params-table_name
                       table_ref  = table_ref ).
  ENDMETHOD.

  METHOD build_dynamic_table.
    " TODO: parameter MAPPINGS is never used (ABAP cleaner)

    DATA(struct_desc) = CAST cl_abap_structdescr(
                      cl_abap_typedescr=>describe_by_name( ms_params-table_name ) ).
    DATA(table_type) = cl_abap_tabledescr=>create( p_line_type  = struct_desc
                                                   p_table_kind = cl_abap_tabledescr=>tablekind_std
                                                   p_unique     = abap_false ).
    CREATE DATA result TYPE HANDLE table_type.
  ENDMETHOD.

  METHOD fill_dynamic_row.
    FIELD-SYMBOLS <row>   TYPE any.
    FIELD-SYMBOLS <field> TYPE any.

    ASSIGN row_ref->* TO <row>.
    LOOP AT mappings INTO DATA(mapping).
      READ TABLE cells INTO DATA(cell_val) INDEX mapping-position.
      IF sy-subrc = 0.
        ASSIGN COMPONENT mapping-field_name OF STRUCTURE <row> TO <field>.
        IF sy-subrc = 0.
          <field> = cell_val.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_table_validator IMPLEMENTATION.
  METHOD validate.
    IF is_custom_namespace( table_name ) = abap_false.
      RAISE EXCEPTION TYPE lcx_dbuf_validation_error
        EXPORTING text = |Table { table_name } is not in Z* or Y* | ##NO_TEXT.
    ENDIF.

    IF exists_in_ddic( table_name ) = abap_false.
      RAISE EXCEPTION TYPE lcx_dbuf_validation_error
        EXPORTING text = |Table { table_name } not found in DDIC as transparent table| ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD is_custom_namespace.
    DATA(first_char) = table_name(1).
    result = xsdbool( first_char = 'Z' OR first_char = 'Y' ).
  ENDMETHOD.

  METHOD exists_in_ddic.
    SELECT SINGLE tabname FROM dd02l "#EC CI_NOORDER
      INTO @DATA(found)
      WHERE tabname  = @table_name
        AND tabclass = 'TRANSP'
        AND as4local = 'A'.
    result = xsdbool( sy-subrc = 0 AND found IS NOT INITIAL ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_row_validator IMPLEMENTATION.
  METHOD validate_row.
    result-row_index = row_index.
    result-is_valid  = abap_true.

    LOOP AT mappings INTO DATA(mapping).
      READ TABLE cells INTO DATA(cell_value) INDEX mapping-position.
      IF sy-subrc <> 0.
        result-is_valid = abap_false.
        result-message  = |Row { row_index }: Missing value for field { mapping-field_name }| ##NO_TEXT.
        RETURN.
      ENDIF.

      DATA(field_def) = get_field_metadata( table_name = table_name
                                            field_name = mapping-field_name ).

      IF field_def-fieldname IS NOT INITIAL.
        IF check_length( value     = cell_value
                         field_def = field_def ) = abap_false.
          result-is_valid = abap_false.
          result-message  = |Row { row_index }: Value "{ cell_value }" exceeds max length |
                         && |{ field_def-leng } for field { mapping-field_name }| ##NO_TEXT.
          RETURN.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_field_metadata.
    SELECT SINGLE * FROM dd03l "#EC CI_NOORDER
      INTO @result
      WHERE tabname   = @table_name
        AND fieldname = @field_name
        AND as4local  = 'A'. "#EC CI_ALL_FIELDS_NEEDED
  ENDMETHOD.

  METHOD check_length.
    IF field_def-leng = 0.
      result = abap_true.
      RETURN.
    ENDIF.
    result = xsdbool( strlen( value ) <= field_def-leng ).
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_result_xlsx_writer IMPLEMENTATION.
  METHOD lif_dbuf_result_writer~write.
    DATA lo_excel      TYPE REF TO object.
    DATA lo_ws         TYPE REF TO object.
    DATA lo_style_ok   TYPE REF TO zcl_excel_style.
    DATA lv_guid_ok    TYPE zexcel_cell_style.
    DATA lo_style_err  TYPE REF TO zcl_excel_style.
    DATA lv_guid_err   TYPE zexcel_cell_style.
    DATA lo_exporter   TYPE REF TO object.
    DATA lo_class_desc TYPE REF TO cl_abap_classdescr.
    DATA lo_ref_desc   TYPE REF TO cl_abap_refdescr.
    DATA lr_in         TYPE REF TO data.
    DATA lr_out        TYPE REF TO data.
    DATA ls_p          TYPE abap_parmbind.
    DATA lt_ptab       TYPE abap_parmbind_tab.

    TRY.
        CREATE OBJECT lo_excel TYPE ('ZCL_EXCEL').

        CALL METHOD lo_excel->('GET_ACTIVE_WORKSHEET')
          RECEIVING eo_worksheet = lo_ws.

        CALL METHOD lo_ws->('SET_TITLE')
          EXPORTING ip_title = |{ table_name }UploadResult|.

        CALL METHOD lo_ws->('SET_CELL')
          EXPORTING ip_column = 'A'
                    ip_row    = 1
                    ip_value  = 'Row'.
        CALL METHOD lo_ws->('SET_CELL')
          EXPORTING ip_column = 'B'
                    ip_row    = 1
                    ip_value  = 'Status' ##NO_TEXT.
        CALL METHOD lo_ws->('SET_CELL')
          EXPORTING ip_column = 'C'
                    ip_row    = 1
                    ip_value  = 'Message' ##NO_TEXT.
        CALL METHOD lo_ws->('SET_CELL')
          EXPORTING ip_column = 'D'
                    ip_row    = 1
                    ip_value  = 'Raw Data' ##NO_TEXT.

        CREATE OBJECT lo_style_ok.
        lv_guid_ok = lo_style_ok->get_guid( ).

        CREATE OBJECT lo_style_err.
        lv_guid_err = lo_style_err->get_guid( ).

        LOOP AT rows INTO DATA(row).
          DATA(r) = sy-tabix + 1.

          CALL METHOD lo_ws->('SET_CELL')
            EXPORTING ip_column = 'A'
                      ip_row    = r
                      ip_value  = row-row_number.

          CALL METHOD lo_ws->('SET_CELL')
            EXPORTING ip_column = 'B'
                      ip_row    = r
                      ip_value  = row-status.

          CALL METHOD lo_ws->('SET_CELL')
            EXPORTING ip_column = 'C'
                      ip_row    = r
                      ip_value  = row-message.

          CALL METHOD lo_ws->('SET_CELL')
            EXPORTING ip_column = 'D'
                      ip_row    = r
                      ip_value  = row-raw_data.

          CALL METHOD lo_ws->('SET_CELL_STYLE')
            EXPORTING ip_column = 'B'
                      ip_row    = r
                      ip_style  = COND zexcel_cell_style(
                                     WHEN row-status = 'S'
                                     THEN lv_guid_ok
                                     ELSE lv_guid_err ).
        ENDLOOP.

        CREATE OBJECT lo_exporter TYPE ('ZCL_EXCEL_WRITER_2007').

        lo_class_desc ?= cl_abap_typedescr=>describe_by_name( 'ZCL_EXCEL' ).
        lo_ref_desc    = cl_abap_refdescr=>get( lo_class_desc ).
        CREATE DATA lr_in TYPE HANDLE lo_ref_desc.
        ASSIGN lr_in->* TO FIELD-SYMBOL(<in>).
        <in> ?= lo_excel.

        CREATE DATA lr_out TYPE xstring.

        ls_p-name  = 'IO_EXCEL'.
        ls_p-kind  = cl_abap_objectdescr=>exporting.
        ls_p-value = lr_in.
        INSERT ls_p INTO TABLE lt_ptab.

        CLEAR ls_p.
        ls_p-name  = 'EP_FILE'.
        ls_p-kind  = cl_abap_objectdescr=>receiving.
        ls_p-value = lr_out.
        INSERT ls_p INTO TABLE lt_ptab.

        CALL METHOD lo_exporter->('ZIF_EXCEL_WRITER~WRITE_FILE')
          PARAMETER-TABLE lt_ptab.

        ASSIGN lr_out->* TO FIELD-SYMBOL(<out>).
        result = <out>.

      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION TYPE lcx_dbuf_file_error
          EXPORTING text     = |XLSX write failed: { exc->if_message~get_text( ) }| ##NO_TEXT
                    previous = exc.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_result_csv_writer IMPLEMENTATION.
  METHOD lif_dbuf_result_writer~write.
    DATA(nl) = cl_abap_char_utilities=>newline.
    DATA(output) = |Row#,Status,Message,Raw Data{ nl }| ##NO_TEXT.

    LOOP AT rows INTO DATA(row).
      DATA(msg) = replace( val  = row-message
                           sub  = ','
                           with = ';' ).
      DATA(data) = replace( val  = row-raw_data
                            sub  = ','
                            with = ';' ).
      output = output && |{ row-row_number },{ row-status },{ msg },{ data }{ nl }|.
    ENDLOOP.

    TRY.
        result = cl_abap_codepage=>convert_to( source = output ).
      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION TYPE lcx_dbuf_file_error
          EXPORTING text     = |CSV encode failed: { exc->if_message~get_text( ) }| ##NO_TEXT
                    previous = exc.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_reader_factory IMPLEMENTATION.
  METHOD create_for_extension.
    DATA(xlsx_ext) = COND abap_bool(
      WHEN to_upper( extension ) = ext_xlsx
        OR to_upper( extension ) = ext_xlsm
        OR to_upper( extension ) = ext_xlshuge
      THEN abap_true
      ELSE abap_false ).

    IF xlsx_ext = abap_true AND abap2xlsx_available( ) = abap_false.
      RAISE EXCEPTION TYPE lcx_dbuf_file_error
        EXPORTING text = |XLSX/XLSM support requires abap2xlsx. | ##NO_TEXT
                         && |See: https://github.com/abap2xlsx/abap2xlsx|.
    ENDIF.

    CASE to_upper( extension ).
      WHEN ext_xlsx.
        result = NEW lcl_dbuf_xlsx_reader( ).
      WHEN ext_xlsm.
        result = NEW lcl_dbuf_xlsm_reader( ).
      WHEN ext_xlshuge.
        result = NEW lcl_dbuf_huge_xlsx_reader( ).
      WHEN OTHERS.
        DATA(dsv) = NEW lcl_dbuf_dsv_reader( ).
        DATA(sep) = COND char1(
          WHEN separator IS SUPPLIED AND separator <> space
          THEN separator
          ELSE separator_for_extension( extension ) ).
        dsv->set_separator( sep ).
        result = dsv.
    ENDCASE.
  ENDMETHOD.

  METHOD separator_for_extension.
    CASE to_upper( extension ).
      WHEN ext_tsv. result = cl_abap_char_utilities=>horizontal_tab.
      WHEN ext_psv. result = '|'.
      WHEN OTHERS. result = ','.
    ENDCASE.
  ENDMETHOD.

  METHOD abap2xlsx_available.
    TRY.
        cl_abap_typedescr=>describe_by_name( 'ZCL_EXCEL' ).
        result = abap_true.
      CATCH " cx_sy_type_creation_error
            cx_root.
        result = abap_false.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_null_committer IMPLEMENTATION.
  METHOD lif_dbuf_db_committer~commit.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    ASSIGN table_ref->* TO <table>.
    DATA(row_count) = COND i( WHEN <table> IS ASSIGNED THEN lines( <table> ) ELSE 0 ).
    result-rows_committed = 0.
    result-rows_failed    = 0.
    result-message        = |TEST MODE: { row_count } row(s) validated; no DB write performed| ##NO_TEXT.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_live_committer IMPLEMENTATION.
  METHOD lif_dbuf_db_committer~commit.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    ASSIGN table_ref->* TO <table>.
    IF <table> IS NOT ASSIGNED OR <table> IS INITIAL.
      result-message = 'No data to commit' ##NO_TEXT.
      RETURN.
    ENDIF.
    TRY.
        MODIFY (table_name) CLIENT SPECIFIED FROM TABLE <table>. "#EC CI_DYNTAB
        IF sy-subrc = 0.
          COMMIT WORK.
          result-rows_committed = lines( <table> ).
          result-message        = |{ result-rows_committed } row(s) committed to { table_name }| ##NO_TEXT.
        ELSE.
          ROLLBACK WORK. "#EC CI_ROLLBACK
          result-rows_failed = lines( <table> ).
          result-message     = |MODIFY { table_name } failed. SY-SUBRC = { sy-subrc }| ##NO_TEXT.
          RAISE EXCEPTION TYPE lcx_dbuf_validation_error
            EXPORTING text = result-message.
        ENDIF.
      CATCH cx_sy_open_sql_db INTO DATA(exc).
        ROLLBACK WORK. "#EC CI_ROLLBACK
        result-rows_failed = lines( <table> ).
        result-message     = exc->if_message~get_text( ).
        RAISE EXCEPTION TYPE lcx_dbuf_validation_error
          EXPORTING text     = result-message
                    previous = exc.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_file_handler IMPLEMENTATION.
  METHOD upload_to_xstring.
    "--- FRONTEND path: SAPGUI file upload ---

    DATA lv_file_length TYPE i.
    DATA lt_binary_tab  TYPE solix_tab.

    IF lcl_dbuf_env=>gui_available( ) = abap_true.

      cl_gui_frontend_services=>gui_upload( EXPORTING  filename                = file_path
                                                       filetype                = 'BIN'
                                            IMPORTING  filelength              = lv_file_length
                                            CHANGING   data_tab                = lt_binary_tab
                                            EXCEPTIONS file_open_error         = 1
                                                       file_read_error         = 2
                                                       no_batch                = 3
                                                       gui_refuse_filetransfer = 4
                                                       OTHERS                  = 5 ).

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE lcx_dbuf_file_error
          EXPORTING text = |Cannot open file: { file_path } (SY-SUBRC={ sy-subrc })| ##NO_TEXT.
      ENDIF.

      CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
        EXPORTING  input_length = lv_file_length
        IMPORTING  buffer       = result
        TABLES     binary_tab   = lt_binary_tab
        EXCEPTIONS OTHERS       = 1.

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE lcx_dbuf_file_error
          EXPORTING text = |Binary conversion failed for: { file_path }| ##NO_TEXT.
      ENDIF.

    ELSE.

      "--- SERVER path: application server file (AL11 / Linux) ---
      OPEN DATASET file_path FOR INPUT IN BINARY MODE.
      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE lcx_dbuf_file_error
          EXPORTING text = |Cannot open server file: { file_path } (SY-SUBRC={ sy-subrc })| ##NO_TEXT.
      ENDIF.

      READ DATASET file_path INTO result.
      DATA(lv_read_rc) = sy-subrc.
      CLOSE DATASET file_path.

      IF lv_read_rc <> 0.
        RAISE EXCEPTION TYPE lcx_dbuf_file_error
          EXPORTING text = |Failed reading server file: { file_path } (SY-SUBRC={ lv_read_rc })| ##NO_TEXT.
      ENDIF.

    ENDIF.
  ENDMETHOD.

  METHOD get_file_path_via_f4.
    DATA lt_file_table TYPE filetable.
    DATA lv_rc         TYPE i.

    IF lcl_dbuf_env=>gui_available( ) = abap_true.
      cl_gui_frontend_services=>file_open_dialog(
        EXPORTING
          window_title      = 'Select upload file' ##NO_TEXT
          default_extension = '*.xlsx'
          file_filter       = 'Upload Files (*.csv;*.tsv;*.psv;*.txt;*.xlsx;*.xlsm)|*.csv;*.tsv;*.psv;*.txt;*.xlsx;*.xlsm|All Files (*.*)|*.*' ##NO_TEXT
        CHANGING
          file_table        = lt_file_table
          rc                = lv_rc
        EXCEPTIONS
          OTHERS            = 1 ).

      IF sy-subrc = 0 AND lines( lt_file_table ) > 0.
        file_path = lt_file_table[ 1 ]-filename.
      ENDIF.
    ELSE.
      " No GUI: user must type path directly into the selection screen parameter.
      " F4 help is not available in background / no-GUI context.
      MESSAGE 'F4 file browse not available without SAPGUI. Enter path manually.' TYPE 'I' ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD f4_server_file.
    DATA lv_dir    TYPE dxfields-longpath.
    DATA lv_result TYPE dxfields-longpath.

    " Use directory of current value as starting path if available,
    " otherwise fall back to start_dir parameter
    IF file_path IS NOT INITIAL.
      lv_dir = substring_before( val = file_path
                                 sub = '/'
                                 occ = -1 ).
      IF lv_dir IS INITIAL.
        lv_dir = start_dir.
      ENDIF.
    ELSE.
      lv_dir = start_dir.
    ENDIF.

    CALL FUNCTION 'F4_DXFILENAME_TOPRECURSION'
      EXPORTING  i_location_flag = 'A'    " 'A' = application server
                 i_server        = ' '
                 i_path          = lv_dir
                 filemask        = '*.*'
                 fileoperation   = operation
      IMPORTING  o_path          = lv_result
      EXCEPTIONS rfc_error       = 1
                 OTHERS          = 2.

    IF sy-subrc = 0 AND lv_result IS NOT INITIAL.
      file_path = lv_result.
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_dsv_reader IMPLEMENTATION.
  METHOD set_separator.
    me->separator = separator.
  ENDMETHOD.

  METHOD lif_dbuf_file_reader~read.
    DATA(raw_string) = xstring_to_string( file_content ).
    DATA(clean)      = strip_bom( raw_string ).

    DATA(lines) = VALUE string_table( ).
    SPLIT clean AT cl_abap_char_utilities=>newline INTO TABLE lines.

    DATA(sheet) = VALUE lif_dbuf_file_reader=>sheet( name = 'Sheet1' ) ##NO_TEXT.

    LOOP AT lines INTO DATA(line).
      line = replace( val  = line
                      sub  = cl_abap_char_utilities=>cr_lf
                      with = '' ).
      line = replace( val  = line
                      sub  = cl_abap_char_utilities=>newline
                      with = '' ).
      IF line IS INITIAL. CONTINUE. ENDIF.

      DATA(row) = VALUE lif_dbuf_file_reader=>row( cells = tokenize_line( line ) ).
      APPEND row TO sheet-rows.
    ENDLOOP.

    APPEND sheet TO result.
  ENDMETHOD.

  METHOD xstring_to_string.
    DATA(bom_hex) = cl_abap_char_utilities=>byte_order_mark_utf8.
    DATA(bom_len) = xstrlen( bom_hex ).
    DATA(data_to_convert) = xdata.
    IF xstrlen( xdata ) > bom_len AND xdata(bom_len) = bom_hex.
      data_to_convert = xdata+bom_len.
    ENDIF.
    DATA(conv) = cl_abap_conv_in_ce=>create( input       = data_to_convert
                                             encoding    = 'UTF-8'
                                             ignore_cerr = abap_true ).
    conv->read( IMPORTING data = result ).
  ENDMETHOD.

  METHOD strip_bom.
    " BOM already stripped in xstring_to_string — passthrough only
    result = raw.
  ENDMETHOD.

  METHOD tokenize_line.
    DATA in_quotes TYPE abap_bool VALUE abap_false.
    DATA current   TYPE string.

    DATA(len) = strlen( line ).
    DATA(idx) = 0.
    WHILE idx < len.
      DATA(ch) = substring( val = line
                            off = idx
                            len = 1 ).
      IF ch = '"'.
        IF in_quotes = abap_false.
          in_quotes = abap_true.
        ELSE.
          in_quotes = abap_false.
        ENDIF.
      ELSEIF ch = separator AND in_quotes = abap_false.
        APPEND current TO result.
        CLEAR current.
      ELSE.
        current = current && ch.
      ENDIF.
      idx = idx + 1.
    ENDWHILE.

    " Append last token (no trailing separator needed)
    APPEND current TO result.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_committer_factory IMPLEMENTATION.
  METHOD create.
    IF test_mode = abap_true.
      result = NEW lcl_dbuf_null_committer( ).
    ELSE.
      result = NEW lcl_dbuf_live_committer( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_column_mapper IMPLEMENTATION.
  METHOD map_headers.
    IF header_row IS INITIAL.
      RAISE EXCEPTION TYPE lcx_dbuf_mapping_error
        EXPORTING text = |Header row is empty for table { table_name }| ##NO_TEXT.
    ENDIF.

    DATA(ddic_fields) = get_ddic_fields( table_name ).

    LOOP AT header_row INTO DATA(token).
      DATA(position)    = sy-tabix.
      DATA(upper_token) = to_upper( condense( token ) ).
      " TODO: variable is assigned but never used (ABAP cleaner)
      READ TABLE ddic_fields INTO DATA(field_row) WITH KEY ('TABNAME') = upper_token.
      IF sy-subrc = 0.
        APPEND VALUE column_mapping( header_token = token
                                     field_name   = upper_token
                                     position     = position ) TO result.
      ENDIF.
    ENDLOOP.

    IF result IS INITIAL.
      RAISE EXCEPTION TYPE lcx_dbuf_mapping_error
        EXPORTING text = |No header tokens matched DDIC fields of { table_name }. Check column names.| ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD get_ddic_fields.
    SELECT fieldname FROM dd03l
      INTO TABLE @result
      WHERE tabname          = @table_name
        AND as4local         = 'A'
        AND fieldname NOT LIKE '.%'.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_auth_checker IMPLEMENTATION.
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

    RAISE EXCEPTION TYPE lcx_dbuf_auth_error
      EXPORTING text = |Not authorized to change table { table_name }| ##NO_TEXT.
  ENDMETHOD.

  METHOD f4_table.
    TYPES: BEGIN OF ty_table_row,
             tabname TYPE dd02l-tabname,
             ddtext  TYPE dd02t-ddtext,
           END OF ty_table_row.

    DATA lt_tables     TYPE STANDARD TABLE OF ty_table_row WITH DEFAULT KEY.
    DATA lt_authorized TYPE STANDARD TABLE OF ty_table_row WITH DEFAULT KEY.
    DATA lt_return     TYPE TABLE OF ddshretval.

    " Fetch all Z/Y transparent tables with their short texts
    SELECT t~tabname,
           d~ddtext
      FROM dd02l AS t
             LEFT OUTER JOIN
               dd02t AS d ON  d~tabname    = t~tabname
                          AND d~ddlanguage = @sy-langu
                          AND d~as4local   = 'A'
      INTO TABLE @lt_tables
      WHERE t~tabclass    = 'TRANSP'
        AND t~as4local    = 'A'
        AND t~tabname  LIKE @search_pattern  " e.g. 'ZSD%', 'Y%', 'Z%'
      ORDER BY t~tabname.

    " Filter to only tables the user is authorized for
    DATA(lo_checker) = NEW lcl_dbuf_auth_checker( ).
    LOOP AT lt_tables INTO DATA(ls_table).
      TRY.
          lo_checker->check( ls_table-tabname ).
          APPEND ls_table TO lt_authorized.
        CATCH lcx_dbuf_auth_error.
          " Skip unauthorized tables silently
      ENDTRY.
    ENDLOOP.

    IF lt_authorized IS INITIAL.
      MESSAGE 'No authorized Z/Y tables found for your user.' TYPE 'I' ##NO_TEXT.
      RETURN.
    ENDIF.

    " Present F4 popup using F4IF_INT_TABLE_VALUE_REQUEST
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING  retfield        = 'TABNAME'
                 dynpprog        = sy-repid
                 dynpnr          = sy-dynnr
                 dynprofield     = 'P_TABLE'
                 value_org       = 'S'
                 multiple_choice = ' '
                 display         = ' '
      TABLES     value_tab       = lt_authorized
                 return_tab      = lt_return
      EXCEPTIONS parameter_error = 1
                 no_values_found = 2
                 OTHERS          = 3.

    IF sy-subrc = 0 AND lines( lt_return ) > 0.
      table_name = lt_return[ 1 ]-fieldval.
    ENDIF.
  ENDMETHOD.

  METHOD get_auth_group.
    SELECT SINGLE cclass FROM tddat
      INTO @result
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


CLASS lcl_dbuf_template_builder IMPLEMENTATION.
  METHOD build_csv.
    DATA lt_fields  TYPE STANDARD TABLE OF dd03l WITH DEFAULT KEY.
    DATA lt_headers TYPE string_table.

    SELECT * FROM dd03l
      INTO TABLE @lt_fields
      WHERE tabname          = @table_name
        AND as4local         = 'A'
        AND fieldname NOT LIKE '.%'
      ORDER BY position.

    IF lt_fields IS INITIAL.
      RAISE EXCEPTION TYPE lcx_dbuf_validation_error
        EXPORTING text = |No fields found in DDIC for table { table_name }| ##NO_TEXT.
    ENDIF.

    LOOP AT lt_fields INTO DATA(ls_field).
      APPEND ls_field-fieldname TO lt_headers.
    ENDLOOP.

    result = concat_lines_of( table = lt_headers
                              sep   = ',' ).
  ENDMETHOD.

  METHOD download.
    DATA lv_filename TYPE string.
    DATA lv_xstring  TYPE xstring.
    DATA lv_length   TYPE i.
    DATA lt_binary   TYPE solix_tab.
    DATA lv_path     TYPE string.
    DATA lv_fullpath TYPE string.

    lv_filename = |{ table_name }_template.csv|.

    " Convert string to xstring (UTF-8)
    TRY.
        lv_xstring = cl_abap_codepage=>convert_to( source   = content
                                                   codepage = 'UTF-8' ).
      CATCH cx_root INTO DATA(conv_exc).
        RAISE EXCEPTION TYPE lcx_dbuf_file_error
          EXPORTING text     = |Template encoding failed: { conv_exc->if_message~get_text( ) }| ##NO_TEXT
                    previous = conv_exc.
    ENDTRY.

    " Convert xstring to binary table
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING buffer        = lv_xstring
      IMPORTING output_length = lv_length
      TABLES    binary_tab    = lt_binary.

    " Prompt user for save location and download
    cl_gui_frontend_services=>file_save_dialog(
      EXPORTING
        window_title      = 'Save Template' ##NO_TEXT
        default_file_name = lv_filename
        default_extension = 'csv'
        file_filter       = 'Save Template (*.csv;*.tsv;*.psv;*.txt;)|*.csv;*.tsv;*.psv;*.txt;|All Files (*.*)|*.*' ##NO_TEXT
      CHANGING
        filename          = lv_filename
        path              = lv_path
        fullpath          = lv_fullpath
      EXCEPTIONS
        cntl_error        = 1
        error_no_gui      = 2
        OTHERS            = 3 ).
    IF sy-subrc <> 0 OR lv_fullpath IS INITIAL.
      RETURN.  " User cancelled — not an error
    ENDIF.
    IF sy-subrc <> 0 OR lv_filename IS INITIAL.
      RETURN.  " User cancelled — not an error
    ENDIF.

    cl_gui_frontend_services=>gui_download( EXPORTING  filename                = lv_fullpath
                                                       filetype                = 'BIN'
                                                       bin_filesize            = lv_length
                                            CHANGING   data_tab                = lt_binary
                                            EXCEPTIONS file_write_error        = 1
                                                       filesize_not_allowed    = 2
                                                       invalid_type            = 3
                                                       no_batch                = 4
                                                       gui_refuse_filetransfer = 5
                                                       OTHERS                  = 6 ).

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_dbuf_file_error
        EXPORTING text = |Template download failed for: { lv_filename } (SY-SUBRC={ sy-subrc })| ##NO_TEXT.
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_env IMPLEMENTATION.
  METHOD gui_available.
    DATA lt_version TYPE filetable.
    DATA lv_rc      TYPE i.

    result = abap_false.
    TRY.
        cl_gui_frontend_services=>get_gui_version( CHANGING   version_table            = lt_version
                                                              rc                       = lv_rc
                                                   EXCEPTIONS get_gui_version_failed   = 1
                                                              cant_write_version_table = 2
                                                              gui_no_version           = 3
                                                              cntl_error               = 4
                                                              error_no_gui             = 5
                                                              not_supported_by_gui     = 6
                                                              OTHERS                   = 7 ).
        IF sy-subrc = 0.
          result = abap_true.
        ENDIF.
      CATCH cx_root.
        result = abap_false.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_download DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS run
      IMPORTING iv_mode     TYPE string
                iv_xstring  TYPE xstring
                iv_ext      TYPE string
                iv_table    TYPE tabname
                iv_srv_path TYPE string OPTIONAL
                iv_fpath    TYPE string OPTIONAL.

  PRIVATE SECTION.
    CLASS-METHODS to_binary
      IMPORTING iv_xstring TYPE xstring
      EXPORTING et_binary  TYPE solix_tab
                ev_length  TYPE i.

    CLASS-METHODS frontend
      IMPORTING iv_xstring TYPE xstring
                iv_ext     TYPE string
                iv_table   TYPE tabname
                iv_fpath   TYPE string OPTIONAL.

    CLASS-METHODS backend
      IMPORTING iv_xstring  TYPE xstring
                iv_ext      TYPE string
                iv_table    TYPE tabname
                iv_srv_path TYPE string OPTIONAL.
ENDCLASS.


CLASS lcl_dbuf_download IMPLEMENTATION.
  METHOD run.
    CASE iv_mode.
      WHEN 'FRONT'. frontend( iv_xstring = iv_xstring
                              iv_ext     = iv_ext
                              iv_table   = iv_table
                              iv_fpath   = iv_fpath ).
      WHEN 'BACK'. backend( iv_xstring  = iv_xstring
                            iv_ext      = iv_ext
                            iv_table    = iv_table
                            iv_srv_path = iv_srv_path ).
      WHEN OTHERS. RETURN.
    ENDCASE.
  ENDMETHOD.

  METHOD to_binary.
    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
      EXPORTING buffer        = iv_xstring
      IMPORTING output_length = ev_length
      TABLES    binary_tab    = et_binary.
  ENDMETHOD.

  METHOD frontend.
    DATA lv_fullpath TYPE string.
    DATA lv_filename TYPE string.
    DATA lv_path     TYPE string.
    DATA lt_binary   TYPE solix_tab.
    DATA lv_binlen   TYPE i.

    " If caller already provided a full path — skip dialog entirely
    IF iv_fpath IS NOT INITIAL AND iv_fpath CA '\' OR iv_fpath CA '/'.
      lv_fullpath = iv_fpath.
    ELSE.
      lv_filename = COND #( WHEN iv_fpath IS NOT INITIAL
                            THEN iv_fpath
                            ELSE |{ iv_table }_upload_result.{ iv_ext }| ).

      cl_gui_frontend_services=>file_save_dialog(
        EXPORTING  window_title      = 'Save Upload Result' ##NO_TEXT
                   default_file_name = lv_filename
                   default_extension = iv_ext
                   file_filter       = '*.xlsx;*.csv|Result Files|*.*|All Files' ##NO_TEXT
        CHANGING   filename          = lv_filename
                   path              = lv_path
                   fullpath          = lv_fullpath
        EXCEPTIONS cntl_error        = 1
                   error_no_gui      = 2
                   OTHERS            = 3 ).

      IF sy-subrc <> 0 OR lv_fullpath IS INITIAL.
        MESSAGE 'File save dialog cancelled — ALV result shown below.' TYPE 'I' ##NO_TEXT.
        RETURN.
      ENDIF.
    ENDIF.

    to_binary( EXPORTING iv_xstring = iv_xstring
               IMPORTING et_binary  = lt_binary
                         ev_length  = lv_binlen ).

    cl_gui_frontend_services=>gui_download( EXPORTING  filename                = lv_fullpath
                                                       filetype                = 'BIN'
                                                       bin_filesize            = lv_binlen
                                            CHANGING   data_tab                = lt_binary
                                            EXCEPTIONS file_write_error        = 1
                                                       gui_refuse_filetransfer = 2
                                                       OTHERS                  = 3 ).

    IF sy-subrc = 0.
      MESSAGE |Result saved to: { lv_fullpath }| TYPE 'I' ##NO_TEXT.
    ELSE.
      MESSAGE |Download failed (SY-SUBRC={ sy-subrc })| TYPE 'W' ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD backend.
    " Only append extension if p_srv has no extension already
    DATA(lv_has_ext) = xsdbool( iv_srv_path CA '.' ).
    DATA(lv_path) = COND string(
      WHEN iv_srv_path IS NOT INITIAL AND lv_has_ext = abap_true THEN iv_srv_path                              " user already typed extension
      WHEN iv_srv_path IS NOT INITIAL                            THEN |{ iv_srv_path }.{ iv_ext }|             " append derived extension
      ELSE                                                            |/tmp/{ iv_table }_upload_result.{ iv_ext }| ).

    OPEN DATASET lv_path FOR OUTPUT IN BINARY MODE.
    IF sy-subrc <> 0.
      MESSAGE |Cannot open server path: { lv_path }| TYPE 'W' ##NO_TEXT.
      RETURN.
    ENDIF.
    TRANSFER iv_xstring TO lv_path.
    CLOSE DATASET lv_path.
    MESSAGE |Result written to: { lv_path }| TYPE 'I' ##NO_TEXT.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dbuf_alv DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS display
      IMPORTING it_rows  TYPE lif_dbuf_result_writer=>result_rows
                iv_table TYPE tabname
                iv_test  TYPE abap_bool.
ENDCLASS.


CLASS lcl_dbuf_alv IMPLEMENTATION.
  METHOD display.
    TYPES: BEGIN OF ty_alv_row,
             row_number TYPE i,
             status     TYPE c LENGTH 1,
             message    TYPE string,
             raw_data   TYPE string,
             celltab    TYPE lvc_t_scol,
           END OF ty_alv_row.

    DATA lt_alv TYPE STANDARD TABLE OF ty_alv_row WITH DEFAULT KEY.

    LOOP AT it_rows INTO DATA(ls_row).
      DATA(ls_alv) = VALUE ty_alv_row( row_number = ls_row-row_number
                                       status     = ls_row-status
                                       message    = ls_row-message
                                       raw_data   = ls_row-raw_data ).

      APPEND VALUE lvc_s_scol( fname = 'STATUS'
                               color = VALUE lvc_s_colo( col = COND i( WHEN ls_row-status = 'S' THEN 5 ELSE 6 )
                                                         int = 0
                                                         inv = 0 ) ) TO ls_alv-celltab.

      APPEND ls_alv TO lt_alv.
    ENDLOOP.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_alv)
                                CHANGING  t_table      = lt_alv ).

        DATA(lo_cols) = lo_alv->get_columns( ).
        lo_cols->set_color_column( 'CELLTAB' ).
        lo_cols->set_optimize( abap_true ).

        TRY.
            CAST cl_salv_column_table( lo_cols->get_column( 'ROW_NUMBER' ) )->set_long_text( 'Row #' ) ##NO_TEXT.
            CAST cl_salv_column_table( lo_cols->get_column( 'STATUS' ) )->set_long_text( 'Status' ) ##NO_TEXT.
            CAST cl_salv_column_table( lo_cols->get_column( 'MESSAGE' ) )->set_long_text( 'Message' ) ##NO_TEXT.
            CAST cl_salv_column_table( lo_cols->get_column( 'RAW_DATA' ) )->set_long_text( 'Raw Data' ) ##NO_TEXT.
            CAST cl_salv_column_table( lo_cols->get_column( 'CELLTAB' ) )->set_visible( abap_false ).
          CATCH cx_salv_not_found
                cx_salv_data_error.
        ENDTRY.

        lo_alv->get_display_settings( )->set_list_header(
            |{ iv_table } Upload Result — | ##NO_TEXT
            && COND string( WHEN iv_test = abap_true THEN 'TEST MODE' ELSE 'LIVE' ) ).

        lo_alv->get_functions( )->set_all( abap_true ).
        lo_alv->display( ).

      CATCH cx_salv_msg INTO DATA(lo_exc).
        MESSAGE |ALV display error: { lo_exc->if_message~get_text( ) }| TYPE 'W' ##NO_TEXT.
      CATCH cx_salv_data_error INTO DATA(lo_data_exc).
        MESSAGE |ALV data error: { lo_data_exc->if_message~get_text( ) }| TYPE 'W' ##NO_TEXT.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

"----------------------------------------------------------------------
" Selection Screen
"----------------------------------------------------------------------
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:
    p_file  TYPE string LOWER CASE MODIF ID fro,  " group1 = 'F'
    p_sfile TYPE string LOWER CASE MODIF ID bck,  " group1 = 'B'
    p_table TYPE tabname OBLIGATORY DEFAULT 'Z*',
    p_sep   TYPE c DEFAULT ',' MODIF ID sep,
    p_hdr   TYPE abap_bool AS CHECKBOX DEFAULT 'X',
    p_test  TYPE abap_bool AS CHECKBOX DEFAULT ' '.
  SELECTION-SCREEN COMMENT /1(72) TEXT-002.
  SELECTION-SCREEN COMMENT /1(72) TEXT-003.
  SELECTION-SCREEN PUSHBUTTON /1(40) btn_tmpl USER-COMMAND tmpl_dl.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t02.
  PARAMETERS:
    p_front RADIOBUTTON GROUP rmod DEFAULT 'X' USER-COMMAND umod,
    p_back  RADIOBUTTON GROUP rmod,
    p_nodl  RADIOBUTTON GROUP rmod.
  " Frontend result save path (pre-fill for save dialog) — frontend mode only
  PARAMETERS p_fpath TYPE string LOWER CASE MODIF ID frs.
  PARAMETERS p_srv   TYPE string LOWER CASE MODIF ID bck
                     DEFAULT '/tmp/dbuf_result'.
SELECTION-SCREEN END OF BLOCK b2.

INITIALIZATION.
  btn_tmpl = 'Download CSV Template' ##NO_TEXT.

AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'TMPL_DL'.
      IF p_table IS INITIAL.
        MESSAGE 'Please enter a table name first.' TYPE 'I' ##NO_TEXT.
        RETURN.
      ENDIF.

      TRY.
          NEW lcl_dbuf_table_validator( )->validate( p_table ).
        CATCH lcx_dbuf_validation_error INTO DATA(val_exc).
          MESSAGE val_exc->mv_text TYPE 'I'.
          RETURN.
      ENDTRY.

      TRY.
          DATA(lv_tmpl_csv) = lcl_dbuf_template_builder=>build_csv( p_table ).
          lcl_dbuf_template_builder=>download( table_name = p_table
                                               content    = lv_tmpl_csv ).
        CATCH lcx_dbuf_error INTO DATA(tmpl_exc).
          MESSAGE tmpl_exc->mv_text TYPE 'E'.
      ENDTRY.
  ENDCASE.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  NEW lcl_dbuf_file_handler( )->get_file_path_via_f4( CHANGING file_path = p_file ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_fpath.
  " Frontend save path: use frontend save dialog as the F4 picker itself

  DATA lv_fn TYPE string.
  DATA lv_pt TYPE string.
  DATA lv_fp TYPE string.

  lv_fn = p_fpath.

  cl_gui_frontend_services=>file_save_dialog( EXPORTING  window_title      = 'Select Result Save Location' ##NO_TEXT
                                                         default_file_name = lv_fn
                                                         default_extension = 'xlsx'
                                                         file_filter       = '*.xlsx;*.csv|Result Files|*.*|All Files'
                                              CHANGING   filename          = lv_fn
                                                         path              = lv_pt
                                                         fullpath          = lv_fp
                                              EXCEPTIONS cntl_error        = 1
                                                         error_no_gui      = 2
                                                         OTHERS            = 3 ).

  IF sy-subrc = 0 AND lv_fp IS NOT INITIAL.
    p_fpath = lv_fp.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sfile.
  lcl_dbuf_file_handler=>f4_server_file( EXPORTING operation = 'R'
                                         CHANGING  file_path = p_sfile ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_srv.
  lcl_dbuf_file_handler=>f4_server_file( EXPORTING operation = 'W'
                                         CHANGING  file_path = p_srv ).

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_table.
  DATA lt_dynp TYPE TABLE OF dynpread.

  APPEND VALUE #( fieldname = 'P_TABLE' ) TO lt_dynp.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING  dyname               = sy-repid
               dynumb               = sy-dynnr
    TABLES     dynpfields           = lt_dynp
    EXCEPTIONS invalid_abapworkarea = 1
               invalid_dynprofield  = 2
               invalid_dynproname   = 3
               invalid_dynpronummer = 4
               invalid_request      = 5
               no_fielddescription  = 6
               invalid_parameter    = 7
               undefind_error       = 8
               double_conversion    = 9
               stepl_not_found      = 10
               OTHERS               = 11.

  DATA(lv_typed) = condense( lt_dynp[ 1 ]-fieldvalue ).

  DATA(lv_pattern) = COND tabname(
    WHEN sy-subrc <> 0 OR lv_typed IS INITIAL
    THEN 'Z%'
    ELSE replace( val  = to_upper( lv_typed )
                  sub  = '*'
                  with = '%'
                  occ  = 0 ) ).

  IF lv_pattern NA '%_'.
    lv_pattern = lv_pattern && '%'.
  ENDIF.

  lcl_dbuf_auth_checker=>f4_table( EXPORTING search_pattern = lv_pattern
                                   CHANGING  table_name     = p_table ).


AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN INTO DATA(scr).
    CASE scr-group1.

      WHEN 'SEP'.
        DATA(lv_active_path) = COND string(
          WHEN p_back = 'X'
          THEN p_sfile
          ELSE p_file ).
        DATA(lv_ext) = COND string(
          WHEN lv_active_path IS NOT INITIAL
          THEN to_upper( substring_after( val = lv_active_path
                                          sub = '.'
                                          occ = -1 ) )
          ELSE '' ).
        scr-active = COND #(
          WHEN lv_ext = 'XLSX' OR lv_ext = 'XLSM' OR lv_ext = 'XLSHUGE'
          THEN '0'
          ELSE '1' ).
        MODIFY SCREEN FROM scr.

      WHEN 'FRO'.
        " p_file: visible for frontend download AND ALV-only
        scr-active = COND #( WHEN p_back = 'X' THEN '0' ELSE '1' ).
        scr-input  = scr-active.
        MODIFY SCREEN FROM scr.

      WHEN 'FRS'.
        " p_fpath: visible for frontend download only (not ALV-only, no download needed)
        scr-active = COND #( WHEN p_front = 'X' THEN '1' ELSE '0' ).
        scr-input  = scr-active.
        MODIFY SCREEN FROM scr.

      WHEN 'BCK'.
        " p_sfile + p_srv: visible for backend only
        scr-active = COND #( WHEN p_back = 'X' THEN '1' ELSE '0' ).
        scr-input  = scr-active.
        MODIFY SCREEN FROM scr.

    ENDCASE.
  ENDLOOP.

  "----------------------------------------------------------------------
  " Start of Selection
  "----------------------------------------------------------------------
START-OF-SELECTION.
  DATA(lv_upload_path) = COND string(
    WHEN p_back = 'X'
    THEN p_sfile
    ELSE p_file ).

  IF lv_upload_path IS INITIAL.
    MESSAGE 'Please enter an upload file path.' TYPE 'S' DISPLAY LIKE 'E' ##NO_TEXT.
    LEAVE LIST-PROCESSING.
  ENDIF.

  TRY.
      DATA(processor) = NEW lcl_dbuf_upload_processor( VALUE #( file_path  = lv_upload_path
                                                                table_name = p_table
                                                                separator  = p_sep
                                                                has_header = p_hdr
                                                                test_mode  = p_test ) ).

      DATA(result_xstring) = processor->execute( ).
      DATA(out_ext)        = to_lower( processor->get_out_format( ) ).

      lcl_dbuf_download=>run( iv_mode     = COND #( WHEN p_front = 'X' THEN 'FRONT'
                                                    WHEN p_back = 'X'  THEN 'BACK'
                                                    ELSE                    'NONE' )
                              iv_xstring  = result_xstring
                              iv_ext      = out_ext
                              iv_table    = p_table
                              iv_srv_path = p_srv
                              iv_fpath    = p_fpath ).

      lcl_dbuf_alv=>display( it_rows  = processor->get_result_rows( )
                             iv_table = p_table
                             iv_test  = p_test ).

    CATCH lcx_dbuf_auth_error INTO DATA(auth_exc).
      MESSAGE auth_exc->mv_text TYPE 'S' DISPLAY LIKE 'E'. LEAVE LIST-PROCESSING.
    CATCH lcx_dbuf_validation_error INTO DATA(val_exc2).
      MESSAGE val_exc2->mv_text TYPE 'S' DISPLAY LIKE 'E'. LEAVE LIST-PROCESSING.
    CATCH lcx_dbuf_mapping_error INTO DATA(map_exc).
      MESSAGE map_exc->mv_text TYPE 'S' DISPLAY LIKE 'E'. LEAVE LIST-PROCESSING.
    CATCH lcx_dbuf_file_error INTO DATA(file_exc).
      MESSAGE file_exc->mv_text TYPE 'S' DISPLAY LIKE 'E'. LEAVE LIST-PROCESSING.
    CATCH lcx_dbuf_error INTO DATA(base_exc).
      MESSAGE base_exc->mv_text TYPE 'S' DISPLAY LIKE 'E'. LEAVE LIST-PROCESSING.
  ENDTRY.
