REPORT zdbuf_standalone.

INTERFACE zif_dbuf_result_writer DEFERRED.
INTERFACE zif_dbuf_file_reader DEFERRED.
INTERFACE zif_dbuf_db_committer DEFERRED.
CLASS zcl_dbuf_xlsx_reader DEFINITION DEFERRED.
CLASS zcl_dbuf_xlsm_reader DEFINITION DEFERRED.
CLASS zcl_dbuf_writer_factory DEFINITION DEFERRED.
CLASS zcl_dbuf_upload_processor DEFINITION DEFERRED.
CLASS zcl_dbuf_table_validator DEFINITION DEFERRED.
CLASS zcl_dbuf_row_validator DEFINITION DEFERRED.
CLASS zcl_dbuf_result_xlsx_writer DEFINITION DEFERRED.
CLASS zcl_dbuf_result_csv_writer DEFINITION DEFERRED.
CLASS zcl_dbuf_reader_factory DEFINITION DEFERRED.
CLASS zcl_dbuf_null_committer DEFINITION DEFERRED.
CLASS zcl_dbuf_live_committer DEFINITION DEFERRED.
CLASS zcl_dbuf_huge_xlsx_reader DEFINITION DEFERRED.
CLASS zcl_dbuf_file_handler DEFINITION DEFERRED.
CLASS zcl_dbuf_dsv_reader DEFINITION DEFERRED.
CLASS zcl_dbuf_committer_factory DEFINITION DEFERRED.
CLASS zcl_dbuf_column_mapper DEFINITION DEFERRED.
CLASS zcl_dbuf_auth_checker DEFINITION DEFERRED.
CLASS zcx_dbuf_error DEFINITION
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

CLASS zcx_dbuf_auth_error DEFINITION
  INHERITING FROM zcx_dbuf_error
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        text     TYPE string OPTIONAL
        previous TYPE REF TO cx_root OPTIONAL.

ENDCLASS.
CLASS zcx_dbuf_auth_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( text = text previous = previous ).
  ENDMETHOD.
ENDCLASS.

CLASS zcx_dbuf_file_error DEFINITION
  INHERITING FROM zcx_dbuf_error
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        text     TYPE string OPTIONAL
        previous TYPE REF TO cx_root OPTIONAL.

ENDCLASS.
CLASS zcx_dbuf_file_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( text = text previous = previous ).
  ENDMETHOD.
ENDCLASS.

CLASS zcx_dbuf_mapping_error DEFINITION
  INHERITING FROM zcx_dbuf_error
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        text     TYPE string OPTIONAL
        previous TYPE REF TO cx_root OPTIONAL.

ENDCLASS.
CLASS zcx_dbuf_mapping_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( text = text previous = previous ).
  ENDMETHOD.
ENDCLASS.

CLASS zcx_dbuf_validation_error DEFINITION
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
    super->constructor( text = text previous = previous ).
  ENDMETHOD.
ENDCLASS.

INTERFACE zif_dbuf_db_committer.

  TYPES:
    BEGIN OF commit_result,
      rows_committed TYPE i,
      rows_failed    TYPE i,
      message        TYPE string,
    END OF commit_result.

  METHODS commit
    IMPORTING
      table_name    TYPE tabname
      table_ref     TYPE REF TO data
    RETURNING
      VALUE(result) TYPE char1ommit_result
    RAISING
      zcx_dbuf_validation_error.

ENDINTERFACE.

INTERFACE zif_dbuf_file_reader.

  TYPES:
    BEGIN OF row,
      cells TYPE string_table,
    END OF row,
    rows TYPE STANDARD TABLE OF row WITH DEFAULT KEY,
    BEGIN OF sheet,
      name TYPE string,
      rows TYPE rows,
    END OF sheet,
    sheets TYPE STANDARD TABLE OF sheet WITH DEFAULT KEY.

  "! Read file content and return parsed sheets.
  METHODS read
    IMPORTING
      file_content  TYPE xstring
      has_header    TYPE abap_bool DEFAULT abap_true
    RETURNING
      VALUE(result) TYPE sheets
    RAISING
      zcx_dbuf_file_error.

