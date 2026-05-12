CLASS zcl_dbuf_upload_processor DEFINITION
  PUBLIC FINAL CREATE PUBLIC.

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
        row_ref  TYPE REF TO data
        cells    TYPE string_table
        mappings TYPE zcl_dbuf_column_mapper=>column_mappings.

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
    result_xstring = writer->write( table_name = ms_params-table_name
                                    rows       = result_rows ).
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
      extension = extension
      separator = ms_params-separator ).

    DATA(sheets) = reader->read(
      file_content = file_content
      has_header   = ms_params-has_header ).
    DATA header_tokens TYPE string_table.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    IF sheets IS INITIAL.
      RAISE EXCEPTION NEW zcx_dbuf_file_error( text = 'File contains no parseable sheets' ).
    ENDIF.

    DATA(rows) = sheets[ 1 ]-rows.
    IF rows IS INITIAL.
      RAISE EXCEPTION NEW zcx_dbuf_file_error( text = 'File sheet is empty' ).
    ENDIF.

    DATA(start_row) = 2.


    IF ms_params-has_header = abap_true.
      header_tokens = rows[ 1 ]-cells.
    ELSE.
      start_row = 1.
      SELECT fieldname FROM dd03l
        WHERE tabname = @ms_params-table_name AND as4local = 'A'
          AND fieldname NOT LIKE '.%' ORDER BY position INTO TABLE @header_tokens.
    ENDIF.

    DATA(mappings)   = mo_mapper->map_headers(
      table_name = ms_params-table_name
      header_row = header_tokens ).
    DATA(table_ref)  = build_dynamic_table( mappings ).
    DATA(committer)  = zcl_dbuf_committer_factory=>create( ms_params-test_mode ).


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
          raw_data   = concat_lines_of( table = data_row-cells
                                        sep   = ',' )
          ) TO result.
        row_idx = row_idx + 1.
        CONTINUE.
      ENDIF.

      CREATE DATA DATA(row_ref) LIKE LINE OF <table>.
      fill_dynamic_row( row_ref  = row_ref
                        cells    = data_row-cells
                        mappings = mappings ).
      INSERT row_ref->* INTO TABLE <table>.

      APPEND VALUE zif_dbuf_result_writer=>result_row(
        row_number = row_idx status = 'S' message = 'OK'
        raw_data   = concat_lines_of( table = data_row-cells
                                      sep   = ',' )
        ) TO result.
      row_idx = row_idx + 1.
    ENDLOOP.

    committer->commit( table_name = ms_params-table_name
                       table_ref  = table_ref ).
  ENDMETHOD.

  METHOD build_dynamic_table.
    DATA(struct_desc) = cl_abap_structdescr=>describe_by_name( ms_params-table_name ).
    DATA(table_type)  = cl_abap_tabledescr=>create(
      p_line_type  = struct_desc
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