ENDINTERFACE.

INTERFACE zif_dbuf_result_writer.

  TYPES:
    BEGIN OF result_row,
      row_number TYPE i,
      status     TYPE c LENGTH 1,
      message    TYPE string,
      raw_data   TYPE string,
    END OF result_row,
    result_rows TYPE STANDARD TABLE OF result_row WITH DEFAULT KEY.

  METHODS write
    IMPORTING
      table_name    TYPE tabname
      rows          TYPE result_rows
    RETURNING
      VALUE(result) TYPE xstring
    RAISING
      zcx_dbuf_file_error.

ENDINTERFACE.

CLASS zcl_dbuf_auth_checker DEFINITION
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
CLASS zcl_dbuf_column_mapper DEFINITION
  FINAL
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
      IMPORTING
        table_name    TYPE tabname
        header_row    TYPE string_table
      RETURNING
        VALUE(result) TYPE column_mappings
      RAISING
        zcx_dbuf_mapping_error.

  PRIVATE SECTION.
    METHODS get_ddic_fields
      IMPORTING
        table_name    TYPE tabname
      RETURNING
        VALUE(result) TYPE STANDARD TABLE.

ENDCLASS.
CLASS zcl_dbuf_committer_factory DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS create
      IMPORTING
        test_mode     TYPE abap_bool DEFAULT abap_false
      RETURNING
        VALUE(result) TYPE REF TO zif_dbuf_db_committer.
ENDCLASS.
CLASS zcl_dbuf_dsv_reader DEFINITION FINAL CREATE PUBLIC.

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
      IMPORTING separator TYPE char1.

  PRIVATE SECTION.
    DATA separator TYPE char1s VALUE ','.

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
CLASS zcl_dbuf_file_handler DEFINITION
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
CLASS zcl_dbuf_huge_xlsx_reader DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_file_reader.
ENDCLASS.
CLASS zcl_dbuf_live_committer DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_db_committer.
ENDCLASS.
CLASS zcl_dbuf_null_committer DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_db_committer.
ENDCLASS.
CLASS zcl_dbuf_reader_factory DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS:
      ext_csv      TYPE string VALUE 'CSV',
      ext_tsv      TYPE string VALUE 'TSV',
      ext_psv      TYPE string VALUE 'PSV',
      ext_txt      TYPE string VALUE 'TXT',
      ext_xlsx     TYPE string VALUE 'XLSX',
      ext_xlsm     TYPE string VALUE 'XLSM',
      ext_xlshuge  TYPE string VALUE 'XLSHUGE'.

    CLASS-METHODS create_for_extension
      IMPORTING
        extension     TYPE string
        separator     TYPE char1 OPTIONAL
      RETURNING
        VALUE(result) TYPE REF TO zif_dbuf_file_reader.

    CLASS-METHODS separator_for_extension
      IMPORTING
        extension     TYPE string
      RETURNING
        VALUE(result) TYPE char1.

ENDCLASS.
CLASS zcl_dbuf_result_csv_writer DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_result_writer.
ENDCLASS.
CLASS zcl_dbuf_result_xlsx_writer DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_result_writer.
ENDCLASS.
CLASS zcl_dbuf_row_validator DEFINITION FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF validation_result,
        row_index TYPE i,
        is_valid  TYPE abap_bool,
        message   TYPE string,
      END OF validation_result.

    METHODS validate_row
      IMPORTING
        row_index     TYPE i
        cells         TYPE string_table
        mappings      TYPE zcl_dbuf_column_mapper=>column_mappings
        table_name    TYPE tabname
      RETURNING
        VALUE(result) TYPE validation_result.

  PRIVATE SECTION.
    METHODS get_field_metadata
      IMPORTING
        table_name    TYPE tabname
        field_name    TYPE fieldname
      RETURNING
        VALUE(result) TYPE dd03l.

    METHODS check_length
      IMPORTING
        value         TYPE string
        field_def     TYPE dd03l
      RETURNING
        VALUE(result) TYPE abap_bool.

ENDCLASS.
CLASS zcl_dbuf_table_validator DEFINITION
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Validates table name: Z*/Y* namespace + DDIC TRANSP check.
    METHODS validate
      IMPORTING
        table_name TYPE tabname
      RAISING
        zcx_dbuf_validation_error.

  PRIVATE SECTION.
    METHODS is_custom_namespace
      IMPORTING
        table_name    TYPE tabname
      RETURNING
        VALUE(result) TYPE abap_bool.

    METHODS exists_in_ddic
      IMPORTING
        table_name    TYPE tabname
      RETURNING
        VALUE(result) TYPE abap_bool.

ENDCLASS.
CLASS zcl_dbuf_upload_processor DEFINITION FINAL CREATE PUBLIC.

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
      IMPORTING
        params TYPE upload_params.

    METHODS execute
      RETURNING
        VALUE(result_xstring) TYPE xstring
      RAISING
        zcx_dbuf_error.

  PRIVATE SECTION.
    DATA ms_params   TYPE upload_params.
    DATA mo_mapper   TYPE REF TO zcl_dbuf_column_mapper.
    DATA mo_validator TYPE REF TO zcl_dbuf_row_validator.

    METHODS read_file
      RETURNING
        VALUE(result) TYPE xstring
      RAISING
        zcx_dbuf_file_error.

    METHODS get_extension
      RETURNING
        VALUE(result) TYPE string.

    METHODS parse_and_process
      IMPORTING
        file_content  TYPE xstring
      RETURNING
        VALUE(result) TYPE zif_dbuf_result_writer=>result_rows
      RAISING
        zcx_dbuf_error.

    METHODS build_dynamic_table
      IMPORTING
        mappings      TYPE zcl_dbuf_column_mapper=>column_mappings
      RETURNING
        VALUE(result) TYPE REF TO data
      RAISING
        zcx_dbuf_validation_error.

    METHODS fill_dynamic_row
      IMPORTING
        row_ref    TYPE REF TO data
        cells      TYPE string_table
        mappings   TYPE zcl_dbuf_column_mapper=>column_mappings.

ENDCLASS.
CLASS zcl_dbuf_writer_factory DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    CONSTANTS:
      fmt_xlsx TYPE string VALUE 'XLSX',
      fmt_csv  TYPE string VALUE 'CSV'.

    CLASS-METHODS create
      IMPORTING
        format        TYPE string DEFAULT 'XLSX'
      RETURNING
        VALUE(result) TYPE REF TO zif_dbuf_result_writer.
ENDCLASS.
CLASS zcl_dbuf_xlsm_reader DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_file_reader.
ENDCLASS.
CLASS zcl_dbuf_xlsx_reader DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_dbuf_file_reader.
ENDCLASS.
CLASS zcl_dbuf_xlsx_reader IMPLEMENTATION.
  METHOD zif_dbuf_file_reader~read.
    DATA(excel)  = NEW zcl_excel( ).
    DATA(reader) = NEW zcl_excel_reader_2007( ).
    TRY.
        reader->load_data( EXPORTING iv_data = file_content CHANGING io_excel = excel ).
      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION TYPE zcx_dbuf_file_error
          EXPORTING text = |XLSX read failed: { exc->if_message~get_text( ) }| previous = exc.
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

CLASS zcl_dbuf_writer_factory IMPLEMENTATION.
  METHOD create.
    CASE to_upper( format ).
      WHEN fmt_csv.
        result = NEW zcl_dbuf_result_csv_writer( ).
      WHEN OTHERS.
        result = NEW zcl_dbuf_result_xlsx_writer( ).
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

CLASS zcl_dbuf_upload_processor IMPLEMENTATION.

  METHOD constructor.
    ms_params   = params.
    mo_mapper   = NEW zcl_dbuf_column_mapper( ).
    mo_validator = NEW zcl_dbuf_row_validator( ).
  ENDMETHOD.

  METHOD execute.
    NEW zcl_dbuf_table_validator( )->validate( ms_params-table_name ).
    NEW zcl_dbuf_auth_checker( )->check( ms_params-table_name ).

    DATA(file_content) = read_file( ).
    DATA(result_rows)  = parse_and_process( file_content ).

    DATA(writer) = zcl_dbuf_writer_factory=>create( ms_params-out_format ).
    result_xstring = writer->write( table_name = ms_params-table_name rows = result_rows ).
  ENDMETHOD.

  METHOD read_file.
    result = NEW zcl_dbuf_file_handler( )->upload_to_xstring( ms_params-file_path ).
  ENDMETHOD.

  METHOD get_extension.
    DATA(parts) = VALUE string_table( ).
    SPLIT ms_params-file_path AT '.' INTO TABLE parts.
    DATA(count) = lines( parts ).
    IF count > 1.
      result = to_upper( parts[ count ] ).
    ENDIF.
  ENDMETHOD.

  METHOD parse_and_process.
    DATA(extension) = get_extension( ).
    DATA(reader)    = zcl_dbuf_reader_factory=>create_for_extension(
      extension = extension separator = ms_params-separator ).

    DATA(sheets) = reader->read(
      file_content = file_content
      has_header   = ms_params-has_header ).

    IF sheets IS INITIAL.
      RAISE EXCEPTION TYPE zcx_dbuf_file_error
        EXPORTING text = 'File contains no parseable sheets'.
    ENDIF.

    DATA(rows) = sheets[ 1 ]-rows.
    IF rows IS INITIAL.
      RAISE EXCEPTION TYPE zcx_dbuf_file_error
        EXPORTING text = 'File sheet is empty'.
    ENDIF.

    DATA(start_row) = 2.
    DATA header_tokens TYPE string_table.

    IF ms_params-has_header = abap_true.
      header_tokens = rows[ 1 ]-cells.
    ELSE.
      start_row = 1.
      SELECT fieldname FROM dd03l INTO TABLE @header_tokens
        WHERE tabname = @ms_params-table_name AND as4local = 'A'
          AND fieldname NOT LIKE '.%' ORDER BY position.
    ENDIF.

    DATA(mappings)   = mo_mapper->map_headers(
      table_name = ms_params-table_name header_row = header_tokens ).
    DATA(table_ref)  = build_dynamic_table( mappings ).
    DATA(committer)  = zcl_dbuf_committer_factory=>create( ms_params-test_mode ).

    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    ASSIGN table_ref->* TO <table>.

    DATA(row_idx) = start_row.
    LOOP AT rows INTO DATA(data_row) FROM start_row.
      DATA(vr) = mo_validator->validate_row(
        row_index  = row_idx
        cells      = data_row-cells
        mappings   = mappings
        table_name = ms_params-table_name ).

      IF vr-is_valid = abap_false.
        APPEND VALUE zif_dbuf_result_writer=>result_row(
          row_number = row_idx status = 'E' message = vr-message
          raw_data   = concat_lines_of( table = data_row-cells sep = ',' )
        ) TO result.
        row_idx = row_idx + 1.
        CONTINUE.
      ENDIF.

      CREATE DATA DATA(row_ref) LIKE LINE OF <table>.
      fill_dynamic_row( row_ref = row_ref cells = data_row-cells mappings = mappings ).
      INSERT row_ref->* INTO TABLE <table>.

      APPEND VALUE zif_dbuf_result_writer=>result_row(
        row_number = row_idx status = 'S' message = 'OK'
        raw_data   = concat_lines_of( table = data_row-cells sep = ',' )
      ) TO result.
      row_idx = row_idx + 1.
    ENDLOOP.

    committer->commit( table_name = ms_params-table_name table_ref = table_ref ).
  ENDMETHOD.

  METHOD build_dynamic_table.
    DATA(struct_desc) = cl_abap_structdescr=>describe_by_name( ms_params-table_name ).
    DATA(table_type)  = cl_abap_tabledescr=>create(
      p_line_type = struct_desc
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

CLASS zcl_dbuf_table_validator IMPLEMENTATION.

  METHOD validate.
    IF is_custom_namespace( table_name ) = abap_false.
      RAISE EXCEPTION TYPE zcx_dbuf_validation_error
        EXPORTING text = |Table { table_name } is not in Z* or Y* namespace|.
    ENDIF.

    IF exists_in_ddic( table_name ) = abap_false.
      RAISE EXCEPTION TYPE zcx_dbuf_validation_error
        EXPORTING text = |Table { table_name } not found in DDIC as transparent table|.
    ENDIF.
  ENDMETHOD.

  METHOD is_custom_namespace.
    DATA(first_char) = table_name(1).
    result = xsdbool( first_char = 'Z' OR first_char = 'Y' ).
  ENDMETHOD.

  METHOD exists_in_ddic.
    SELECT SINGLE tabname FROM dd02l INTO @DATA(found)
      WHERE tabname  = @table_name
        AND tabclass = 'TRANSP'
        AND as4local = 'A'.
    result = xsdbool( sy-subrc = 0 AND found IS NOT INITIAL ).
  ENDMETHOD.

ENDCLASS.

CLASS zcl_dbuf_row_validator IMPLEMENTATION.

  METHOD validate_row.
    result-row_index = row_index.
    result-is_valid  = abap_true.

    LOOP AT mappings INTO DATA(mapping).
      READ TABLE cells INTO DATA(cell_value) INDEX mapping-position.
      IF sy-subrc <> 0.
        result-is_valid = abap_false.
        result-message  = |Row { row_index }: Missing value for field { mapping-field_name }|.
        RETURN.
      ENDIF.

      DATA(field_def) = get_field_metadata( table_name = table_name field_name = mapping-field_name ).

      IF field_def-fieldname IS NOT INITIAL.
        IF check_length( value = cell_value field_def = field_def ) = abap_false.
          result-is_valid = abap_false.
          result-message  = |Row { row_index }: Value "{ cell_value }" exceeds max length |
                         && |{ field_def-leng } for field { mapping-field_name }|.
          RETURN.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_field_metadata.
    SELECT SINGLE * FROM dd03l INTO @result
      WHERE tabname   = @table_name
        AND fieldname = @field_name
        AND as4local  = 'A'.
  ENDMETHOD.

  METHOD check_length.
    IF field_def-leng = 0.
      result = abap_true.
      RETURN.
    ENDIF.
    result = xsdbool( strlen( value ) <= field_def-leng ).
  ENDMETHOD.

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

CLASS zcl_dbuf_result_csv_writer IMPLEMENTATION.
  METHOD zif_dbuf_result_writer~write.
    DATA(nl) = cl_abap_char_utilities=>newline.
    DATA(output) = |Row#,Status,Message,Raw Data{ nl }|.

    LOOP AT rows INTO DATA(row).
      DATA(msg)  = replace( val = row-message  sub = ',' of = ';' ).
      DATA(data) = replace( val = row-raw_data sub = ',' of = ';' ).
      output = output && |{ row-row_number },{ row-status },{ msg },{ data }{ nl }|.
    ENDLOOP.

    TRY.
        result = cl_abap_codepage=>convert_from( output ).
      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION TYPE zcx_dbuf_file_error
          EXPORTING text = |CSV encode failed: { exc->if_message~get_text( ) }| previous = exc.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

CLASS zcl_dbuf_reader_factory IMPLEMENTATION.

  METHOD create_for_extension.
    CASE to_upper( extension ).
      WHEN ext_xlsx.
        result = NEW zcl_dbuf_xlsx_reader( ).
      WHEN ext_xlsm.
        result = NEW zcl_dbuf_xlsm_reader( ).
      WHEN ext_xlshuge.
        result = NEW zcl_dbuf_huge_xlsx_reader( ).
      WHEN OTHERS.
        DATA(dsv) = NEW zcl_dbuf_dsv_reader( ).
        DATA(sep) = COND c(
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
      WHEN OTHERS.  result = ','.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.

CLASS zcl_dbuf_null_committer IMPLEMENTATION.
  METHOD zif_dbuf_db_committer~commit.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    ASSIGN table_ref->* TO <table>.
    DATA(row_count) = COND i( WHEN <table> IS ASSIGNED THEN lines( <table> ) ELSE 0 ).
    result-rows_committed = 0.
    result-rows_failed    = 0.
    result-message = |TEST MODE: { row_count } row(s) validated; no DB write performed|.
  ENDMETHOD.
ENDCLASS.

CLASS zcl_dbuf_live_committer IMPLEMENTATION.
  METHOD zif_dbuf_db_committer~commit.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.
    ASSIGN table_ref->* TO <table>.
    IF <table> IS NOT ASSIGNED OR <table> IS INITIAL.
      result-message = 'No data to commit'.
      RETURN.
    ENDIF.
    TRY.
        MODIFY (table_name) CLIENT SPECIFIED FROM TABLE <table>. "#EC CI_DYNTAB
        IF sy-subrc = 0.
          COMMIT WORK.
          result-rows_committed = lines( <table> ).
          result-message = |{ result-rows_committed } row(s) committed to { table_name }|.
        ELSE.
          ROLLBACK WORK.
          result-rows_failed = lines( <table> ).
          result-message = |MODIFY { table_name } failed. SY-SUBRC = { sy-subrc }|.
          RAISE EXCEPTION TYPE zcx_dbuf_validation_error EXPORTING text = result-message.
        ENDIF.
      CATCH cx_sy_open_sql_db INTO DATA(exc).
        ROLLBACK WORK.
        result-rows_failed = lines( <table> ).
        result-message = exc->if_message~get_text( ).
        RAISE EXCEPTION TYPE zcx_dbuf_validation_error
          EXPORTING text = result-message previous = exc.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

CLASS zcl_dbuf_huge_xlsx_reader IMPLEMENTATION.
  METHOD zif_dbuf_file_reader~read.
    DATA(excel)  = NEW zcl_excel( ).
    DATA(reader) = NEW zcl_excel_reader_huge_file( ).
    TRY.
        reader->load_data( EXPORTING iv_data = file_content CHANGING io_excel = excel ).
      CATCH cx_root INTO DATA(exc).
        RAISE EXCEPTION TYPE zcx_dbuf_file_error
          EXPORTING text = |Huge XLSX read failed: { exc->if_message~get_text( ) }| previous = exc.
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
      IMPORTING buffer       = result
      TABLES binary_tab   = binary_tab
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

CLASS zcl_dbuf_committer_factory IMPLEMENTATION.
  METHOD create.
    IF test_mode = abap_true.
      result = NEW zcl_dbuf_null_committer( ).
    ELSE.
      result = NEW zcl_dbuf_live_committer( ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS zcl_dbuf_column_mapper IMPLEMENTATION.

  METHOD map_headers.
    IF header_row IS INITIAL.
      RAISE EXCEPTION TYPE zcx_dbuf_mapping_error
        EXPORTING text = |Header row is empty for table { table_name }|.
    ENDIF.

    DATA(ddic_fields) = get_ddic_fields( table_name ).

    LOOP AT header_row INTO DATA(token).
      DATA(position)    = sy-tabix.
      DATA(upper_token) = to_upper( condense( token ) ).
      READ TABLE ddic_fields INTO DATA(field_row) WITH KEY ('FIELDNAME') = upper_token.
      IF sy-subrc = 0.
        APPEND VALUE column_mapping(
          header_token = token
          field_name   = upper_token
          position     = position ) TO result.
      ENDIF.
    ENDLOOP.

    IF result IS INITIAL.
      RAISE EXCEPTION TYPE zcx_dbuf_mapping_error
        EXPORTING text =
          |No header tokens matched DDIC fields of { table_name }. Check column names.|.
    ENDIF.
  ENDMETHOD.

  METHOD get_ddic_fields.
    SELECT fieldname FROM dd03l INTO TABLE @result
      WHERE tabname  = @table_name
        AND as4local = 'A'
        AND fieldname NOT LIKE '.%'.
  ENDMETHOD.

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

****************************************************
INTERFACE lif_abapmerge_marker.
* abapmerge 0.16.8 - 2026-05-11T12:26:56.187Z
  CONSTANTS c_merge_timestamp TYPE string VALUE `2026-05-11T12:26:56.187Z`.
  CONSTANTS c_abapmerge_version TYPE string VALUE `0.16.8`.
ENDINTERFACE.
****************************************************
